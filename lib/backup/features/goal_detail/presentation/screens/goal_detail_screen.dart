import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/provider/providers.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/animation_consts.dart';
import '../../../../core/widgets/circular_progress_indicator.dart' as custom;
import '../../../../core/widgets/streak_indicator.dart';
import '../../../../core/widgets/pressable_card.dart';
import '../../../../core/models/goals/goals_model.dart';
import '../../../timer/presentation/timer_screen.dart';
import '../viewmodels/goal_detail_view_model.dart';
import 'goal_create_modal.dart';

/// 改善された目標詳細画面
class GoalDetailScreen extends ConsumerStatefulWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AnimationConsts.medium,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 一時的にHybridRepositoryから直接取得（個別目標プロバイダーが必要）
    final goalAsync = ref.watch(
      FutureProvider<GoalsModel?>((ref) async {
        try {
          final repository = ref.watch(hybridGoalsRepositoryProvider);
          return await repository.getGoalById(widget.goalId);
        } catch (e) {
          return null;
        }
      }),
    );

    return goalAsync.when(
      data: (goal) {
        if (goal == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('目標詳細'),
              backgroundColor: ColorConsts.primary,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: Text('目標が見つかりません')),
          );
        }

        return _buildGoalDetail(context, goal);
      },
      loading:
          () => Scaffold(
            appBar: AppBar(
              title: const Text('目標詳細'),
              backgroundColor: ColorConsts.primary,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (error, stack) => Scaffold(
            appBar: AppBar(
              title: const Text('目標詳細'),
              backgroundColor: ColorConsts.primary,
              foregroundColor: Colors.white,
            ),
            body: Center(child: Text('エラーが発生しました: $error')),
          ),
    );
  }

  Widget _buildGoalDetail(BuildContext context, GoalsModel goal) {
    return Scaffold(
      backgroundColor: ColorConsts.backgroundPrimary,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              // アプリバー
              _buildSliverAppBar(goal),

              // コンテンツ
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(SpacingConsts.l),
                  child: Column(
                    children: [
                      // 進捗概要カード
                      _buildProgressOverviewCard(goal),

                      const SizedBox(height: SpacingConsts.l),

                      // 統計カード
                      _buildStatsCard(goal),

                      const SizedBox(height: SpacingConsts.l),

                      // ネガティブ回避カード
                      _buildAvoidanceCard(goal),

                      const SizedBox(height: SpacingConsts.l),

                      // アクションカード
                      _buildActionCard(goal),

                      const SizedBox(height: SpacingConsts.l),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(GoalsModel goal) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: ColorConsts.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          goal.title,
          style: TextConsts.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ColorConsts.primary, ColorConsts.primaryLight],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: SpacingConsts.l,
                bottom: SpacingConsts.l,
                child: StreakIndicator(
                  streakDays: 5, // TODO: 実際のデータに置き換え
                  showAnimation: true,
                  size: 48.0,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          onPressed: () => _showEditModal(goal),
        ),
      ],
    );
  }

  Widget _buildProgressOverviewCard(GoalsModel goal) {
    final progress = goal.getProgressRate();

    return PressableCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(SpacingConsts.l),
      backgroundColor: ColorConsts.cardBackground,
      borderRadius: 20.0,
      elevation: 2.0,
      child: Column(
        children: [
          Text(
            '今日の進捗',
            style: TextConsts.h3.copyWith(
              color: ColorConsts.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: SpacingConsts.l),

          Row(
            children: [
              // プログレスサークル
              custom.CircularProgressIndicator(
                progress: progress,
                size: 120.0,
                strokeWidth: 10.0,
                showAnimation: true,
              ),

              const SizedBox(width: SpacingConsts.l),

              // 詳細情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressDetail(
                      label: '達成率',
                      value: '${(progress * 100).toInt()}%',
                      color:
                          progress >= 0.8
                              ? ColorConsts.success
                              : ColorConsts.primary,
                    ),
                    const SizedBox(height: SpacingConsts.m),
                    _buildProgressDetail(
                      label: '今日の時間',
                      value: '45分', // TODO: 実際のデータに置き換え
                      color: ColorConsts.textPrimary,
                    ),
                    const SizedBox(height: SpacingConsts.m),
                    _buildProgressDetail(
                      label: '目標時間',
                      value:
                          '${(goal.targetMinutes ~/ 60)}時間${(goal.targetMinutes % 60)}分',
                      color: ColorConsts.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDetail({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextConsts.caption.copyWith(
            color: ColorConsts.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingConsts.xs),
        Text(
          value,
          style: TextConsts.h4.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(GoalsModel goal) {
    return PressableCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(SpacingConsts.l),
      backgroundColor: ColorConsts.cardBackground,
      borderRadius: 20.0,
      elevation: 2.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '統計情報',
            style: TextConsts.h4.copyWith(
              color: ColorConsts.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: SpacingConsts.l),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.schedule_outlined,
                  label: '累計時間',
                  value: '15時間',
                  color: ColorConsts.primary,
                ),
              ),
              Container(width: 1, height: 50, color: ColorConsts.border),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.calendar_today_outlined,
                  label: '実行日数',
                  value: '12日',
                  color: ColorConsts.success,
                ),
              ),
              Container(width: 1, height: 50, color: ColorConsts.border),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.trending_up_outlined,
                  label: '平均時間',
                  value: '38分',
                  color: ColorConsts.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: SpacingConsts.s),
        Text(
          value,
          style: TextConsts.h4.copyWith(
            color: ColorConsts.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextConsts.caption.copyWith(color: ColorConsts.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAvoidanceCard(GoalsModel goal) {
    if (goal.avoidMessage.isEmpty) return const SizedBox.shrink();

    return PressableCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(SpacingConsts.l),
      backgroundColor: ColorConsts.error.withValues(alpha: 0.05),
      borderRadius: 20.0,
      elevation: 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorConsts.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: SpacingConsts.m),
              Text(
                'やらないとどうなる？',
                style: TextConsts.h4.copyWith(
                  color: ColorConsts.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: SpacingConsts.m),

          Text(
            goal.avoidMessage,
            style: TextConsts.body.copyWith(
              color: ColorConsts.textPrimary,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(GoalsModel goal) {
    return PressableCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(SpacingConsts.l),
      backgroundColor: ColorConsts.cardBackground,
      borderRadius: 20.0,
      elevation: 2.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'アクション',
            style: TextConsts.h4.copyWith(
              color: ColorConsts.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: SpacingConsts.l),

          // タイマー開始ボタン
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _startTimer(goal),
              icon: const Icon(Icons.timer_outlined),
              label: Text(
                'タイマーを開始',
                style: TextConsts.body.copyWith(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConsts.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),

          const SizedBox(height: SpacingConsts.m),

          // その他のアクション
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditModal(goal),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('編集'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorConsts.textSecondary,
                    side: const BorderSide(color: ColorConsts.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: SpacingConsts.m),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareGoal,
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('共有'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorConsts.textSecondary,
                    side: const BorderSide(color: ColorConsts.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startTimer(GoalsModel goal) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TimerScreen(goalId: goal.id)),
    );
  }

  void _showEditModal(GoalsModel goal) async {
    final result = await GoalCreateModal.show(context, existingGoal: goal);
    if (result != null && mounted) {
      // 目標が更新された場合、画面を再描画
      setState(() {
        // UI更新
      });
    }
  }

  void _shareGoal() {
    // TODO: 目標共有機能の実装
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('共有機能は実装中です'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(SpacingConsts.l),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
