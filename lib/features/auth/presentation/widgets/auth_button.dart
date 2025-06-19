import 'package:flutter/material.dart';
import 'dart:io';
import '../../../../core/utils/color_consts.dart';

/// 認証ボタンの種類
enum AuthButtonType { email, google, apple }

/// 認証ボタンウィジェット
class AuthButton extends StatelessWidget {
  const AuthButton({
    super.key,
    required this.type,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  final AuthButtonType type;
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  /// AppleログインボタンがiOSでのみ表示されるかチェック
  static bool shouldShowAppleLogin() {
    return Platform.isIOS;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: _getButtonStyle(),
        child:
            isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (type != AuthButtonType.email) ...[
                      _getIcon(),
                      const SizedBox(width: 12),
                    ],
                    Text(text, style: _getTextStyle()),
                  ],
                ),
      ),
    );
  }

  ButtonStyle _getButtonStyle() {
    switch (type) {
      case AuthButtonType.email:
        return ElevatedButton.styleFrom(
          backgroundColor: ColorConsts.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        );
      case AuthButtonType.google:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: const BorderSide(color: ColorConsts.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        );
      case AuthButtonType.apple:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        );
    }
  }

  Widget _getIcon() {
    switch (type) {
      case AuthButtonType.google:
        return const Icon(Icons.g_mobiledata, size: 24);
      case AuthButtonType.apple:
        return const Icon(Icons.apple, size: 24);
      case AuthButtonType.email:
        return const SizedBox.shrink();
    }
  }

  TextStyle _getTextStyle() {
    return const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  }
}
