import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/widgets/goal_input_field.dart';
import '../../../../core/models/goals/goals_model.dart';

/// 改善された目標作成モーダル
class GoalCreateModal extends StatelessWidget {
  const GoalCreateModal({super.key});

  @override
  Widget build(BuildContext context) {
    // このクラスは直接使用されず、show()メソッドのみが使用される
    return const SizedBox.shrink();
  }

  static Future<dynamic> show(
    BuildContext context, {
    GoalsModel? existingGoal,
  }) {
    return showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: ColorConsts.cardBackground,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // ハンドル
                Container(
                  margin: const EdgeInsets.only(
                    top: SpacingConsts.m,
                    bottom: SpacingConsts.s,
                  ),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ColorConsts.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // ヘッダー
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingConsts.l,
                    vertical: SpacingConsts.m,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: ColorConsts.border, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          existingGoal != null ? '目標を編集' : '新しい目標を作成',
                          style: TextConsts.h3.copyWith(
                            color: ColorConsts.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: ColorConsts.backgroundSecondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: ColorConsts.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // コンテンツ（スクロール対応）
                Expanded(
                  child: _GoalCreateModalContent(existingGoal: existingGoal),
                ),

                // Safe Area padding
                SafeArea(
                  top: false,
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom,
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

// スクロールコントローラーを受け取る内部ウィジェット
class _GoalCreateModalContent extends StatefulWidget {
  final GoalsModel? existingGoal;

  const _GoalCreateModalContent({this.existingGoal});

  @override
  State<_GoalCreateModalContent> createState() =>
      _GoalCreateModalContentState();
}

class _GoalCreateModalContentState extends State<_GoalCreateModalContent> {
  final _formKey = GlobalKey<FormState>();

  String _title = '';
  String _description = '';
  String _avoidMessage = '';
  int _targetMinutes = 30;
  late DateTime _deadline;
  bool _isLoading = false;

  String? _titleError;
  String? _avoidMessageError;

  @override
  void initState() {
    super.initState();
    // 編集モードの場合は既存の値を設定
    if (widget.existingGoal != null) {
      _title = widget.existingGoal!.title;
      _description = widget.existingGoal!.description ?? '';
      _avoidMessage = widget.existingGoal!.avoidMessage;
      _targetMinutes = widget.existingGoal!.targetMinutes;
      _deadline = widget.existingGoal!.deadline;
    } else {
      // 新規作成の場合は30日後をデフォルトに設定
      _deadline = DateTime.now().add(const Duration(days: 30));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: SpacingConsts.l),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // 説明テキスト
            _buildDescription(),

            const SizedBox(height: SpacingConsts.l),

            // フォーム
            _buildForm(),

            const SizedBox(height: SpacingConsts.l),

            // 作成ボタン
            _buildCreateButton(),

            const SizedBox(height: SpacingConsts.l),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(SpacingConsts.l),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorConsts.primary.withOpacity(0.1),
            ColorConsts.primaryLight.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorConsts.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorConsts.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: SpacingConsts.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '目標設定のコツ',
                  style: TextConsts.body.copyWith(
                    color: ColorConsts.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: SpacingConsts.xs),
                Text(
                  '具体的で達成可能な目標を設定し、\n「やらないとどうなるか」も明確にしましょう',
                  style: TextConsts.caption.copyWith(
                    color: ColorConsts.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        // 目標タイトル
        GoalInputField(
          labelText: '目標タイトル',
          hintText: '例：英語の勉強',
          initialValue: _title,
          maxLength: 50,
          prefixIcon: Icons.flag_outlined,
          onChanged: (value) {
            setState(() {
              _title = value;
              _titleError = _validateTitle(value);
            });
          },
          validator: _validateTitle,
          textInputAction: TextInputAction.next,
        ),

        const SizedBox(height: SpacingConsts.l),

        // 目標説明
        GoalInputField(
          labelText: '目標の詳細（任意）',
          hintText: '例：TOEICで800点を取るために毎日英単語を覚える',
          initialValue: _description,
          maxLines: 3,
          maxLength: 200,
          prefixIcon: Icons.description_outlined,
          onChanged: (value) {
            setState(() {
              _description = value;
            });
          },
          textInputAction: TextInputAction.next,
        ),

        const SizedBox(height: SpacingConsts.l),

        // 目標時間設定
        _buildTargetTimeSelector(),

        const SizedBox(height: SpacingConsts.l),

        // デッドライン設定
        _buildDeadlineSelector(),

        const SizedBox(height: SpacingConsts.l),

        // ネガティブ回避メッセージ
        GoalInputField(
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
          '総目標時間',
          style: TextConsts.labelLarge.copyWith(
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
                    TimeUtils.formatDurationFromMinutes(_targetMinutes),
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
            color:
                isEditMode
                    ? ColorConsts.backgroundSecondary.withOpacity(0.5)
                    : ColorConsts.backgroundSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isEditMode
                      ? ColorConsts.border.withOpacity(0.5)
                      : ColorConsts.border,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEditMode
                        ? Icons.lock_outlined
                        : Icons.calendar_today_outlined,
                    color:
                        isEditMode
                            ? ColorConsts.textTertiary
                            : ColorConsts.primary,
                    size: 24,
                  ),
                  const SizedBox(width: SpacingConsts.s),
                  Text(
                    '${_deadline.year}年${_deadline.month}月${_deadline.day}日',
                    style: TextConsts.h3.copyWith(
                      color:
                          isEditMode
                              ? ColorConsts.textTertiary
                              : ColorConsts.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (!isEditMode) ...[
                const SizedBox(height: SpacingConsts.m),
                GestureDetector(
                  onTap: () async {
                    final DateTime tomorrow = DateTime.now().add(
                      const Duration(days: 1),
                    );
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
                      border: Border.all(
                        color: ColorConsts.primary,
                        width: 1.5,
                      ),
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
                      color: ColorConsts.border.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
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

  Widget _buildCreateButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isFormValid() && !_isLoading ? _handleSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConsts.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: SpacingConsts.m + 4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : Text(
                      widget.existingGoal != null ? '変更を保存' : '目標を作成',
                      style: TextConsts.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ),

        // 編集モード時のみ削除ボタンを表示
        if (widget.existingGoal != null) ...[
          const SizedBox(height: SpacingConsts.m),
          TextButton.icon(
            icon: Icon(Icons.delete_outline, color: ColorConsts.error),
            label: Text(
              'この目標を削除',
              style: TextConsts.body.copyWith(
                color: ColorConsts.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: _isLoading ? null : _handleDeleteGoal,
          ),
        ],
      ],
    );
  }

  // バリデーション
  String? _validateTitle(String? value) {
    if (value == null || value.isEmpty) return 'タイトルを入力してください';
    if (value.length < 2) return 'タイトルは2文字以上で入力してください';
    return null;
  }

  String? _validateAvoidMessage(String? value) {
    if (value == null || value.isEmpty) return 'ネガティブ回避メッセージを入力してください';
    if (value.length < 5) return '5文字以上で入力してください';
    return null;
  }

  bool _isFormValid() {
    return _title.isNotEmpty &&
        _avoidMessage.isNotEmpty &&
        _titleError == null &&
        _avoidMessageError == null;
  }

  Future<void> _handleSubmit() async {
    if (widget.existingGoal != null) {
      await _handleUpdateGoal();
    } else {
      await _handleCreateGoal();
    }
  }

  Future<void> _handleCreateGoal() async {
    if (!_isFormValid()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 保存機能は未実装
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pop();

        // 未実装メッセージ
        Get.snackbar(
          '未実装',
          '保存機能は開発中です',
          backgroundColor: ColorConsts.primary,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
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

  Future<void> _handleUpdateGoal() async {
    if (!_isFormValid()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 保存機能は未実装
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pop();

        // 未実装メッセージ
        Get.snackbar(
          '未実装',
          '保存機能は開発中です',
          backgroundColor: ColorConsts.primary,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
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

  Future<void> _handleDeleteGoal() async {
    // 削除確認ダイアログを表示
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('目標を削除しますか？'),
                content: Text(
                  '「${widget.existingGoal!.title}」を削除すると、'
                  '関連する学習記録も全て削除されます。\n'
                  'この操作は取り消せません。',
                ),
                actions: [
                  TextButton(
                    child: Text(
                      'キャンセル',
                      style: TextConsts.body.copyWith(
                        color: ColorConsts.textSecondary,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  TextButton(
                    child: Text(
                      '削除',
                      style: TextConsts.body.copyWith(
                        color: ColorConsts.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 削除機能は未実装
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pop('deleted');

        // 未実装メッセージ
        Get.snackbar(
          '未実装',
          '削除機能は開発中です',
          backgroundColor: ColorConsts.primary,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
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
            Container(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 時間ピッカー
                  Container(
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
                  Container(
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
