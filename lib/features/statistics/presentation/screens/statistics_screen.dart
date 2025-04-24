import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/statistics_view_model.dart';
import '../../domain/entities/statistics.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(filteredStatisticsProvider);
    final dateRange = ref.watch(dateRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('統計'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _selectDateRange(context, ref),
          ),
        ],
      ),
      body: Column(
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
              ],
            ),
          ),
          Expanded(
            child: statisticsAsync.when(
              data: (statistics) {
                if (statistics.isEmpty) {
                  return const Center(
                    child: Text('この期間のデータはありません'),
                  );
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
                        _buildDailyStatsList(context, statistics),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('エラーが発生しました: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    int totalMinutes,
    int totalGoals,
    int days,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '統計サマリー',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildSummaryItem(context, '合計時間', '$totalMinutes 分'),
            _buildSummaryItem(context, '合計目標達成数', '$totalGoals 個'),
            _buildSummaryItem(
                context, '1日平均時間', '${(totalMinutes / days).round()} 分/日'),
            _buildSummaryItem(context, '1日平均目標達成数',
                '${(totalGoals / days).toStringAsFixed(1)} 個/日'),
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
      BuildContext context, List<Statistics> statistics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '日別の記録',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: statistics.length,
          itemBuilder: (context, index) {
            final stat = statistics[index];
            return Card(
              child: ListTile(
                title: Text(DateFormat('yyyy/MM/dd').format(stat.date)),
                subtitle:
                    Text('${stat.totalMinutes}分 / ${stat.goalCount}個の目標達成'),
                trailing: const Icon(Icons.timeline),
                onTap: () {
                  // 詳細ビューに移動する処理（必要に応じて実装）
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
