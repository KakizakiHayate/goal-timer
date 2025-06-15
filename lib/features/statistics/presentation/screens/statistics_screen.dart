import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/statistics_view_model.dart';
import '../../domain/entities/statistics.dart';
import '../../domain/entities/daily_stats.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('統計'),
          bottom: const TabBar(tabs: [Tab(text: '今日の統計'), Tab(text: '期間統計')]),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () => _selectDate(context, ref),
            ),
          ],
        ),
        body: TabBarView(children: [_DailyStatsTab(), _PeriodStatsTab()]),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, WidgetRef ref) async {
    final currentDate = ref.read(selectedDateProvider);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      ref.read(selectedDateProvider.notifier).state = pickedDate;
    }
  }
}

class _DailyStatsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final dailyStatsAsync = ref.watch(dailyStatsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '${DateFormat('yyyy年MM月dd日').format(selectedDate)}の記録',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: dailyStatsAsync.when(
            data: (stats) {
              if (stats.totalMinutes == 0) {
                return const Center(child: Text('この日の記録はありません'));
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDailySummaryCard(context, stats),
                      const SizedBox(height: 16),
                      _buildGoalBreakdownCard(context, stats),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('エラーが発生しました: $error')),
          ),
        ),
      ],
    );
  }

  Widget _buildDailySummaryCard(BuildContext context, DailyStats stats) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('学習サマリー', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            const SizedBox(height: 8),
            _buildSummaryItem(context, '総学習時間', stats.formattedTotalTime),
            _buildSummaryItem(context, '学習した目標数', '${stats.goalCount}個'),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalBreakdownCard(BuildContext context, DailyStats stats) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('目標別内訳', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.goalMinutes.length,
              itemBuilder: (context, index) {
                final goalId = stats.goalMinutes.keys.elementAt(index);
                final minutes = stats.goalMinutes[goalId] ?? 0;
                final title = stats.goalTitles[goalId] ?? 'Unknown Goal';

                final hours = minutes ~/ 60;
                final mins = minutes % 60;
                final timeText =
                    hours > 0
                        ? '$hours時間${mins > 0 ? '$mins分' : ''}'
                        : '$mins分';

                return ListTile(
                  title: Text(title),
                  subtitle: Text('学習時間: $timeText'),
                  trailing: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      '${(minutes / stats.totalMinutes * 100).round()}%',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _PeriodStatsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(dateRangeProvider);
    final statisticsAsync = ref.watch(filteredStatisticsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '期間: ${DateFormat('yyyy/MM/dd').format(dateRange.startDate)} - '
                '${DateFormat('yyyy/MM/dd').format(dateRange.endDate)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: () => _selectDateRange(context, ref),
                child: const Text('期間変更'),
              ),
            ],
          ),
        ),
        Expanded(
          child: statisticsAsync.when(
            data: (statistics) {
              if (statistics.isEmpty) {
                return const Center(child: Text('この期間のデータはありません'));
              }

              int totalMinutes = 0;
              int totalGoals = 0;

              for (var stat in statistics) {
                totalMinutes += stat.totalMinutes;
                totalGoals += stat.goalCount;
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildSummaryCard(
                        context,
                        totalMinutes,
                        totalGoals,
                        statistics.length,
                      ),
                      const SizedBox(height: 16),
                      _buildDailyStatsList(context, statistics, ref),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('エラーが発生しました: $error')),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    int totalMinutes,
    int totalGoals,
    int days,
  ) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final totalTimeText =
        hours > 0 ? '$hours時間${minutes > 0 ? '$minutes分' : ''}' : '$minutes分';

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('期間統計', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            const SizedBox(height: 8),
            _buildSummaryItem(context, '合計時間', totalTimeText),
            _buildSummaryItem(context, '合計目標達成数', '$totalGoals 個'),
            _buildSummaryItem(
              context,
              '1日平均時間',
              '${(totalMinutes / days).round()} 分/日',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildDailyStatsList(
    BuildContext context,
    List<Statistics> statistics,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('日別の記録', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: statistics.length,
          itemBuilder: (context, index) {
            final stat = statistics[index];

            final hours = stat.totalMinutes ~/ 60;
            final minutes = stat.totalMinutes % 60;
            final timeText =
                hours > 0
                    ? '$hours時間${minutes > 0 ? '$minutes分' : ''}'
                    : '$minutes分';

            return Card(
              child: ListTile(
                title: Text(DateFormat('yyyy/MM/dd').format(stat.date)),
                subtitle: Text('$timeText / ${stat.goalCount}個の目標'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // 選択された日付を設定してタブを切り替え
                  ref.read(selectedDateProvider.notifier).state = stat.date;
                  DefaultTabController.of(context).animateTo(0);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _selectDateRange(BuildContext context, WidgetRef ref) async {
    final initialDateRange = ref.read(dateRangeProvider);

    final pickedDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: initialDateRange.startDate,
        end: initialDateRange.endDate,
      ),
    );

    if (pickedDateRange != null) {
      ref.read(dateRangeProvider.notifier).state = DateRange(
        startDate: pickedDateRange.start,
        endDate: pickedDateRange.end,
      );
    }
  }
}
