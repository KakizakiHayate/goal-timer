import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/goals/goals_model.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/string_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/utils/ui_consts.dart';
import '../../view_model/home_view_model.dart';

class AddGoalModal extends StatefulWidget {
  final GoalsModel? goal;

  const AddGoalModal({super.key, this.goal});

  @override
  State<AddGoalModal> createState() => _AddGoalModalState();
}

class _AddGoalModalState extends State<AddGoalModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _avoidMessageController;
  late int _targetMinutes;
  DateTime? _selectedDeadline;
  bool _isLoading = false;

  bool get _isEdit => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _titleController = TextEditingController(text: goal?.title ?? '');
    _descriptionController = TextEditingController(
      text: goal?.description ?? '',
    );
    _targetMinutes = goal?.targetMinutes ?? 30;
    _avoidMessageController = TextEditingController(
      text: goal?.avoidMessage ?? '',
    );
    _selectedDeadline = goal?.deadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _avoidMessageController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: UIConsts.maxDeadlineDays),
      ),
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ColorConsts.primary,
              onPrimary: Colors.white,
              onSurface: ColorConsts.textPrimary,
            ),
          ),
          child: child,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  Future<void> _saveGoal() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final selectedDeadline = _selectedDeadline;
    if (selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(StringConsts.selectDeadlineMessage),
          backgroundColor: ColorConsts.error,
        ),
      );
      return;
    }

    // async gapの前にcontext関連の参照をキャプチャ
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      final homeViewModel = Get.find<HomeViewModel>();
      final goal = widget.goal;
      if (_isEdit && goal != null) {
        await homeViewModel.updateGoal(
          original: goal,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          targetMinutes: _targetMinutes,
          avoidMessage: _avoidMessageController.text.trim(),
          deadline: selectedDeadline,
        );
      } else {
        await homeViewModel.addGoal(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          targetMinutes: _targetMinutes,
          avoidMessage: _avoidMessageController.text.trim(),
          deadline: selectedDeadline,
        );
      }

      if (mounted) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? StringConsts.goalUpdatedMessage
                  : StringConsts.goalAddedMessage,
            ),
            backgroundColor: ColorConsts.success,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? StringConsts.goalUpdateFailedMessage
                  : StringConsts.goalAddFailedMessage,
            ),
            backgroundColor: ColorConsts.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(SpacingConsts.l),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleField(),
                      const SizedBox(height: SpacingConsts.l),
                      _buildDescriptionField(),
                      const SizedBox(height: SpacingConsts.l),
                      _buildTargetMinutesField(),
                      const SizedBox(height: SpacingConsts.l),
                      _buildDeadlineField(),
                      const SizedBox(height: SpacingConsts.l),
                      _buildAvoidMessageField(),
                      const SizedBox(height: SpacingConsts.xl),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(SpacingConsts.l),
      decoration: const BoxDecoration(
        color: ColorConsts.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: ColorConsts.shadowLight,
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _isEdit ? StringConsts.editGoalTitle : StringConsts.addGoalTitle,
              style: TextConsts.h3.copyWith(
                color: ColorConsts.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            color: ColorConsts.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          StringConsts.goalNameLabel,
          style: TextConsts.body.copyWith(
            color: ColorConsts.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingConsts.s),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: StringConsts.goalNamePlaceholder,
            filled: true,
            fillColor: ColorConsts.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(SpacingConsts.m),
          ),
          maxLength: 50,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return StringConsts.goalNameRequired;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          StringConsts.descriptionLabel,
          style: TextConsts.body.copyWith(
            color: ColorConsts.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingConsts.s),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: StringConsts.descriptionPlaceholder,
            filled: true,
            fillColor: ColorConsts.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(SpacingConsts.m),
          ),
          maxLines: 3,
          maxLength: 200,
        ),
      ],
    );
  }

  Widget _buildTargetMinutesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          StringConsts.targetMinutesLabel,
          style: TextConsts.body.copyWith(
            color: ColorConsts.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingConsts.s),
        GestureDetector(
          onTap: () async {
            await showDialog(
              context: context,
              builder: (BuildContext context) {
                return _TimePickerDialog(
                  initialMinutes: _targetMinutes,
                  onTimeSelected: (minutes) {
                    setState(() {
                      _targetMinutes = minutes;
                    });
                  },
                );
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.all(SpacingConsts.m),
            decoration: BoxDecoration(
              color: ColorConsts.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  color: ColorConsts.primary,
                  size: 20,
                ),
                const SizedBox(width: SpacingConsts.m),
                Expanded(
                  child: Text(
                    TimeUtils.formatDurationFromMinutes(_targetMinutes),
                    style: TextConsts.body.copyWith(
                      color: ColorConsts.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: ColorConsts.textTertiary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlineField() {
    final selectedDeadline = _selectedDeadline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          StringConsts.deadlineLabel,
          style: TextConsts.body.copyWith(
            color: ColorConsts.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingConsts.s),
        InkWell(
          onTap: _selectDeadline,
          child: Container(
            padding: const EdgeInsets.all(SpacingConsts.m),
            decoration: BoxDecoration(
              color: ColorConsts.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: ColorConsts.primary,
                  size: 20,
                ),
                const SizedBox(width: SpacingConsts.m),
                Expanded(
                  child: Text(
                    selectedDeadline != null
                        ? DateFormat('yyyy年M月d日').format(selectedDeadline)
                        : StringConsts.selectDeadlinePlaceholder,
                    style: TextConsts.body.copyWith(
                      color:
                          selectedDeadline != null
                              ? ColorConsts.textPrimary
                              : ColorConsts.textTertiary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: ColorConsts.textTertiary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        // 総目標時間の表示（期限が選択されている場合のみ）
        if (selectedDeadline != null) ...[
          const SizedBox(height: SpacingConsts.s),
          _buildTotalTargetTimeText(selectedDeadline),
        ],
      ],
    );
  }

  Widget _buildTotalTargetTimeText(DateTime deadline) {
    final remainingDays = TimeUtils.calculateRemainingDays(deadline);
    final totalTargetMinutes = TimeUtils.calculateTotalTargetMinutes(
      targetMinutes: _targetMinutes,
      remainingDays: remainingDays,
    );

    return Text(
      '残り$remainingDays日 → 総目標時間: ${TimeUtils.formatMinutesToHoursAndMinutes(totalTargetMinutes)}',
      style: TextConsts.bodySmall.copyWith(
        color: ColorConsts.textSecondary,
      ),
    );
  }

  Widget _buildAvoidMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          StringConsts.avoidMessageLabel,
          style: TextConsts.body.copyWith(
            color: ColorConsts.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingConsts.xs),
        Text(
          StringConsts.avoidMessageHint,
          style: TextConsts.caption.copyWith(color: ColorConsts.textTertiary),
        ),
        const SizedBox(height: SpacingConsts.s),
        TextFormField(
          controller: _avoidMessageController,
          decoration: InputDecoration(
            hintText: StringConsts.avoidMessagePlaceholder,
            filled: true,
            fillColor: ColorConsts.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(SpacingConsts.m),
          ),
          maxLines: 3,
          maxLength: 200,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return StringConsts.avoidMessageRequired;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveGoal,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConsts.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: SpacingConsts.m),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child:
            _isLoading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Text(
                  _isEdit ? StringConsts.updateButton : StringConsts.saveButton,
                  style: TextConsts.h4.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }
}

// タイムピッカーダイアログ
class _TimePickerDialog extends StatefulWidget {
  final int initialMinutes;
  final Function(int) onTimeSelected;

  const _TimePickerDialog({
    required this.initialMinutes,
    required this.onTimeSelected,
  });

  @override
  State<_TimePickerDialog> createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<_TimePickerDialog> {
  late int _selectedHours;
  late int _selectedMinutes;
  late FixedExtentScrollController _hoursController;
  late FixedExtentScrollController _minutesController;

  @override
  void initState() {
    super.initState();
    _selectedHours = widget.initialMinutes ~/ TimeUtils.minutesPerHour;
    _selectedMinutes = widget.initialMinutes % TimeUtils.minutesPerHour;
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
                          _selectedHours * TimeUtils.minutesPerHour +
                          _selectedMinutes;
                      if (totalMinutes > TimeUtils.minValidMinutes) {
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
