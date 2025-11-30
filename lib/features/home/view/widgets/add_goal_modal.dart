import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/models/goals/goals_model.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/ui_consts.dart';
import '../../../../core/utils/string_consts.dart';
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
  late final TextEditingController _targetMinutesController;
  late final TextEditingController _avoidMessageController;
  DateTime? _selectedDeadline;
  bool _isLoading = false;

  bool get _isEdit => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _titleController = TextEditingController(text: goal?.title ?? '');
    _descriptionController =
        TextEditingController(text: goal?.description ?? '');
    _targetMinutesController =
        TextEditingController(text: goal?.targetMinutes.toString() ?? '');
    _avoidMessageController =
        TextEditingController(text: goal?.avoidMessage ?? '');
    _selectedDeadline = goal?.deadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetMinutesController.dispose();
    _avoidMessageController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: UIConsts.maxDeadlineDays)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ColorConsts.primary,
              onPrimary: Colors.white,
              onSurface: ColorConsts.textPrimary,
            ),
          ),
          child: child!,
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(StringConsts.selectDeadlineMessage),
          backgroundColor: ColorConsts.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final homeViewModel = Get.find<HomeViewModel>();
      if (_isEdit) {
        await homeViewModel.updateGoal(
          original: widget.goal!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          targetMinutes: int.parse(_targetMinutesController.text.trim()),
          avoidMessage: _avoidMessageController.text.trim(),
          deadline: _selectedDeadline!,
        );
      } else {
        await homeViewModel.addGoal(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          targetMinutes: int.parse(_targetMinutesController.text.trim()),
          avoidMessage: _avoidMessageController.text.trim(),
          deadline: _selectedDeadline!,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? StringConsts.goalUpdatedMessage
                : StringConsts.goalAddedMessage),
            backgroundColor: ColorConsts.success,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? StringConsts.goalUpdateFailedMessage
                : StringConsts.goalAddFailedMessage),
            backgroundColor: ColorConsts.error,
          ),
        );
      }
    }finally {
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
      decoration: BoxDecoration(
        color: ColorConsts.cardBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: ColorConsts.shadowLight,
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _isEdit
                  ? StringConsts.editGoalTitle
                  : StringConsts.addGoalTitle,
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
        TextFormField(
          controller: _targetMinutesController,
          decoration: InputDecoration(
            hintText: StringConsts.targetMinutesPlaceholder,
            filled: true,
            fillColor: ColorConsts.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(SpacingConsts.m),
            suffixText: '分',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return StringConsts.targetMinutesRequired;
            }
            final minutes = int.tryParse(value.trim());
            if (minutes == null || minutes <= 0) {
              return StringConsts.invalidNumber;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDeadlineField() {
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
                    _selectedDeadline == null
                        ? StringConsts.selectDeadlinePlaceholder
                        : '${_selectedDeadline!.year}年${_selectedDeadline!.month}月${_selectedDeadline!.day}日',
                    style: TextConsts.body.copyWith(
                      color: _selectedDeadline == null
                          ? ColorConsts.textTertiary
                          : ColorConsts.textPrimary,
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
          style: TextConsts.caption.copyWith(
            color: ColorConsts.textTertiary,
          ),
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
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _isEdit
                    ? StringConsts.updateButton
                    : StringConsts.saveButton,
                style: TextConsts.h4.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
