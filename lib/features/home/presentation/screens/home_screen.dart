import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/animation_consts.dart';
import '../../../../core/widgets/goal_card.dart';
import '../widgets/today_progress_widget.dart';
import '../view_models/home_view_model.dart';
import '../../provider/home_provider.dart';
import '../../../goal_timer/presentation/screens/timer_screen.dart';
import '../../../statistics/presentation/screens/statistics_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../../core/provider/providers.dart';
import '../../../auth/domain/entities/auth_state.dart' as app_auth;
import '../../../auth/provider/auth_provider.dart';
import '../../../../core/utils/route_names.dart';
import '../../../../core/models/goals/goals_model.dart';
import '../../../goal_detail/presentation/screens/goal_create_modal.dart';
import '../../../../core/widgets/common_button.dart';
import '../../../../core/widgets/pressable_card.dart';
import '../../../goal_detail/presentation/viewmodels/goal_detail_view_model.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../onboarding/presentation/view_models/tutorial_view_model.dart';
import '../../../onboarding/presentation/widgets/tutorial_overlay.dart';

/// 改善されたホーム画面
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  // タブインデックス定数（BottomNavigationBarのアイテム順序に合わせる）
  static const int _homeTabIndex = 0;
  static const int _timerTabIndex = 1;
  static const int _addButtonTabIndex = 2; // BottomNavigationBarでの追加ボタン位置
  static const int _statisticsTabIndex = 3;
  static const int _settingsTabIndex = 4;

  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    _fabAnimationController = AnimationController(
      duration: AnimationConsts.medium,
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: AnimationConsts.bounceCurve,
      ),
    );

    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 認証状態をチェック
    final authState = ref.watch(globalAuthStateProvider);
    final tutorialState = ref.watch(tutorialViewModelProvider);

    // 認証状態監視：オンボーディングが必要な場合は適切な画面に戻る
    ref.listen(globalAuthStateProvider, (previous, next) {
      if (next.needsOnboarding) {
        // 初回起動または未認証の場合
        if (next == app_auth.AuthState.initial) {
          Navigator.of(context).pushReplacementNamed(RouteNames.onboardingGoalCreation);
        } else if (next == app_auth.AuthState.unauthenticated) {
          Navigator.of(context).pushReplacementNamed(RouteNames.login);
        }
      }
    });

    // アプリを使用できない状態の場合は読み込み画面を表示
    if (!authState.canUseApp) {
      String message = '読み込み中...';
      if (authState == app_auth.AuthState.loading) {
        message = '認証状態を確認中...';
      } else if (authState == app_auth.AuthState.error) {
        message = 'エラーが発生しました';
      }
      
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (authState != app_auth.AuthState.error)
                const CircularProgressIndicator(),
              if (authState == app_auth.AuthState.error)
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      );
    }

    final pages = [
      const _HomeTabContent(), // 0: ホーム
      const _TimerPage(), // 1: タイマー
      const SizedBox.shrink(), // 2: 追加ボタン用空スペース
      const StatisticsScreen(), // 3: 統計
      const SettingsScreen(), // 4: 設定
    ];

    final mainScaffold = Scaffold(
      backgroundColor: ColorConsts.backgroundPrimary,
      body: pages[_tabController.index],
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );

    // チュートリアルが有効な場合、オーバーレイを表示
    if (tutorialState.isTutorialActive && 
        _tabController.index == _homeTabIndex && 
        tutorialState.currentStepId == 'home_goal_selection') {
      return Stack(
        children: [
          mainScaffold,
          _buildGoalSelectionTutorial(),
        ],
      );
    }

    return mainScaffold;
  }

  Widget _buildBottomNavigationBar() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: ColorConsts.cardBackground,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: ColorConsts.shadowMedium,
                offset: const Offset(0, -4),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _tabController.index,
            onTap: (index) {
              // 中央の追加ボタンがタップされた場合
              if (index == _addButtonTabIndex) {
                _showAddGoalModal(context);
                return;
              }

              // pages配列と直接対応するため、インデックス調整は不要
              _tabController.animateTo(index);
              setState(() {});
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: ColorConsts.primary,
            unselectedItemColor: ColorConsts.textTertiary,
            selectedLabelStyle: TextConsts.caption.copyWith(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextConsts.caption,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'ホーム',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.timer_outlined),
                activeIcon: Icon(Icons.timer),
                label: 'タイマー',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add, color: Colors.transparent),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart),
                label: '統計',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: '設定',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabScaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [ColorConsts.primary, ColorConsts.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: ColorConsts.primary.withOpacity(0.4),
                  offset: const Offset(0, 8),
                  blurRadius: 24,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () {
                // TODO: 目標追加モーダルを表示
                _showAddGoalModal(context);
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            ),
          ),
        );
      },
    );
  }

  void _showAddGoalModal(BuildContext context) {
    GoalCreateModal.show(context).then((_) {
      if (context.mounted) {
        // 目標リストを再読み込み
        ref.invalidate(goalDetailListProvider);
        ref.read(homeViewModelProvider.notifier).reloadGoals();
      }
    });
  }

  /// チュートリアル：目標選択ガイド
  Widget _buildGoalSelectionTutorial() {
    final viewModel = ref.read(homeViewModelProvider.notifier);
    final goals = viewModel.filteredGoals;

    // 最初の目標がある場合、その実際のGoalCardをハイライト
    if (goals.isEmpty) {
      // 目標がない場合は従来通り
      return TutorialOverlay(
        targetWidget: Container(
          width: 200,
          height: 100,
          decoration: BoxDecoration(
            color: ColorConsts.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text('目標カードをタップしてタイマーを開始'),
          ),
        ),
        title: 'ゴールタイマーの使い方',
        description: '作成した目標をタップすることで、専用のタイマー画面に移動できます。実際にタップしてタイマーを体験してみましょう！',
        onNext: () {
          final tutorialViewModel = ref.read(tutorialViewModelProvider.notifier);
          tutorialViewModel.nextStep('timer_operation');
        },
        onSkip: () {
          final tutorialViewModel = ref.read(tutorialViewModelProvider.notifier);
          tutorialViewModel.skipTutorial();
          Navigator.pushReplacementNamed(context, RouteNames.onboardingAccountPromotion);
        },
      );
    }

    // 実際の目標カードを複製してハイライト表示
    final firstGoal = goals.first;
    final streakDays = viewModel.getGoalStreakFromCache(firstGoal.id) ?? 0;
    final timerButtonKey = GlobalKey(); // タイマーボタン用のKey
    
    return TutorialOverlay(
      targetWidget: GoalCard(
        title: firstGoal.title,
        description: firstGoal.description.isNotEmpty ? firstGoal.description : null,
        progress: firstGoal.getProgressRate(),
        streakDays: streakDays,
        avoidMessage: firstGoal.avoidMessage.isNotEmpty ? firstGoal.avoidMessage : null,
        timerButtonKey: timerButtonKey, // タイマーボタンのKeyを設定
        onTap: () {
          // チュートリアル用：カード全体のタップでタイマー画面に遷移
          _navigateToTimerScreen(context, firstGoal.id);
        },
        onTimerTap: () {
          // チュートリアル用：タイマーボタンのタップでタイマー画面に遷移
          _navigateToTimerScreen(context, firstGoal.id);
        },
      ),
      targetButtonKey: timerButtonKey, // ボタンハイライト用のKeyを指定
      title: 'この目標でタイマーを体験しましょう',
      description: '作成した「${firstGoal.title}」の目標カードの「タイマー開始」ボタンをタップして、タイマー画面に移動しましょう！',
      onNext: () {
        final tutorialViewModel = ref.read(tutorialViewModelProvider.notifier);
        tutorialViewModel.nextStep('timer_operation');
      },
      onSkip: () {
        final tutorialViewModel = ref.read(tutorialViewModelProvider.notifier);
        tutorialViewModel.skipTutorial();
        Navigator.pushReplacementNamed(context, RouteNames.onboardingAccountPromotion);
      },
    );
  }

  // チュートリアル用のタイマー画面への遷移メソッド
  void _navigateToTimerScreen(BuildContext context, String goalId) {
    final tutorialState = ref.read(tutorialViewModelProvider);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimerScreen(
          goalId: goalId,
          isTutorialMode: tutorialState.isTutorialActive,
        ),
      ),
    );
  }
}

