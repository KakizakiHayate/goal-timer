import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/local/app_database.dart';
import '../../../core/data/local/local_goals_datasource.dart';
import '../../../core/data/local/local_study_daily_logs_datasource.dart';
import '../../../core/data/supabase/supabase_auth_datasource.dart';
import '../../../core/data/supabase/supabase_goals_datasource.dart';
import '../../../core/data/supabase/supabase_study_logs_datasource.dart';
import '../../../core/services/migration_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../home/view/home_screen.dart';

/// ウェルカム画面のViewModel
class WelcomeViewModel extends GetxController {
  late final SupabaseAuthDatasource _authDatasource;
  late final MigrationService _migrationService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  @override
  void onInit() {
    super.onInit();
    _initializeDataSources();
  }

  void _initializeDataSources() {
    final supabase = Supabase.instance.client;
    final appDatabase = Get.find<AppDatabase>();

    _authDatasource = SupabaseAuthDatasource(supabase: supabase);

    _migrationService = MigrationService(
      localGoalsDatasource: LocalGoalsDatasource(database: appDatabase),
      localStudyLogsDatasource:
          LocalStudyDailyLogsDatasource(database: appDatabase),
      supabaseGoalsDatasource: SupabaseGoalsDatasource(supabase: supabase),
      supabaseStudyLogsDatasource:
          SupabaseStudyLogsDatasource(supabase: supabase),
    );
  }

  /// ゲストとして開始（匿名ログイン）
  Future<void> startAsGuest() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _errorMessage = null;
      update();

      AppLogger.instance.i('ゲストとして開始します');

      // 匿名認証を実行
      final response = await _authDatasource.signInAnonymously();
      final userId = response.user?.id;

      if (userId == null) {
        throw Exception('匿名認証に失敗しました: ユーザーIDが取得できません');
      }

      AppLogger.instance.i('匿名認証成功: $userId');

      // データ移行を実行
      AppLogger.instance.d('[WelcomeVM] _migrateDataIfNeeded 開始');
      await _migrateDataIfNeeded(userId);
      AppLogger.instance.d('[WelcomeVM] _migrateDataIfNeeded 完了');

      // 移行フラグの確認（デバッグ用）
      final isMigratedNow = await _migrationService.isMigrated();
      AppLogger.instance.d('[WelcomeVM] 遷移前 isMigrated=$isMigratedNow');

      // ホーム画面へ遷移
      Get.offAll(() => const HomeScreen());
    } catch (error, stackTrace) {
      AppLogger.instance.e('ゲスト開始に失敗しました', error, stackTrace);
      _errorMessage = '開始に失敗しました。しばらくしてからお試しください。';
      update();
    } finally {
      _isLoading = false;
      update();
    }
  }

  /// データ移行を実行（必要な場合）
  /// 移行失敗時も例外をthrowせず、ローカルデータで継続使用可能にする
  Future<void> _migrateDataIfNeeded(String userId) async {
    await _migrationService.migrateAndLogResult(userId);
  }
}
