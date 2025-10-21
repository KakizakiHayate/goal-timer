import 'package:flutter/material.dart';
import '../../utils/color_consts.dart';
import '../../utils/spacing_consts.dart';
import '../../utils/text_consts.dart';

/// 目標時間選択ダイアログ
/// 時間と分を選択できるホイールピッカー
class TimePickerDialog extends StatefulWidget {
  final int initialMinutes;
  final Function(int) onTimeSelected;

  const TimePickerDialog({
    super.key,
    required this.initialMinutes,
    required this.onTimeSelected,
  });

  /// ダイアログを表示
  static Future<void> show({
    required BuildContext context,
    required int initialMinutes,
    required Function(int) onTimeSelected,
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return TimePickerDialog(
          initialMinutes: initialMinutes,
          onTimeSelected: onTimeSelected,
        );
      },
    );
  }

  @override
  State<TimePickerDialog> createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<TimePickerDialog> {
  late int _selectedHours;
  late int _selectedMinutes;
  late FixedExtentScrollController _hoursController;
  late FixedExtentScrollController _minutesController;

  @override
  void initState() {
    super.initState();
    _selectedHours = widget.initialMinutes ~/ 60;
    _selectedMinutes = widget.initialMinutes % 60;
    _hoursController = FixedExtentScrollController(initialItem: _selectedHours);
    _minutesController = FixedExtentScrollController(
      initialItem: _selectedMinutes,
    );
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(SpacingConsts.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '目標時間を設定',
              style: TextConsts.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: SpacingConsts.l),
            SizedBox(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 時間ピッカー
                  SizedBox(
                    width: 80,
                    child: ListWheelScrollView.useDelegate(
                      controller: _hoursController,
                      itemExtent: 40,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedHours = index;
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 24,
                        builder: (context, index) {
                          return Center(
                            child: Text(
                              '$index',
                              style: TextConsts.h3.copyWith(
                                color:
                                    _selectedHours == index
                                        ? ColorConsts.primary
                                        : ColorConsts.textTertiary,
                                fontWeight:
                                    _selectedHours == index
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Text(
                    '時間',
                    style: TextConsts.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: SpacingConsts.l),
                  // 分ピッカー
                  SizedBox(
                    width: 80,
                    child: ListWheelScrollView.useDelegate(
                      controller: _minutesController,
                      itemExtent: 40,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedMinutes = index;
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 60,
                        builder: (context, index) {
                          return Center(
                            child: Text(
                              '$index',
                              style: TextConsts.h3.copyWith(
                                color:
                                    _selectedMinutes == index
                                        ? ColorConsts.primary
                                        : ColorConsts.textTertiary,
                                fontWeight:
                                    _selectedMinutes == index
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Text(
                    '分',
                    style: TextConsts.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SpacingConsts.l),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'キャンセル',
                      style: TextConsts.body.copyWith(
                        color: ColorConsts.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: SpacingConsts.m),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final totalMinutes =
                          _selectedHours * 60 + _selectedMinutes;
                      if (totalMinutes > 0) {
                        widget.onTimeSelected(totalMinutes);
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConsts.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: SpacingConsts.m,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '決定',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
