import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../../core/services/temp_user_service.dart';
import '../../../../../core/services/startup_logic_service.dart';
import '../../../../../core/services/data_migration_service.dart';

part 'onboarding_view_model.freezed.dart';

@freezed
class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(0) int currentStep,
    @Default(0.0) double progress,
    @Default(false) bool isLoading,
    @Default('') String tempUserId,
    String? errorMessage,
    @Default(false) bool isDataMigrationInProgress,
  }) = _OnboardingState;
}

class OnboardingViewModel extends StateNotifier<OnboardingState> {
  OnboardingViewModel(
    this._tempUserService,
    this._startupLogicService,
    this._dataMigrationService,
  ) : super(const OnboardingState()) {
    _initializeOnboarding();
  }

  final TempUserService _tempUserService;
  final StartupLogicService _startupLogicService;
  final DataMigrationService _dataMigrationService;

  /// オンボーディング初期化
  Future<void> _initializeOnboarding() async {
    try {
      state = state.copyWith(isLoading: true);

      // 既存の仮ユーザーがあるかチェック
      final tempUserId = await _tempUserService.getTempUserId();
      if (tempUserId != null) {
        // 継続フロー
        final step = await _tempUserService.getOnboardingStep();
        final progress = await _startupLogicService.getOnboardingProgress();

        state = state.copyWith(
          tempUserId: tempUserId,
          currentStep: step,
          progress: progress,
          isLoading: false,
        );
      } else {
        // 新規フロー
        await _startNewOnboarding();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'オンボーディング初期化に失敗しました: $e',
      );
    }
  }

  /// 新規オンボーディング開始
  Future<void> _startNewOnboarding() async {
    try {
      await _startupLogicService.initializeForNewUser();
      final tempUserId = await _tempUserService.getTempUserId();

      state = state.copyWith(
        tempUserId: tempUserId ?? '',
        currentStep: 0,
        progress: 0.0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '新規オンボーディング開始に失敗しました: $e',
      );
    }
  }

  /// ステップ完了
  Future<void> completeStep(int step) async {
    try {
      state = state.copyWith(isLoading: true);

      await _startupLogicService.completeOnboardingStep(step);
      final progress = await _startupLogicService.getOnboardingProgress();

      state = state.copyWith(
        currentStep: step,
        progress: progress,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'ステップ完了処理に失敗しました: $e',
      );
    }
  }

  /// 目標作成完了（ステップ1）
  Future<void> completeGoalCreation() async {
    await completeStep(1);
  }

  /// アカウント作成完了（ステップ2）
  Future<void> completeAccountCreation() async {
    await completeStep(2);
  }

  /// ゲストとして続行
  Future<void> continueAsGuest() async {
    await completeAccountCreation();
  }

  /// データ移行実行
  Future<bool> migrateDataToAuthenticatedUser(String realUserId) async {
    try {
      state = state.copyWith(isDataMigrationInProgress: true);

      final tempUserId = state.tempUserId;
      if (tempUserId.isEmpty) {
        throw Exception('仮ユーザーIDが見つかりません');
      }

      final success = await _dataMigrationService.migrateTempUserData(
        tempUserId,
        realUserId,
      );

      if (success) {
        await completeAccountCreation();
        state = state.copyWith(isDataMigrationInProgress: false);
        return true;
      } else {
        // リトライロジック
        final retrySuccess = await _dataMigrationService.retryMigration(
          tempUserId,
          realUserId,
        );

        state = state.copyWith(
          isDataMigrationInProgress: false,
          errorMessage: retrySuccess ? null : 'データ移行に失敗しました。サポートにお問い合わせください。',
        );

        return retrySuccess;
      }
    } catch (e) {
      state = state.copyWith(
        isDataMigrationInProgress: false,
        errorMessage: 'データ移行中にエラーが発生しました: $e',
      );
      return false;
    }
  }

  /// エラークリア
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// 現在のステップが指定されたステップかチェック
  bool isCurrentStep(int step) {
    return state.currentStep == step;
  }

  /// 指定されたステップが完了済みかチェック
  bool isStepCompleted(int step) {
    return state.currentStep > step;
  }

  /// オンボーディング完了チェック
  bool get isOnboardingCompleted {
    return state.currentStep >= 3;
  }

  /// 次のステップのルートを取得
  Future<String> getNextRoute() async {
    if (isOnboardingCompleted) {
      return '/home';
    }

    return await _startupLogicService.determineInitialRoute();
  }
}

// Providers
final tempUserServiceProvider = Provider<TempUserService>((ref) {
  return TempUserService();
});

final startupLogicServiceProvider = Provider<StartupLogicService>((ref) {
  final tempUserService = ref.read(tempUserServiceProvider);
  return StartupLogicService(tempUserService);
});

final dataMigrationServiceProvider = Provider<DataMigrationService>((ref) {
  return DataMigrationService();
});

final onboardingViewModelProvider =
    StateNotifierProvider<OnboardingViewModel, OnboardingState>((ref) {
      final tempUserService = ref.read(tempUserServiceProvider);
      final startupLogicService = ref.read(startupLogicServiceProvider);
      final dataMigrationService = ref.read(dataMigrationServiceProvider);

      return OnboardingViewModel(
        tempUserService,
        startupLogicService,
        dataMigrationService,
      );
    });
