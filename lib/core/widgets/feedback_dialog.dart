import 'package:flutter/material.dart';

import '../utils/color_consts.dart';
import '../utils/spacing_consts.dart';
import '../utils/text_consts.dart';

/// フィードバックダイアログの結果
enum FeedbackDialogResult {
  /// 「回答する」を選択
  answer,

  /// 「今はしない」を選択
  dismiss,
}

/// フィードバックダイアログ（Apple HIG準拠）
///
/// カウントダウン完了時に表示し、ユーザーからフィードバックを収集する
class FeedbackDialog extends StatelessWidget {
  final bool isJapanese;

  const FeedbackDialog({
    required this.isJapanese,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SpacingConsts.l,
          SpacingConsts.l,
          SpacingConsts.l,
          SpacingConsts.m,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // タイトル
            Text(
              isJapanese
                  ? '目標達成おめでとうございます!'
                  : 'Congratulations on achieving your goal!',
              style: TextConsts.h4.copyWith(
                fontWeight: FontWeight.w600,
                color: ColorConsts.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpacingConsts.m),

            // 本文
            Text(
              isJapanese
                  ? 'より使いやすいアプリにするために、1分だけお声を聞かせていただけませんか？開発者が全て目を通します。'
                  : 'Could you spare a minute to help us improve? The developer reads every response.',
              style: TextConsts.body.copyWith(
                color: ColorConsts.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpacingConsts.l),

            // ボタン
            Column(
              children: [
                // プライマリボタン: 回答する
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(
                      FeedbackDialogResult.answer,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConsts.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: SpacingConsts.m,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isJapanese ? '回答する' : 'Answer',
                      style: TextConsts.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: SpacingConsts.s),

                // セカンダリボタン: 今はしない
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(
                      FeedbackDialogResult.dismiss,
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: SpacingConsts.m,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      isJapanese ? '今はしない' : 'Not now',
                      style: TextConsts.body.copyWith(
                        color: ColorConsts.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// フィードバックダイアログを表示する
  ///
  /// [context] BuildContext
  /// [isJapanese] 日本語表示かどうか
  /// Returns: [FeedbackDialogResult] or null if dismissed
  static Future<FeedbackDialogResult?> show({
    required BuildContext context,
    required bool isJapanese,
  }) {
    return showDialog<FeedbackDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => FeedbackDialog(isJapanese: isJapanese),
    );
  }
}
