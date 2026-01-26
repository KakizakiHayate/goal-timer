import 'package:connectivity_plus/connectivity_plus.dart';
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

  /// 完了（ホーム画面へ遷移）
  completedToHome,

  /// 完了（ウェルカム画面へ遷移）
  completedToWelcome,

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
      // connectivity_plus 7.x: List<ConnectivityResult>を返す
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOfflineResult =
          connectivityResult.contains(ConnectivityResult.none) ||
              connectivityResult.isEmpty;
      if (isOfflineResult) {
        _status.value = SplashStatus.offline;
        update();
        return;
      }

      // DataSourceを初期化
      _initializeDataSources();

      // 既存セッションを確認
      _status.value = SplashStatus.authenticating;
      update();

      final hasSession = await _checkExistingSession();

      if (hasSession) {
        // 既存セッションがある場合はデータ移行を実行してホーム画面へ
        _status.value = SplashStatus.migrating;
        update();
        await _migrateDataIfNeeded();

        _status.value = SplashStatus.completedToHome;
        update();
      } else {
        // セッションがない場合はウェルカム画面へ
        _status.value = SplashStatus.completedToWelcome;
        update();
      }
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
      supabaseGoalsDatasource: SupabaseGoalsDatasource(supabase: supabase),
      supabaseStudyLogsDatasource:
          SupabaseStudyLogsDatasource(supabase: supabase),
    );
  }

  /// 既存セッションを確認
  ///
  /// セッションがある場合はtrueを返し、_userIdを設定
  /// セッションがない場合はfalseを返す
  Future<bool> _checkExistingSession() async {
    try {
      // 既存セッションがあるか確認
      final currentUser = _authDatasource.currentUser;
      if (currentUser != null) {
        AppLogger.instance.i('既存セッションを使用: ${currentUser.id}');
        _userId = currentUser.id;
        return true;
      }

      AppLogger.instance.i('セッションなし: ウェルカム画面へ遷移');
      return false;
    } catch (error, stackTrace) {
      AppLogger.instance.e('セッション確認に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// データ移行を実行（必要な場合）
  /// 移行失敗時も例外をthrowせず、ローカルデータで継続使用可能にする
  Future<void> _migrateDataIfNeeded() async {
    try {
      final userId = _userId;
      if (userId == null) {
        AppLogger.instance.w('ユーザーIDがないため移行をスキップ');
        return;
      }

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

  /// オフラインから復帰してリトライ
  Future<void> retryFromOffline() async {
    _status.value = SplashStatus.initial;
    update();
    await initialize();
  }
}
