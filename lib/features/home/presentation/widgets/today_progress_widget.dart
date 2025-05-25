part of '../screens/home_screen.dart';

Widget _buildTodayProgress(BuildContext context) {
  // 仮の進捗値
  const todayProgress = 0.35;

  return Padding(
    padding: const EdgeInsets.all(16),
    child: Card(
      elevation: 0,
      color: ColorConsts.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ColorConsts.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '今日の進捗',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorConsts.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '1時間45分 / 目標5時間',
                    style: TextStyle(color: ColorConsts.textLight),
                  ),
                ),
                Text(
                  '${(todayProgress * 100).toInt()}%',
                  style: const TextStyle(
                    color: ColorConsts.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: todayProgress,
              backgroundColor: ColorConsts.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                ColorConsts.primary,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 目標選択ダイアログを表示
                _showGoalSelectionDialog(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConsts.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('タイマーを開始する'),
            ),

            // メモ記録ボタン
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, RouteNames.memoRecord);
              },
              icon: const Icon(Icons.note_add),
              label: const Text('学習メモを記録する'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConsts.primary,
                side: const BorderSide(color: ColorConsts.primary),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
