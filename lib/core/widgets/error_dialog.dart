import 'package:flutter/material.dart';

import '../utils/color_consts.dart';
import '../utils/spacing_consts.dart';
import '../utils/text_consts.dart';

/// エラーダイアログの種類
enum ErrorDialogType {
  save,
  delete,
  network,
  generic,
}

/// エラーダイアログ表示用のヘルパークラス
class ErrorDialog {
  /// エラーダイアログのデフォルトタイトル
  static const String _defaultSaveTitle = '保存に失敗しました';
  static const String _defaultDeleteTitle = '削除に失敗しました';
  static const String _defaultNetworkTitle = 'ネットワークエラー';
  static const String _defaultGenericTitle = 'エラーが発生しました';

  /// エラーダイアログのデフォルトメッセージ
  static const String _defaultMessage = 'ネットワーク接続を確認してください。';

  /// エラーダイアログを表示する
  ///
  /// [context] ビルドコンテキスト
  /// [type] エラーダイアログの種類（デフォルト: generic）
  /// [title] ダイアログのタイトル（指定しない場合はtypeに応じたデフォルト値）
  /// [message] ダイアログのメッセージ（指定しない場合はデフォルト値）
  static Future<void> show(
    BuildContext context, {
    ErrorDialogType type = ErrorDialogType.generic,
    String? title,
    String? message,
  }) async {
    final dialogTitle = title ?? _getTitleForType(type);
    final dialogMessage = message ?? _defaultMessage;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SpacingConsts.radiusMd),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: ColorConsts.error,
                size: 24,
              ),
              const SizedBox(width: SpacingConsts.sm),
              Expanded(
                child: Text(
                  dialogTitle,
                  style: TextConsts.h4.copyWith(
                    color: ColorConsts.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            dialogMessage,
            style: TextConsts.bodyMedium.copyWith(
              color: ColorConsts.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextConsts.buttonMedium.copyWith(
                  color: ColorConsts.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// エラータイプに応じたタイトルを取得
  static String _getTitleForType(ErrorDialogType type) {
    switch (type) {
      case ErrorDialogType.save:
        return _defaultSaveTitle;
      case ErrorDialogType.delete:
        return _defaultDeleteTitle;
      case ErrorDialogType.network:
        return _defaultNetworkTitle;
      case ErrorDialogType.generic:
        return _defaultGenericTitle;
    }
  }

  /// 保存エラーダイアログを表示するショートカット
  static Future<void> showSaveError(
    BuildContext context, {
    String? message,
  }) async {
    return show(
      context,
      type: ErrorDialogType.save,
      message: message,
    );
  }

  /// 削除エラーダイアログを表示するショートカット
  static Future<void> showDeleteError(
    BuildContext context, {
    String? message,
  }) async {
    return show(
      context,
      type: ErrorDialogType.delete,
      message: message,
    );
  }

  /// ネットワークエラーダイアログを表示するショートカット
  static Future<void> showNetworkError(
    BuildContext context, {
    String? message,
  }) async {
    return show(
      context,
      type: ErrorDialogType.network,
      message: message,
    );
  }
}
