import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/animation_consts.dart';
import '../viewmodels/statistics_view_model.dart';

/// Issue #49: シンプル化された統計画面
/// 期間選択式に変更、3項目のみ表示
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Issue #49: 期間選択用の状態
  DateTime _selectedStartDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now();

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

    // Issue #49: 初期化時に今日の日付で設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateDateRangeForToday();
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
                    // Issue #49: 期間表示と変更ボタン
                    _buildPeriodDisplay(),

                    const SizedBox(height: SpacingConsts.l),

                    // Issue #49: シンプル化されたメトリクス（3項目のみ）
                    _buildSimplifiedMetrics(),

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
          '📊 学習統計',
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

  // Issue #49: 期間表示と変更ボタン
  Widget _buildPeriodDisplay() {
    final isRangeSelection = !_isSameDay(_selectedStartDate, _selectedEndDate);
    final displayText = isRangeSelection 
        ? '期間: ${_formatDate(_selectedStartDate)} - ${_formatDate(_selectedEndDate)}'
        : '期間: ${_formatDate(_selectedStartDate)}';

    return Container(
      padding: const EdgeInsets.all(SpacingConsts.m),
      decoration: BoxDecoration(
        color: ColorConsts.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ColorConsts.shadowLight,
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📅 $displayText',
                style: TextConsts.bodyMedium.copyWith(
                  color: ColorConsts.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingConsts.sm),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showPeriodSelectionDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConsts.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: SpacingConsts.sm),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('期間を変更する'),
            ),
          ),
        ],
      ),
    );
  }

  // Issue #49: シンプル化されたメトリクス表示（3項目のみ）
  Widget _buildSimplifiedMetrics() {
    return Consumer(
      builder: (context, ref, child) {
        final metricsAsync = ref.watch(statisticsMetricsProvider);

        return metricsAsync.when(
          data: (metrics) => Container(
            padding: const EdgeInsets.all(SpacingConsts.m),
            decoration: BoxDecoration(
              color: ColorConsts.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: ColorConsts.shadowLight,
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📈 統計データ',
                  style: TextConsts.h4.copyWith(
                    color: ColorConsts.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: SpacingConsts.m),
                _buildSimpleMetricRow(
                  label: '総学習時間',
                  value: metrics.totalHours,
                  icon: Icons.schedule_outlined,
                ),
                const SizedBox(height: SpacingConsts.sm),
                _buildSimpleMetricRow(
                  label: '継続日数',
                  value: metrics.consecutiveDays,
                  icon: Icons.whatshot_outlined,
                ),
                const SizedBox(height: SpacingConsts.sm),
                _buildSimpleMetricRow(
                  label: '目標達成率',
                  value: metrics.achievementRate,
                  icon: Icons.trending_up_outlined,
                ),
              ],
            ),
          ),
          loading: () => _buildLoadingMetrics(),
          error: (error, stack) => _buildErrorMetrics(),
        );
      },
    );
  }

  Widget _buildSimpleMetricRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: ColorConsts.primary,
        ),
        const SizedBox(width: SpacingConsts.sm),
        Expanded(
          child: Text(
            label,
            style: TextConsts.bodyMedium.copyWith(
              color: ColorConsts.textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: TextConsts.bodyMedium.copyWith(
            color: ColorConsts.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingMetrics() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(SpacingConsts.m),
      decoration: BoxDecoration(
        color: ColorConsts.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator()),
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

  // Issue #49: ヘルパー関数
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  void _updateDateRangeForToday() {
    final today = DateTime.now();
    setState(() {
      _selectedStartDate = DateTime(today.year, today.month, today.day);
      _selectedEndDate = DateTime(today.year, today.month, today.day);
    });

    // dateRangeProviderを今日の日付で更新
    ref.read(dateRangeProvider.notifier).state = DateRange(
      startDate: _selectedStartDate,
      endDate: _selectedEndDate,
    );
  }

  void _showPeriodSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('期間を選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('今日'),
              onTap: () {
                _selectToday();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('昨日'),
              onTap: () {
                _selectYesterday();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('過去7日間'),
              onTap: () {
                _selectLast7Days();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('過去30日間'),
              onTap: () {
                _selectLast30Days();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('カスタム範囲'),
              onTap: () {
                Navigator.of(context).pop();
                _showCustomRangePicker();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  void _selectToday() {
    final today = DateTime.now();
    setState(() {
      _selectedStartDate = DateTime(today.year, today.month, today.day);
      _selectedEndDate = DateTime(today.year, today.month, today.day);
    });
    _updateDateRange();
  }

  void _selectYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    setState(() {
      _selectedStartDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
      _selectedEndDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
    });
    _updateDateRange();
  }

  void _selectLast7Days() {
    final today = DateTime.now();
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    setState(() {
      _selectedStartDate = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);
      _selectedEndDate = DateTime(today.year, today.month, today.day);
    });
    _updateDateRange();
  }

  void _selectLast30Days() {
    final today = DateTime.now();
    final thirtyDaysAgo = today.subtract(const Duration(days: 30));
    setState(() {
      _selectedStartDate = DateTime(thirtyDaysAgo.year, thirtyDaysAgo.month, thirtyDaysAgo.day);
      _selectedEndDate = DateTime(today.year, today.month, today.day);
    });
    _updateDateRange();
  }

  void _showCustomRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _selectedStartDate,
        end: _selectedEndDate,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
      _updateDateRange();
    }
  }

  void _updateDateRange() {
    ref.read(dateRangeProvider.notifier).state = DateRange(
      startDate: _selectedStartDate,
      endDate: _selectedEndDate,
    );
  }
}