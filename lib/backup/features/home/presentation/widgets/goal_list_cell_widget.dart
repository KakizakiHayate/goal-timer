import 'package:flutter/material.dart';
import 'package:goal_timer/backup/core/models/goals/goals_model.dart';
import 'package:goal_timer/backup/core/utils/color_consts.dart';
import 'package:goal_timer/backup/features/goal_detail/presentation/screens/goal_detail_screen.dart';

class GoalListCellWidget extends StatelessWidget {
  final GoalsModel goal;

  const GoalListCellWidget({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    // 残り時間を計算
    final remainingTimeText = goal.getRemainingTimeText();
    final isAlmostOutOfTime = goal.getRemainingMinutes() < 60; // 残り1時間未満は警告色

    return Material(
      color: ColorConsts.cardBackground,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GoalDetailScreenWithData(goal: goal),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 目標タイトル
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorConsts.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: ColorConsts.textSecondary,
                      size: 16,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 避けたい未来メッセージ（強調表示）
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade50, Colors.red.shade100],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        goal.avoidMessage,
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 進捗情報
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '残り$remainingTimeText',
                      style: TextStyle(
                        color:
                            isAlmostOutOfTime
                                ? Colors.red
                                : ColorConsts.textSecondary,
                        fontWeight:
                            isAlmostOutOfTime
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(goal.getProgressRate() * 100).toInt()}%',
                      style: const TextStyle(
                        color: ColorConsts.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(
                  value: goal.getProgressRate(),
                  backgroundColor: ColorConsts.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    ColorConsts.success,
                  ),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
