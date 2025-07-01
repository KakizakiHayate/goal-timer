import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/animation_consts.dart';
import '../../../../core/widgets/goal_card_v2.dart';
import '../widgets/today_progress_widget_v2.dart';
import '../view_models/home_view_model.dart';
import '../../provider/home_provider.dart';
import '../../../goal_timer/presentation/screens/timer_screen.dart';
import '../../../statistics/presentation/screens/statistics_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../shared/widgets/sync_status_indicator.dart';
import '../../../../core/provider/providers.dart';
import '../../../auth/domain/entities/auth_state.dart' as app_auth;
import '../../../auth/provider/auth_provider.dart';
import '../../../../core/utils/route_names.dart';

/// 改善されたホーム画面
class HomeScreenV2 extends ConsumerStatefulWidget {
  const HomeScreenV2({super.key});

  @override
  ConsumerState<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends ConsumerState<HomeScreenV2>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    _fabAnimationController = AnimationController(
      duration: AnimationConsts.medium,
      vsync: this,
    );
    
    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
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

    // 認証状態監視：未認証の場合はログイン画面に戻る
    ref.listen(globalAuthStateProvider, (previous, next) {
      if (next == app_auth.AuthState.unauthenticated) {
        Navigator.of(context).pushReplacementNamed(RouteNames.login);
      }
    });

    // 認証されていない場合は読み込み画面を表示
    if (authState != app_auth.AuthState.authenticated) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('認証状態を確認中...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ColorConsts.backgroundPrimary,
      body: TabBarView(
        controller: _tabController,
        children: const [
          _HomeTabContent(),
          _TimerTabContent(),
          StatisticsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
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
          child: TabBar(
            controller: _tabController,
            labelColor: ColorConsts.primary,
            unselectedLabelColor: ColorConsts.textTertiary,
            indicatorColor: Colors.transparent,
            labelStyle: TextConsts.caption.copyWith(
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: TextConsts.caption.copyWith(
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              _buildTabItem(Icons.home_outlined, Icons.home, 'ホーム', 0),
              _buildTabItem(Icons.timer_outlined, Icons.timer, 'タイマー', 1),
              _buildTabItem(Icons.analytics_outlined, Icons.analytics, '統計', 2),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabItem(
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
    int index,
  ) {
    final isSelected = _tabController.index == index;
    
    return Tab(
      height: 70,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: AnimationConsts.fast,
            child: Icon(
              isSelected ? filledIcon : outlinedIcon,
              key: ValueKey(isSelected),
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
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
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddGoalModal(BuildContext context) {
    // TODO: 目標追加モーダルの実装
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('目標追加'),
        content: const Text('目標追加機能は実装中です'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
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

    return CustomScrollView(
      slivers: [
        // アプリバー
        _buildSliverAppBar(context, ref),
        
        // 今日の進捗
        SliverToBoxAdapter(
          child: TodayProgressWidgetV2(
            todayProgress: 0.7, // TODO: 実際の進捗データに置き換え
            totalMinutes: 180,
            targetMinutes: 240,
            currentStreak: 5,
            totalGoals: 3,
            completedGoals: 2,
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
        _buildGoalList(homeViewModel),
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: ColorConsts.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Goal Timer',
          style: TextConsts.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ColorConsts.primary, ColorConsts.primaryLight],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      actions: [
        const SyncStatusIndicator(),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'settings':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
                break;
              case 'signout':
                _showSignOutDialog(context, ref);
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('設定'),
                dense: true,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'signout',
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text(
                  'サインアウト',
                  style: TextStyle(color: Colors.red),
                ),
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalList(HomeViewModel viewModel) {
    final goals = viewModel.filteredGoals;

    if (goals.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final goal = goals[index];
          return GoalCardV2(
            title: goal.title,
            description: goal.description.isNotEmpty ? goal.description : null,
            progress: goal.getProgressRate(),
            streakDays: 3, // TODO: 実際のストリークデータに置き換え
            avoidMessage: goal.avoidMessage.isNotEmpty ? goal.avoidMessage : null,
            onTap: () {
              // TODO: 目標詳細画面に遷移
            },
            onTimerTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TimerScreen(goalId: goal.id),
                ),
              );
            },
            onEditTap: () {
              // TODO: 目標編集画面に遷移
            },
          );
        },
        childCount: goals.length,
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('サインアウト'),
          content: const Text('サインアウトしますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final authNotifier = ref.read(authViewModelProvider.notifier);
                  await authNotifier.signOut();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('サインアウトに失敗しました: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('サインアウト'),
            ),
          ],
        );
      },
    );
  }
}

class _TimerTabContent extends ConsumerWidget {
  const _TimerTabContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: タイマー選択画面の実装
    return Scaffold(
      appBar: AppBar(
        title: const Text('タイマー'),
        backgroundColor: ColorConsts.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'タイマー選択画面\n（実装中）',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}