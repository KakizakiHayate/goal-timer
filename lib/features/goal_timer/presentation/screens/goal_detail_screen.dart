import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/features/goal_timer/domain/entities/goal.dart';
import 'package:goal_timer/features/goal_timer/presentation/screens/goal_edit_screen.dart';
import 'package:goal_timer/features/goal_timer/presentation/viewmodels/goal_view_model.dart';
import 'package:intl/intl.dart';

// 選択されたゴールのIDを保持するプロバイダー
final selectedGoalIdProvider = StateProvider<String?>((ref) => null);

// 選択されたゴールを取得するプロバイダー
final selectedGoalProvider = FutureProvider<Goal?>((ref) async {
  final goalId = ref.watch(selectedGoalIdProvider);
  if (goalId == null) return null;

  final repository = ref.read(goalRepositoryProvider);
  return await repository.getGoalById(goalId);
});

class GoalDetailScreen extends ConsumerStatefulWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  @override
  void initState() {
    super.initState();
    // initStateでプロバイダーを更新するのを遅延させる
    Future.microtask(
        () => ref.read(selectedGoalIdProvider.notifier).state = widget.goalId);
  }

  @override
  Widget build(BuildContext context) {
    // 選択されたゴールを取得
    final goalAsync = ref.watch(selectedGoalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ゴール詳細'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: goalAsync.when(
        data: (goal) {
          if (goal == null) {
            return const Center(child: Text('ゴールが見つかりませんでした'));
          }

          final formatter = DateFormat('yyyy年MM月dd日');
          final deadlineString = formatter.format(goal.deadline);

          // 残り日数を計算
          final daysLeft = goal.deadline.difference(DateTime.now()).inDays;
          final daysLeftText =
              daysLeft < 0 ? '期限切れ (${daysLeft.abs()}日経過)' : '残り $daysLeft 日';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 8),
                            Text('期限日: $deadlineString'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getColorByDaysLeft(daysLeft),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            daysLeftText,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '詳細:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(goal.description),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildProgressSection(context, goal),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラーが発生しました: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // ゴール編集画面に遷移する
          goalAsync.whenData((goal) {
            if (goal != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GoalEditScreen(goal: goal),
                ),
              );
            }
          });
        },
        tooltip: 'ゴールを編集',
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, Goal goal) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '進捗状況',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(
                      goal.isCompleted
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: goal.isCompleted ? Colors.green : null,
                    ),
                    label: Text(goal.isCompleted ? '完了済み' : '未完了'),
                    onPressed: () {
                      // ゴールの完了状態を切り替える
                      final updatedGoal = goal.copyWith(
                        isCompleted: !goal.isCompleted,
                      );

                      // リポジトリを通じてゴールを更新
                      final repository = ref.read(goalRepositoryProvider);
                      repository.updateGoal(updatedGoal).then((_) {
                        // プロバイダーを更新
                        ref.invalidate(goalListProvider);
                        ref.invalidate(selectedGoalProvider);

                        // 成功メッセージを表示
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(goal.isCompleted
                                ? 'ゴールを未完了に設定しました'
                                : 'ゴールを完了済みに設定しました'),
                          ),
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
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
