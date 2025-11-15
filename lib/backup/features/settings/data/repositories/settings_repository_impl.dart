import '../../domain/entities/settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  // TODO: 実際には SharedPreferences などでデータを永続化する実装が必要
  Settings? _cachedSettings;

  @override
  Future<Settings> getSettings() async {
    // キャッシュがあればそれを返す、なければデフォルト設定を返す
    return _cachedSettings ?? Settings.defaultSettings();
  }

  @override
  Future<void> saveSettings(Settings settings) async {
    // キャッシュを更新（本来はデータを永続化する処理が必要）
    _cachedSettings = settings;
    // TODO: 実際のデータ永続化処理を実装
  }
}
