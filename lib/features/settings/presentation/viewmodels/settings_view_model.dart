import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/settings.dart';
import '../../domain/usecases/get_settings_usecase.dart';
import '../../domain/usecases/save_settings_usecase.dart';
import '../../data/repositories/settings_repository_impl.dart';

// リポジトリプロバイダー
final settingsRepositoryProvider = Provider((ref) => SettingsRepositoryImpl());

// ユースケースプロバイダー
final getSettingsUseCaseProvider = Provider(
  (ref) => GetSettingsUseCase(ref.watch(settingsRepositoryProvider)),
);

final saveSettingsUseCaseProvider = Provider(
  (ref) => SaveSettingsUseCase(ref.watch(settingsRepositoryProvider)),
);

// 設定の状態管理プロバイダー
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<Settings>>(
      (ref) => SettingsNotifier(
        ref.watch(getSettingsUseCaseProvider),
        ref.watch(saveSettingsUseCaseProvider),
      ),
    );

class SettingsNotifier extends StateNotifier<AsyncValue<Settings>> {
  final GetSettingsUseCase _getSettingsUseCase;
  final SaveSettingsUseCase _saveSettingsUseCase;

  SettingsNotifier(this._getSettingsUseCase, this._saveSettingsUseCase)
    : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      state = const AsyncValue.loading();
      final settings = await _getSettingsUseCase.execute();
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateSettings(Settings settings) async {
    try {
      state = const AsyncValue.loading();
      await _saveSettingsUseCase.execute(settings);
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateTheme(String theme) async {
    if (state.hasValue) {
      final currentSettings = state.value!;
      await updateSettings(currentSettings.copyWith(theme: theme));
    }
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    if (state.hasValue) {
      final currentSettings = state.value!;
      await updateSettings(
        currentSettings.copyWith(notificationsEnabled: enabled),
      );
    }
  }

  Future<void> updateReminderInterval(int interval) async {
    if (state.hasValue) {
      final currentSettings = state.value!;
      await updateSettings(
        currentSettings.copyWith(reminderInterval: interval),
      );
    }
  }

  Future<void> updateSoundEnabled(bool enabled) async {
    if (state.hasValue) {
      final currentSettings = state.value!;
      await updateSettings(currentSettings.copyWith(soundEnabled: enabled));
    }
  }

  Future<void> updateDefaultTimerDuration(int minutes) async {
    if (state.hasValue) {
      final currentSettings = state.value!;
      await updateSettings(
        currentSettings.copyWith(defaultTimerDuration: minutes),
      );
    }
  }
}
