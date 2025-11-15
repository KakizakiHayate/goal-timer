import '../entities/settings.dart';
import '../repositories/settings_repository.dart';

class SaveSettingsUseCase {
  final SettingsRepository repository;

  SaveSettingsUseCase(this.repository);

  Future<void> execute(Settings settings) {
    return repository.saveSettings(settings);
  }
}
