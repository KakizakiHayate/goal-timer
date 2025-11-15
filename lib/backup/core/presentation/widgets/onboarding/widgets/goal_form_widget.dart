import 'package:flutter/material.dart';
import '../../../../utils/color_consts.dart';
import '../../../../utils/spacing_consts.dart';
import '../../../../utils/text_consts.dart';
import '../../../../widgets/custom_text_field.dart';

/// 目標作成フォームウィジェット
class GoalFormWidget extends StatefulWidget {
  const GoalFormWidget({
    super.key,
    required this.onFormChanged,
    this.initialGoalName = '',
    this.initialReason = '',
    this.initialConsequence = '',
  });

  final Function(
    String goalName,
    String reason,
    String consequence,
    bool isValid,
  )
  onFormChanged;
  final String initialGoalName;
  final String initialReason;
  final String initialConsequence;

  @override
  State<GoalFormWidget> createState() => _GoalFormWidgetState();
}

class _GoalFormWidgetState extends State<GoalFormWidget> {
  late final TextEditingController _goalNameController;
  late final TextEditingController _reasonController;
  late final TextEditingController _consequenceController;

  static const int _maxGoalNameLength = 30;
  static const int _maxReasonLength = 100;
  static const int _maxConsequenceLength = 100;

  @override
  void initState() {
    super.initState();
    _goalNameController = TextEditingController(text: widget.initialGoalName);
    _reasonController = TextEditingController(text: widget.initialReason);
    _consequenceController = TextEditingController(
      text: widget.initialConsequence,
    );

    // 初期状態での検証
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateAndNotify();
    });
  }

  @override
  void dispose() {
    _goalNameController.dispose();
    _reasonController.dispose();
    _consequenceController.dispose();
    super.dispose();
  }

  void _validateAndNotify() {
    final goalName = _goalNameController.text.trim();
    final reason = _reasonController.text.trim();
    final consequence = _consequenceController.text.trim();

    final isValid =
        goalName.isNotEmpty &&
        reason.isNotEmpty &&
        consequence.isNotEmpty &&
        goalName.length <= _maxGoalNameLength &&
        reason.length <= _maxReasonLength &&
        consequence.length <= _maxConsequenceLength;

    widget.onFormChanged(goalName, reason, consequence, isValid);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(SpacingConsts.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 目標名入力
          _buildSectionTitle('目標名', isRequired: true),
          const SizedBox(height: SpacingConsts.sm),
          CustomTextField(
            key: const Key('goal_name_field'),
            labelText: '目標名',
            hintText: '例: TOEIC 800点取得',
            initialValue: _goalNameController.text,
            maxLength: _maxGoalNameLength,
            onChanged: (value) {
              _goalNameController.text = value;
              _validateAndNotify();
            },
          ),

          const SizedBox(height: SpacingConsts.lg),

          // 理由入力
          _buildSectionTitle('なぜこの目標を達成したいですか？', isRequired: true),
          const SizedBox(height: SpacingConsts.sm),
          CustomTextField(
            key: const Key('goal_reason_field'),
            labelText: '理由',
            hintText: '例: 海外転職のために英語力を向上させたい',
            initialValue: _reasonController.text,
            maxLines: 3,
            maxLength: _maxReasonLength,
            onChanged: (value) {
              _reasonController.text = value;
              _validateAndNotify();
            },
          ),

          const SizedBox(height: SpacingConsts.lg),

          // 達成しない場合の結果
          _buildSectionTitle('達成しないとどうなりますか？', isRequired: true),
          const SizedBox(height: SpacingConsts.sm),
          Text(
            'ネガティブな結果を明確にすることで、モチベーションを維持しやすくなります',
            style: TextConsts.bodySmall.copyWith(
              color: ColorConsts.textTertiary,
            ),
          ),
          const SizedBox(height: SpacingConsts.sm),
          CustomTextField(
            key: const Key('goal_consequence_field'),
            labelText: '達成しない場合の結果',
            hintText: '例: キャリアアップの機会を逃してしまう',
            initialValue: _consequenceController.text,
            maxLines: 3,
            maxLength: _maxConsequenceLength,
            onChanged: (value) {
              _consequenceController.text = value;
              _validateAndNotify();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          title,
          style: TextConsts.labelLarge.copyWith(
            color: ColorConsts.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: SpacingConsts.xs),
          Text(
            '*',
            style: TextConsts.labelLarge.copyWith(
              color: ColorConsts.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
