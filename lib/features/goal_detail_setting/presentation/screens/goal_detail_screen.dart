import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:goal_timer/core/utils/color_consts.dart';
import 'package:goal_timer/features/goal_detail_setting/domain/entities/goal_detail.dart';
import 'package:goal_timer/features/goal_detail_setting/presentation/viewmodels/goal_detail_view_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:goal_timer/features/goal_detail_setting/presentation/screens/goal_edit_modal.dart';

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
    GoalDetail goalDetail,
    WidgetRef ref,
  ) {
    final formatter = DateFormat('yyyy年MM月dd日');
    final deadlineString = formatter.format(goalDetail.deadline);
    final totalHoursSpent = goalDetail.spentMinutes / 60;

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
  Widget _buildAvoidFutureSection(GoalDetail goalDetail) {
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
  Widget _buildTimeInfoSection(GoalDetail goalDetail) {
    final dailyMinutesTarget =
        (goalDetail.targetHours * 60) ~/
        goalDetail.remainingDays.clamp(1, double.infinity);

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
                  title: '残り日数',
                  value: '${goalDetail.remainingDays}日',
                  color:
                      goalDetail.remainingDays < 7 ? Colors.red : Colors.blue,
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
  Widget _buildProgressSection(GoalDetail goalDetail) {
    final progressColor = _getProgressColor(goalDetail.progressPercent);

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
                  '進捗率: ${(goalDetail.progressPercent * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '目標: ${goalDetail.targetHours}時間',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: goalDetail.progressPercent,
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
  Widget _buildStudyTimeChart(GoalDetail goalDetail) {
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
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}h');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
                if (value >= 0 && value < 7) {
                  return Text(weekdays[value.toInt()]);
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: ColorConsts.primary,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: ColorConsts.primary.withOpacity(0.2),
            ),
            dotData: const FlDotData(show: true),
          ),
        ],
        minY: 0,
      ),
    );
  }

  // アクションボタン
  Widget _buildActionButtons(
    BuildContext context,
    GoalDetail goalDetail,
    WidgetRef ref,
  ) {
    return Row(
      children: [
        // 編集ボタン
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _showEditGoalModal(context, goalDetail, ref);
            },
            icon: const Icon(Icons.edit),
            label: const Text('編集する'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConsts.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 削除ボタン
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _showDeleteConfirmation(context, goalDetail, ref);
            },
            icon: const Icon(Icons.delete),
            label: const Text('削除する'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // 削除確認ダイアログ
  void _showDeleteConfirmation(
    BuildContext context,
    GoalDetail goalDetail,
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
                onPressed: () {
                  // TODO: 目標を削除する処理を実装
                  // モックリポジトリなので、ディープリンクと表示のリフレッシュだけ行う
                  Navigator.pop(context); // ダイアログを閉じる
                  Navigator.pop(context); // 詳細画面を閉じる

                  // リストを更新するためにプロバイダーを更新
                  ref.refresh(goalDetailListProvider);

                  // 成功メッセージを表示
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('目標が削除されました'),
                      backgroundColor: Colors.red,
                    ),
                  );
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
    GoalDetail goalDetail,
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
}