class _HomeTabContent extends ConsumerWidget {
  const _HomeTabContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeViewModelProvider);
    final homeViewModel = ref.read(homeViewModelProvider.notifier);
    final tutorialState = ref.watch(tutorialViewModelProvider);

    // ローディング中の表示
    if (homeState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('データを読み込み中...'),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // ユーザー挨拶
        _buildUserGreeting(context, ref),

        // 今日の進捗
        SliverToBoxAdapter(
          child: TodayProgressWidget(
            todayProgress: homeViewModel.statistics.todayProgress,
            totalMinutes: homeViewModel.statistics.totalMinutes,
            targetMinutes: homeViewModel.statistics.targetMinutes,
            currentStreak: homeViewModel.statistics.currentStreak,
            totalGoals: homeViewModel.statistics.totalGoals,
            completedGoals: homeViewModel.statistics.completedGoals,
          ),
        ),

        // セクションヘッダー
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingConsts.l,
              vertical: SpacingConsts.m,
            ),
            child: Text(
              'マイ目標',
              style: TextConsts.h3.copyWith(
                color: ColorConsts.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // 目標リスト
        _buildGoalList(homeState, homeViewModel, ref, tutorialState),
      ],
    );
  }

  Widget _buildUserGreeting(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return SliverToBoxAdapter(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            SpacingConsts.l,
            SpacingConsts.m,
            SpacingConsts.l,
            SpacingConsts.s,
          ),
          child: currentUserAsync.when(
            data: (user) {
              final greeting = _getGreeting();
              final userName =
                  user?.displayName ?? user?.email.split('@')[0] ?? 'ゲスト';

              return Text(
                '$greeting、$userName さん',
                style: TextConsts.h3.copyWith(
                  color: ColorConsts.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
            loading:
                () => Text(
                  '${_getGreeting()}！',
                  style: TextConsts.h3.copyWith(
                    color: ColorConsts.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            error:
                (error, stack) => Text(
                  '${_getGreeting()}！',
                  style: TextConsts.h3.copyWith(
                    color: ColorConsts.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'おはよう';
    } else if (hour < 18) {
      return 'こんにちは';
    } else {
      return 'こんばんは';
    }
  }

  Widget _buildGoalList(
    HomeState homeState,
    HomeViewModel viewModel,
    WidgetRef ref,
    TutorialState tutorialState,
  ) {
    final goals = viewModel.filteredGoals;

    if (goals.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingConsts.l,
            vertical: SpacingConsts.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.flag_outlined,
                size: 80,
                color: ColorConsts.textTertiary,
              ),
              const SizedBox(height: SpacingConsts.l),
              Text(
                '目標がありません',
                style: TextConsts.h3.copyWith(
                  color: ColorConsts.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SpacingConsts.s),
              Text(
                '右下の+ボタンから\n新しい目標を追加してください',
                style: TextConsts.body.copyWith(
                  color: ColorConsts.textTertiary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final goal = goals[index];
        final streakDays = viewModel.getGoalStreakFromCache(goal.id) ?? 0;

        return GoalCard(
          title: goal.title,
          description: goal.description.isNotEmpty ? goal.description : null,
          progress: goal.getProgressRate(),
          streakDays: streakDays,
          avoidMessage: goal.avoidMessage.isNotEmpty ? goal.avoidMessage : null,
          onTap: () {
            // TODO: 目標詳細画面に遷移
          },
          onTimerTap: () {
            // チュートリアル中の場合、特別な処理
            if (tutorialState.isTutorialActive && 
                tutorialState.currentStepId == 'home_goal_selection') {
              final tutorialViewModel = ref.read(tutorialViewModelProvider.notifier);
              tutorialViewModel.startTimerOperationStep();
            }
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TimerScreen(
                  goalId: goal.id,
                  isTutorialMode: tutorialState.isTutorialActive,
                ),
              ),
            );
          },
          onEditTap: () async {
            AppLogger.instance.i('🎯 [HomeScreen] 編集ボタンがタップされました');
            AppLogger.instance.i(
              '🎯 [HomeScreen] 編集対象目標: ${goal.title} (ID: ${goal.id})',
            );

            final result = await GoalCreateModal.show(
              context,
              existingGoal: goal,
            );

            AppLogger.instance.i('🔙 [HomeScreen] モーダルから戻りました');

            if (result != null) {
              if (result == 'deleted') {
                // 削除された場合
                AppLogger.instance.i('🗑️ [HomeScreen] 目標が削除されました');
                AppLogger.instance.i('🔄 [HomeScreen] UI更新処理を開始します...');

                // プロバイダーを無効化してデータを再読み込み
                ref.invalidate(goalDetailListProvider);
                ref.read(homeViewModelProvider.notifier).reloadGoals();

                AppLogger.instance.i('✅ [HomeScreen] 削除後のUI更新完了');
              } else if (result is GoalsModel) {
                // 更新された場合
                AppLogger.instance.i(
                  '✅ [HomeScreen] 更新された目標を受け取りました: ${result.title}',
                );
                AppLogger.instance.i('🔄 [HomeScreen] UI更新処理を開始します...');

                // プロバイダーを無効化してデータを再読み込み
                ref.invalidate(goalDetailListProvider);
                ref.read(homeViewModelProvider.notifier).reloadGoals();

                AppLogger.instance.i(
                  '✅ [HomeScreen] プロバイダー無効化とViewModelリロード完了',
                );
              }
            } else {
              AppLogger.instance.i(
                'ℹ️ [HomeScreen] 更新がキャンセルされました（null が返されました）',
              );
            }
          },
        );
      }, childCount: goals.length),
    );
  }
}

class _TimerPage extends ConsumerWidget {
  const _TimerPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 目標一覧を取得
    final goalDetailsAsync = ref.watch(goalDetailListProvider);

    return goalDetailsAsync.when(
      data: (goals) {
        if (goals.isEmpty) {
          // 目標がない場合は目標作成を促すメッセージを表示
          return Scaffold(
            appBar: AppBar(
              title: const Text('タイマー'),
              backgroundColor: ColorConsts.primary,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(SpacingConsts.l),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.flag,
                      size: 80,
                      color: ColorConsts.textTertiary,
                    ),
                    const SizedBox(height: SpacingConsts.l),
                    Text(
                      'タイマーを使用するには\n目標を作成してください',
                      textAlign: TextAlign.center,
                      style: TextConsts.h3.copyWith(
                        color: ColorConsts.textSecondary,
                      ),
                    ),
                    const SizedBox(height: SpacingConsts.xl),
                    CommonButton(
                      text: '目標を作成',
                      variant: ButtonVariant.primary,
                      onPressed: () => _showAddGoalModal(context, ref),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 目標がある場合は目標一覧を表示
        return Scaffold(
          appBar: AppBar(
            title: const Text('タイマー'),
            backgroundColor: ColorConsts.primary,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(SpacingConsts.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'タイマーを開始する目標を選択してください',
                  style: TextConsts.h4.copyWith(
                    color: ColorConsts.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: SpacingConsts.l),
                Expanded(
                  child: ListView.separated(
                    itemCount: goals.length,
                    separatorBuilder:
                        (context, index) =>
                            const SizedBox(height: SpacingConsts.m),
                    itemBuilder: (context, index) {
                      final goal = goals[index];
                      return _buildGoalTimerCard(context, goal);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading:
          () => Scaffold(
            appBar: AppBar(
              title: const Text('タイマー'),
              backgroundColor: ColorConsts.primary,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (error, stack) => Scaffold(
            appBar: AppBar(
              title: const Text('タイマー'),
              backgroundColor: ColorConsts.primary,
              foregroundColor: Colors.white,
            ),
            body: Center(child: Text('エラーが発生しました: $error')),
          ),
    );
  }

  Widget _buildGoalTimerCard(BuildContext context, GoalsModel goal) {
    return PressableCard(
      onTap: () {
        // タイマー画面に遷移
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TimerScreen(goalId: goal.id)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(SpacingConsts.l),
        child: Row(
          children: [
            // アイコン
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: ColorConsts.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: ColorConsts.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: SpacingConsts.l),

            // テキスト情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: TextConsts.h4.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: SpacingConsts.xs),
                  Text(
                    '${goal.spentMinutes}分 / ${goal.targetMinutes}分',
                    style: TextConsts.body.copyWith(
                      color: ColorConsts.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // 進捗率
            Text(
              '${(goal.getProgressRate() * 100).toInt()}%',
              style: TextConsts.body.copyWith(
                color: ColorConsts.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalModal(BuildContext context, WidgetRef ref) {
    GoalCreateModal.show(context).then((_) {
      if (context.mounted) {
        // 目標リストを再読み込み
        ref.invalidate(goalDetailListProvider);
        ref.read(homeViewModelProvider.notifier).reloadGoals();
      }
    });
  }
}
