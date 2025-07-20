import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/animation_consts.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../../../core/widgets/chart_card.dart';
import '../../../../core/widgets/achievement_badge.dart';

/// 改善された統計画面
/// データビジュアライゼーションと達成感を重視
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedPeriod = 0; // 0: 週間, 1: 月間, 2: 年間

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AnimationConsts.slow,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
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
    return Scaffold(
      backgroundColor: ColorConsts.backgroundPrimary,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // アプリバー
            _buildSliverAppBar(),
            
            // コンテンツ
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(SpacingConsts.l),
                child: Column(
                  children: [
                    // 期間選択
                    _buildPeriodSelector(),
                    
                    const SizedBox(height: SpacingConsts.l),
                    
                    // メトリクスグリッド
                    _buildMetricsGrid(),
                    
                    const SizedBox(height: SpacingConsts.l),
                    
                    // チャート
                    _buildChartsSection(),
                    
                    const SizedBox(height: SpacingConsts.l),
                    
                    // 達成バッジ
                    _buildAchievementsSection(),
                    
                    const SizedBox(height: SpacingConsts.l),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: ColorConsts.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          '統計',
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
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['週間', '月間', '年間'];
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ColorConsts.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: periods.asMap().entries.map((entry) {
          final index = entry.key;
          final period = entry.value;
          final isSelected = _selectedPeriod == index;
          
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = index;
                });
              },
              child: AnimatedContainer(
                duration: AnimationConsts.fast,
                padding: const EdgeInsets.symmetric(
                  vertical: SpacingConsts.m,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? ColorConsts.cardBackground : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: ColorConsts.shadowLight,
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  period,
                  style: TextConsts.body.copyWith(
                    color: isSelected ? ColorConsts.primary : ColorConsts.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: SpacingConsts.m,
      mainAxisSpacing: SpacingConsts.m,
      childAspectRatio: 1.3,
      children: [
        MetricCard(
          title: '総勉強時間',
          value: '24',
          unit: 'h',
          icon: Icons.schedule_outlined,
          iconColor: ColorConsts.primary,
          changeText: '+2.5h',
          changeColor: ColorConsts.success,
          subtitle: '先週比',
        ),
        MetricCard(
          title: '継続日数',
          value: '12',
          unit: '日',
          icon: Icons.whatshot_outlined,
          iconColor: ColorConsts.warning,
          changeText: '+3日',
          changeColor: ColorConsts.success,
          subtitle: '現在のストリーク',
        ),
        MetricCard(
          title: '達成率',
          value: '85',
          unit: '%',
          icon: Icons.trending_up_outlined,
          iconColor: ColorConsts.success,
          changeText: '+5%',
          changeColor: ColorConsts.success,
          subtitle: '目標達成率',
        ),
        MetricCard(
          title: '平均集中時間',
          value: '42',
          unit: '分',
          icon: Icons.timer_outlined,
          iconColor: ColorConsts.primary,
          changeText: '+7分',
          changeColor: ColorConsts.success,
          subtitle: '1セッション平均',
        ),
      ],
    );
  }

  Widget _buildChartsSection() {
    return Column(
      children: [
        // 勉強時間チャート
        ChartCard(
          title: '勉強時間の推移',
          subtitle: '過去7日間の勉強時間',
          chart: _buildTimeChart(),
          legendItems: [
            ChartLegendItem(label: '実績', color: ColorConsts.primary),
            ChartLegendItem(label: '目標', color: ColorConsts.textTertiary),
          ],
        ),
        
        const SizedBox(height: SpacingConsts.l),
        
        // 目標別時間分布チャート
        ChartCard(
          title: '目標別時間分布',
          subtitle: '今週の目標別勉強時間',
          chart: _buildDistributionChart(),
          legendItems: [
            ChartLegendItem(label: '英語', color: ColorConsts.primary),
            ChartLegendItem(label: 'プログラミング', color: ColorConsts.success),
            ChartLegendItem(label: '資格勉強', color: ColorConsts.warning),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeChart() {
    // TODO: 実際のチャートライブラリを使用して実装
    return Container(
      decoration: BoxDecoration(
        color: ColorConsts.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          '時間推移チャート\n（実装予定）',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ColorConsts.textSecondary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDistributionChart() {
    // TODO: 実際のチャートライブラリを使用して実装
    return Container(
      decoration: BoxDecoration(
        color: ColorConsts.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          '分布チャート\n（実装予定）',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ColorConsts.textSecondary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '達成バッジ',
          style: TextConsts.h3.copyWith(
            color: ColorConsts.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: SpacingConsts.m),
        
        Text(
          '継続的な努力で獲得できるバッジです',
          style: TextConsts.body.copyWith(
            color: ColorConsts.textSecondary,
          ),
        ),
        
        const SizedBox(height: SpacingConsts.l),
        
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: SpacingConsts.m,
          mainAxisSpacing: SpacingConsts.m,
          childAspectRatio: 0.8,
          children: [
            AchievementBadge(
              title: '初回達成',
              description: '初めて目標を達成',
              icon: Icons.flag_outlined,
              color: ColorConsts.success,
              isUnlocked: true,
              unlockedAt: DateTime.now().subtract(const Duration(days: 5)),
            ),
            AchievementBadge(
              title: '3日継続',
              description: '3日間連続で目標達成',
              icon: Icons.local_fire_department,
              color: ColorConsts.warning,
              isUnlocked: true,
              unlockedAt: DateTime.now().subtract(const Duration(days: 2)),
            ),
            AchievementBadge(
              title: '1週間継続',
              description: '7日間連続で目標達成',
              icon: Icons.calendar_view_week,
              color: ColorConsts.primary,
              isUnlocked: false,
            ),
            AchievementBadge(
              title: '早起き習慣',
              description: '朝6時前に勉強開始',
              icon: Icons.wb_sunny_outlined,
              color: ColorConsts.warning,
              isUnlocked: false,
            ),
            AchievementBadge(
              title: '集中マスター',
              description: '2時間連続で集中',
              icon: Icons.psychology_outlined,
              color: ColorConsts.primary,
              isUnlocked: false,
            ),
            AchievementBadge(
              title: '目標達成王',
              description: '月間目標を100%達成',
              icon: Icons.emoji_events_outlined,
              color: const Color(0xFFFFD700),
              isUnlocked: false,
            ),
          ],
        ),
      ],
    );
  }
}