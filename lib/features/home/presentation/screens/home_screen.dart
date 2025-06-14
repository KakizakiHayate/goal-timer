import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_timer/core/utils/color_consts.dart';
import 'package:goal_timer/core/utils/route_names.dart';
import 'package:goal_timer/features/home/presentation/widgets/goal_list_cell_widget.dart';
import 'package:goal_timer/features/home/presentation/view_models/home_view_model.dart';
import 'package:goal_timer/features/goal_timer/presentation/screens/timer_screen.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/features/goal_detail/presentation/viewmodels/goal_detail_view_model.dart';
import 'package:goal_timer/features/goal_detail/presentation/screens/goal_edit_modal.dart';
import 'package:goal_timer/features/home/provider/home_provider.dart';
import 'package:goal_timer/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:goal_timer/features/goal_timer/presentation/viewmodels/timer_view_model.dart';
import 'package:goal_timer/core/utils/app_logger.dart';
import 'package:goal_timer/features/settings/presentation/screens/settings_screen.dart';
import 'package:goal_timer/core/provider/providers.dart';
import 'package:goal_timer/features/shared/widgets/sync_status_indicator.dart';

part '../widgets/add_goal_modal.dart';
part '../widgets/filter_bar_widget.dart';
part '../widgets/today_progress_widget.dart';
part '../widgets/goal_selection_dialog.dart';

// ホーム画面のタブインデックスを管理するプロバイダー
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

final _pages = [
  const _HomeScreen(),
  const _TimerPage(),
  const StatisticsScreen(),
];

// StatefulWidgetに変更
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 同期処理はHomeViewModelで自動的に実行されるため、ここでは何もしない
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(homeTabIndexProvider);

    return Scaffold(
      body: _buildPage(currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => ref.read(homeTabIndexProvider.notifier).state = index,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'タイマー'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: '統計'),
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

    // 同期処理はHomeViewModelで自動的に実行されるため、ここでは削除

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
          // 同期状態インジケーター
          const SyncStatusIndicator(),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // 設定画面へ移動（名前付きルート経由ではなく直接MaterialPageRouteを使用）
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(context, homeState, homeViewModel),
          // _buildTodayProgress(context),
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
                      child: InkWell(
                        onTap: () {
                          // 選択した目標IDでタイマー画面に遷移（直接ルート方式）
                          AppLogger.instance.i(
                            '目標付きタイマーに遷移します: ID=${goal.id}（直接ルート方式）',
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => TimerScreen(goalId: goal.id),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        splashColor: ColorConsts.primary.withOpacity(0.1),
                        highlightColor: ColorConsts.primary.withOpacity(0.05),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      goal.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.timer,
                                    color: ColorConsts.primary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 10,
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        goal.avoidMessage,
                                        style: TextStyle(
                                          color: Colors.red.shade900,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                        ),
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
                    AppLogger.instance.i('目標なしタイマーに遷移します（直接ルート方式）');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TimerScreen(),
                      ),
                    );
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
