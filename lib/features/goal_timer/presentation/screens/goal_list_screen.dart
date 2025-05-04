import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/features/goal_timer/domain/entities/goal.dart';
import 'package:goal_timer/features/goal_timer/presentation/screens/goal_add_screen.dart';
import 'package:goal_timer/features/goal_timer/presentation/screens/goal_detail_screen.dart';
import 'package:goal_timer/features/goal_timer/presentation/viewmodels/goal_view_model.dart';
import 'package:intl/intl.dart';

class GoalListScreen extends ConsumerWidget {
  const GoalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // goalListProviderを使用してゴール一覧を取得
    final goalListAsync = ref.watch(goalListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ゴールタイマー'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: goalListAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return const Center(child: Text('ゴールが設定されていません'));
          }

          return ListView.builder(
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              return GoalListItem(goal: goal);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラーが発生しました: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 新しいゴール追加画面に遷移
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const GoalAddScreen(),
            ),
          );
        },
        tooltip: '新しいゴールを追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class GoalListItem extends StatelessWidget {
  final Goal goal;

  const GoalListItem({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy/MM/dd');
    final deadlineString = formatter.format(goal.deadline);

    // 残り日数を計算
    final daysLeft = goal.deadline.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          goal.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal.description),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text('期限: $deadlineString'),
                const SizedBox(width: 8),
                Chip(
                  label: Text('残り$daysLeft日'),
                  backgroundColor: _getColorByDaysLeft(daysLeft),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          goal.isCompleted ? Icons.check_circle : Icons.circle_outlined,
          color: goal.isCompleted ? Colors.green : Colors.grey,
        ),
        onTap: () {
          // 詳細画面に遷移
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GoalDetailScreen(goalId: goal.id),
            ),
          );
        },
      ),
    );
  }

  // 残り日数に応じた色を返す
  Color _getColorByDaysLeft(int days) {
    if (days < 0) return Colors.red.shade200; // 期限切れ
    if (days < 3) return Colors.orange.shade200; // 残り3日未満
    if (days < 7) return Colors.yellow.shade200; // 残り7日未満
    return Colors.green.shade200; // それ以上
  }
}
