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

/// サインアップ画面
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
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
    _scrollController.dispose();
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

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final isSmallScreen = screenHeight < 700; // iPhone SE等の判定
    final isVerySmallScreen = screenHeight < 650; // iPhone SE 1st gen等
    final availableHeight =
        screenHeight - mediaQuery.padding.top - mediaQuery.padding.bottom;

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
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: availableHeight),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: SpacingConsts.xl,
                    right: SpacingConsts.xl,
                    top:
                        isVerySmallScreen
                            ? SpacingConsts.xs
                            : (isSmallScreen
                                ? SpacingConsts.s
                                : SpacingConsts.l),
                    bottom:
                        keyboardHeight > 0 ? SpacingConsts.s : SpacingConsts.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 戻るボタン
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildBackButton(),
                      ),

                      SizedBox(
                        height:
                            isVerySmallScreen
                                ? SpacingConsts.s
                                : (isSmallScreen
                                    ? SpacingConsts.l
                                    : SpacingConsts.xl),
                      ),

                      // ヘッダーセクション
                      _buildHeader(isVerySmallScreen),

                      SizedBox(
                        height:
                            isVerySmallScreen
                                ? SpacingConsts.s
                                : (isSmallScreen
                                    ? SpacingConsts.l
                                    : SpacingConsts.xl),
                      ),

                      // フォームセクション
                      _buildForm(),

                      SizedBox(
                        height:
                            isVerySmallScreen
                                ? SpacingConsts.s
                                : (isSmallScreen
                                    ? SpacingConsts.l
                                    : SpacingConsts.xl),
                      ),

                      // サインアップボタン
                      _buildSignupButton(authState, authNotifier),

                      SizedBox(
                        height:
                            isVerySmallScreen
                                ? SpacingConsts.s
                                : (isSmallScreen
                                    ? SpacingConsts.l
                                    : SpacingConsts.xl),
                      ),

                      // 区切り線
                      _buildDivider(),

                      SizedBox(
                        height:
                            isVerySmallScreen
                                ? SpacingConsts.s
                                : (isSmallScreen
                                    ? SpacingConsts.l
                                    : SpacingConsts.xl),
                      ),

                      // ソーシャルサインアップボタン
                      _buildSocialSignupButtons(authState, authNotifier),

                      SizedBox(
                        height:
                            isVerySmallScreen
                                ? SpacingConsts.s
                                : (isSmallScreen
                                    ? SpacingConsts.l
                                    : SpacingConsts.xl),
                      ),

                      // ログインリンク
                      _buildLoginLink(),

                      SizedBox(
                        height:
                            keyboardHeight > 0
                                ? SpacingConsts.s
                                : SpacingConsts.xxl,
                      ),
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

  Widget _buildHeader(bool isVerySmallScreen) {
    final isSmallScreen = MediaQuery.of(context).size.height < 700;
    return Column(
      children: [
        Text(
          'アカウント作成',
          style: (isVerySmallScreen
                  ? TextConsts.h3
                  : (isSmallScreen ? TextConsts.h2 : TextConsts.h1))
              .copyWith(
                color: ColorConsts.textPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
        ),
        SizedBox(
          height: isVerySmallScreen ? SpacingConsts.xxs : SpacingConsts.xs,
        ),
        Text(
          '目標達成への旅を\n今日から始めましょう',
          style: (isVerySmallScreen
                  ? TextConsts.caption
                  : (isSmallScreen ? TextConsts.caption : TextConsts.body))
              .copyWith(color: ColorConsts.textSecondary, height: 1.4),
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
          textInputAction: TextInputAction.next,
          errorText: _passwordError,
          onChanged: (value) {
            setState(() {
              _password = value;
              _passwordError = _validatePassword(value);
              // パスワード確認の再検証
              if (_confirmPassword.isNotEmpty) {
                _confirmPasswordError = _validateConfirmPassword(
                  _confirmPassword,
                );
              }
            });
          },
        ),
        const SizedBox(height: SpacingConsts.l),
        Focus(
          onFocusChange: (hasFocus) {
            if (hasFocus) {
              // パスワード確認フィールドにフォーカスした時にスクロール
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
            }
          },
          child: AuthTextField(
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
        ),
      ],
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      if (keyboardHeight > 0) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
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

  Widget _buildSocialSignupButtons(AuthState authState, dynamic authNotifier) {
    final bool isLoading = authState == AuthState.loading;

    return Column(
      children: [
        // Googleサインアップボタン
        AuthButton(
          type: AuthButtonType.google,
          text: 'Googleでサインアップ',
          isLoading: isLoading,
          onPressed: isLoading ? null : () => _handleGoogleSignup(authNotifier),
        ),

        // AppleサインアップボタンはiOSのみ
        if (AuthButton.shouldShowAppleLogin()) ...[
          const SizedBox(height: SpacingConsts.m),
          AuthButton(
            type: AuthButtonType.apple,
            text: 'Appleでサインアップ',
            isLoading: isLoading,
            onPressed:
                isLoading ? null : () => _handleAppleSignup(authNotifier),
          ),
        ],
      ],
    );
  }

  Widget _buildLoginLink() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'すでにアカウントをお持ちの方は ',
          style: TextConsts.body.copyWith(color: ColorConsts.textSecondary),
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
        AppLogger.instance.e('Apple Sign-In Error', e);
        _showErrorSnackBar('Appleサインアップに失敗しました: ${e.toString()}');
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
