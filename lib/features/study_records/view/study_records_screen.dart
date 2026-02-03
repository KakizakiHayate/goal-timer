import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/color_consts.dart';
import '../../../core/utils/spacing_consts.dart';
import '../../../core/utils/text_consts.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/study_records_view_model.dart';
import 'widgets/daily_record_bottom_sheet.dart';
import 'widgets/monthly_calendar.dart';

/// 学習記録画面
class StudyRecordsScreen extends StatefulWidget {
  const StudyRecordsScreen({super.key});

  @override
  State<StudyRecordsScreen> createState() => _StudyRecordsScreenState();
}

class _StudyRecordsScreenState extends State<StudyRecordsScreen> {
  @override
  void initState() {
    super.initState();
    Get.put(StudyRecordsViewModel());
  }

  @override
  void dispose() {
    Get.delete<StudyRecordsViewModel>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: ColorConsts.backgroundPrimary,
      appBar: AppBar(
        title: Text(l10n?.studyRecordsTitle ?? 'Study Records'),
        backgroundColor: ColorConsts.cardBackground,
        foregroundColor: ColorConsts.textPrimary,
        elevation: 0,
      ),
      body: GetBuilder<StudyRecordsViewModel>(
        builder: (viewModel) {
          final state = viewModel.state;

          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: SpacingConsts.m),
                _buildMonthNavigation(l10n, viewModel, state),
                const SizedBox(height: SpacingConsts.m),
                _buildCalendarCard(viewModel, state),
                const SizedBox(height: SpacingConsts.l),
                _buildStreakInfo(l10n, state),
                const SizedBox(height: SpacingConsts.l),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 月ナビゲーション
  Widget _buildMonthNavigation(
    AppLocalizations? l10n,
    StudyRecordsViewModel viewModel,
    StudyRecordsState state,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingConsts.l),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed:
                state.canGoPrevious
                    ? () => viewModel.goToPreviousMonth()
                    : null,
            icon: Icon(
              Icons.chevron_left,
              color:
                  state.canGoPrevious
                      ? ColorConsts.textPrimary
                      : ColorConsts.disabled,
            ),
          ),
          Text(
            _formatMonth(l10n, state.currentMonth),
            style: TextConsts.h3.copyWith(fontWeight: FontWeight.w600),
          ),
          IconButton(
            onPressed: state.canGoNext ? () => viewModel.goToNextMonth() : null,
            icon: Icon(
              Icons.chevron_right,
              color:
                  state.canGoNext
                      ? ColorConsts.textPrimary
                      : ColorConsts.disabled,
            ),
          ),
        ],
      ),
    );
  }

  /// カレンダーカード
  Widget _buildCalendarCard(
    StudyRecordsViewModel viewModel,
    StudyRecordsState state,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SpacingConsts.l),
      padding: const EdgeInsets.all(SpacingConsts.m),
      decoration: BoxDecoration(
        color: ColorConsts.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: MonthlyCalendar(
        currentMonth: state.currentMonth,
        studyDates: state.studyDates,
        onDateTap: (date) => _showDailyRecords(viewModel, date),
      ),
    );
  }

  /// ストリーク情報
  Widget _buildStreakInfo(AppLocalizations? l10n, StudyRecordsState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SpacingConsts.l),
      padding: const EdgeInsets.all(SpacingConsts.m),
      decoration: BoxDecoration(
        color: ColorConsts.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStreakItem(
              title: l10n?.currentStreakLabel ?? 'Current Streak',
              value: l10n?.daysSuffix(state.currentStreak) ?? '${state.currentStreak} days',
              icon: '🔥',
            ),
          ),
          Container(width: 1, height: 48, color: ColorConsts.disabled),
          Expanded(
            child: _buildStreakItem(
              title: l10n?.longestStreakLabel ?? 'Longest Streak',
              value: l10n?.daysSuffix(state.longestStreak) ?? '${state.longestStreak} days',
              icon: '🏆',
            ),
          ),
        ],
      ),
    );
  }

  /// ストリーク情報アイテム
  Widget _buildStreakItem({
    required String title,
    required String value,
    required String icon,
  }) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: SpacingConsts.xs),
        Text(
          value,
          style: TextConsts.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: ColorConsts.textPrimary,
          ),
        ),
        const SizedBox(height: SpacingConsts.xxs),
        Text(
          title,
          style: TextConsts.bodySmall.copyWith(
            color: ColorConsts.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 月をフォーマット
  String _formatMonth(AppLocalizations? l10n, DateTime date) {
    return l10n?.monthFormat(date.year, date.month) ?? '${date.year}/${date.month}';
  }

  /// 日別学習記録を表示
  Future<void> _showDailyRecords(
    StudyRecordsViewModel viewModel,
    DateTime date,
  ) async {
    final records = await viewModel.fetchDailyRecords(date);
    if (records.isEmpty) return;

    if (!mounted) return;

    await DailyRecordBottomSheet.show(
      context: context,
      date: date,
      records: records,
    );
  }
}
