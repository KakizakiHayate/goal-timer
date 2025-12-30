import 'package:shared_preferences/shared_preferences.dart';
import 'package:goal_timer/backup/core/services/data_migration_service.dart';
import 'package:goal_timer/backup/core/utils/app_logger.dart';

/// Service for managing temporary user data during onboarding
class TempUserService {
  static const String _tempUserIdKey = 'temp_user_id';
  static const String _tempUserCreatedAtKey = 'temp_user_created_at';
  static const String _tempOnboardingStepKey = 'temp_onboarding_step';
  static const int _expirationDays = 7;

  /// Generate a new temporary user ID and store it
  Future<String> generateTempUserId() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempUserId = 'local_user_temp_$timestamp';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tempUserIdKey, tempUserId);
    await prefs.setInt(_tempUserCreatedAtKey, timestamp);

    return tempUserId;
  }

  /// Get the current temporary user ID
  Future<String?> getTempUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tempUserIdKey);
  }

  /// Check if the temporary user data has expired (older than 7 days)
  Future<bool> isTempUserExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final createdAt = prefs.getInt(_tempUserCreatedAtKey);

    if (createdAt == null) {
      return false; // No temp user exists
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final expirationTime = createdAt + (_expirationDays * 24 * 60 * 60 * 1000);

    return now > expirationTime;
  }

  /// Delete all temporary user data
  Future<void> deleteTempUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tempUserIdKey);
    await prefs.remove(_tempUserCreatedAtKey);
    await prefs.remove(_tempOnboardingStepKey);
  }

  /// Update the current onboarding step
  Future<void> updateOnboardingStep(int step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tempOnboardingStepKey, step);
  }

  /// Get the current onboarding step
  Future<int> getOnboardingStep() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_tempOnboardingStepKey) ?? 0;
  }

  /// Check if temporary user exists and is valid
  Future<bool> hasTempUser() async {
    final tempUserId = await getTempUserId();
    if (tempUserId == null) return false;

    final isExpired = await isTempUserExpired();
    return !isExpired;
  }

  /// Get creation timestamp of temp user
  Future<int?> getTempUserCreatedAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_tempUserCreatedAtKey);
  }

  /// Validate temp user ID format
  bool validateTempUserId(String? userId) {
    if (userId == null || userId.isEmpty) return false;
    return userId.startsWith('local_user_temp_') && userId.length > 18;
  }

  /// Delete all temporary user data and associated records
  /// This method combines deleteTempUserData with database cleanup
  Future<void> clearAllData() async {
    try {
      final tempUserId = await getTempUserId();

      if (tempUserId != null) {
        // ✅ Providerを使わず、直接DataMigrationServiceをインスタンス化
        final migrationService = DataMigrationService();
        final success = await migrationService.cleanupTempData(tempUserId);

        if (!success) {
          AppLogger.instance.w('DataMigrationService.cleanupTempDataが失敗しました');
        }
      }

      // Clear SharedPreferences data
      await deleteTempUserData();
    } catch (e, stackTrace) {
      // Log error but don't throw to ensure UI remains functional
      AppLogger.instance.e('一時ユーザーデータの削除中にエラーが発生しました', e, stackTrace);
      // Still attempt to clear SharedPreferences as fallback
      await deleteTempUserData();
    }
  }
}
