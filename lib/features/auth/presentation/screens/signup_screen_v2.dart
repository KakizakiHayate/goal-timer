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

/// 改善されたサインアップ画面
class SignupScreenV2 extends ConsumerStatefulWidget {
  const SignupScreenV2({super.key});

  @override
  ConsumerState<SignupScreenV2> createState() => _SignupScreenV2State();
}

class _SignupScreenV2State extends ConsumerState<SignupScreenV2>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  
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
                      const SizedBox(height: SpacingConsts.xxl),

                      // 戻るボタン
                      _buildBackButton(),

                      const SizedBox(height: SpacingConsts.l),

                      // ヘッダーセクション
                      _buildHeader(),

                      const SizedBox(height: SpacingConsts.xxl),

                      // フォームセクション
                      _buildForm(),

                      const SizedBox(height: SpacingConsts.xl),

                      // サインアップボタン
                      _buildSignupButton(authState, authNotifier),

                      const SizedBox(height: SpacingConsts.xl),

                      // 区切り線
                      _buildDivider(),

                      const SizedBox(height: SpacingConsts.xl),

                      // ソーシャルサインアップボタン
                      _buildSocialSignupButtons(authState, authNotifier),

                      const SizedBox(height: SpacingConsts.xxl),

                      // ログインリンク
                      _buildLoginLink(),

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

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ColorConsts.cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: ColorConsts.shadowLight,
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: ColorConsts.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'アカウント作成',
          style: TextConsts.h1.copyWith(
            color: ColorConsts.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: SpacingConsts.s),
        Text(
          '目標達成への旅を\n今日から始めましょう',
          style: TextConsts.body.copyWith(
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
        const SizedBox(height: SpacingConsts.l),
        AuthTextFieldV2(
          labelText: 'パスワード',
          obscureText: true,
          textInputAction: TextInputAction.next,
          errorText: _passwordError,
          onChanged: (value) {
            setState(() {
              _password = value;
              _passwordError = _validatePassword(value);
              // パスワード確認の再検証
              if (_confirmPassword.isNotEmpty) {
                _confirmPasswordError = _validateConfirmPassword(_confirmPassword);
              }
            });
          },
        ),
        const SizedBox(height: SpacingConsts.l),
        AuthTextFieldV2(
          labelText: 'パスワード確認',
          obscureText: true,
          textInputAction: TextInputAction.done,
          errorText: _confirmPasswordError,
          onChanged: (value) {
            setState(() {
              _confirmPassword = value;
              _confirmPasswordError = _validateConfirmPassword(value);
            });
          },
          onSubmitted: (_) {
            if (_isFormValid()) {
              _handleEmailSignup(ref.read(authViewModelProvider.notifier));
            }
          },
        ),
      ],
    );
  }

  Widget _buildSignupButton(AuthState authState, dynamic authNotifier) {
    return AuthButtonV2(
      type: AuthButtonType.email,
      text: 'アカウントを作成',
      isLoading: authState == AuthState.loading,
      onPressed: _isFormValid() ? () => _handleEmailSignup(authNotifier) : null,
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

  Widget _buildSocialSignupButtons(AuthState authState, dynamic authNotifier) {
    final bool isLoading = authState == AuthState.loading;

    return Column(
      children: [
        // Googleサインアップボタン
        AuthButtonV2(
          type: AuthButtonType.google,
          text: 'Googleでサインアップ',
          isLoading: isLoading,
          onPressed: isLoading ? null : () => _handleGoogleSignup(authNotifier),
        ),

        // AppleサインアップボタンはiOSのみ
        if (AuthButtonV2.shouldShowAppleLogin()) ...[
          const SizedBox(height: SpacingConsts.m),
          AuthButtonV2(
            type: AuthButtonType.apple,
            text: 'Appleでサインアップ',
            isLoading: isLoading,
            onPressed: isLoading ? null : () => _handleAppleSignup(authNotifier),
          ),
        ],
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'すでにアカウントをお持ちの方は ',
          style: TextConsts.body.copyWith(
            color: ColorConsts.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'ログイン',
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
    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
      return 'パスワードには英字と数字を含めてください';
    }
    return null;
  }

  String? _validateConfirmPassword(String value) {
    if (value.isEmpty) return 'パスワード確認を入力してください';
    if (value != _password) return 'パスワードが一致しません';
    return null;
  }

  bool _isFormValid() {
    return _email.isNotEmpty &&
        _password.isNotEmpty &&
        _confirmPassword.isNotEmpty &&
        _emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null;
  }

  // 認証処理
  Future<void> _handleEmailSignup(dynamic authNotifier) async {
    try {
      await authNotifier.signUpWithEmail(_email, _password);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('アカウント作成に失敗しました');
      }
    }
  }

  Future<void> _handleGoogleSignup(dynamic authNotifier) async {
    try {
      await authNotifier.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Googleサインアップに失敗しました');
      }
    }
  }

  Future<void> _handleAppleSignup(dynamic authNotifier) async {
    try {
      await authNotifier.signInWithApple();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Appleサインアップに失敗しました');
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
        margin: const EdgeInsets.all(SpacingConsts.l),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}