import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/backup/core/utils/color_consts.dart';
import 'package:goal_timer/backup/core/models/goals/goals_model.dart';
import 'package:goal_timer/backup/features/goal_detail/presentation/viewmodels/goal_detail_view_model.dart';

class GoalDetailSettingScreen extends ConsumerWidget {
  final bool isModal;

  const GoalDetailSettingScreen({super.key, this.isModal = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalDetailsAsync = ref.watch(goalDetailListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('目標管理'),
        backgroundColor: ColorConsts.primary,
        foregroundColor: Colors.white,
        leading:
            isModal
                ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
                : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: 新規目標追加画面への遷移
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: goalDetailsAsync.when(
        data: (goals) => _buildGoalList(context, goals, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラーが発生しました: $error')),
      ),
    );
  }

  Widget _buildGoalList(
    BuildContext context,
    List<GoalsModel> goals,
    WidgetRef ref,
  ) {
    if (goals.isEmpty) {
      return const Center(child: Text('目標がありません。右上の+ボタンから目標を追加しましょう。'));
    }

    return ListView.builder(
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        return _buildGoalCard(context, goal, ref);
      },
    );
  }

  Widget _buildGoalCard(BuildContext context, GoalsModel goal, WidgetRef ref) {
    final remainingDays = goal.deadline.difference(DateTime.now()).inDays;
    final progressRate = goal.getProgressRate();
    final progressColor = _getProgressColor(progressRate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // TODO: 目標詳細編集画面への遷移
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '残り$remainingDays日',
                    style: TextStyle(
                      color: remainingDays < 7 ? Colors.red : Colors.black54,
                      fontWeight:
                          remainingDays < 7
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                goal.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: Colors.amber,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      goal.avoidMessage,
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progressRate,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '進捗: ${(progressRate * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: progressColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '目標: ${(goal.targetMinutes ~/ 60)}時間${(goal.targetMinutes % 60)}分（${(goal.spentMinutes / 60).toStringAsFixed(1)}時間経過）',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
