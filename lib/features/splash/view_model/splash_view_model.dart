import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/local/app_database.dart';
import '../../../core/data/local/local_goals_datasource.dart';
import '../../../core/data/local/local_study_daily_logs_datasource.dart';
import '../../../core/data/local/local_users_datasource.dart';
import '../../../core/data/supabase/supabase_auth_datasource.dart';
import '../../../core/data/supabase/supabase_goals_datasource.dart';
import '../../../core/data/supabase/supabase_study_logs_datasource.dart';
import '../../../core/data/supabase/supabase_users_datasource.dart';
import '../../../core/services/migration_service.dart';
import '../../../core/utils/app_logger.dart';

/// Splash画面の状態
enum SplashStatus {
  /// 初期状態
  initial,

  /// ネットワーク確認中
  checkingNetwork,

  /// オフライン
  offline,

  /// 認証中
  authenticating,

  /// データ移行中
  migrating,

  /// 完了
  completed,

  /// エラー
  error,
}

/// Splash画面のViewModel
class SplashViewModel extends GetxController {
  final Connectivity _connectivity;
  late final SupabaseAuthDatasource _authDatasource;
  late final MigrationService _migrationService;

  SplashViewModel({
    Connectivity? connectivity,
    SupabaseAuthDatasource? authDatasource,
    MigrationService? migrationService,
  }) : _connectivity = connectivity ?? Connectivity() {
    // DataSourceの初期化はinitialize()で行う
  }

  /// 現在の状態
  final _status = SplashStatus.initial.obs;
  SplashStatus get status => _status.value;

  /// エラーメッセージ
  final _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  /// 認証済みユーザーID
  String? _userId;
  String? get userId => _userId;

  /// ネットワーク接続状態
  bool get isOffline => _status.value == SplashStatus.offline;

  /// エラー状態
  bool get hasError => _status.value == SplashStatus.error;

  /// 初期化処理を開始
  Future<void> initialize() async {
    try {
      _status.value = SplashStatus.checkingNetwork;
      update();

      // ネットワーク確認
      final connectivityResult = await _connectivity.checkConnectivity();
      // connectivity_plus 5.x: ConnectivityResult（単一）
      // connectivity_plus 6.x+: List<ConnectivityResult>
      final isOfflineResult = connectivityResult is List
          ? (connectivityResult as List).contains(ConnectivityResult.none)
          : connectivityResult == ConnectivityResult.none;
      if (isOfflineResult) {
        _status.value = SplashStatus.offline;
        update();
        return;
      }

      // DataSourceを初期化
      _initializeDataSources();

      // 匿名認証
      _status.value = SplashStatus.authenticating;
      update();
      await _signInAnonymously();

      // データ移行
      _status.value = SplashStatus.migrating;
      update();
      await _migrateDataIfNeeded();

      // 完了
      _status.value = SplashStatus.completed;
      update();
    } catch (error, stackTrace) {
      AppLogger.instance.e('Splash初期化エラー', error, stackTrace);
      _status.value = SplashStatus.error;
      _errorMessage.value = '初期化に失敗しました。運営にお問い合わせください。';
      update();
    }
  }

  /// DataSourceを初期化
  void _initializeDataSources() {
    final supabase = Supabase.instance.client;
    final appDatabase = Get.find<AppDatabase>();

    _authDatasource = SupabaseAuthDatasource(supabase: supabase);

    _migrationService = MigrationService(
      localGoalsDatasource: LocalGoalsDatasource(database: appDatabase),
      localStudyLogsDatasource:
          LocalStudyDailyLogsDatasource(database: appDatabase),
      localUsersDatasource: LocalUsersDatasource(database: appDatabase),
      supabaseGoalsDatasource: SupabaseGoalsDatasource(supabase: supabase),
      supabaseStudyLogsDatasource:
          SupabaseStudyLogsDatasource(supabase: supabase),
      supabaseUsersDatasource: SupabaseUsersDatasource(supabase: supabase),
    );
  }

  /// 匿名認証を実行
  Future<void> _signInAnonymously() async {
    try {
      // 既存セッションがあるか確認
      final currentUser = _authDatasource.currentUser;
      if (currentUser != null) {
        AppLogger.instance.i('既存セッションを使用: ${currentUser.id}');
        _userId = currentUser.id;
        return;
      }

      // 匿名認証を実行
      final response = await _authDatasource.signInAnonymously();
      _userId = response.user?.id;

      if (_userId == null) {
        throw Exception('匿名認証に失敗しました: ユーザーIDが取得できません');
      }

      AppLogger.instance.i('匿名認証成功: $_userId');
    } catch (error, stackTrace) {
      AppLogger.instance.e('匿名認証に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// データ移行を実行（必要な場合）
  Future<void> _migrateDataIfNeeded() async {
    try {
      if (_userId == null) {
        AppLogger.instance.w('ユーザーIDがないため移行をスキップ');
        return;
      }

      final result = await _migrationService.migrate(_userId!);

      if (result.success) {
        if (result.skipped) {
          AppLogger.instance.i('データ移行: ${result.message}');
        } else {
          AppLogger.instance.i(
            'データ移行成功: 目標${result.goalCount}件、ログ${result.studyLogCount}件',
          );
        }
      } else {
        AppLogger.instance.e('データ移行失敗: ${result.message}');
        throw Exception(result.message);
      }
    } catch (error, stackTrace) {
      AppLogger.instance.e('データ移行に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// オフラインから復帰してリトライ
  Future<void> retryFromOffline() async {
    _status.value = SplashStatus.initial;
    update();
    await initialize();
  }
}
