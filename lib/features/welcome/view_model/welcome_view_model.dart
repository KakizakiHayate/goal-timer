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
      await _migrateDataIfNeeded(userId);

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
    try {
      final result = await _migrationService.migrate(userId);

      if (result.migrationFailed) {
        // 移行失敗時もログのみ、例外はthrowしない
        AppLogger.instance.w(
          'データ移行に失敗しましたが、ローカルデータで継続します: ${result.message}',
        );
      } else if (result.skipped) {
        AppLogger.instance.i('データ移行: ${result.message}');
      } else {
        AppLogger.instance.i(
          'データ移行成功: 目標${result.goalCount}件、ログ${result.studyLogCount}件',
        );
      }
      // 例外をthrowしない。常にホーム画面へ遷移
    } catch (error, stackTrace) {
      // 予期せぬエラーの場合もログのみ
      AppLogger.instance.e('データ移行で予期せぬエラー', error, stackTrace);
      // rethrowしない → ホーム画面へ遷移を継続
    }
  }
}
