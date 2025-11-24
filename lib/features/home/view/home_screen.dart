import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/color_consts.dart';
import '../../../core/utils/text_consts.dart';
import '../../../core/utils/spacing_consts.dart';
import '../../../core/utils/animation_consts.dart';
import '../../../core/widgets/goal_card.dart';
import '../../../core/widgets/pressable_card.dart';
import '../view_model/home_view_model.dart';
import '../../settings/view/settings_screen.dart';
import '../../timer/view/timer_screen.dart';
import '../../goal_detail/presentation/screens/goal_create_modal.dart';

/// ホーム画面
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Get.put(HomeViewModel());

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
    Get.delete<HomeViewModel>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeTabContent(),
      const _TimerTabContent(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: ColorConsts.backgroundPrimary,
      body: pages[_tabController.index],
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
          child: BottomNavigationBar(
            currentIndex: _tabController.index,
            onTap: (index) {
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
              onPressed: () => GoalCreateModal.show(context),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            ),
          ),
        );
      },
    );
  }

}

class _HomeTabContent extends StatelessWidget {
  const _HomeTabContent();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeViewModel>(
      builder: (homeViewModel) {
        final homeState = homeViewModel.state;

        if (homeState.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return CustomScrollView(
          slivers: [
            // ユーザー挨拶
            SliverToBoxAdapter(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SpacingConsts.l,
                    SpacingConsts.m,
                    SpacingConsts.l,
                    SpacingConsts.s,
                  ),
                  child: Text(
                    '${_getGreeting()}、ゲストユーザー さん',
                    style: TextConsts.h3.copyWith(
                      color: ColorConsts.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
      },
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

  Widget _buildGoalList(HomeViewModel viewModel) {
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
                '下の+ボタンから\n新しい目標を追加してください',
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

          return GoalCard(
            title: goal.title,
            description: goal.description?.isNotEmpty == true ? goal.description : null,
            progress: 0.0, // TODO: 進捗率の計算ロジックを実装
            streakDays: 0,
            avoidMessage:
                goal.avoidMessage.isNotEmpty ? goal.avoidMessage : null,
            onTap: () {
              // 目標詳細画面（Coming Soon）
            },
            onTimerTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TimerScreen(
                    goal: goal,
                    goalId: goal.id
                  ),
                ),
              );
            },
            onEditTap: () {
              // 編集機能（Coming Soon）
            },
          );
        },
        childCount: goals.length,
      ),
    );
  }
}

class _TimerTabContent extends StatelessWidget {
  const _TimerTabContent();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeViewModel>(
      builder: (homeViewModel) {
        final goals = homeViewModel.state.goals;

        return Scaffold(
          appBar: AppBar(
            title: const Text('タイマー'),
            backgroundColor: ColorConsts.primary,
            foregroundColor: Colors.white,
          ),
          body: goals.isEmpty
              ? Center(
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
                      ],
                    ),
                  ),
                )
              : Padding(
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
                          separatorBuilder: (context, index) =>
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
    );
  }

  Widget _buildGoalTimerCard(BuildContext context, goal) {
    return PressableCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TimerScreen(goal: goal, goalId: goal.id),
          ),
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
              '0%', // TODO: 進捗率の計算ロジックを実装
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
}
