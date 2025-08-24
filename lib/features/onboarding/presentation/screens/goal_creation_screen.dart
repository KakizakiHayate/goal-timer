import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/widgets/common_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../widgets/onboarding_progress_bar.dart';
import '../view_models/onboarding_view_model.dart';
import '../view_models/tutorial_view_model.dart';
import '../../../../core/utils/route_names.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../../core/usecases/goals/create_goal_usecase.dart';
import '../../../../core/provider/providers.dart';
import '../../../../core/utils/app_logger.dart';

/// 目標作成画面（オンボーディング ステップ1）
class GoalCreationScreen extends ConsumerStatefulWidget {
  const GoalCreationScreen({super.key});

  @override
  ConsumerState<GoalCreationScreen> createState() => _GoalCreationScreenState();
}

class _GoalCreationScreenState extends ConsumerState<GoalCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _title = '';
  String _description = '';
  String _avoidMessage = '';
  int _targetMinutes = 120; // デフォルト2時間
  bool _isLoading = false;

  String? _titleError;
  String? _avoidMessageError;

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingViewModelProvider);
    final onboardingViewModel = ref.read(onboardingViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: ColorConsts.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          '最初の目標を設定',
          style: TextConsts.h4.copyWith(color: ColorConsts.textPrimary),
        ),
        backgroundColor: ColorConsts.backgroundPrimary,
        elevation: 0,
        automaticallyImplyLeading: false, // 戻るボタンなし
      ),
      body: Column(
        children: [
          // プログレスバー
          OnboardingProgressBar(progress: 0.33, currentStep: 1, totalSteps: 3),

          // フォーム部分
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(SpacingConsts.l),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 説明
                    _buildDescription(),
                    
                    const SizedBox(height: SpacingConsts.l),
                    
                    // フォーム
                    _buildForm(),
                  ],
                ),
              ),
            ),
          ),

          // エラー表示
          if (onboardingState.errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(SpacingConsts.md),
              padding: const EdgeInsets.all(SpacingConsts.md),
              decoration: BoxDecoration(
                color: ColorConsts.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ColorConsts.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: ColorConsts.error, size: 20),
                  const SizedBox(width: SpacingConsts.sm),
                  Expanded(
                    child: Text(
                      onboardingState.errorMessage!,
                      style: TextConsts.bodySmall.copyWith(
                        color: ColorConsts.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 次へボタン
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(SpacingConsts.md),
            child: CommonButton(
              key: const Key('next_button'),
              text: '次へ',
              variant: ButtonVariant.primary,
              size: ButtonSize.large,
              isExpanded: true,
              isLoading: onboardingState.isLoading,
              onPressed: _isFormComplete ? _onNextPressed : null,
            ),
          ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorConsts.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: SpacingConsts.m),
              Expanded(
                child: Text(
                  'あなたの最初の目標を設定しましょう',
                  style: TextConsts.h4.copyWith(
                    color: ColorConsts.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingConsts.m),
          Text(
            '目標を明確にすることで、集中して取り組むことができます。「回避したいこと」を設定することで、より強いモチベーションを維持できます。',
            style: TextConsts.bodyMedium.copyWith(
              color: ColorConsts.textSecondary,
              height: 1.6,
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
          hintText: '例：英語の勉強、プログラミング学習',
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

        // 目標の詳細説明
        CustomTextField(
          labelText: '目標の詳細（任意）',
          hintText: '例：毎日30分英語を勉強する、Webサイトを作る',
          initialValue: _description,
          maxLength: 200,
          maxLines: 3,
          prefixIcon: Icons.description_outlined,
          onChanged: (value) {
            setState(() {
              _description = value;
            });
          },
          textInputAction: TextInputAction.next,
        ),

        const SizedBox(height: SpacingConsts.l),

        // 回避したいこと
        CustomTextField(
          labelText: '回避したいこと',
          hintText: '例：英語ができずに海外で困る、技術についていけない',
          initialValue: _avoidMessage,
          maxLength: 100,
          maxLines: 2,
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

        const SizedBox(height: SpacingConsts.l),

        // 目標時間
        _buildTimeSelector(),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      padding: const EdgeInsets.all(SpacingConsts.l),
      decoration: BoxDecoration(
        color: ColorConsts.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConsts.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.schedule_outlined,
                color: ColorConsts.textSecondary,
                size: 20,
              ),
              const SizedBox(width: SpacingConsts.s),
              Text(
                '目標時間',
                style: TextConsts.labelMedium.copyWith(
                  color: ColorConsts.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingConsts.m),
          Text(
            '${_targetMinutes}分',
            style: TextConsts.h3.copyWith(
              color: ColorConsts.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: SpacingConsts.s),
          Text(
            'チュートリアル用に2時間（120分）が設定されています',
            style: TextConsts.caption.copyWith(
              color: ColorConsts.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // バリデーションメソッド
  String? _validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return '目標タイトルを入力してください';
    }
    if (value.length < 2) {
      return '目標タイトルは2文字以上で入力してください';
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

  bool get _isFormComplete {
    return _title.isNotEmpty &&
        _title.length >= 2 &&
        _avoidMessage.isNotEmpty &&
        _avoidMessage.length >= 5;
  }

  Future<void> _onNextPressed() async {
    final onboardingViewModel = ref.read(onboardingViewModelProvider.notifier);
    final tutorialViewModel = ref.read(tutorialViewModelProvider.notifier);
    final authViewModel = ref.read(authViewModelProvider.notifier);

    try {
      // TODO: 実際のゴールデータをローカルDBに保存する処理
      // 現在はステップ完了のみ実装
      await _saveGoalData();

      // ステップ1完了
      await onboardingViewModel.completeGoalCreation();

      // 認証状態をゲスト状態に設定
      authViewModel.setGuestState();

      // チュートリアルフローを開始
      final onboardingState = ref.read(onboardingViewModelProvider);
      await tutorialViewModel.startTutorial(
        tempUserId: onboardingState.tempUserId,
        totalSteps: 3, // goal_selection -> timer_operation -> timer_completion
      );

      // ホーム画面に遷移（チュートリアルが自動的に開始される）
      if (mounted) {
        Navigator.pushReplacementNamed(context, RouteNames.home);
      }
    } catch (e) {
      // エラーは onboardingViewModel 内で処理される
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('目標作成に失敗しました: $e'),
            backgroundColor: ColorConsts.error,
          ),
        );
      }
    }
  }

  Future<void> _saveGoalData() async {
    try {
      final createGoalUseCase = ref.read(createGoalUseCaseProvider);
      final onboardingState = ref.read(onboardingViewModelProvider);
      
      // オンボーディングでは目標時間を2時間（120分）に設定
      const int defaultTargetMinutes = 120;
      
      // デフォルトの締切（30日後）
      final deadline = DateTime.now().add(const Duration(days: 30));

      final goal = await createGoalUseCase.call(
        userId: onboardingState.tempUserId,
        title: _title,
        description: _description,
        avoidMessage: _avoidMessage,
        targetMinutes: defaultTargetMinutes,
        deadline: deadline,
      );

      AppLogger.instance.i('オンボーディング目標が作成されました: ${goal.title}');
    } catch (e) {
      AppLogger.instance.e('オンボーディング目標の作成に失敗しました', e);
      rethrow;
    }
  }
}
