import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/models/goals/goals_model.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../view_model/home_view_model.dart';

class EditGoalModal extends StatefulWidget {
  final GoalsModel goal;

  const EditGoalModal({super.key, required this.goal});

  @override
  State<EditGoalModal> createState() => _EditGoalModalState();
}

class _EditGoalModalState extends State<EditGoalModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _targetMinutesController;
  late final TextEditingController _avoidMessageController;
  late DateTime _selectedDeadline;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal.title);
    _descriptionController =
        TextEditingController(text: widget.goal.description ?? '');
    _targetMinutesController =
        TextEditingController(text: widget.goal.targetMinutes.toString());
    _avoidMessageController =
        TextEditingController(text: widget.goal.avoidMessage);
    _selectedDeadline = widget.goal.deadline;
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
      initialDate: _selectedDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

  Future<void> _updateGoal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final homeViewModel = Get.find<HomeViewModel>();
      await homeViewModel.updateGoal(
        original: widget.goal,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        targetMinutes: int.parse(_targetMinutesController.text.trim()),
        avoidMessage: _avoidMessageController.text.trim(),
        deadline: _selectedDeadline,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('目標を更新しました'),
            backgroundColor: ColorConsts.success,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('目標の更新に失敗しました'),
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
                      _buildUpdateButton(),
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
              '目標を編集',
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
          '目標名 *',
          style: TextConsts.body.copyWith(
            color: ColorConsts.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingConsts.s),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: '例: TOEIC 800点取得',
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
              return '目標名を入力してください';
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
          '説明',
          style: TextConsts.body.copyWith(
            color: ColorConsts.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingConsts.s),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: '例: 海外転職のために英語力を向上させたい',
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
          '目標時間（分） *',
          style: TextConsts.body.copyWith(
            color: ColorConsts.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingConsts.s),
        TextFormField(
          controller: _targetMinutesController,
          decoration: InputDecoration(
            hintText: '例: 1500',
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
              return '目標時間を入力してください';
            }
            final minutes = int.tryParse(value.trim());
            if (minutes == null || minutes <= 0) {
              return '正しい数値を入力してください';
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
          '期限 *',
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
                    '${_selectedDeadline.year}年${_selectedDeadline.month}月${_selectedDeadline.day}日',
                    style: TextConsts.body.copyWith(
                      color: ColorConsts.textPrimary,
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
          '達成しないとどうなりますか？ *',
          style: TextConsts.body.copyWith(
            color: ColorConsts.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingConsts.xs),
        Text(
          'ネガティブな結果を明確にすることで、モチベーションを維持しやすくなります',
          style: TextConsts.caption.copyWith(
            color: ColorConsts.textTertiary,
          ),
        ),
        const SizedBox(height: SpacingConsts.s),
        TextFormField(
          controller: _avoidMessageController,
          decoration: InputDecoration(
            hintText: '例: キャリアアップの機会を逃してしまう',
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
              return '達成しない場合の結果を入力してください';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateGoal,
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
                '更新',
                style: TextConsts.h4.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
