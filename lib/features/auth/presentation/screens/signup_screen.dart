import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../../provider/auth_provider.dart';
import '../../domain/entities/auth_state.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/route_names.dart';

/// サインアップ画面
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _displayName = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String? _displayNameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorConsts.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ヘッダーセクション
                  _buildHeader(),

                  const SizedBox(height: 32),

                  // フォームセクション
                  _buildForm(),

                  const SizedBox(height: 32),

                  // サインアップボタン
                  _buildSignupButton(authState, authNotifier),

                  const SizedBox(height: 24),

                  // 区切り線
                  _buildDivider(),

                  const SizedBox(height: 24),

                  // ソーシャルログインボタン
                  _buildSocialLoginButtons(authState, authNotifier),

                  const SizedBox(height: 32),

                  // ログインリンク
                  _buildLoginLink(),

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
          'アカウント作成',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: ColorConsts.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '目標達成の旅を始めましょう',
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
          labelText: 'ユーザー名',
          keyboardType: TextInputType.name,
          errorText: _displayNameError,
          onChanged: (value) {
            setState(() {
              _displayName = value;
              _displayNameError = _validateDisplayName(value);
            });
          },
        ),
        const SizedBox(height: 16),
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
              // パスワードが変更されたら確認パスワードも再チェック
              if (_confirmPassword.isNotEmpty) {
                _confirmPasswordError = _validateConfirmPassword(
                  _confirmPassword,
                );
              }
            });
          },
        ),
        const SizedBox(height: 16),
        AuthTextField(
          labelText: 'パスワード確認',
          obscureText: true,
          errorText: _confirmPasswordError,
          onChanged: (value) {
            setState(() {
              _confirmPassword = value;
              _confirmPasswordError = _validateConfirmPassword(value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildSignupButton(AuthState authState, dynamic authNotifier) {
    return AuthButton(
      type: AuthButtonType.email,
      text: 'アカウントを作成',
      isLoading: authState == AuthState.loading,
      onPressed: _isFormValid() ? () => _handleEmailSignup(authNotifier) : null,
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
        // Googleサインアップボタン
        AuthButton(
          type: AuthButtonType.google,
          text: 'Googleで作成',
          isLoading: isLoading,
          onPressed: isLoading ? null : () => _handleGoogleSignup(authNotifier),
        ),

        // AppleサインアップボタンはiOSのみ
        if (AuthButton.shouldShowAppleLogin()) ...[
          const SizedBox(height: 12),
          AuthButton(
            type: AuthButtonType.apple,
            text: 'Appleで作成',
            isLoading: isLoading,
            onPressed:
                isLoading ? null : () => _handleAppleSignup(authNotifier),
          ),
        ],
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'すでにアカウントをお持ちですか？ ',
          style: TextStyle(fontSize: 14, color: ColorConsts.textSecondary),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'ログイン',
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
  String? _validateDisplayName(String value) {
    if (value.isEmpty) return 'ユーザー名を入力してください';
    if (value.length < 2) return 'ユーザー名は2文字以上で入力してください';
    if (value.length > 50) return 'ユーザー名は50文字以下で入力してください';
    return null;
  }

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
    if (value.length > 100) return 'パスワードは100文字以下で入力してください';
    return null;
  }

  String? _validateConfirmPassword(String value) {
    if (value.isEmpty) return 'パスワード確認を入力してください';
    if (value != _password) return 'パスワードが一致しません';
    return null;
  }

  bool _isFormValid() {
    return _displayName.isNotEmpty &&
        _email.isNotEmpty &&
        _password.isNotEmpty &&
        _confirmPassword.isNotEmpty &&
        _displayNameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null;
  }

  // 認証処理
  Future<void> _handleEmailSignup(dynamic authNotifier) async {
    try {
      await authNotifier.signUpWithEmail(_email, _password, _displayName);
    } catch (e) {
      if (mounted) {
        _showErrorDialog('アカウント作成に失敗しました', e.toString());
      }
    }
  }

  Future<void> _handleGoogleSignup(dynamic authNotifier) async {
    try {
      await authNotifier.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Googleアカウント作成に失敗しました', e.toString());
      }
    }
  }

  Future<void> _handleAppleSignup(dynamic authNotifier) async {
    try {
      await authNotifier.signInWithApple();
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Appleアカウント作成に失敗しました', e.toString());
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
