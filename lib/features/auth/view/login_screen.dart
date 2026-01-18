import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/color_consts.dart';
import '../../../core/utils/spacing_consts.dart';
import '../../../core/utils/text_consts.dart';
import '../view_model/auth_view_model.dart';

/// ログイン画面（アカウント連携用）
/// 設定画面からの遷移と、将来のチュートリアルでも使用する共通コンポーネント
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConsts.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'アカウント連携',
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
                    'アカウントを連携すると、データを\n安全にバックアップできます',
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
                        : () => _onGoogleLoginPressed(viewModel),
                    icon: _buildGoogleIcon(),
                    label: 'Google でログイン',
                    backgroundColor: Colors.white,
                    textColor: ColorConsts.textPrimary,
                  ),

                  const SizedBox(height: SpacingConsts.m),

                  // Appleログインボタン（iOSのみ）
                  if (Platform.isIOS) ...[
                    _buildLoginButton(
                      onPressed: viewModel.isLoading
                          ? null
                          : () => _onAppleLoginPressed(viewModel),
                      icon: const Icon(Icons.apple, color: Colors.white, size: 24),
                      label: 'Apple でログイン',
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
                    '連携後もゲストとしてのデータは保持されます',
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

  Future<void> _onGoogleLoginPressed(AuthViewModel viewModel) async {
    // 確認ダイアログを表示
    final confirmed = await _showConfirmDialog('Google');
    if (!confirmed) return;

    final success = await viewModel.linkWithGoogle();
    if (success && mounted) {
      _showSuccessDialog();
    }
  }

  Future<void> _onAppleLoginPressed(AuthViewModel viewModel) async {
    // 確認ダイアログを表示
    final confirmed = await _showConfirmDialog('Apple');
    if (!confirmed) return;

    final success = await viewModel.linkWithApple();
    if (success && mounted) {
      _showSuccessDialog();
    }
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
            child: Text(
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
