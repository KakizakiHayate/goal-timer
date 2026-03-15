import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/models/goals/goals_model.dart';
import '../../../core/utils/calendar_utils.dart';
import '../../../core/utils/color_consts.dart';
import '../../../core/utils/spacing_consts.dart';
import '../../../core/utils/text_consts.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/utils/ui_consts.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/manual_entry_view_model.dart';

/// 手動学習時間入力モーダルを表示する
Future<bool?> showManualEntryModal(
  BuildContext context, {
  required List<GoalsModel> goals,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ManualEntryModal(goals: goals),
  );
}

/// 手動学習時間入力モーダル
class ManualEntryModal extends StatefulWidget {
  final List<GoalsModel> goals;

  const ManualEntryModal({super.key, required this.goals});

  @override
  State<ManualEntryModal> createState() => _ManualEntryModalState();
}

class _ManualEntryModalState extends State<ManualEntryModal> {
  DateTime _displayMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    Get.put(ManualEntryViewModel());
  }

  @override
  void dispose() {
    Get.delete<ManualEntryViewModel>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight =
        (screenHeight - keyboardHeight) * UIConsts.modalHeightFactor;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: ColorConsts.backgroundPrimary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              Flexible(
                child: GetBuilder<ManualEntryViewModel>(
                  builder: (viewModel) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingConsts.l,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGoalSelector(context, viewModel),
                          const SizedBox(height: SpacingConsts.l),
                          _buildTimePicker(context, viewModel),
                          const SizedBox(height: SpacingConsts.l),
                          _buildDateSelector(context, viewModel),
                          const SizedBox(height: SpacingConsts.l),
                          _buildSaveButton(context, viewModel),
                          const SizedBox(height: SpacingConsts.l),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ヘッダー（タイトル + 閉じるボタン）
  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(SpacingConsts.m),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40),
          Text(
            l10n?.manualEntryTitle ?? '手動で記録',
            style: TextConsts.h4.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: ColorConsts.textSecondary),
          ),
        ],
      ),
    );
  }

  /// 目標選択セクション
  Widget _buildGoalSelector(
    BuildContext context,
    ManualEntryViewModel viewModel,
  ) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.manualEntrySelectGoal ?? '目標を選択',
          style: TextConsts.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: ColorConsts.textPrimary,
          ),
        ),
        const SizedBox(height: SpacingConsts.s),
        ...widget.goals.map((goal) {
          final isSelected = viewModel.selectedGoal?.id == goal.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: SpacingConsts.s),
            child: GestureDetector(
              onTap: () => viewModel.selectGoal(goal),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(SpacingConsts.m),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ColorConsts.primary.withValues(alpha: 0.1)
                      : ColorConsts.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isSelected ? ColorConsts.primary : ColorConsts.disabled,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? ColorConsts.primary
                          : ColorConsts.textTertiary,
                      size: 20,
                    ),
                    const SizedBox(width: SpacingConsts.s),
                    Expanded(
                      child: Text(
                        goal.title,
                        style: TextConsts.bodyMedium.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? ColorConsts.primary
                              : ColorConsts.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// 学習時間ピッカーセクション
  Widget _buildTimePicker(
    BuildContext context,
    ManualEntryViewModel viewModel,
  ) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.manualEntryStudyTime ?? '学習時間',
          style: TextConsts.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: ColorConsts.textPrimary,
          ),
        ),
        const SizedBox(height: SpacingConsts.s),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: ColorConsts.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorConsts.disabled),
          ),
          child: CupertinoTimerPicker(
            mode: CupertinoTimerPickerMode.hm,
            initialTimerDuration: viewModel.selectedDuration,
            onTimerDurationChanged: (duration) {
              viewModel.setDuration(duration);
            },
          ),
        ),
      ],
    );
  }

  /// 日付選択セクション（MonthlyCalendar風のカスタム実装）
  Widget _buildDateSelector(
    BuildContext context,
    ManualEntryViewModel viewModel,
  ) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.manualEntryStudyDate ?? '学習日',
          style: TextConsts.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: ColorConsts.textPrimary,
          ),
        ),
        const SizedBox(height: SpacingConsts.s),
        Container(
          padding: const EdgeInsets.all(SpacingConsts.m),
          decoration: BoxDecoration(
            color: ColorConsts.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorConsts.disabled),
          ),
          child: Column(
            children: [
              _buildMonthNavigation(),
              const SizedBox(height: SpacingConsts.s),
              _buildWeekdayHeader(),
              const SizedBox(height: SpacingConsts.xs),
              _buildCalendarGrid(viewModel),
            ],
          ),
        ),
      ],
    );
  }

  /// 月ナビゲーション（前月・次月ボタン）
  Widget _buildMonthNavigation() {
    final now = DateTime.now();
    final isCurrentMonth = _displayMonth.year == now.year &&
        _displayMonth.month == now.month;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _displayMonth = DateTime(
                _displayMonth.year,
                _displayMonth.month - 1,
              );
            });
          },
          icon: const Icon(Icons.chevron_left, color: ColorConsts.textSecondary),
        ),
        Text(
          CalendarUtils.formatYearMonth(
            _displayMonth,
            Localizations.localeOf(context).toString(),
          ),
          style: TextConsts.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        IconButton(
          onPressed: isCurrentMonth
              ? null
              : () {
                  setState(() {
                    _displayMonth = DateTime(
                      _displayMonth.year,
                      _displayMonth.month + 1,
                    );
                  });
                },
          icon: Icon(
            Icons.chevron_right,
            color: isCurrentMonth
                ? ColorConsts.disabled
                : ColorConsts.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 曜日ヘッダー（ロケール対応）
  Widget _buildWeekdayHeader() {
    final locale = Localizations.localeOf(context).toString();
    final weekdays = CalendarUtils.getOrderedWeekdays(locale);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays
          .map(
            (day) => SizedBox(
              width: 40,
              child: Center(
                child: Text(
                  day,
                  style: TextConsts.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: ColorConsts.textSecondary,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  /// カレンダーグリッド
  Widget _buildCalendarGrid(ManualEntryViewModel viewModel) {
    final locale = Localizations.localeOf(context).toString();
    final days = CalendarUtils.generateCalendarDays(
      month: _displayMonth,
      locale: locale,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        if (day == null) return const SizedBox.shrink();

        final isToday = day.year == today.year &&
            day.month == today.month &&
            day.day == today.day;
        final isFuture = day.isAfter(today);
        final isSelected = day.year == viewModel.selectedDate.year &&
            day.month == viewModel.selectedDate.month &&
            day.day == viewModel.selectedDate.day;

        return GestureDetector(
          onTap: isFuture
              ? null
              : () {
                  viewModel.setDate(day);
                  setState(() {});
                },
          child: Container(
            decoration: _getDayCellDecoration(
              isToday: isToday,
              isFuture: isFuture,
              isSelected: isSelected,
            ),
            child: Center(
              child: Text(
                '${day.day}',
                style: TextConsts.bodyMedium.copyWith(
                  color: _getDayTextColor(
                    isToday: isToday,
                    isFuture: isFuture,
                    isSelected: isSelected,
                  ),
                  fontWeight:
                      (isToday || isSelected) ? FontWeight.w600 : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _getDayCellDecoration({
    required bool isToday,
    required bool isFuture,
    required bool isSelected,
  }) {
    if (isSelected) {
      return BoxDecoration(
        color: ColorConsts.primary,
        borderRadius: BorderRadius.circular(8),
      );
    }
    if (isToday) {
      return BoxDecoration(
        border: Border.all(color: ColorConsts.primary, width: 2),
        borderRadius: BorderRadius.circular(8),
      );
    }
    if (isFuture) {
      return const BoxDecoration();
    }
    return const BoxDecoration();
  }

  Color _getDayTextColor({
    required bool isToday,
    required bool isFuture,
    required bool isSelected,
  }) {
    if (isSelected) return Colors.white;
    if (isFuture) return ColorConsts.textTertiary;
    if (isToday) return ColorConsts.primary;
    return ColorConsts.textPrimary;
  }

  /// 保存ボタン
  Widget _buildSaveButton(
    BuildContext context,
    ManualEntryViewModel viewModel,
  ) {
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: viewModel.canSave ? () => _onSave(context, viewModel) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConsts.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ColorConsts.disabled,
          padding: const EdgeInsets.symmetric(vertical: SpacingConsts.m),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: viewModel.isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                l10n?.commonBtnSave ?? '保存',
                style: TextConsts.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  /// 保存処理
  Future<void> _onSave(
    BuildContext context,
    ManualEntryViewModel viewModel,
  ) async {
    final l10n = AppLocalizations.of(context);
    final result = await viewModel.save();

    if (!context.mounted) return;

    if (result) {
      // バイブレーション
      HapticFeedback.mediumImpact();

      // 達成演出表示
      await _showCongratsDialog(context, viewModel);

      if (!context.mounted) return;
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.manualEntrySaveFailed ?? '保存に失敗しました'),
          backgroundColor: ColorConsts.error,
        ),
      );
    }
  }

  /// 達成演出ダイアログ
  Future<void> _showCongratsDialog(
    BuildContext context,
    ManualEntryViewModel viewModel,
  ) async {
    final l10n = AppLocalizations.of(context);
    final duration = viewModel.selectedDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % TimeUtils.minutesPerHour;

    String timeText;
    if (l10n != null) {
      timeText = l10n.timeFormatHoursMinutes(hours, minutes);
    } else {
      timeText = TimeUtils.formatMinutesToHoursAndMinutes(duration.inMinutes);
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        // 自動で閉じるタイマー
        Future.delayed(const Duration(seconds: 2), () {
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
        });

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(SpacingConsts.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.celebration,
                  size: 64,
                  color: ColorConsts.warning,
                ),
                const SizedBox(height: SpacingConsts.m),
                Text(
                  l10n?.manualEntryCongratsTitle ?? 'お疲れ様でした！',
                  style: TextConsts.h3.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: SpacingConsts.s),
                Text(
                  l10n?.manualEntryCongratsMessage(timeText) ??
                      '$timeTextの学習を記録しました',
                  style: TextConsts.bodyMedium.copyWith(
                    color: ColorConsts.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
