import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_timer/core/utils/color_consts.dart';
import 'package:goal_timer/features/home/presentation/widgets/goal_list_cell_widget.dart';
import 'package:goal_timer/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:goal_timer/features/goal_detail_setting/presentation/screens/goal_detail_setting_screen.dart';
import 'package:goal_timer/features/goal_timer/presentation/screens/timer_screen.dart';
import 'package:goal_timer/features/goal_detail_setting/domain/entities/goal_detail.dart';
import 'package:goal_timer/features/goal_detail_setting/presentation/viewmodels/goal_detail_view_model.dart';
import 'package:goal_timer/features/goal_detail_setting/data/repositories/goal_detail_repository_impl.dart';
import 'package:goal_timer/features/goal_detail_setting/presentation/screens/goal_edit_modal.dart';

// ホーム画面のタブインデックスを管理するプロバイダー
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

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

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const _HomePage();
      case 1:
        return const TimerScreen();
      default:
        return const _HomePage();
    }
  }
}

class _HomePage extends ConsumerWidget {
  const _HomePage();

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
              Navigator.pushNamed(context, '/settings');
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

  // 目標追加モーダルを表示
  void _showAddGoalModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // フルスクリーンに近い高さで表示
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.95, // 画面の95%の高さ
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: const GoalEditModal(
              title: '目標を追加',
              goalDetail: null, // 新規追加なのでnull
            ),
          ),
        );
      },
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
          side: BorderSide(color: ColorConsts.border, width: 1),
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
                  // タブをタイマー画面に切り替え
                  final notifier = ProviderScope.containerOf(
                    context,
                  ).read(homeTabIndexProvider.notifier);
                  notifier.state = 1; // タイマータブのインデックス
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
}
