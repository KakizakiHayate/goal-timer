import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../features/auth/presentation/widgets/auth_button.dart';
import '../../../../core/models/goals/goals_model.dart';
import '../../../../core/provider/providers.dart';
import '../../../../features/auth/provider/auth_provider.dart';

/// 改善された目標作成モーダル
class GoalCreateModal extends StatelessWidget {
  const GoalCreateModal({super.key});

  @override
  Widget build(BuildContext context) {
    // このクラスは直接使用されず、show()メソッドのみが使用される
    return const SizedBox.shrink();
  }

  static Future<GoalsModel?> show(BuildContext context) {
    return showModalBottomSheet<GoalsModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => Container(
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
                  bottom: BorderSide(
                    color: ColorConsts.border,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '新しい目標を作成',
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
            const Expanded(
              child: _GoalCreateModalContent(),
            ),
            
            // Safe Area padding
            SafeArea(
              top: false,
              child: SizedBox(height: MediaQuery.of(context).padding.bottom),
            ),
          ],
        ),
      ),
    );
  }
}

// スクロールコントローラーを受け取る内部ウィジェット
class _GoalCreateModalContent extends ConsumerStatefulWidget {
  const _GoalCreateModalContent();

  @override
  ConsumerState<_GoalCreateModalContent> createState() => _GoalCreateModalContentState();
}

class _GoalCreateModalContentState extends ConsumerState<_GoalCreateModalContent> {
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingConsts.l,
      ),
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
            ColorConsts.primary.withValues(alpha: 0.1),
            ColorConsts.primaryLight.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorConsts.primary.withValues(alpha: 0.2),
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
                  const Icon(
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
    return AuthButton(
      type: AuthButtonType.email,
      text: '目標を作成',
      isLoading: _isLoading,
      onPressed: _isFormValid() ? _handleCreateGoal : null,
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

  Future<void> _handleCreateGoal() async {
    if (!_isFormValid()) return;

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
        title: _title,
        description: _description,
        avoidMessage: _avoidMessage,
        targetMinutes: _targetMinutes,
        deadline: DateTime.now().add(const Duration(days: 30)),
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
}