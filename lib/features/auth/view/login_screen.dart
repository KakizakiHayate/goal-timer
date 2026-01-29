import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/color_consts.dart';
import '../../../core/utils/spacing_consts.dart';
import '../../../core/utils/text_consts.dart';
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
  String get _title => widget.mode == LoginMode.login ? 'ログイン' : 'アカウント連携';

  /// モードに応じた説明文
  String get _description => widget.mode == LoginMode.login
      ? '以前のデータを引き継いで\n再開できます'
      : 'アカウントを連携すると、データを\n安全にバックアップできます';

  /// モードに応じた注意書き
  String get _notice => widget.mode == LoginMode.login
      ? 'アカウントをお持ちでない場合は「すぐに始める」をご利用ください'
      : '連携後もゲストとしてのデータは保持されます';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConsts.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          _title,
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
                    _description,
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
                    label: 'Google で${widget.mode == LoginMode.login ? 'ログイン' : '連携'}',
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
                      label: 'Apple で${widget.mode == LoginMode.login ? 'ログイン' : '連携'}',
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
                    _notice,
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
    String title;
    String message;

    switch (errorType) {
      case AuthErrorType.accountNotFound:
        title = 'ログインできませんでした';
        message =
            'このアカウントは登録されていません。\n新規登録は「すぐに始める」からアカウント連携を行ってください。';
      case AuthErrorType.accountAlreadyExists:
        title = '連携できませんでした';
        message =
            'このアカウントは既に登録されています。\n連携するには、一度ログインしてアカウントを削除してください。';
      case AuthErrorType.emailNotFound:
        title = widget.mode == LoginMode.login
            ? 'ログインできませんでした'
            : '連携できませんでした';
        message =
            'メールアドレスを取得できませんでした。\n設定からApple IDの連携を解除して再度お試しください。';
      case AuthErrorType.other:
      case AuthErrorType.none:
        title = widget.mode == LoginMode.login
            ? 'ログインできませんでした'
            : '連携できませんでした';
        message = 'エラーが発生しました。\nしばらくしてから再度お試しください。';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Get.find<AuthViewModel>().clearError();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConsts.primary,
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
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
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アカウントを連携しますか？'),
        content: Text('$providerアカウントと連携します'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'キャンセル',
              style: TextStyle(color: ColorConsts.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConsts.primary,
            ),
            child: const Text(
              '連携する',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('連携完了'),
        content: const Text('アカウントが正常に連携されました'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // ダイアログを閉じる
              Navigator.of(context).pop(); // ログイン画面を閉じる
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConsts.primary,
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
