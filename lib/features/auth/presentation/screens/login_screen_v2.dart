import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/auth_button_v2.dart';
import '../widgets/auth_text_field_v2.dart';
import '../../provider/auth_provider.dart';
import '../../domain/entities/auth_state.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/route_names.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/animation_consts.dart';
import '../../../../core/utils/v2_constants_adapter.dart';
import '../../../../core/utils/app_logger.dart';

/// 改善されたログイン画面
class LoginScreenV2 extends ConsumerStatefulWidget {
  const LoginScreenV2({super.key});

  @override
  ConsumerState<LoginScreenV2> createState() => _LoginScreenV2State();
}

class _LoginScreenV2State extends ConsumerState<LoginScreenV2>
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
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: SpacingConsts.xl),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: SpacingConsts.xxl * 2),

                      // ヘッダーセクション
                      _buildHeader(),

                      const SizedBox(height: SpacingConsts.xxl * 2),

                      // フォームセクション
                      _buildForm(),

                      const SizedBox(height: SpacingConsts.xl),

                      // ログインボタン
                      _buildLoginButton(authState, authNotifier),

                      const SizedBox(height: SpacingConsts.xl),

                      // 区切り線
                      _buildDivider(),

                      const SizedBox(height: SpacingConsts.xl),

                      // ソーシャルログインボタン
                      _buildSocialLoginButtons(authState, authNotifier),

                      const SizedBox(height: SpacingConsts.xxl),

                      // サインアップリンク
                      _buildSignUpLink(),

                      const SizedBox(height: SpacingConsts.xl),
                    ],
                  ),
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
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ColorConsts.primary, ColorConsts.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: ColorConsts.primary.withOpacity(0.3),
                offset: const Offset(0, 8),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Icon(
            Icons.timer_outlined,
            color: Colors.white,
            size: 48,
          ),
        ),
        const SizedBox(height: SpacingConsts.xl),
        Text(
          'おかえりなさい',
          style: TextConsts.h1.copyWith(
            color: ColorConsts.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: SpacingConstsV2.s),
        Text(
          '今日も目標に向かって\n一歩ずつ前進しましょう',
          style: TextConstsV2.body.copyWith(
            color: ColorConsts.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        AuthTextFieldV2(
          labelText: 'メールアドレス',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          errorText: _emailError,
          autofocus: true,
          onChanged: (value) {
            setState(() {
              _email = value;
              _emailError = _validateEmail(value);
            });
          },
        ),
        const SizedBox(height: SpacingConstsV2.l),
        AuthTextFieldV2(
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
    return AuthButtonV2(
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
                colors: [
                  ColorConsts.border.withOpacity(0),
                  ColorConsts.border,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SpacingConstsV2.l),
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
                colors: [
                  ColorConsts.border,
                  ColorConsts.border.withOpacity(0),
                ],
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
        AuthButtonV2(
          type: AuthButtonType.google,
          text: 'Googleでログイン',
          isLoading: isLoading,
          onPressed: isLoading ? null : () => _handleGoogleLogin(authNotifier),
        ),

        // AppleログインボタンはiOSのみ
        if (AuthButtonV2.shouldShowAppleLogin()) ...[
          const SizedBox(height: SpacingConstsV2.m),
          AuthButtonV2(
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
        Text(
          'アカウントをお持ちでない方は ',
          style: TextConstsV2.body.copyWith(
            color: ColorConsts.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(RouteNames.signup);
          },
          child: Text(
            'サインアップ',
            style: TextConstsV2.body.copyWith(
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
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: ColorConsts.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(SpacingConstsV2.l),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}