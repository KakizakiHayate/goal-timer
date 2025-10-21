import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/widgets/goal_form/goal_form_widget.dart';
import '../../../../core/widgets/goal_form/goal_form_data.dart';
import '../../../../features/auth/presentation/widgets/auth_button.dart';
import '../../../../core/models/goals/goals_model.dart';
import '../../../../core/provider/providers.dart';
import '../../../../features/auth/provider/auth_provider.dart';
import '../../../../core/utils/app_logger.dart';

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
class _GoalCreateModalContent extends ConsumerStatefulWidget {
  final GoalsModel? existingGoal;

  const _GoalCreateModalContent({this.existingGoal});

  @override
  ConsumerState<_GoalCreateModalContent> createState() =>
      _GoalCreateModalContentState();
}

class _GoalCreateModalContentState
    extends ConsumerState<_GoalCreateModalContent> {
  GoalFormData _formData = GoalFormData.empty();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 編集モードの場合は初期値を設定
    if (widget.existingGoal != null) {
      _formData = GoalFormData(
        title: widget.existingGoal!.title,
        description: widget.existingGoal!.description,
        avoidMessage: widget.existingGoal!.avoidMessage,
        targetMinutes: widget.existingGoal!.targetMinutes,
        deadline: widget.existingGoal!.deadline,
        isValid: true, // 既存データは有効とみなす
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: SpacingConsts.l),
      child: Column(
        children: [
          // 説明テキスト
          _buildDescription(),

          const SizedBox(height: SpacingConsts.l),

          // 共通フォーム
          GoalFormWidget(
            existingGoal: widget.existingGoal,
            onFormChanged: (formData) {
              setState(() {
                _formData = formData;
              });
            },
            showDeadlineField: true,
            isDeadlineEditable: true,
          ),

          const SizedBox(height: SpacingConsts.l),

          // 作成ボタン
          _buildCreateButton(),

          const SizedBox(height: SpacingConsts.l),
        ],
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
        CustomTextField(
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
        CustomTextField(
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
            color: isEditMode 
                ? ColorConsts.backgroundSecondary.withOpacity(0.5)
                : ColorConsts.backgroundSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEditMode 
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
                    isEditMode ? Icons.lock_outlined : Icons.calendar_today_outlined,
                    color: isEditMode 
                        ? ColorConsts.textTertiary
                        : ColorConsts.primary,
                    size: 24,
                  ),
                  const SizedBox(width: SpacingConsts.s),
                  Text(
                    '${_deadline.year}年${_deadline.month}月${_deadline.day}日',
                    style: TextConsts.h3.copyWith(
                      color: isEditMode 
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
                    final DateTime tomorrow = DateTime.now().add(const Duration(days: 1));
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _deadline.isBefore(tomorrow) ? tomorrow : _deadline,
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
                      border: Border.all(color: ColorConsts.primary, width: 1.5),
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
        AuthButton(
          type: AuthButtonType.email,
          text: widget.existingGoal != null ? '変更を保存' : '目標を作成',
          isLoading: _isLoading,
          onPressed: _formData.isValid ? _handleSubmit : null,
        ),

        // 編集モード時のみ削除ボタンを表示
        if (widget.existingGoal != null) ...[
          const SizedBox(height: SpacingConsts.m),
          TextButton.icon(
            icon: const Icon(Icons.delete_outline, color: ColorConsts.error),
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

  Future<void> _handleSubmit() async {
    if (widget.existingGoal != null) {
      await _handleUpdateGoal();
    } else {
      await _handleCreateGoal();
    }
  }

  Future<void> _handleCreateGoal() async {
    if (!_formData.isValid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // CreateGoalUseCaseを使用
      final createGoalUseCase = ref.read(createGoalUseCaseProvider);

      // 現在のユーザーIDを取得
      final authViewModel = ref.read(authViewModelProvider.notifier);
      final currentUserId = authViewModel.currentUser?.id;

      if (currentUserId == null) {
        throw Exception('ユーザーが認証されていません');
      }

      // 目標を作成
      final newGoal = await createGoalUseCase(
        userId: currentUserId,
        title: _formData.title,
        description: _formData.description,
        avoidMessage: _formData.avoidMessage,
        targetMinutes: _formData.targetMinutes,
        deadline: _formData.deadline,
      );

      if (mounted) {
        Navigator.of(context).pop(newGoal);

        // 成功メッセージ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '目標「${_formData.title}」を作成しました！',
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
              '目標の作成に失敗しました: ${e.toString()}',
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

  Future<void> _handleUpdateGoal() async {
    if (!_formData.isValid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      AppLogger.instance.i('🔄 目標更新処理を開始します');
      AppLogger.instance.i(
        '📝 更新対象目標: ${widget.existingGoal!.title} (ID: ${widget.existingGoal!.id})',
      );
      AppLogger.instance.i(
        '📝 更新内容: タイトル=${_formData.title}, 説明=${_formData.description}, 回避メッセージ=${_formData.avoidMessage}, 目標時間=${_formData.targetMinutes}分',
      );

      // UpdateGoalUseCaseを使用
      final updateGoalUseCase = ref.read(updateGoalUseCaseProvider);
      AppLogger.instance.i('✅ UpdateGoalUseCaseを取得しました');

      // 目標を更新
      AppLogger.instance.i('🚀 UseCase.call()を呼び出します...');
      final updatedGoal = await updateGoalUseCase(
        originalGoal: widget.existingGoal!,
        title: _formData.title,
        description: _formData.description,
        avoidMessage: _formData.avoidMessage,
        targetMinutes: _formData.targetMinutes,
      );

      AppLogger.instance.i('✅ UseCase.call()が完了しました');
      AppLogger.instance.i(
        '📊 更新結果: ${updatedGoal.title} (ID: ${updatedGoal.id})',
      );
      AppLogger.instance.i('📊 更新後の目標時間: ${updatedGoal.targetMinutes}分');

      if (mounted) {
        AppLogger.instance.i('🔙 モーダルを閉じて更新された目標を返します');
        Navigator.of(context).pop(updatedGoal);

        // 成功メッセージ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '目標「${_formData.title}」を更新しました！',
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
        AppLogger.instance.i('✅ 成功メッセージを表示しました');
      }
    } catch (e) {
      AppLogger.instance.e('❌ 目標更新処理でエラーが発生しました', e);
      AppLogger.instance.e('❌ エラー詳細: ${e.toString()}');
      AppLogger.instance.e('❌ エラータイプ: ${e.runtimeType}');

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
        AppLogger.instance.i('❌ エラーメッセージを表示しました');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        AppLogger.instance.i('🏁 目標更新処理が終了しました');
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
      AppLogger.instance.i('🗑️ 目標削除処理を開始します');
      AppLogger.instance.i(
        '🎯 削除対象目標: ${widget.existingGoal!.title} (ID: ${widget.existingGoal!.id})',
      );

      // DeleteGoalUseCaseを使用
      final deleteGoalUseCase = ref.read(deleteGoalUseCaseProvider);
      AppLogger.instance.i('✅ DeleteGoalUseCaseを取得しました');

      // 目標を削除
      AppLogger.instance.i('🚀 削除処理を実行します...');
      await deleteGoalUseCase(
        goalId: widget.existingGoal!.id,
        goalTitle: widget.existingGoal!.title,
      );

      AppLogger.instance.i('✅ 削除処理が完了しました');

      if (mounted) {
        AppLogger.instance.i('🔙 モーダルを閉じて削除完了を通知します');
        // 削除が成功したことを示すために特別な値を返す
        Navigator.of(context).pop('deleted');

        // 成功メッセージ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '目標「${widget.existingGoal!.title}」を削除しました',
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
        AppLogger.instance.i('✅ 成功メッセージを表示しました');
      }
    } catch (e) {
      AppLogger.instance.e('❌ 目標削除処理でエラーが発生しました', e);
      AppLogger.instance.e('❌ エラー詳細: ${e.toString()}');

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
        AppLogger.instance.i('❌ エラーメッセージを表示しました');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        AppLogger.instance.i('🏁 目標削除処理が終了しました');
      }
    }
  }
}
