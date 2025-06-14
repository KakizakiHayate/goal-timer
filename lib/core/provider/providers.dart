import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/config/env_config.dart';
import 'package:goal_timer/core/data/datasources/local/goals/local_goals_datasource.dart';
import 'package:goal_timer/core/data/datasources/supabase/goals/supabase_goals_datasource.dart';
import 'package:goal_timer/core/data/datasources/supabase/supabase_datasource.dart';
import 'package:goal_timer/core/data/repositories/goals/goals_repository.dart';
import 'package:goal_timer/core/data/repositories/hybrid/goals/hybrid_goals_repository.dart';
import 'package:goal_timer/core/data/repositories/supabase/goals/goals_repository_impl.dart';
import 'package:goal_timer/core/provider/sync_state_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

// 新しく追加したクラスのインポート
import 'package:goal_timer/core/data/datasources/local/users/local_users_datasource.dart';
import 'package:goal_timer/core/data/datasources/supabase/users/supabase_users_datasource.dart';
import 'package:goal_timer/core/data/repositories/hybrid/users/hybrid_users_repository.dart';
import 'package:goal_timer/core/data/datasources/local/daily_study_logs/local_daily_study_logs_datasource.dart';
import 'package:goal_timer/core/data/datasources/supabase/daily_study_logs/supabase_daily_study_logs_datasource.dart';
import 'package:goal_timer/core/data/repositories/hybrid/daily_study_logs/hybrid_daily_study_logs_repository.dart';

// UseCaseのインポート
import 'package:goal_timer/core/usecases/goals/fetch_goals_usecase.dart';
import 'package:goal_timer/core/usecases/goals/sync_goals_usecase.dart';

// ProviderScopeでアプリをラップするために使用するプロバイダーコンテナ
final counterStateProvider = StateProvider<int>((ref) => 0);

// Supabase初期化プロバイダー
final supabaseInitProvider = FutureProvider<void>((ref) async {
  try {
    // Supabaseの初期化状態をチェック
    try {
      // すでに初期化されているか確認
      final client = Supabase.instance.client;
      AppLogger.instance.i('Supabaseはすでに初期化されています');
      return;
    } catch (e) {
      // 初期化されていない場合は初期化
      AppLogger.instance.i('Supabaseを初期化します...');
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
      );
      AppLogger.instance.i('Supabaseの初期化が完了しました');
    }
  } catch (e) {
    AppLogger.instance.e('Supabase初期化中にエラーが発生しました', e);
    throw e;
  }
});

// Supabase初期化状態プロバイダー
final supabaseInitializedProvider = StateProvider<bool>((ref) {
  final asyncValue = ref.watch(supabaseInitProvider);
  return asyncValue.when(
    data: (_) => true,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Supabaseクライアントのプロバイダー
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  // 初期化を確実に行うために依存関係を明示
  final initialized = ref.watch(supabaseInitializedProvider);
  if (!initialized) {
    throw Exception('Supabaseが初期化されていません');
  }
  return Supabase.instance.client;
});

/// SupabaseのDataSourceプロバイダー
final supabaseDatasourceProvider = Provider<SupabaseDatasource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseDatasource(client: client);
});

/// SupabaseのGoalsRepositoryプロバイダー（リモートのみ）
final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final goalsDatasource = SupabaseGoalsDatasource(client);
  return GoalsRepositoryImpl(goalsDatasource);
});

/// ローカルGoalsDatasourceプロバイダー
final localGoalsDatasourceProvider = Provider<LocalGoalsDatasource>((ref) {
  return LocalGoalsDatasource();
});

/// リモートGoalsDatasourceプロバイダー
final remoteGoalsDatasourceProvider = Provider<SupabaseGoalsDatasource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseGoalsDatasource(client);
});

/// ハイブリッド（ローカル+リモート）GoalsRepositoryプロバイダー
final hybridGoalsRepositoryProvider = Provider<HybridGoalsRepository>((ref) {
  final localDatasource = ref.watch(localGoalsDatasourceProvider);
  final remoteDatasource = ref.watch(remoteGoalsDatasourceProvider);
  final syncNotifier = ref.watch(syncStateProvider.notifier);

  return HybridGoalsRepository(
    localDatasource: localDatasource,
    remoteDatasource: remoteDatasource,
    syncNotifier: syncNotifier,
  );
});

/// ローカルUsersDatasourceプロバイダー
final localUsersDatasourceProvider = Provider<LocalUsersDatasource>((ref) {
  return LocalUsersDatasource();
});

/// リモートUsersDatasourceプロバイダー
final remoteUsersDatasourceProvider = Provider<SupabaseUsersDatasource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseUsersDatasource(client);
});

/// ハイブリッド（ローカル+リモート）UsersRepositoryプロバイダー
final hybridUsersRepositoryProvider = Provider<HybridUsersRepository>((ref) {
  final localDatasource = ref.watch(localUsersDatasourceProvider);
  final remoteDatasource = ref.watch(remoteUsersDatasourceProvider);
  final syncNotifier = ref.watch(syncStateProvider.notifier);

  return HybridUsersRepository(
    localDatasource: localDatasource,
    remoteDatasource: remoteDatasource,
    syncNotifier: syncNotifier,
  );
});

/// ローカルDailyStudyLogsDatasourceプロバイダー
final localDailyStudyLogsDatasourceProvider =
    Provider<LocalDailyStudyLogsDatasource>((ref) {
      return LocalDailyStudyLogsDatasource();
    });

/// リモートDailyStudyLogsDatasourceプロバイダー
final remoteDailyStudyLogsDatasourceProvider =
    Provider<SupabaseDailyStudyLogsDatasource>((ref) {
      final client = ref.watch(supabaseClientProvider);
      return SupabaseDailyStudyLogsDatasource(client);
    });

/// ハイブリッド（ローカル+リモート）DailyStudyLogsRepositoryプロバイダー
final hybridDailyStudyLogsRepositoryProvider =
    Provider<HybridDailyStudyLogsRepository>((ref) {
      final localDatasource = ref.watch(localDailyStudyLogsDatasourceProvider);
      final remoteDatasource = ref.watch(
        remoteDailyStudyLogsDatasourceProvider,
      );
      final syncNotifier = ref.watch(syncStateProvider.notifier);

      return HybridDailyStudyLogsRepository(
        localDatasource: localDatasource,
        remoteDatasource: remoteDatasource,
        syncNotifier: syncNotifier,
      );
    });

// ===== UseCaseプロバイダー =====

/// 目標データ取得UseCaseプロバイダー
final fetchGoalsUseCaseProvider = Provider<FetchGoalsUseCase>((ref) {
  final repository = ref.watch(hybridGoalsRepositoryProvider);
  return FetchGoalsUseCase(repository);
});

/// 目標データ同期UseCaseプロバイダー
final syncGoalsUseCaseProvider = Provider<SyncGoalsUseCase>((ref) {
  final repository = ref.watch(hybridGoalsRepositoryProvider);
  return SyncGoalsUseCase(repository);
});
