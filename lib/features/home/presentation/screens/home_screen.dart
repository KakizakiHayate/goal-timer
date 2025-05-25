import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_timer/core/utils/color_consts.dart';
import 'package:goal_timer/core/utils/route_names.dart';
import 'package:goal_timer/features/home/presentation/widgets/goal_list_cell_widget.dart';
import 'package:goal_timer/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:goal_timer/features/goal_timer/presentation/screens/timer_screen.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/features/goal_detail/presentation/viewmodels/goal_detail_view_model.dart';
import 'package:goal_timer/features/goal_detail/presentation/screens/goal_edit_modal.dart';

part '../widgets/add_goal_modal.dart';

// ホーム画面のタブインデックスを管理するプロバイダー
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

final _pages = [const _HomeScreen(), const _TimerPage()];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(homeTabIndexProvider);

    return Scaffold(
      body: _buildPage(currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => ref.read(homeTabIndexProvider.notifier).state = index,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'タイマー'),
        ],
      ),
    );
  }

  Widget _buildPage(int index) => _pages[index];
}

class _HomeScreen extends ConsumerWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeViewModelProvider);
    final homeViewModel = ref.read(homeViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: ColorConsts.background,
      appBar: AppBar(
        title: const Text(
          'マイ目標',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: ColorConsts.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // 設定画面へ移動
              Navigator.pushNamed(context, RouteNames.settings);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(context, homeState, homeViewModel),
          _buildTodayProgress(context),
          const SizedBox(height: 16),
          _buildGoalList(context, homeViewModel),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 目標追加モーダルを表示
          _showAddGoalModal(context);
        },
        backgroundColor: ColorConsts.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // フィルターバーウィジェット
  Widget _buildFilterBar(
    BuildContext context,
    HomeState state,
    HomeViewModel viewModel,
  ) {
    return Material(
      color: Colors.white,
      elevation: 1,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Text(
              '表示:',
              style: TextStyle(fontSize: 14, color: ColorConsts.textLight),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: state.filterType,
              underline: Container(),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: ColorConsts.primary,
              ),
              items: const [
                DropdownMenuItem(value: '全て', child: Text('全て')),
                DropdownMenuItem(value: '進行中', child: Text('進行中')),
                DropdownMenuItem(value: '完了', child: Text('完了')),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  viewModel.changeFilter(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // 今日の進捗バーウィジェット
  Widget _buildTodayProgress(BuildContext context) {
    // 仮の進捗値
    const todayProgress = 0.35;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        color: ColorConsts.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ColorConsts.border, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '今日の進捗',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorConsts.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '1時間45分 / 目標5時間',
                      style: TextStyle(color: ColorConsts.textLight),
                    ),
                  ),
                  Text(
                    '${(todayProgress * 100).toInt()}%',
                    style: const TextStyle(
                      color: ColorConsts.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: todayProgress,
                backgroundColor: ColorConsts.border,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  ColorConsts.primary,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // 目標選択ダイアログを表示
                  _showGoalSelectionDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConsts.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('タイマーを開始する'),
              ),

              // メモ記録ボタン
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, RouteNames.memoRecord);
                },
                icon: const Icon(Icons.note_add),
                label: const Text('学習メモを記録する'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorConsts.primary,
                  side: const BorderSide(color: ColorConsts.primary),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 目標リストウィジェット
  Widget _buildGoalList(BuildContext context, HomeViewModel viewModel) {
    final goals = viewModel.filteredGoals;

    if (goals.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            '目標がありません。\n右下の+ボタンから追加してください。',
            textAlign: TextAlign.center,
            style: TextStyle(color: ColorConsts.textLight, fontSize: 16),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          return GoalListCellWidget(goal: goals[index]);
        },
      ),
    );
  }

  // 目標選択ダイアログを表示
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
                  onPressed: () {
                    Navigator.pop(context); // ダイアログを閉じる
                    // 目標なしでタイマー画面に遷移
                    Navigator.pushNamed(context, RouteNames.timer);
                  },
                  child: const Text('目標なしでタイマーを開始'),
                ),
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

// タイマーページウィジェット
class _TimerPage extends ConsumerWidget {
  const _TimerPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 目標一覧を取得
    final goalDetailsAsync = ref.watch(goalDetailListProvider);

    return goalDetailsAsync.when(
      data: (goals) {
        if (goals.isEmpty) {
          // 目標がない場合はタイマー画面をそのまま表示
          return const TimerScreen();
        }

        // 目標選択画面を表示
        return Scaffold(
          appBar: AppBar(
            title: const Text('タイマー'),
            backgroundColor: ColorConsts.primary,
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '目標を選択してタイマーを開始',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: goals.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Text(
                          goal.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              '達成率: ${(goal.getProgressRate() * 100).toStringAsFixed(1)}%',
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: goal.getProgressRate(),
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getProgressColor(goal.getProgressRate()),
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.timer,
                          color: ColorConsts.primary,
                        ),
                        onTap: () {
                          // 選択した目標IDでタイマー画面に遷移
                          Navigator.pushNamed(
                            context,
                            RouteNames.timerWithGoal,
                            arguments: goal.id,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    // 目標なしでタイマー画面に遷移
                    Navigator.pushNamed(context, RouteNames.timer);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[400],
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    '目標なしでタイマーを開始',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (error, _) =>
              Scaffold(body: Center(child: Text('エラーが発生しました: $error'))),
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
