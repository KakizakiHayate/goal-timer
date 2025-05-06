import 'package:flutter/material.dart';

import 'package:goal_timer/core/utils/color_consts.dart';
import 'package:goal_timer/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:goal_timer/features/goal_detail_setting/presentation/screens/goal_detail_screen.dart';

class GoalListCellWidget extends StatelessWidget {
  final GoalItem goal;

  const GoalListCellWidget({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorConsts.cardBackground,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GoalDetailScreen(goalId: goal.id),
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
                    '残り${goal.remainingDays}日',
                    style: const TextStyle(color: ColorConsts.textLight),
                  ),
                  const Spacer(),
                  Text(
                    '${(goal.progressPercent * 100).toInt()}%',
                    style: const TextStyle(
                      color: ColorConsts.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: goal.progressPercent,
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
