import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  TutorialViewModel(this._tempUserService) : super(const TutorialState()) {
    print('🏗️ TutorialViewModel 初期化開始');
    print('初期状態: ${state.toString()}');
    // 初期化時にSharedPreferencesから状態を復元
    _loadTutorialState();
  }

  /// SharedPreferencesからチュートリアル状態を復元
  Future<void> _loadTutorialState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isTutorialActive = prefs.getBool('tutorial_active') ?? false;
      
      if (isTutorialActive) {
        // チュートリアルが進行中の場合、保存された状態を復元
        final tempUserId = await _tempUserService.getTempUserId();
        final currentStepId = prefs.getString('tutorial_current_step') ?? 'home_goal_selection';
        final currentStepIndex = prefs.getInt('tutorial_current_step_index') ?? 0;
        final totalSteps = prefs.getInt('tutorial_total_steps') ?? 3;
        
        print('🔄 チュートリアル状態を復元中...');
        print('  - isTutorialActive: $isTutorialActive');
        print('  - currentStepId: $currentStepId');
        print('  - currentStepIndex: $currentStepIndex');
        print('  - totalSteps: $totalSteps');
        print('  - tempUserId: $tempUserId');
        
        state = state.copyWith(
          isTutorialActive: true,
          tempUserId: tempUserId,
          currentStepId: currentStepId,
          currentStepIndex: currentStepIndex,
          totalSteps: totalSteps,
          isCompleted: false,
        );
        
        print('✅ チュートリアル状態を復元しました: ${state.toString()}');
      } else {
        print('ℹ️ アクティブなチュートリアルはありません');
      }
    } catch (e) {
      print('❌ チュートリアル状態の復元に失敗: $e');
    }
  }

  /// チュートリアルを開始
  Future<void> startTutorial({
    required String tempUserId,
    required int totalSteps,
  }) async {
    print('🚀 Starting tutorial with tempUserId: $tempUserId, totalSteps: $totalSteps');
    
    const currentStepId = 'home_goal_selection';
    const currentStepIndex = 0;
    
    // チュートリアル状態を永続化して、StartupLogicServiceが参照できるようにする
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_active', true);
    await prefs.setString('tutorial_current_step', currentStepId);
    await prefs.setInt('tutorial_current_step_index', currentStepIndex);
    await prefs.setInt('tutorial_total_steps', totalSteps);
    
    state = state.copyWith(
      isTutorialActive: true,
      tempUserId: tempUserId,
      totalSteps: totalSteps,
      currentStepIndex: currentStepIndex,
      currentStepId: currentStepId,
      isCompleted: false,
    );
    print('✅ Tutorial state updated and saved: ${state.toString()}');
  }

  /// 次のステップに進む
  Future<void> nextStep(String stepId) async {
    print('⏭️ nextStep called with stepId: $stepId');
    print('Current state: index=${state.currentStepIndex}, total=${state.totalSteps}');
    
    if (state.currentStepIndex < state.totalSteps - 1) {
      final newStepIndex = state.currentStepIndex + 1;
      
      // SharedPreferencesに保存
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tutorial_current_step', stepId);
      await prefs.setInt('tutorial_current_step_index', newStepIndex);
      
      state = state.copyWith(
        currentStepIndex: newStepIndex,
        currentStepId: stepId,
      );
      print('✅ Advanced to step: ${state.currentStepIndex}, stepId: ${state.currentStepId}');
    } else {
      // チュートリアル完了
      print('🏁 Tutorial completed, calling completeTutorial()');
      await completeTutorial();
    }
  }

  /// チュートリアルを完了
  Future<void> completeTutorial() async {
    print('🏆 completeTutorial called');
    print('📋 現在のチュートリアル状態: isTutorialActive=${state.isTutorialActive}');
    
    // tempユーザーがまだ作成されていない場合は作成
    final tempUserId = await _tempUserService.getTempUserId();
    if (tempUserId == null) {
      final newTempUserId = await _tempUserService.generateTempUserId();
      print('✅ Temp user created for guest mode: $newTempUserId');
    } else {
      print('ℹ️ Temp user already exists: $tempUserId');
    }
    
    print('🚩 チュートリアルフラグをクリア中...');
    await _clearTutorialFlag();
    
    print('🔄 チュートリアル状態を更新中...');
    state = state.copyWith(
      isTutorialActive: false,
      isCompleted: true,
    );
    print('✅ チュートリアル完了 - 新しい状態: isTutorialActive=${state.isTutorialActive}, isCompleted=${state.isCompleted}');
  }

  /// チュートリアルをスキップ
  Future<void> skipTutorial() async {
    print('⏸️ skipTutorial called');
    
    // tempユーザーがまだ作成されていない場合は作成（スキップしてもゲストユーザーになる）
    final tempUserId = await _tempUserService.getTempUserId();
    if (tempUserId == null) {
      final newTempUserId = await _tempUserService.generateTempUserId();
      print('✅ Temp user created for guest mode (skip): $newTempUserId');
    } else {
      print('ℹ️ Temp user already exists: $tempUserId');
    }
    
    await _clearTutorialFlag();
    state = state.copyWith(
      isTutorialActive: false,
      isCompleted: true,
    );
    print('✅ Tutorial skipped, state: ${state.toString()}');
  }

  /// チュートリアルフラグをクリア
  Future<void> _clearTutorialFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tutorial_active');
    await prefs.remove('tutorial_current_step');
    await prefs.remove('tutorial_current_step_index');
    await prefs.remove('tutorial_total_steps');
    print('🗑️ チュートリアル関連のSharedPreferencesデータをクリアしました');
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

  /// ホーム画面でのタイマーボタンshowcaseステップ
  void startTimerButtonShowcaseStep() {
    state = state.copyWith(currentStepId: 'home_timer_button_showcase');
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