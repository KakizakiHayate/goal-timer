import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/color_consts.dart';
import '../../../core/utils/spacing_consts.dart';
import '../../../core/utils/text_consts.dart';
import '../../../core/utils/time_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/analytics_state.dart';
import '../view_model/analytics_view_model.dart';

/// 分析画面
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    Get.put(AnalyticsViewModel());
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Get.find<AnalyticsViewModel>().loadData(
      periodType: AnalyticsPeriodType.week,
      referenceDate: DateTime.now(),
    );
  }

  @override
  void dispose() {
    Get.delete<AnalyticsViewModel>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.navAnalytics ?? 'Analytics'),
        backgroundColor: ColorConsts.primary,
        foregroundColor: Colors.white,
      ),
      body: GetBuilder<AnalyticsViewModel>(
        builder: (viewModel) {
          final state = viewModel.state;

          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(SpacingConsts.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PeriodSelector(viewModel: viewModel),
                const SizedBox(height: SpacingConsts.md),
                _PeriodNavigator(viewModel: viewModel),
                const SizedBox(height: SpacingConsts.md),
                _SummaryCards(state: state),
                const SizedBox(height: SpacingConsts.lg),
                if (state.isEmpty)
                  _EmptyState(
                    onStartStudying: () {
                      // タイマータブ（index 1）に切り替え
                      final homeState = context.findAncestorStateOfType<State>();
                      if (homeState != null) {
                        // BottomNavigationBarのonTapを呼ぶ代わりに、
                        // Navigatorでpopしてタイマータブに移動
                      }
                    },
                  )
                else ...[
                  _StackedBarChart(state: state),
                  const SizedBox(height: SpacingConsts.md),
                  _Legend(state: state),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 週/月の切り替えセグメント
class _PeriodSelector extends StatelessWidget {
  final AnalyticsViewModel viewModel;

  const _PeriodSelector({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = viewModel.state;

    return Container(
      decoration: BoxDecoration(
        color: ColorConsts.backgroundSecondary,
        borderRadius: BorderRadius.circular(SpacingConsts.radiusSm),
      ),
      padding: const EdgeInsets.all(SpacingConsts.xs),
      child: Row(
        children: [
          _buildSegment(
            label: l10n?.analyticsWeek ?? 'Week',
            isSelected: state.periodType == AnalyticsPeriodType.week,
            onTap: () =>
                viewModel.switchPeriodType(AnalyticsPeriodType.week),
          ),
          _buildSegment(
            label: l10n?.analyticsMonth ?? 'Month',
            isSelected: state.periodType == AnalyticsPeriodType.month,
            onTap: () =>
                viewModel.switchPeriodType(AnalyticsPeriodType.month),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: SpacingConsts.sm),
          decoration: BoxDecoration(
            color: isSelected ? ColorConsts.cardBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(SpacingConsts.radiusXs),
            boxShadow: isSelected
                ? [
                    const BoxShadow(
                      color: ColorConsts.shadowLight,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextConsts.labelMedium.copyWith(
                color: isSelected
                    ? ColorConsts.primary
                    : ColorConsts.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 期間ナビゲーション（< 2026/02/16 - 02/22 >）
class _PeriodNavigator extends StatelessWidget {
  final AnalyticsViewModel viewModel;

  const _PeriodNavigator({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final state = viewModel.state;
    final periodLabel = _formatPeriodLabel(context, state);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => viewModel.goToPreviousPeriod(),
          icon: const Icon(Icons.chevron_left),
          color: ColorConsts.textSecondary,
        ),
        Text(
          periodLabel,
          style: TextConsts.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          onPressed: state.canGoForward
              ? () => viewModel.goToNextPeriod()
              : null,
          icon: const Icon(Icons.chevron_right),
          color: state.canGoForward
              ? ColorConsts.textSecondary
              : ColorConsts.disabled,
        ),
      ],
    );
  }

  String _formatPeriodLabel(BuildContext context, AnalyticsState state) {
    final l10n = AppLocalizations.of(context);

    if (state.periodType == AnalyticsPeriodType.month) {
      final monthName = DateFormat.MMMM(
        Localizations.localeOf(context).languageCode,
      ).format(state.startDate);

      return l10n?.analyticsMonthYear(monthName, state.startDate.year) ??
          '${state.startDate.year}/${state.startDate.month}';
    }

    // 週表示
    final startFormatted = DateFormat('MM/dd').format(state.startDate);
    final endFormatted = DateFormat('MM/dd').format(state.endDate);
    return '$startFormatted - $endFormatted';
  }
}

/// サマリーカード（合計時間・1日平均・学習日数）
class _SummaryCards extends StatelessWidget {
  final AnalyticsState state;

  const _SummaryCards({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: l10n?.analyticsTotalTime ?? 'Total Time',
            value: _formatTime(context, state.totalSeconds),
          ),
        ),
        const SizedBox(width: SpacingConsts.sm),
        Expanded(
          child: _SummaryCard(
            label: l10n?.analyticsDailyAverage ?? 'Daily Avg',
            value: _formatTime(context, state.dailyAverageSeconds),
          ),
        ),
        const SizedBox(width: SpacingConsts.sm),
        Expanded(
          child: _SummaryCard(
            label: l10n?.analyticsStudyDays ?? 'Study Days',
            value: l10n?.analyticsDaysSuffix(state.studyDaysCount) ??
                '${state.studyDaysCount}日',
          ),
        ),
      ],
    );
  }

  String _formatTime(BuildContext context, int totalSeconds) {
    final l10n = AppLocalizations.of(context);
    if (l10n != null) {
      return TimeUtils.formatSecondsToHoursAndMinutesL10n(totalSeconds, l10n);
    }
    return TimeUtils.formatSecondsToHoursAndMinutes(totalSeconds);
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingConsts.sm,
        vertical: SpacingConsts.md,
      ),
      decoration: BoxDecoration(
        color: ColorConsts.cardBackground,
        borderRadius: BorderRadius.circular(SpacingConsts.radiusMd),
        boxShadow: const [
          BoxShadow(
            color: ColorConsts.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextConsts.caption.copyWith(
              color: ColorConsts.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: SpacingConsts.xs),
          Text(
            value,
            style: TextConsts.labelMedium.copyWith(
              color: ColorConsts.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 積み上げ棒グラフ
class _StackedBarChart extends StatelessWidget {
  final AnalyticsState state;

  const _StackedBarChart({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      padding: const EdgeInsets.only(
        top: SpacingConsts.md,
        right: SpacingConsts.sm,
      ),
      decoration: BoxDecoration(
        color: ColorConsts.cardBackground,
        borderRadius: BorderRadius.circular(SpacingConsts.radiusMd),
        boxShadow: const [
          BoxShadow(
            color: ColorConsts.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _calculateMaxY(),
          barTouchData: _buildBarTouchData(context),
          titlesData: _buildTitlesData(context),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _calculateInterval(),
            getDrawingHorizontalLine: (value) => FlLine(
              color: ColorConsts.border.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          barGroups: _buildBarGroups(),
        ),
      ),
    );
  }

  double _calculateMaxY() {
    if (state.maxDailySeconds <= 0) return 60;
    // 最大値の1.2倍を上限にする
    return state.maxDailySeconds * 1.2;
  }

  double _calculateInterval() {
    final maxY = _calculateMaxY();
    if (state.useHoursUnit) {
      // 時間単位: 1時間ごと
      return TimeUtils.secondsPerHour.toDouble();
    }
    // 分単位: 適切な間隔を計算
    final maxMinutes = maxY / TimeUtils.secondsPerMinute;
    if (maxMinutes <= 15) return 5 * TimeUtils.secondsPerMinute.toDouble();
    if (maxMinutes <= 30) return 10 * TimeUtils.secondsPerMinute.toDouble();
    return 15 * TimeUtils.secondsPerMinute.toDouble();
  }

  BarTouchData _buildBarTouchData(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        tooltipRoundedRadius: SpacingConsts.radiusSm,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final dayData = state.dailyData[group.x];
          if (!dayData.hasStudy) return null;

          final dateStr = DateFormat('MM/dd').format(dayData.date);
          final totalMinutes =
              dayData.totalSeconds ~/ TimeUtils.secondsPerMinute;

          final lines = <String>[dateStr];

          // 目標ごとの内訳
          for (final entry in dayData.goalSeconds.entries) {
            final goal = state.activeGoals
                .where((g) => g.id == entry.key)
                .firstOrNull;
            final goalName = goal?.title ?? '';
            final minutes = entry.value ~/ TimeUtils.secondsPerMinute;
            lines.add('$goalName: ${minutes}m');
          }

          final totalLabel = l10n?.analyticsTotal ?? 'Total';
          lines.add('$totalLabel: ${totalMinutes}m');

          return BarTooltipItem(
            lines.join('\n'),
            TextConsts.caption.copyWith(
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

  FlTitlesData _buildTitlesData(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) =>
              _buildBottomTitle(value.toInt(), context),
          reservedSize: 28,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: _calculateInterval(),
          getTitlesWidget: (value, meta) =>
              _buildLeftTitle(value, l10n),
        ),
      ),
    );
  }

  Widget _buildBottomTitle(int index, BuildContext context) {
    if (index < 0 || index >= state.dailyData.length) {
      return const SizedBox.shrink();
    }

    final date = state.dailyData[index].date;

    if (state.periodType == AnalyticsPeriodType.week) {
      // 週表示: 曜日の略称
      final weekdayLabel = DateFormat.E(
        Localizations.localeOf(context).languageCode,
      ).format(date);
      return Padding(
        padding: const EdgeInsets.only(top: SpacingConsts.xs),
        child: Text(
          weekdayLabel,
          style: TextConsts.caption.copyWith(fontSize: 10),
        ),
      );
    }

    // 月表示: 7日間隔でラベル
    if (date.day == 1 || date.day % 7 == 0) {
      return Padding(
        padding: const EdgeInsets.only(top: SpacingConsts.xs),
        child: Text(
          '${date.day}',
          style: TextConsts.caption.copyWith(fontSize: 10),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildLeftTitle(double value, AppLocalizations? l10n) {
    if (state.useHoursUnit) {
      final hours = value ~/ TimeUtils.secondsPerHour;
      return Text(
        l10n?.analyticsHoursFormat(hours) ?? '${hours}h',
        style: TextConsts.caption.copyWith(fontSize: 10),
      );
    }
    final minutes = value ~/ TimeUtils.secondsPerMinute;
    return Text(
      l10n?.analyticsMinutesFormat(minutes) ?? '${minutes}m',
      style: TextConsts.caption.copyWith(fontSize: 10),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return state.dailyData.asMap().entries.map((entry) {
      final index = entry.key;
      final dayData = entry.value;

      final rodStackItems = <BarChartRodStackItem>[];
      double cumulative = 0;

      // 目標をcreatedAt順にソートして積み上げ
      final sortedGoals = List.of(state.activeGoals)
        ..sort((a, b) => (a.createdAt ?? DateTime.now())
            .compareTo(b.createdAt ?? DateTime.now()));

      for (var i = 0; i < sortedGoals.length; i++) {
        final goal = sortedGoals[i];
        final seconds = dayData.goalSeconds[goal.id] ?? 0;
        if (seconds <= 0) continue;

        final color = AnalyticsColors.getColor(i);
        rodStackItems.add(
          BarChartRodStackItem(
            cumulative,
            cumulative + seconds,
            color,
          ),
        );
        cumulative += seconds;
      }

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: cumulative,
            rodStackItems: rodStackItems,
            width: state.periodType == AnalyticsPeriodType.week ? 24 : 8,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            color: rodStackItems.isEmpty
                ? Colors.transparent
                : null,
          ),
        ],
      );
    }).toList();
  }
}

/// 凡例（目標名 + 色）
class _Legend extends StatelessWidget {
  final AnalyticsState state;

  const _Legend({required this.state});

  @override
  Widget build(BuildContext context) {
    final sortedGoals = List.of(state.activeGoals)
      ..sort((a, b) => (a.createdAt ?? DateTime.now())
          .compareTo(b.createdAt ?? DateTime.now()));

    return Wrap(
      spacing: SpacingConsts.md,
      runSpacing: SpacingConsts.sm,
      children: sortedGoals.asMap().entries.map((entry) {
        final index = entry.key;
        final goal = entry.value;
        final color = AnalyticsColors.getColor(index);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: SpacingConsts.xs),
            Text(
              goal.title,
              style: TextConsts.caption.copyWith(
                color: ColorConsts.textSecondary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

/// 空状態表示
class _EmptyState extends StatelessWidget {
  final VoidCallback onStartStudying;

  const _EmptyState({required this.onStartStudying});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SpacingConsts.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bar_chart,
              size: 80,
              color: ColorConsts.textTertiary,
            ),
            const SizedBox(height: SpacingConsts.lg),
            Text(
              l10n?.analyticsNoData ?? 'No study records yet',
              style: TextConsts.h4.copyWith(
                color: ColorConsts.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: SpacingConsts.md),
            ElevatedButton(
              onPressed: onStartStudying,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConsts.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingConsts.lg,
                  vertical: SpacingConsts.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(SpacingConsts.radiusMd),
                ),
              ),
              child: Text(
                l10n?.analyticsStartStudying ??
                    'Start studying with Timer',
                style: TextConsts.buttonMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
