import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/widgets/common_button.dart';
import '../viewmodels/quick_record_viewmodel.dart';
import 'time_input_field.dart';

/// Issue #44: 手動学習記録ダイアログ
class QuickRecordDialog extends ConsumerWidget {
  final String goalId;
  final String goalTitle;

  const QuickRecordDialog({
    super.key,
    required this.goalId,
    required this.goalTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(quickRecordViewModelProvider({
      'goalId': goalId,
      'goalTitle': goalTitle,
    }));
    final viewModelNotifier = ref.read(quickRecordViewModelProvider({
      'goalId': goalId,
      'goalTitle': goalTitle,
    }).notifier);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(SpacingConsts.l),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // タイトル
            Row(
              children: [
                const Icon(
                  Icons.edit_note,
                  color: ColorConsts.primary,
                  size: 24,
                ),
                const SizedBox(width: SpacingConsts.sm),
                Expanded(
                  child: Text(
                    '📝 学習時間を記録',
                    style: TextConsts.h4.copyWith(
                      color: ColorConsts.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: ColorConsts.textSecondary,
                ),
              ],
            ),

            const SizedBox(height: SpacingConsts.l),

            // 目標名
            Container(
              padding: const EdgeInsets.all(SpacingConsts.m),
              decoration: BoxDecoration(
                color: ColorConsts.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.flag_outlined,
                    color: ColorConsts.primary,
                    size: 20,
                  ),
                  const SizedBox(width: SpacingConsts.sm),
                  Text(
                    '目標: ',
                    style: TextConsts.labelMedium.copyWith(
                      color: ColorConsts.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      goalTitle,
                      style: TextConsts.bodyMedium.copyWith(
                        color: ColorConsts.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: SpacingConsts.l),

            // 日付選択
            _buildDateSelector(context, viewModel, viewModelNotifier),

            const SizedBox(height: SpacingConsts.l),

            // 学習時間入力
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '学習時間:',
                  style: TextConsts.labelLarge.copyWith(
                    color: ColorConsts.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: SpacingConsts.m),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TimeInputField(
                      fieldKey: const Key('hours_input'),
                      label: '時間',
                      unit: '時間',
                      initialValue: viewModel.hours.toString(),
                      maxValue: 23,
                      onChanged: viewModelNotifier.updateHoursFromString,
                    ),
                    TimeInputField(
                      fieldKey: const Key('minutes_input'),
                      label: '分',
                      unit: '分',
                      initialValue: viewModel.minutes.toString(),
                      maxValue: 59,
                      onChanged: viewModelNotifier.updateMinutesFromString,
                    ),
                  ],
                ),
              ],
            ),

            // エラーメッセージ
            if (viewModel.errorMessage != null) ...[
              const SizedBox(height: SpacingConsts.m),
              Container(
                padding: const EdgeInsets.all(SpacingConsts.sm),
                decoration: BoxDecoration(
                  color: ColorConsts.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: ColorConsts.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: ColorConsts.error,
                      size: 16,
                    ),
                    const SizedBox(width: SpacingConsts.xs),
                    Expanded(
                      child: Text(
                        viewModel.errorMessage!,
                        style: TextConsts.bodySmall.copyWith(
                          color: ColorConsts.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: SpacingConsts.l),

            // アクションボタン
            Row(
              children: [
                Expanded(
                  child: CommonButton(
                    text: 'キャンセル',
                    variant: ButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: SpacingConsts.m),
                Expanded(
                  child: CommonButton(
                    text: '記録する',
                    variant: ButtonVariant.primary,
                    isLoading: viewModel.isLoading,
                    onPressed: () => _onSavePressed(context, viewModelNotifier),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(
    BuildContext context,
    QuickRecordState viewModel,
    QuickRecordViewModel viewModelNotifier,
  ) {
    final dateText = '${viewModel.selectedDate.year}/'
        '${viewModel.selectedDate.month.toString().padLeft(2, '0')}/'
        '${viewModel.selectedDate.day.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(SpacingConsts.m),
      decoration: BoxDecoration(
        color: ColorConsts.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            color: ColorConsts.primary,
            size: 20,
          ),
          const SizedBox(width: SpacingConsts.sm),
          Text(
            '日付: ',
            style: TextConsts.labelMedium.copyWith(
              color: ColorConsts.textSecondary,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _showDatePicker(context, viewModel, viewModelNotifier),
              child: Row(
                children: [
                  Text(
                    dateText,
                    style: TextConsts.bodyMedium.copyWith(
                      color: ColorConsts.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: SpacingConsts.xs),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: ColorConsts.primary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDatePicker(
    BuildContext context,
    QuickRecordState viewModel,
    QuickRecordViewModel viewModelNotifier,
  ) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: viewModel.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorConsts.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: ColorConsts.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      viewModelNotifier.updateDate(pickedDate);
    }
  }

  Future<void> _onSavePressed(
    BuildContext context,
    QuickRecordViewModel viewModelNotifier,
  ) async {
    final success = await viewModelNotifier.saveRecord();
    
    if (success) {
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // 成功スナックバー表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: SpacingConsts.sm),
                Text(
                  '学習時間を記録しました',
                  style: TextConsts.bodyMedium.copyWith(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: ColorConsts.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}