import 'package:flutter/material.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/utils/color_consts.dart';
import 'package:goal_timer/core/utils/time_utils.dart';
import 'package:goal_timer/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:goal_timer/features/goal_detail/presentation/screens/goal_detail_screen.dart';

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
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.avoidMessage,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: ColorConsts.textLight,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                goal.title,
                style: const TextStyle(
                  fontSize: 16,
                  color: ColorConsts.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '残り$remainingTimeText',
                    style: TextStyle(
                      color:
                          isAlmostOutOfTime
                              ? Colors.red
                              : ColorConsts.textLight,
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
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: goal.getProgressRate(),
                backgroundColor: ColorConsts.border,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  ColorConsts.success,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
