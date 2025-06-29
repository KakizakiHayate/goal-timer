import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../../provider/auth_provider.dart';
import '../../domain/entities/auth_state.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/route_names.dart';

/// ログイン画面
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String? _emailError;
  String? _passwordError;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final authNotifier = ref.read(authViewModelProvider.notifier);

    // 認証成功時の画面遷移
    ref.listen(authViewModelProvider, (previous, next) {
      if (next == AuthState.authenticated) {
        Navigator.of(context).pushReplacementNamed(RouteNames.home);
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),

                  // ヘッダーセクション
                  _buildHeader(),

                  const SizedBox(height: 48),

                  // フォームセクション
                  _buildForm(),

                  const SizedBox(height: 32),

                  // ログインボタン
                  _buildLoginButton(authState, authNotifier),

                  const SizedBox(height: 24),

                  // 区切り線
                  _buildDivider(),

                  const SizedBox(height: 24),

                  // ソーシャルログインボタン
                  _buildSocialLoginButtons(authState, authNotifier),

                  const SizedBox(height: 32),

                  // サインアップリンク
                  _buildSignUpLink(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // アプリアイコン（仮）
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: ColorConsts.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.timer, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 24),
        const Text(
          'おかえりなさい',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: ColorConsts.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '目標達成への道のりを続けましょう',
          style: TextStyle(fontSize: 16, color: ColorConsts.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        AuthTextField(
          labelText: 'メールアドレス',
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
          onChanged: (value) {
            setState(() {
              _email = value;
              _emailError = _validateEmail(value);
            });
          },
        ),
        const SizedBox(height: 16),
        AuthTextField(
          labelText: 'パスワード',
          obscureText: true,
          errorText: _passwordError,
          onChanged: (value) {
            setState(() {
              _password = value;
              _passwordError = _validatePassword(value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildLoginButton(AuthState authState, dynamic authNotifier) {
    return AuthButton(
      type: AuthButtonType.email,
      text: 'ログイン',
      isLoading: authState == AuthState.loading,
      onPressed: _isFormValid() ? () => _handleEmailLogin(authNotifier) : null,
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: ColorConsts.border)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'または',
            style: TextStyle(fontSize: 14, color: ColorConsts.textSecondary),
          ),
        ),
        Expanded(child: Container(height: 1, color: ColorConsts.border)),
      ],
    );
  }

  Widget _buildSocialLoginButtons(AuthState authState, dynamic authNotifier) {
    final bool isLoading = authState == AuthState.loading;

    return Column(
      children: [
        // Googleログインボタン
        AuthButton(
          type: AuthButtonType.google,
          text: 'Googleでログイン',
          isLoading: isLoading,
          onPressed: isLoading ? null : () => _handleGoogleLogin(authNotifier),
        ),

        // AppleログインボタンはiOSのみ
        if (AuthButton.shouldShowAppleLogin()) ...[
          const SizedBox(height: 12),
          AuthButton(
            type: AuthButtonType.apple,
            text: 'Appleでログイン',
            isLoading: isLoading,
            onPressed: isLoading ? null : () => _handleAppleLogin(authNotifier),
          ),
        ],
      ],
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'アカウントをお持ちでない方は ',
          style: TextStyle(fontSize: 14, color: ColorConsts.textSecondary),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(RouteNames.signup);
          },
          child: const Text(
            'サインアップ',
            style: TextStyle(
              fontSize: 14,
              color: ColorConsts.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // バリデーション関数
  String? _validateEmail(String value) {
    if (value.isEmpty) return 'メールアドレスを入力してください';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return '正しいメールアドレスを入力してください';
    }
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'パスワードを入力してください';
    if (value.length < 6) return 'パスワードは6文字以上で入力してください';
    return null;
  }

  bool _isFormValid() {
    return _email.isNotEmpty &&
        _password.isNotEmpty &&
        _emailError == null &&
        _passwordError == null;
  }

  // 認証処理
  Future<void> _handleEmailLogin(dynamic authNotifier) async {
    try {
      await authNotifier.signInWithEmail(_email, _password);
    } catch (e) {
      if (mounted) {
        _showErrorDialog('ログインに失敗しました', e.toString());
      }
    }
  }

  Future<void> _handleGoogleLogin(dynamic authNotifier) async {
    try {
      await authNotifier.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Googleログインに失敗しました', e.toString());
      }
    }
  }

  Future<void> _handleAppleLogin(dynamic authNotifier) async {
    try {
      await authNotifier.signInWithApple();
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Appleログインに失敗しました', e.toString());
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
