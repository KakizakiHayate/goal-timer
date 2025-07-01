import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/widgets/custom_text_field_v2.dart';
import '../../../../core/widgets/modal_bottom_sheet_v2.dart';
import '../../../../features/auth/presentation/widgets/auth_button_v2.dart';
import '../../../../core/models/goals/goals_model.dart';

/// 改善された目標作成モーダル
class GoalCreateModalV2 extends ConsumerStatefulWidget {
  const GoalCreateModalV2({super.key});

  @override
  ConsumerState<GoalCreateModalV2> createState() => _GoalCreateModalV2State();

  static Future<GoalsModel?> show(BuildContext context) {
    return ModalBottomSheetV2.show<GoalsModel>(
      context: context,
      title: '新しい目標を作成',
      height: MediaQuery.of(context).size.height * 0.85,
      child: const GoalCreateModalV2(),
    );
  }
}

class _GoalCreateModalV2State extends ConsumerState<GoalCreateModalV2> {
  final _formKey = GlobalKey<FormState>();
  
  String _title = '';
  String _description = '';
  String _avoidMessage = '';
  int _targetMinutes = 30;
  bool _isLoading = false;

  String? _titleError;
  String? _avoidMessageError;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // 説明テキスト
          _buildDescription(),
          
          const SizedBox(height: SpacingConsts.xl),
          
          // フォーム
          _buildForm(),
          
          const SizedBox(height: SpacingConsts.xxl),
          
          // 作成ボタン
          _buildCreateButton(),
          
          const SizedBox(height: SpacingConsts.xl),
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
        CustomTextFieldV2(
          labelText: '目標タイトル',
          hintText: '例：英語の勉強',
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
        CustomTextFieldV2(
          labelText: '目標の詳細（任意）',
          hintText: '例：TOEICで800点を取るために毎日英単語を覚える',
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
        CustomTextFieldV2(
          labelText: 'やらないとどうなる？',
          hintText: '例：将来の仕事で困る、自分に失望する',
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
                    '$_targetMinutes分',
                    style: TextConsts.h3.copyWith(
                      color: ColorConsts.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SpacingConsts.m),
              Slider(
                value: _targetMinutes.toDouble(),
                min: 15,
                max: 180,
                divisions: 11,
                activeColor: ColorConsts.primary,
                inactiveColor: ColorConsts.border,
                onChanged: (value) {
                  setState(() {
                    _targetMinutes = value.toInt();
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

  Widget _buildCreateButton() {
    return AuthButtonV2(
      type: AuthButtonType.email,
      text: '目標を作成',
      isLoading: _isLoading,
      onPressed: _isFormValid() ? _handleCreateGoal : null,
    );
  }

  // バリデーション
  String? _validateTitle(String value) {
    if (value.isEmpty) return 'タイトルを入力してください';
    if (value.length < 2) return 'タイトルは2文字以上で入力してください';
    return null;
  }

  String? _validateAvoidMessage(String value) {
    if (value.isEmpty) return 'ネガティブ回避メッセージを入力してください';
    if (value.length < 5) return '5文字以上で入力してください';
    return null;
  }

  bool _isFormValid() {
    return _title.isNotEmpty &&
        _avoidMessage.isNotEmpty &&
        _titleError == null &&
        _avoidMessageError == null;
  }

  Future<void> _handleCreateGoal() async {
    if (!_isFormValid()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 実際の目標作成処理を実装
      await Future.delayed(const Duration(seconds: 1)); // 仮の処理
      
      final newGoal = GoalsModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'current_user_id', // TODO: 実際のユーザーIDに置き換え
        title: _title,
        description: _description,
        avoidMessage: _avoidMessage,
        targetMinutes: _targetMinutes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      if (mounted) {
        Navigator.of(context).pop(newGoal);
        
        // 成功メッセージ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '目標「$_title」を作成しました！',
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
              '目標の作成に失敗しました',
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