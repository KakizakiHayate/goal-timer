import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/services/temp_user_service.dart';
import 'onboarding_view_model.dart';

part 'tutorial_view_model.freezed.dart';

/// チュートリアル状態
@freezed
class TutorialState with _$TutorialState {
  const factory TutorialState({
    @Default(false) bool isTutorialActive,
    @Default('') String currentStepId,
    @Default(0) int currentStepIndex,
    @Default(0) int totalSteps,
    @Default(false) bool isCompleted,
    String? tempUserId,
  }) = _TutorialState;
}

/// チュートリアルの進行状況を管理するViewModel
class TutorialViewModel extends StateNotifier<TutorialState> {
  final TempUserService _tempUserService;

  TutorialViewModel(this._tempUserService) : super(const TutorialState());

  /// チュートリアルを開始
  Future<void> startTutorial({
    required String tempUserId,
    required int totalSteps,
  }) async {
    state = state.copyWith(
      isTutorialActive: true,
      tempUserId: tempUserId,
      totalSteps: totalSteps,
      currentStepIndex: 0,
      currentStepId: 'home_goal_selection',
      isCompleted: false,
    );
  }

  /// 次のステップに進む
  void nextStep(String stepId) {
    if (state.currentStepIndex < state.totalSteps - 1) {
      state = state.copyWith(
        currentStepIndex: state.currentStepIndex + 1,
        currentStepId: stepId,
      );
    } else {
      // チュートリアル完了
      completeTutorial();
    }
  }

  /// チュートリアルを完了
  void completeTutorial() {
    state = state.copyWith(
      isTutorialActive: false,
      isCompleted: true,
    );
  }

  /// チュートリアルをスキップ
  void skipTutorial() {
    state = state.copyWith(
      isTutorialActive: false,
      isCompleted: true,
    );
  }

  /// チュートリアルをリセット
  void resetTutorial() {
    state = const TutorialState();
  }

  /// 特定のステップをチェック
  bool isCurrentStep(String stepId) {
    return state.isTutorialActive && state.currentStepId == stepId;
  }

  /// ホーム画面でのゴール選択ステップ
  void startGoalSelectionStep() {
    state = state.copyWith(currentStepId: 'home_goal_selection');
  }

  /// タイマー画面でのタイマー操作ステップ
  void startTimerOperationStep() {
    state = state.copyWith(currentStepId: 'timer_operation');
  }

  /// タイマー完了ステップ
  void startTimerCompletionStep() {
    state = state.copyWith(currentStepId: 'timer_completion');
  }
}

/// TutorialViewModelのプロバイダー
final tutorialViewModelProvider =
    StateNotifierProvider<TutorialViewModel, TutorialState>((ref) {
  final tempUserService = ref.watch(tempUserServiceProvider);
  return TutorialViewModel(tempUserService);
});

/// 現在のチュートリアルステップをチェックするヘルパープロバイダー
final currentTutorialStepProvider = Provider.family<bool, String>((ref, stepId) {
  final tutorialState = ref.watch(tutorialViewModelProvider);
  return tutorialState.isTutorialActive && tutorialState.currentStepId == stepId;
});