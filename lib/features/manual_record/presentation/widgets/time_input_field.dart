import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';

/// Issue #44: 時間・分入力用のカスタムフィールド
class TimeInputField extends StatelessWidget {
  final String label;
  final String unit;
  final String initialValue;
  final int maxValue;
  final Key? fieldKey;
  final ValueChanged<String>? onChanged;

  const TimeInputField({
    super.key,
    required this.label,
    required this.unit,
    required this.initialValue,
    required this.maxValue,
    this.fieldKey,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextConsts.labelMedium.copyWith(
            color: ColorConsts.textSecondary,
          ),
        ),
        const SizedBox(height: SpacingConsts.xs),
        SizedBox(
          width: 80,
          child: TextFormField(
            key: fieldKey,
            initialValue: initialValue,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 2,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _ValueRangeFormatter(maxValue),
            ],
            style: TextConsts.h4.copyWith(
              color: ColorConsts.primary,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              counterText: '', // 文字数カウンターを非表示
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: ColorConsts.shadowLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: ColorConsts.primary, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: ColorConsts.shadowLight),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: SpacingConsts.sm,
                horizontal: SpacingConsts.xs,
              ),
              hintText: '0',
              hintStyle: TextConsts.h4.copyWith(
                color: ColorConsts.textTertiary,
              ),
            ),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: SpacingConsts.xs),
        Text(
          unit,
          style: TextConsts.labelMedium.copyWith(
            color: ColorConsts.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// 値の範囲を制限するInputFormatter
class _ValueRangeFormatter extends TextInputFormatter {
  final int maxValue;

  _ValueRangeFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final value = int.tryParse(newValue.text);
    if (value == null || value > maxValue) {
      return oldValue;
    }

    return newValue;
  }
}