import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/animation_consts.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../../../core/widgets/chart_card.dart';
import '../viewmodels/statistics_view_model.dart';

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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    // 初期化時にデータ期間を設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateDateRange();
    });
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
        children:
            periods.asMap().entries.map((entry) {
              final index = entry.key;
              final period = entry.value;
              final isSelected = _selectedPeriod == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPeriod = index;
                    });
                    // 期間変更時にdateRangeProviderを更新
                    _updateDateRange();
                  },
                  child: AnimatedContainer(
                    duration: AnimationConsts.fast,
                    padding: const EdgeInsets.symmetric(
                      vertical: SpacingConsts.m,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? ColorConsts.cardBackground
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow:
                          isSelected
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
                        color:
                            isSelected
                                ? ColorConsts.primary
                                : ColorConsts.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
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

  void _updateDateRange() {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 0: // 週間
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 1: // 月間
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 2: // 年間
        startDate = now.subtract(const Duration(days: 365));
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    ref.read(dateRangeProvider.notifier).state = DateRange(
      startDate: startDate,
      endDate: now,
    );
    
    // Issue #52: 期間変更時に最適化統計プロバイダーに通知
    ref.read(optimizedStatisticsMetricsProvider.notifier).onDateRangeChanged();
  }

  Widget _buildMetricsGrid() {
    return Consumer(
      builder: (context, ref, child) {
        // Issue #52: 最適化されたローカル優先統計プロバイダーを使用
        final metricsAsync = ref.watch(optimizedStatisticsMetricsProvider);

        return metricsAsync.when(
          data:
              (metrics) => LayoutBuilder(
                builder: (context, constraints) {
                  // 画面幅に応じて2列のレイアウトを動的に調整
                  final availableWidth = constraints.maxWidth;
                  final cardWidth = (availableWidth - SpacingConsts.m) / 2;

                  return Column(
                    children: [
                      // 1行目
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              width: cardWidth,
                              child: MetricCard(
                                title: '総勉強時間',
                                value: metrics.totalHours,
                                unit: 'h',
                                icon: Icons.schedule_outlined,
                                iconColor: ColorConsts.primary,
                                changeText:
                                    metrics.studyTimeComparison['changeText'] ??
                                    '+0.0h',
                                changeColor: _getChangeColor(
                                  metrics.studyTimeComparison['difference'] ??
                                      0,
                                ),
                                subtitle: _getPeriodText(),
                              ),
                            ),
                          ),
                          const SizedBox(width: SpacingConsts.m),
                          Expanded(
                            child: SizedBox(
                              width: cardWidth,
                              child: MetricCard(
                                title: '継続日数',
                                value: metrics.consecutiveDays,
                                unit: '日',
                                icon: Icons.whatshot_outlined,
                                iconColor: ColorConsts.warning,
                                changeText:
                                    metrics.streakComparison['changeText'] ??
                                    '+0日',
                                changeColor: _getChangeColor(
                                  metrics.streakComparison['difference'] ?? 0,
                                ),
                                subtitle: '現在のストリーク',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: SpacingConsts.m),
                      // 2行目
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              width: cardWidth,
                              child: MetricCard(
                                title: '達成率',
                                value: metrics.achievementRate,
                                unit: '%',
                                icon: Icons.trending_up_outlined,
                                iconColor: ColorConsts.success,
                                changeText:
                                    metrics
                                        .achievementRateComparison['changeText'] ??
                                    '+0%',
                                changeColor: _getChangeColor(
                                  metrics.achievementRateComparison['difference'] ??
                                      0,
                                ),
                                subtitle: '目標達成率',
                              ),
                            ),
                          ),
                          const SizedBox(width: SpacingConsts.m),
                          Expanded(
                            child: SizedBox(
                              width: cardWidth,
                              child: MetricCard(
                                title: '平均集中時間',
                                value: metrics.averageSessionTime,
                                unit: '分',
                                icon: Icons.timer_outlined,
                                iconColor: ColorConsts.primary,
                                changeText:
                                    metrics
                                        .averageTimeComparison['changeText'] ??
                                    '+0分',
                                changeColor: _getChangeColor(
                                  metrics.averageTimeComparison['difference'] ??
                                      0,
                                ),
                                subtitle: '1セッション平均',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
          loading: () => _buildLoadingMetrics(),
          error: (error, stack) => _buildErrorMetrics(),
        );
      },
    );
  }

  Widget _buildLoadingMetrics() {
    return const SizedBox(
      height: 200,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorMetrics() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(SpacingConsts.l),
      decoration: BoxDecoration(
        color: ColorConsts.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: ColorConsts.error, size: 48),
            SizedBox(height: SpacingConsts.m),
            Text(
              'データの読み込みに失敗しました',
              style: TextStyle(color: ColorConsts.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Color _getChangeColor(dynamic difference) {
    if (difference == null) return ColorConsts.textSecondary;
    final diff =
        difference is int ? difference.toDouble() : difference as double;
    return diff >= 0 ? ColorConsts.success : ColorConsts.error;
  }

  String _getPeriodText() {
    switch (_selectedPeriod) {
      case 0:
        return '先週比';
      case 1:
        return '先月比';
      case 2:
        return '昨年比';
      default:
        return '前期間比';
    }
  }

  Widget _buildChartsSection() {
    return Consumer(
      builder: (context, ref, child) {
        final goalStatsAsync = ref.watch(goalStatisticsProvider);

        return Column(
          children: [
            // 勉強時間チャート
            ChartCard(
              title: '勉強時間の推移',
              subtitle: _getTimeChartSubtitle(),
              chart: _buildTimeChart(),
              legendItems: [
                ChartLegendItem(label: '実績', color: ColorConsts.primary),
                ChartLegendItem(label: '目標', color: ColorConsts.textTertiary),
              ],
            ),

            const SizedBox(height: SpacingConsts.l),

            // 目標別時間分布チャート
            goalStatsAsync.when(
              data:
                  (goalStats) => ChartCard(
                    title: '目標別時間分布',
                    subtitle: _getDistributionChartSubtitle(),
                    chart: _buildDistributionChart(),
                    legendItems: _buildGoalLegendItems(goalStats),
                  ),
              loading:
                  () => ChartCard(
                    title: '目標別時間分布',
                    subtitle: _getDistributionChartSubtitle(),
                    chart: _buildLoadingChart(),
                    legendItems: [],
                  ),
              error:
                  (error, stack) => ChartCard(
                    title: '目標別時間分布',
                    subtitle: _getDistributionChartSubtitle(),
                    chart: _buildErrorChart(),
                    legendItems: [],
                  ),
            ),
          ],
        );
      },
    );
  }

  String _getTimeChartSubtitle() {
    switch (_selectedPeriod) {
      case 0:
        return '過去7日間の勉強時間';
      case 1:
        return '過去30日間の勉強時間';
      case 2:
        return '過去365日間の勉強時間';
      default:
        return '過去7日間の勉強時間';
    }
  }

  String _getDistributionChartSubtitle() {
    switch (_selectedPeriod) {
      case 0:
        return '今週の目標別勉強時間';
      case 1:
        return '今月の目標別勉強時間';
      case 2:
        return '今年の目標別勉強時間';
      default:
        return '今週の目標別勉強時間';
    }
  }

  List<ChartLegendItem> _buildGoalLegendItems(List<GoalStatistic> goalStats) {
    final colors = [
      ColorConsts.primary,
      ColorConsts.success,
      ColorConsts.warning,
      ColorConsts.error,
      ColorConsts.primaryLight,
    ];

    return goalStats.take(5).toList().asMap().entries.map((entry) {
      final index = entry.key;
      final goal = entry.value;
      return ChartLegendItem(
        label: goal.goalTitle,
        color: colors[index % colors.length],
      );
    }).toList();
  }

  Widget _buildLoadingChart() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: ColorConsts.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorChart() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: ColorConsts.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: ColorConsts.error, size: 32),
            SizedBox(height: SpacingConsts.s),
            Text(
              'チャートの読み込みに失敗しました',
              style: TextStyle(color: ColorConsts.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
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
          style: TextStyle(color: ColorConsts.textSecondary, fontSize: 16),
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
          style: TextStyle(color: ColorConsts.textSecondary, fontSize: 16),
        ),
      ),
    );
  }
}
