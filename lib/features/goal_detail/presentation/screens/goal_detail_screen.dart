import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:goal_timer/core/utils/color_consts.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/features/goal_detail/presentation/viewmodels/goal_detail_view_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:goal_timer/features/goal_detail/presentation/screens/goal_edit_modal.dart';
import 'package:goal_timer/core/utils/route_names.dart';
import 'package:goal_timer/core/utils/app_logger.dart';
import 'package:goal_timer/features/goal_timer/presentation/screens/timer_screen.dart';
import 'package:goal_timer/core/provider/supabase/goals/goals_provider.dart';

/// 目標IDを使用して詳細データを取得する画面
class GoalDetailScreen extends ConsumerWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalDetailAsync = ref.watch(goalDetailProvider(goalId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('目標詳細'),
        backgroundColor: ColorConsts.primary,
        foregroundColor: Colors.white,
      ),
      body: goalDetailAsync.when(
        data: (goalDetail) {
          if (goalDetail == null) {
            return const Center(child: Text('目標が見つかりませんでした'));
          }
          return _buildGoalDetailContent(context, goalDetail, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラーが発生しました: $error')),
      ),
    );
  }

  Widget _buildGoalDetailContent(
    BuildContext context,
    GoalsModel goalDetail,
    WidgetRef ref,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ① 目標名
          Text(
            goalDetail.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ColorConsts.textDark,
            ),
          ),
          const SizedBox(height: 24),

          // ② 回避したい未来
          _buildAvoidFutureSection(goalDetail),
          const SizedBox(height: 24),

          // ③ 1日目標時間 と ④ 累計学習時間
          _buildTimeInfoSection(goalDetail),
          const SizedBox(height: 24),

          // ⑤ 達成率（グラフ）
          _buildProgressSection(goalDetail),
          const SizedBox(height: 32),

          // ⑥ 編集ボタン と ⑦ 削除ボタン
          _buildActionButtons(context, goalDetail, ref),
        ],
      ),
    );
  }

  // 回避したい未来セクション
  Widget _buildAvoidFutureSection(GoalsModel goalDetail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red),
              SizedBox(width: 8),
              Text(
                '回避したい未来',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            goalDetail.avoidMessage,
            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // 時間情報セクション
  Widget _buildTimeInfoSection(GoalsModel goalDetail) {
    // 残り日数を計算
    final remainingDays = goalDetail.deadline
        .difference(DateTime.now())
        .inDays
        .clamp(1, 1000);

    final dailyMinutesTarget =
        (goalDetail.totalTargetHours * 60) ~/ remainingDays;

    // 残り時間を計算
    final remainingTimeText = goalDetail.getRemainingTimeText();
    final isAlmostOutOfTime =
        goalDetail.getRemainingMinutes() < 60; // 残り1時間未満は警告色

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '時間目標',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorConsts.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildTimeInfoItem(
                  icon: Icons.timer,
                  title: '1日目標',
                  value:
                      '${dailyMinutesTarget ~/ 60}時間${dailyMinutesTarget % 60}分',
                  color: ColorConsts.primary,
                ),
                const SizedBox(width: 24),
                _buildTimeInfoItem(
                  icon: Icons.hourglass_full,
                  title: '累計時間',
                  value:
                      '${(goalDetail.spentMinutes ~/ 60)}時間${goalDetail.spentMinutes % 60}分',
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildTimeInfoItem(
                  icon: Icons.calendar_today,
                  title: '目標日',
                  value: DateFormat('yyyy/MM/dd').format(goalDetail.deadline),
                  color: Colors.orange,
                ),
                const SizedBox(width: 24),
                _buildTimeInfoItem(
                  icon: Icons.timelapse,
                  title: '残り時間',
                  value: remainingTimeText,
                  color: isAlmostOutOfTime ? Colors.red : Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 時間情報アイテム
  Widget _buildTimeInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 進捗セクション
  Widget _buildProgressSection(GoalsModel goalDetail) {
    // 進捗率を計算
    final progressRate = goalDetail.getProgressRate();
    final progressColor = _getProgressColor(progressRate);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '目標達成状況',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorConsts.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '進捗率: ${(progressRate * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '目標: ${goalDetail.totalTargetHours}時間',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progressRate,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 24),
            SizedBox(height: 200, child: _buildStudyTimeChart(goalDetail)),
          ],
        ),
      ),
    );
  }

  // 学習時間チャート（仮のデータ）
  Widget _buildStudyTimeChart(GoalsModel goalDetail) {
    // 仮のデータ - 将来的には実際の日々の記録を表示する
    final spots = [
      const FlSpot(0, 1.5), // 1日目: 1.5時間
      const FlSpot(1, 2.0), // 2日目: 2.0時間
      const FlSpot(2, 0.5), // 3日目: 0.5時間
      const FlSpot(3, 3.0), // 4日目: 3.0時間
      const FlSpot(4, 2.5), // 5日目: 2.5時間
      const FlSpot(5, 1.0), // 6日目: 1.0時間
      const FlSpot(6, 2.2), // 7日目: 2.2時間
    ];

    return LineChart(
      LineChartData(
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false, // 垂直線を非表示にして描画負荷を軽減
        ),
        lineTouchData: const LineTouchData(enabled: false), // タッチ機能を無効化して負荷を軽減
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
                  style: const TextStyle(fontSize: 10), // フォントサイズを小さくして最適化
                );
              },
              reservedSize: 24, // サイズを固定
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
                if (value >= 0 && value < 7) {
                  return Text(
                    weekdays[value.toInt()],
                    style: const TextStyle(fontSize: 10), // フォントサイズを小さくして最適化
                  );
                }
                return const Text('');
              },
              reservedSize: 18, // サイズを固定
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false), // 境界線を表示しない
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false, // 曲線をオフにして描画を高速化
            color: ColorConsts.primary,
            barWidth: 2, // 線を細くして描画負荷を軽減
            belowBarData: BarAreaData(
              show: true,
              color: ColorConsts.primary.withAlpha(
                50,
              ), // withOpacityの代わりにwithAlphaを使用
            ),
            dotData: const FlDotData(show: false), // ドットを非表示にして描画負荷を軽減
          ),
        ],
        minY: 0,
      ),
    );
  }

  // アクションボタン
  Widget _buildActionButtons(
    BuildContext context,
    GoalsModel goalDetail,
    WidgetRef ref,
  ) {
    return Column(
      children: [
        // タイマー開始ボタン
        ElevatedButton.icon(
          onPressed: () {
            AppLogger.instance.i('タイマー開始ボタンが押されました。目標ID: ${goalDetail.id}');
            // ルート名による遷移の代わりに、直接画面遷移を行う
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TimerScreen(goalId: goalDetail.id),
              ),
            );
          },
          icon: const Icon(Icons.timer, color: Colors.white),
          label: const Text('タイマーを開始', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConsts.primary,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              context: context,
              icon: Icons.edit,
              label: '編集',
              color: Colors.blue,
              onTap: () {
                _showEditGoalModal(context, goalDetail, ref);
              },
            ),
            _buildActionButton(
              context: context,
              icon: Icons.note_alt,
              label: 'メモを見る',
              color: Colors.green,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  RouteNames.memoRecordWithGoal,
                  arguments: goalDetail.id,
                );
              },
            ),
            _buildActionButton(
              context: context,
              icon: Icons.delete,
              label: '削除',
              color: Colors.red,
              onTap: () {
                _showDeleteConfirmation(context, goalDetail, ref);
              },
            ),
          ],
        ),
      ],
    );
  }

  // 削除確認ダイアログ
  void _showDeleteConfirmation(
    BuildContext context,
    GoalsModel goalDetail,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('目標の削除'),
            content: Text('「${goalDetail.title}」を削除してよろしいですか？このアクションは元に戻せません。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    final goalsNotifier = ref.read(
                      goalsNotifierProvider.notifier,
                    );

                    // 目標を削除
                    await goalsNotifier.deleteGoal(goalDetail.id);

                    // ダイアログと詳細画面を閉じる
                    if (context.mounted) {
                      Navigator.pop(context); // ダイアログを閉じる
                      Navigator.pop(context); // 詳細画面を閉じる

                      // リストを更新するためにプロバイダーを更新
                      // ignore: unused_result
                      ref.refresh(goalDetailListProvider);
                      // ignore: unused_result
                      ref.refresh(goalsListProvider);

                      // 成功メッセージを表示
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('目標が削除されました'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (error) {
                    // エラーが発生した場合
                    if (context.mounted) {
                      Navigator.pop(context); // ダイアログを閉じる

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('削除に失敗しました: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('削除する'),
              ),
            ],
          ),
    );
  }

  // 目標編集モーダル
  void _showEditGoalModal(
    BuildContext context,
    GoalsModel goalDetail,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.95,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: GoalEditModal(title: '目標を編集', goalDetail: goalDetail),
          ),
        );
      },
    );
  }

  // 進捗に応じた色を取得
  Color _getProgressColor(double progress) {
    if (progress < 0.3) {
      return Colors.red;
    } else if (progress < 0.7) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  // アクションボタンを構築するヘルパーメソッド
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

/// 目標データを直接受け取る詳細画面
class GoalDetailScreenWithData extends ConsumerWidget {
  final GoalsModel goal;

  const GoalDetailScreenWithData({super.key, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('目標詳細'),
        backgroundColor: ColorConsts.primary,
        foregroundColor: Colors.white,
      ),
      body: _buildGoalDetailContent(context, goal, ref),
    );
  }

  Widget _buildGoalDetailContent(
    BuildContext context,
    GoalsModel goalDetail,
    WidgetRef ref,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ① 目標名
          Text(
            goalDetail.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ColorConsts.textDark,
            ),
          ),
          const SizedBox(height: 24),

          // ② 回避したい未来
          _buildAvoidFutureSection(goalDetail),
          const SizedBox(height: 24),

          // ③ 1日目標時間 と ④ 累計学習時間
          _buildTimeInfoSection(goalDetail),
          const SizedBox(height: 24),

          // ⑤ 達成率（グラフ）
          _buildProgressSection(goalDetail),
          const SizedBox(height: 32),

          // ⑥ 編集ボタン と ⑦ 削除ボタン
          _buildActionButtons(context, goalDetail, ref),
        ],
      ),
    );
  }

  // 回避したい未来セクション
  Widget _buildAvoidFutureSection(GoalsModel goalDetail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red),
              SizedBox(width: 8),
              Text(
                '回避したい未来',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            goalDetail.avoidMessage,
            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // 時間情報セクション
  Widget _buildTimeInfoSection(GoalsModel goalDetail) {
    // 残り日数を計算
    final remainingDays = goalDetail.deadline
        .difference(DateTime.now())
        .inDays
        .clamp(1, 1000);

    final dailyMinutesTarget =
        (goalDetail.totalTargetHours * 60) ~/ remainingDays;

    // 残り時間を計算
    final remainingTimeText = goalDetail.getRemainingTimeText();
    final isAlmostOutOfTime =
        goalDetail.getRemainingMinutes() < 60; // 残り1時間未満は警告色

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '時間目標',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorConsts.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildTimeInfoItem(
                  icon: Icons.timer,
                  title: '1日目標',
                  value:
                      '${dailyMinutesTarget ~/ 60}時間${dailyMinutesTarget % 60}分',
                  color: ColorConsts.primary,
                ),
                const SizedBox(width: 24),
                _buildTimeInfoItem(
                  icon: Icons.hourglass_full,
                  title: '累計時間',
                  value:
                      '${(goalDetail.spentMinutes ~/ 60)}時間${goalDetail.spentMinutes % 60}分',
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildTimeInfoItem(
                  icon: Icons.calendar_today,
                  title: '目標日',
                  value: DateFormat('yyyy/MM/dd').format(goalDetail.deadline),
                  color: Colors.orange,
                ),
                const SizedBox(width: 24),
                _buildTimeInfoItem(
                  icon: Icons.timelapse,
                  title: '残り時間',
                  value: remainingTimeText,
                  color: isAlmostOutOfTime ? Colors.red : Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 時間情報アイテム
  Widget _buildTimeInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 進捗セクション
  Widget _buildProgressSection(GoalsModel goalDetail) {
    // 進捗率を計算
    final progressRate = goalDetail.getProgressRate();
    final progressColor = _getProgressColor(progressRate);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '目標達成状況',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorConsts.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '進捗率: ${(progressRate * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '目標: ${goalDetail.totalTargetHours}時間',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progressRate,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 24),
            SizedBox(height: 200, child: _buildStudyTimeChart(goalDetail)),
          ],
        ),
      ),
    );
  }

  // 学習時間チャート（仮のデータ）
  Widget _buildStudyTimeChart(GoalsModel goalDetail) {
    // 仮のデータ - 将来的には実際の日々の記録を表示する
    final spots = [
      const FlSpot(0, 1.5), // 1日目: 1.5時間
      const FlSpot(1, 2.0), // 2日目: 2.0時間
      const FlSpot(2, 0.5), // 3日目: 0.5時間
      const FlSpot(3, 3.0), // 4日目: 3.0時間
      const FlSpot(4, 2.5), // 5日目: 2.5時間
      const FlSpot(5, 1.0), // 6日目: 1.0時間
      const FlSpot(6, 2.2), // 7日目: 2.2時間
    ];

    return LineChart(
      LineChartData(
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false, // 垂直線を非表示にして描画負荷を軽減
        ),
        lineTouchData: const LineTouchData(enabled: false), // タッチ機能を無効化して負荷を軽減
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
                  style: const TextStyle(fontSize: 10), // フォントサイズを小さくして最適化
                );
              },
              reservedSize: 24, // サイズを固定
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
                if (value >= 0 && value < 7) {
                  return Text(
                    weekdays[value.toInt()],
                    style: const TextStyle(fontSize: 10), // フォントサイズを小さくして最適化
                  );
                }
                return const Text('');
              },
              reservedSize: 18, // サイズを固定
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false), // 境界線を表示しない
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false, // 曲線をオフにして描画を高速化
            color: ColorConsts.primary,
            barWidth: 2, // 線を細くして描画負荷を軽減
            belowBarData: BarAreaData(
              show: true,
              color: ColorConsts.primary.withAlpha(
                50,
              ), // withOpacityの代わりにwithAlphaを使用
            ),
            dotData: const FlDotData(show: false), // ドットを非表示にして描画負荷を軽減
          ),
        ],
        minY: 0,
      ),
    );
  }

  // アクションボタン
  Widget _buildActionButtons(
    BuildContext context,
    GoalsModel goalDetail,
    WidgetRef ref,
  ) {
    return Column(
      children: [
        // タイマー開始ボタン
        ElevatedButton.icon(
          onPressed: () {
            AppLogger.instance.i('タイマー開始ボタンが押されました。目標ID: ${goalDetail.id}');
            // ルート名による遷移の代わりに、直接画面遷移を行う
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TimerScreen(goalId: goalDetail.id),
              ),
            );
          },
          icon: const Icon(Icons.timer, color: Colors.white),
          label: const Text('タイマーを開始', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConsts.primary,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              context: context,
              icon: Icons.edit,
              label: '編集',
              color: Colors.blue,
              onTap: () {
                _showEditGoalModal(context, goalDetail, ref);
              },
            ),
            _buildActionButton(
              context: context,
              icon: Icons.note_alt,
              label: 'メモを見る',
              color: Colors.green,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  RouteNames.memoRecordWithGoal,
                  arguments: goalDetail.id,
                );
              },
            ),
            _buildActionButton(
              context: context,
              icon: Icons.delete,
              label: '削除',
              color: Colors.red,
              onTap: () {
                _showDeleteConfirmation(context, goalDetail, ref);
              },
            ),
          ],
        ),
      ],
    );
  }

  // 削除確認ダイアログ
  void _showDeleteConfirmation(
    BuildContext context,
    GoalsModel goalDetail,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('目標の削除'),
            content: Text('「${goalDetail.title}」を削除してよろしいですか？このアクションは元に戻せません。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    final goalsNotifier = ref.read(
                      goalsNotifierProvider.notifier,
                    );

                    // 目標を削除
                    await goalsNotifier.deleteGoal(goalDetail.id);

                    // ダイアログと詳細画面を閉じる
                    if (context.mounted) {
                      Navigator.pop(context); // ダイアログを閉じる
                      Navigator.pop(context); // 詳細画面を閉じる

                      // リストを更新するためにプロバイダーを更新
                      // ignore: unused_result
                      ref.refresh(goalDetailListProvider);
                      // ignore: unused_result
                      ref.refresh(goalsListProvider);

                      // 成功メッセージを表示
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('目標が削除されました'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (error) {
                    // エラーが発生した場合
                    if (context.mounted) {
                      Navigator.pop(context); // ダイアログを閉じる

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('削除に失敗しました: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('削除する'),
              ),
            ],
          ),
    );
  }

  // 目標編集モーダル
  void _showEditGoalModal(
    BuildContext context,
    GoalsModel goalDetail,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.95,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: GoalEditModal(title: '目標を編集', goalDetail: goalDetail),
          ),
        );
      },
    );
  }

  // 進捗に応じた色を取得
  Color _getProgressColor(double progress) {
    if (progress < 0.3) {
      return Colors.red;
    } else if (progress < 0.7) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  // アクションボタンを構築するヘルパーメソッド
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
