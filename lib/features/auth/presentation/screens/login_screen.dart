import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../../provider/auth_provider.dart';
import '../../domain/entities/auth_state.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/route_names.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/animation_consts.dart';
import '../../../../core/utils/app_logger.dart';

/// ログイン画面
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String? _emailError;
  String? _passwordError;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AnimationConsts.slow,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
      backgroundColor: ColorConsts.backgroundPrimary,
      resizeToAvoidBottomInset: true, // キーボード表示時のリサイズを有効化
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: SpacingConsts.xl,
                  vertical: SpacingConsts.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 上部余白
                    SizedBox(height: SpacingConsts.xxl),

                    // ヘッダーセクション
                    _buildHeader(),

                    SizedBox(height: SpacingConsts.xl),

                    // フォームセクション
                    _buildForm(),

                    SizedBox(height: SpacingConsts.xl),

                    // ログインボタン
                    _buildLoginButton(authState, authNotifier),

                    SizedBox(height: SpacingConsts.xl),

                    // 区切り線
                    _buildDivider(),

                    SizedBox(height: SpacingConsts.xl),

                    // ソーシャルログインボタン
                    _buildSocialLoginButtons(authState, authNotifier),

                    SizedBox(height: SpacingConsts.xxl),

                    // サインアップリンク
                    _buildSignUpLink(),

                    // 下部余白
                    SizedBox(height: SpacingConsts.xl),
                  ],
                ),
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
        // アプリアイコン
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ColorConsts.primary, ColorConsts.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: ColorConsts.primary.withOpacity(0.3),
                offset: const Offset(0, 4),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Icon(Icons.timer_outlined, color: Colors.white, size: 36),
        ),
        SizedBox(height: SpacingConsts.l),
        Text(
          'おかえりなさい',
          style: TextConsts.h1.copyWith(
            color: ColorConsts.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          ),
        ),
        SizedBox(height: SpacingConsts.xs),
        Text(
          '今日も目標に向かって\n一歩ずつ前進しましょう',
          style: TextConsts.body.copyWith(
            color: ColorConsts.textSecondary,
            height: 1.4,
          ),
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
          textInputAction: TextInputAction.next,
          errorText: _emailError,
          autofocus: false,
          onChanged: (value) {
            setState(() {
              _email = value;
              _emailError = _validateEmail(value);
            });
          },
        ),
        const SizedBox(height: SpacingConsts.l),
        AuthTextField(
          labelText: 'パスワード',
          obscureText: true,
          textInputAction: TextInputAction.done,
          errorText: _passwordError,
          onChanged: (value) {
            setState(() {
              _password = value;
              _passwordError = _validatePassword(value);
            });
          },
          onSubmitted: (_) {
            if (_isFormValid()) {
              _handleEmailLogin(ref.read(authViewModelProvider.notifier));
            }
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
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ColorConsts.border.withOpacity(0), ColorConsts.border],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SpacingConsts.l),
          child: Text(
            'または',
            style: TextConsts.caption.copyWith(
              color: ColorConsts.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ColorConsts.border, ColorConsts.border.withOpacity(0)],
              ),
            ),
          ),
        ),
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
          const SizedBox(height: SpacingConsts.m),
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
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'アカウントをお持ちでない方は ',
          style: TextConsts.body.copyWith(color: ColorConsts.textSecondary),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(RouteNames.signup);
          },
          child: Text(
            'サインアップ',
            style: TextConsts.body.copyWith(
              color: ColorConsts.primary,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: ColorConsts.primary,
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
        _showErrorSnackBar('ログインに失敗しました');
      }
    }
  }

  Future<void> _handleGoogleLogin(dynamic authNotifier) async {
    try {
      await authNotifier.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Googleログインに失敗しました');
      }
    }
  }

  Future<void> _handleAppleLogin(dynamic authNotifier) async {
    try {
      await authNotifier.signInWithApple();
    } catch (e) {
      if (mounted) {
        AppLogger.instance.e('Apple Sign-In Error', e);
        _showErrorSnackBar('Appleログインに失敗しました: ${e.toString()}');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: ColorConsts.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(SpacingConsts.l),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
