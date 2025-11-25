import 'package:flutter/material.dart';

import 'package:goal_timer/core/utils/route_names.dart';
import 'package:goal_timer/features/goal_timer/domain/entities/goal.dart';

class GoalListCellWidget extends StatelessWidget {
  final Goal goal;

  const GoalListCellWidget({Key? key, required this.goal}) : super(key: key);

  String _getRemainingDays() {
    final now = DateTime.now();
    final difference = goal.deadline.difference(now).inDays;
    if (difference < 0) {
      return '期限切れ';
    } else if (difference == 0) {
      return '今日まで';
    } else {
      return '残り${difference}日';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            RouteNames.goalDetailSetting,
            arguments: goal,
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
                      goal.title,
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                goal.description,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(_getRemainingDays(), style: const TextStyle(color: Colors.grey)),
                  const Spacer(),
                  Text(
                    goal.isCompleted ? '完了' : '進行中',
                    style: TextStyle(
                      color: goal.isCompleted ? Colors.green[700] : Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: goal.isCompleted ? 1.0 : 0.0,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  goal.isCompleted ? Colors.green[700]! : Colors.blue[700]!,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
