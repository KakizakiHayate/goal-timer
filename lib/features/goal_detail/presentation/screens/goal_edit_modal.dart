import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/modal_bottom_sheet.dart';
import '../../../../features/auth/presentation/widgets/auth_button.dart';
import '../../../../core/models/goals/goals_model.dart';
import '../../../../core/provider/providers.dart';

/// 改善された目標編集モーダル
class GoalEditModal extends ConsumerStatefulWidget {
  final GoalsModel goal;

  const GoalEditModal({
    super.key,
    required this.goal,
  });

  @override
  ConsumerState<GoalEditModal> createState() => _GoalEditModalState();

  static Future<GoalsModel?> show(BuildContext context, GoalsModel goal) {
    return ModalBottomSheet.show<GoalsModel>(
      context: context,
      title: '目標を編集',
      height: MediaQuery.of(context).size.height * 0.85,
      child: GoalEditModal(goal: goal),
    );
  }
}

class _GoalEditModalState extends ConsumerState<GoalEditModal> {
  final _formKey = GlobalKey<FormState>();
  
  late String _title;
  late String _description;
  late String _avoidMessage;
  late int _totalTargetHours;
  bool _isLoading = false;

  String? _titleError;
  String? _avoidMessageError;

  @override
  void initState() {
    super.initState();
    _title = widget.goal.title;
    _description = widget.goal.description;
    _avoidMessage = widget.goal.avoidMessage;
    _totalTargetHours = widget.goal.totalTargetHours;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // 目標状態表示
          _buildGoalStatus(),
          
          const SizedBox(height: SpacingConsts.l),
          
          // フォーム
          _buildForm(),
          
          const SizedBox(height: SpacingConsts.l),
          
          // アクションボタン
          _buildActionButtons(),
          
          const SizedBox(height: SpacingConsts.l),
        ],
      ),
    );
  }

  Widget _buildGoalStatus() {
    return Container(
      padding: const EdgeInsets.all(SpacingConsts.l),
      decoration: BoxDecoration(
        color: (!widget.goal.isCompleted) 
            ? ColorConsts.success.withOpacity(0.1)
            : ColorConsts.textTertiary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (!widget.goal.isCompleted) 
              ? ColorConsts.success.withOpacity(0.3)
              : ColorConsts.textTertiary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (!widget.goal.isCompleted) ? ColorConsts.success : ColorConsts.textTertiary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              (!widget.goal.isCompleted) ? Icons.check_circle : Icons.pause_circle,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: SpacingConsts.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (!widget.goal.isCompleted) ? 'アクティブな目標' : '一時停止中',
                  style: TextConsts.body.copyWith(
                    color: (!widget.goal.isCompleted) ? ColorConsts.success : ColorConsts.textTertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: SpacingConsts.xs),
                Text(
                  (!widget.goal.isCompleted) 
                      ? 'この目標は現在進行中です'
                      : 'この目標は一時停止されています',
                  style: TextConsts.caption.copyWith(
                    color: ColorConsts.textSecondary,
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
        CustomTextField(
          labelText: '目標タイトル',
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
        CustomTextField(
          labelText: '目標の詳細（任意）',
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
        
        // ネガティブ回避メッセージ
        CustomTextField(
          labelText: 'やらないとどうなる？',
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
            border: Border.all(
              color: ColorConsts.border,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    color: ColorConsts.primary,
                    size: 24,
                  ),
                  const SizedBox(width: SpacingConsts.s),
                  Text(
                    '${_totalTargetHours * 60}分',
                    style: TextConsts.h3.copyWith(
                      color: ColorConsts.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SpacingConsts.m),
              Slider(
                value: (_totalTargetHours * 60).toDouble(),
                min: 15,
                max: 180,
                divisions: 11,
                activeColor: ColorConsts.primary,
                inactiveColor: ColorConsts.border,
                onChanged: (value) {
                  setState(() {
                    _totalTargetHours = (value / 60).round();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '15分',
                    style: TextConsts.caption.copyWith(
                      color: ColorConsts.textTertiary,
                    ),
                  ),
                  Text(
                    '3時間',
                    style: TextConsts.caption.copyWith(
                      color: ColorConsts.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // 保存ボタン
        AuthButton(
          type: AuthButtonType.email,
          text: '変更を保存',
          isLoading: _isLoading,
          onPressed: _hasChanges() && _isFormValid() ? _handleUpdateGoal : null,
        ),
        
        const SizedBox(height: SpacingConsts.m),
        
        // 削除ボタン
        OutlinedButton(
          onPressed: _isLoading ? null : _showDeleteConfirmDialog,
          style: OutlinedButton.styleFrom(
            foregroundColor: ColorConsts.error,
            side: const BorderSide(color: ColorConsts.error),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            minimumSize: const Size(double.infinity, 56),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.delete_outline, size: 20),
              const SizedBox(width: SpacingConsts.s),
              Text(
                '目標を削除',
                style: TextConsts.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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

  bool _hasChanges() {
    return _title != widget.goal.title ||
        _description != widget.goal.description ||
        _avoidMessage != widget.goal.avoidMessage ||
        _totalTargetHours != widget.goal.totalTargetHours;
  }

  Future<void> _handleUpdateGoal() async {
    if (!_isFormValid() || !_hasChanges()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // UpdateGoalUseCaseを使用
      final updateGoalUseCase = ref.read(updateGoalUseCaseProvider);
      
      // 目標を更新
      final updatedGoal = await updateGoalUseCase(
        originalGoal: widget.goal,
        title: _title,
        description: _description,
        avoidMessage: _avoidMessage,
        totalTargetHours: _totalTargetHours,
      );

      if (mounted) {
        Navigator.of(context).pop(updatedGoal);
        
        // 成功メッセージ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '目標を更新しました',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            backgroundColor: ColorConsts.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(SpacingConsts.l),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '目標の更新に失敗しました: ${e.toString()}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            backgroundColor: ColorConsts.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(SpacingConsts.l),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('目標を削除'),
        content: Text(
          '「${widget.goal.title}」を削除しますか？\nこの操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleDeleteGoal();
            },
            style: TextButton.styleFrom(
              foregroundColor: ColorConsts.error,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteGoal() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // DeleteGoalUseCaseを使用
      final deleteGoalUseCase = ref.read(deleteGoalUseCaseProvider);
      
      // 目標を削除
      await deleteGoalUseCase(
        goalId: widget.goal.id,
        goalTitle: widget.goal.title,
      );

      if (mounted) {
        Navigator.of(context).pop('deleted');
        
        // 成功メッセージ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '目標「${widget.goal.title}」を削除しました',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            backgroundColor: ColorConsts.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(SpacingConsts.l),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '目標の削除に失敗しました: ${e.toString()}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            backgroundColor: ColorConsts.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(SpacingConsts.l),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
}