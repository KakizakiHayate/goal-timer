part of '../screens/home_screen.dart';

void _showGoalSelectionDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return Consumer(
        builder: (context, ref, _) {
          final goalDetailsAsync = ref.watch(goalDetailListProvider);

          return AlertDialog(
            title: const Text('目標を選択'),
            content: goalDetailsAsync.when(
              data: (goals) {
                if (goals.isEmpty) {
                  return const Text('目標が登録されていません。\n最初に目標を追加してください。');
                }

                return SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: ListView.builder(
                    itemCount: goals.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final goal = goals[index];
                      return ListTile(
                        title: Text(
                          goal.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '達成率: ${(goal.getProgressRate() * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: _getProgressColor(goal.getProgressRate()),
                          ),
                        ),
                        trailing: const Icon(Icons.timer),
                        onTap: () {
                          Navigator.pop(context); // ダイアログを閉じる
                          // 選択した目標IDでタイマー画面に遷移
                          Navigator.pushNamed(
                            context,
                            RouteNames.timerWithGoal,
                            arguments: goal.id,
                          );
                        },
                      );
                    },
                  ),
                );
              },
              loading:
                  () => const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  ),
              error: (error, _) => Text('エラーが発生しました: $error'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
            ],
          );
        },
      );
    },
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
