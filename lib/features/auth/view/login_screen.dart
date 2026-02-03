import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/color_consts.dart';
import '../../../core/utils/spacing_consts.dart';
import '../../../core/utils/text_consts.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/view/home_screen.dart';
import '../../settings/view_model/settings_view_model.dart';
import '../view_model/auth_view_model.dart';

/// ログイン画面のモード
enum LoginMode {
  /// ログイン（既存アカウントにサインイン）
  login,

  /// アカウント連携（新規登録）
  link,
}

/// ログイン画面（アカウント連携用）
/// 設定画面からの遷移と、ウェルカム画面からも使用する共通コンポーネント
class LoginScreen extends StatefulWidget {
  final LoginMode mode;

  const LoginScreen({
    required this.mode,
    super.key,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    Get.put(AuthViewModel());
  }

  @override
  void dispose() {
    Get.delete<AuthViewModel>();
    super.dispose();
  }

  /// モードに応じたタイトル
  String _getTitle(AppLocalizations? l10n) {
    if (widget.mode == LoginMode.login) {
      return l10n?.loginTitle ?? 'Login';
    }
    return l10n?.accountLinkTitle ?? 'Link Account';
  }

  /// モードに応じた説明文
  String _getDescription(AppLocalizations? l10n) {
    if (widget.mode == LoginMode.login) {
      return l10n?.loginDescription ?? 'Resume with your\nprevious data';
    }
    return l10n?.linkDescription ?? 'Link your account to safely\nbackup your data';
  }

  /// モードに応じた注意書き
  String _getNotice(AppLocalizations? l10n) {
    if (widget.mode == LoginMode.login) {
      return l10n?.loginNotice ?? 'If you don\'t have an account, please use "Start Now"';
    }
    return l10n?.linkNotice ?? 'Your guest data will be preserved after linking';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: ColorConsts.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          _getTitle(l10n),
          style: TextConsts.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ColorConsts.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GetBuilder<AuthViewModel>(
        builder: (viewModel) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(SpacingConsts.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: SpacingConsts.xxl),

                  // 説明テキスト
                  Text(
                    _getDescription(l10n),
                    style: TextConsts.body.copyWith(
                      color: ColorConsts.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: SpacingConsts.xxl),

                  // Googleログインボタン
                  _buildLoginButton(
                    onPressed: viewModel.isLoading
                        ? null
                        : () => _onGooglePressed(viewModel),
                    icon: _buildGoogleIcon(),
                    label: widget.mode == LoginMode.login
                        ? (l10n?.loginWithGoogle ?? 'Login with Google')
                        : (l10n?.linkWithGoogle ?? 'Link with Google'),
                    backgroundColor: Colors.white,
                    textColor: ColorConsts.textPrimary,
                  ),

                  const SizedBox(height: SpacingConsts.m),

                  // Appleログインボタン（iOSのみ）
                  if (Platform.isIOS) ...[
                    _buildLoginButton(
                      onPressed: viewModel.isLoading
                          ? null
                          : () => _onApplePressed(viewModel),
                      icon: const Icon(Icons.apple, color: Colors.white, size: 24),
                      label: widget.mode == LoginMode.login
                          ? (l10n?.loginWithApple ?? 'Login with Apple')
                          : (l10n?.linkWithApple ?? 'Link with Apple'),
                      backgroundColor: Colors.black,
                      textColor: Colors.white,
                    ),
                  ],

                  const SizedBox(height: SpacingConsts.l),

                  // ローディングインジケーター
                  if (viewModel.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(SpacingConsts.m),
                        child: CircularProgressIndicator(),
                      ),
                    ),

                  // エラーメッセージ
                  if (viewModel.hasError)
                    Padding(
                      padding: const EdgeInsets.all(SpacingConsts.m),
                      child: Text(
                        viewModel.errorMessage,
                        style: TextConsts.body.copyWith(
                          color: ColorConsts.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const Spacer(),

                  // 注意書き
                  Text(
                    _getNotice(l10n),
                    style: TextConsts.caption.copyWith(
                      color: ColorConsts.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: SpacingConsts.m),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginButton({
    required VoidCallback? onPressed,
    required Widget icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: backgroundColor == Colors.white
                ? BorderSide(color: Colors.grey.shade300)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: SpacingConsts.m),
            Text(
              label,
              style: TextConsts.body.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Colors.blue.shade600,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _onGooglePressed(AuthViewModel viewModel) async {
    if (widget.mode == LoginMode.login) {
      await _handleGoogleLogin(viewModel);
    } else {
      await _handleGoogleLink(viewModel);
    }
  }

  Future<void> _handleGoogleLogin(AuthViewModel viewModel) async {
    final success = await viewModel.loginWithGoogle();
    if (!mounted) return;

    if (success) {
      _navigateToHome();
      return;
    }
    if (viewModel.errorType != AuthErrorType.none) {
      _showErrorDialog(viewModel.errorType);
    }
  }

  Future<void> _handleGoogleLink(AuthViewModel viewModel) async {
    final confirmed = await _showConfirmDialog('Google');
    if (!confirmed) return;

    final success = await viewModel.linkWithGoogle();
    if (!mounted) return;

    if (success) {
      _showSuccessDialog();
      return;
    }
    if (viewModel.errorType != AuthErrorType.none) {
      _showErrorDialog(viewModel.errorType);
    }
  }

  Future<void> _onApplePressed(AuthViewModel viewModel) async {
    if (widget.mode == LoginMode.login) {
      await _handleAppleLogin(viewModel);
    } else {
      await _handleAppleLink(viewModel);
    }
  }

  Future<void> _handleAppleLogin(AuthViewModel viewModel) async {
    final success = await viewModel.loginWithApple();
    if (!mounted) return;

    if (success) {
      _navigateToHome();
      return;
    }
    if (viewModel.errorType != AuthErrorType.none) {
      _showErrorDialog(viewModel.errorType);
    }
  }

  Future<void> _handleAppleLink(AuthViewModel viewModel) async {
    final confirmed = await _showConfirmDialog('Apple');
    if (!confirmed) return;

    final success = await viewModel.linkWithApple();
    if (!mounted) return;

    if (success) {
      _showSuccessDialog();
      return;
    }
    if (viewModel.errorType != AuthErrorType.none) {
      _showErrorDialog(viewModel.errorType);
    }
  }

  /// エラー種別に応じたダイアログを表示
  void _showErrorDialog(AuthErrorType errorType) {
    final l10n = AppLocalizations.of(context);
    String title;
    String message;

    switch (errorType) {
      case AuthErrorType.accountNotFound:
        title = l10n?.loginFailedTitle ?? 'Login Failed';
        message = l10n?.accountNotFoundMessage ??
            'This account is not registered.\nTo register, please use "Start Now" and link your account.';
      case AuthErrorType.accountAlreadyExists:
        title = l10n?.linkFailedTitle ?? 'Link Failed';
        message = l10n?.accountAlreadyExistsMessage ??
            'This account is already registered.\nTo link, please login first and delete the account.';
      case AuthErrorType.emailNotFound:
        title = widget.mode == LoginMode.login
            ? (l10n?.loginFailedTitle ?? 'Login Failed')
            : (l10n?.linkFailedTitle ?? 'Link Failed');
        message = l10n?.emailNotFoundMessage ??
            'Could not retrieve email address.\nPlease unlink your Apple ID in Settings and try again.';
      case AuthErrorType.other:
      case AuthErrorType.none:
        title = widget.mode == LoginMode.login
            ? (l10n?.loginFailedTitle ?? 'Login Failed')
            : (l10n?.linkFailedTitle ?? 'Link Failed');
        message = l10n?.genericErrorMessage ??
            'An error occurred.\nPlease try again later.';
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Get.find<AuthViewModel>().clearError();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConsts.primary,
            ),
            child: Text(
              l10n?.commonBtnOk ?? 'OK',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToHome() {
    // SettingsViewModelのdisplayNameを更新（シングルトンなので再初期化されないため）
    Get.find<SettingsViewModel>().refreshDisplayName();

    Get.offAll(() => const HomeScreen());
  }

  Future<bool> _showConfirmDialog(String provider) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n?.confirmLinkTitle ?? 'Link your account?'),
        content: Text(l10n?.confirmLinkMessage(provider) ?? 'Link with $provider account'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n?.commonBtnCancel ?? 'Cancel',
              style: const TextStyle(color: ColorConsts.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConsts.primary,
            ),
            child: Text(
              l10n?.btnLink ?? 'Link',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showSuccessDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n?.linkSuccessTitle ?? 'Link Complete'),
        content: Text(l10n?.linkSuccessMessage ?? 'Account linked successfully'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // ダイアログを閉じる
              Navigator.of(context).pop(); // ログイン画面を閉じる
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConsts.primary,
            ),
            child: Text(
              l10n?.commonBtnOk ?? 'OK',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
