import 'package:flutter/material.dart';
import '../../../core/models/goals/goals_model.dart';
import '../../utils/color_consts.dart';
import '../../utils/spacing_consts.dart';
import '../../utils/text_consts.dart';
import '../custom_text_field.dart';
import 'goal_form_data.dart';
import 'time_picker_dialog.dart' as goal;

/// 目標作成・編集用の共通フォームウィジェット
/// GoalCreationScreen と GoalCreateModal で共通利用
class GoalFormWidget extends StatefulWidget {
  final GoalsModel? existingGoal;
  final Function(GoalFormData) onFormChanged;
  final bool showDeadlineField;
  final bool isDeadlineEditable;

  const GoalFormWidget({
    super.key,
    this.existingGoal,
    required this.onFormChanged,
    this.showDeadlineField = true,
    this.isDeadlineEditable = true,
  });

  @override
  State<GoalFormWidget> createState() => _GoalFormWidgetState();
}

class _GoalFormWidgetState extends State<GoalFormWidget> {
  String _title = '';
  String _description = '';
  String _avoidMessage = '';
  int _targetMinutes = 30;
  late DateTime _deadline;

  String? _titleError;
  String? _avoidMessageError;

  @override
  void initState() {
    super.initState();
    // 編集モードの場合は既存の値を設定
    if (widget.existingGoal != null) {
      _title = widget.existingGoal!.title;
      _description = widget.existingGoal!.description;
      _avoidMessage = widget.existingGoal!.avoidMessage;
      _targetMinutes = widget.existingGoal!.targetMinutes;
      _deadline = widget.existingGoal!.deadline;
    } else {
      // 新規作成の場合は30日後をデフォルトに設定
      _deadline = DateTime.now().add(const Duration(days: 30));
    }

    // 初期状態を通知
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyFormChanged();
    });
  }

  void _notifyFormChanged() {
    final isValid = _isFormValid();
    widget.onFormChanged(
      GoalFormData(
        title: _title,
        description: _description,
        avoidMessage: _avoidMessage,
        targetMinutes: _targetMinutes,
        deadline: _deadline,
        isValid: isValid,
      ),
    );
  }

  bool _isFormValid() {
    return _title.isNotEmpty &&
        _title.length >= 2 &&
        _avoidMessage.isNotEmpty &&
        _avoidMessage.length >= 5 &&
        _titleError == null &&
        _avoidMessageError == null;
  }

  String? _validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'タイトルを入力してください';
    }
    if (value.length < 2) {
      return 'タイトルは2文字以上で入力してください';
    }
    return null;
  }

  String? _validateAvoidMessage(String? value) {
    if (value == null || value.isEmpty) {
      return '回避したいことを入力してください';
    }
    if (value.length < 5) {
      return '回避したいことは5文字以上で入力してください';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 目標タイトル
        CustomTextField(
          labelText: '目標タイトル',
          hintText: '例：英語の勉強、プログラミング学習',
          initialValue: _title,
          maxLength: 50,
          prefixIcon: Icons.flag_outlined,
          onChanged: (value) {
            setState(() {
              _title = value;
              _titleError = _validateTitle(value);
              _notifyFormChanged();
            });
          },
          validator: _validateTitle,
          textInputAction: TextInputAction.next,
        ),

        const SizedBox(height: SpacingConsts.l),

        // 目標の詳細説明
        CustomTextField(
          labelText: '目標の詳細（任意）',
          hintText: '例：TOEICで800点を取るために毎日英単語を覚える',
          initialValue: _description,
          maxLength: 200,
          maxLines: 3,
          prefixIcon: Icons.description_outlined,
          onChanged: (value) {
            setState(() {
              _description = value;
              _notifyFormChanged();
            });
          },
          textInputAction: TextInputAction.next,
        ),

        const SizedBox(height: SpacingConsts.l),

        // 目標時間設定
        _buildTargetTimeSelector(),

        const SizedBox(height: SpacingConsts.l),

        // 期限設定（オプション）
        if (widget.showDeadlineField) ...[
          _buildDeadlineSelector(),
          const SizedBox(height: SpacingConsts.l),
        ],

        // やらないとどうなる？
        CustomTextField(
          labelText: 'やらないとどうなる？',
          hintText: '例：将来の仕事で困る、自分に失望する',
          initialValue: _avoidMessage,
          maxLines: 2,
          maxLength: 100,
          prefixIcon: Icons.warning_amber_outlined,
          onChanged: (value) {
            setState(() {
              _avoidMessage = value;
              _avoidMessageError = _validateAvoidMessage(value);
              _notifyFormChanged();
            });
          },
          validator: _validateAvoidMessage,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildTargetTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1日の目標時間',
          style: TextConsts.body.copyWith(
            color: ColorConsts.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingConsts.s),
        Container(
          padding: const EdgeInsets.all(SpacingConsts.l),
          decoration: BoxDecoration(
            color: ColorConsts.backgroundSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ColorConsts.border, width: 1.5),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.schedule_outlined,
                    color: ColorConsts.primary,
                    size: 24,
                  ),
                  const SizedBox(width: SpacingConsts.s),
                  Text(
                    '${_targetMinutes ~/ 60}時間${_targetMinutes % 60}分',
                    style: TextConsts.h3.copyWith(
                      color: ColorConsts.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SpacingConsts.m),
              GestureDetector(
                onTap: () async {
                  await goal.TimePickerDialog.show(
                    context: context,
                    initialMinutes: _targetMinutes,
                    onTimeSelected: (minutes) {
                      setState(() {
                        _targetMinutes = minutes;
                        _notifyFormChanged();
                      });
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingConsts.l,
                    vertical: SpacingConsts.m,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ColorConsts.primary, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: ColorConsts.primary,
                        size: 20,
                      ),
                      const SizedBox(width: SpacingConsts.s),
                      Text(
                        '時間を変更',
                        style: TextConsts.body.copyWith(
                          color: ColorConsts.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlineSelector() {
    final bool isEditMode = widget.existingGoal != null;
    final bool isEditable = widget.isDeadlineEditable && !isEditMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '目標期限',
          style: TextConsts.body.copyWith(
            color: ColorConsts.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingConsts.s),
        Container(
          padding: const EdgeInsets.all(SpacingConsts.l),
          decoration: BoxDecoration(
            color: isEditable
                ? ColorConsts.backgroundSecondary
                : ColorConsts.backgroundSecondary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEditable
                  ? ColorConsts.border
                  : ColorConsts.border.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEditable
                        ? Icons.calendar_today_outlined
                        : Icons.lock_outlined,
                    color: isEditable
                        ? ColorConsts.primary
                        : ColorConsts.textTertiary,
                    size: 24,
                  ),
                  const SizedBox(width: SpacingConsts.s),
                  Text(
                    '${_deadline.year}年${_deadline.month}月${_deadline.day}日',
                    style: TextConsts.h3.copyWith(
                      color: isEditable
                          ? ColorConsts.primary
                          : ColorConsts.textTertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (isEditable) ...[
                const SizedBox(height: SpacingConsts.m),
                GestureDetector(
                  onTap: () async {
                    final DateTime tomorrow =
                        DateTime.now().add(const Duration(days: 1));
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate:
                          _deadline.isBefore(tomorrow) ? tomorrow : _deadline,
                      firstDate: tomorrow,
                      lastDate: DateTime(2100),
                      locale: const Locale('ja', 'JP'),
                    );
                    if (picked != null) {
                      setState(() {
                        _deadline = picked;
                        _notifyFormChanged();
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingConsts.l,
                      vertical: SpacingConsts.m,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: ColorConsts.primary, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.edit_calendar,
                          color: ColorConsts.primary,
                          size: 20,
                        ),
                        const SizedBox(width: SpacingConsts.s),
                        Text(
                          '日付を変更',
                          style: TextConsts.body.copyWith(
                            color: ColorConsts.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: SpacingConsts.m),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingConsts.l,
                    vertical: SpacingConsts.m,
                  ),
                  decoration: BoxDecoration(
                    color: ColorConsts.backgroundSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ColorConsts.border.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock,
                        color: ColorConsts.textTertiary,
                        size: 20,
                      ),
                      const SizedBox(width: SpacingConsts.s),
                      Text(
                        '期限は変更できません',
                        style: TextConsts.body.copyWith(
                          color: ColorConsts.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
