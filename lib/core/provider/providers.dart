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
import 'package:goal_timer/core/usecases/goals/create_goal_usecase.dart';
import 'package:goal_timer/core/usecases/goals/update_goal_usecase.dart';
import 'package:goal_timer/core/usecases/goals/delete_goal_usecase.dart';

// SyncCheckerのインポート
import 'package:goal_timer/core/services/sync_checker.dart';

// 認証関連のインポートを追加
import 'package:goal_timer/features/auth/domain/entities/app_user.dart';
import 'package:goal_timer/features/auth/domain/entities/auth_state.dart'
    as app_auth;
import 'package:goal_timer/features/auth/provider/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ProviderScopeでアプリをラップするために使用するプロバイダーコンテナ
final counterStateProvider = StateProvider<int>((ref) => 0);

// Supabase初期化プロバイダー
final supabaseInitProvider = FutureProvider<void>((ref) async {
  try {
    // Supabaseの初期化状態をチェック
    try {
      // すでに初期化されているか確認
      Supabase.instance.client;
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
    rethrow;
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

/// 目標作成UseCaseプロバイダー
final createGoalUseCaseProvider = Provider<CreateGoalUseCase>((ref) {
  final repository = ref.watch(hybridGoalsRepositoryProvider);
  return CreateGoalUseCase(repository);
});

/// 目標更新UseCaseプロバイダー
final updateGoalUseCaseProvider = Provider<UpdateGoalUseCase>((ref) {
  final repository = ref.watch(hybridGoalsRepositoryProvider);
  return UpdateGoalUseCase(repository);
});

/// 目標削除UseCaseプロバイダー
final deleteGoalUseCaseProvider = Provider<DeleteGoalUseCase>((ref) {
  final repository = ref.watch(hybridGoalsRepositoryProvider);
  return DeleteGoalUseCase(repository);
});

// ===== SyncCheckerプロバイダー =====

/// 同期チェッカープロバイダー
final syncCheckerProvider = Provider<SyncChecker>((ref) {
  final goalsRepository = ref.watch(hybridGoalsRepositoryProvider);
  final usersRepository = ref.watch(hybridUsersRepositoryProvider);
  final dailyStudyLogsRepository = ref.watch(hybridDailyStudyLogsRepositoryProvider);
  final syncNotifier = ref.watch(syncStateProvider.notifier);

  return SyncChecker(
    goalsRepository: goalsRepository,
    usersRepository: usersRepository,
    dailyStudyLogsRepository: dailyStudyLogsRepository,
    syncNotifier: syncNotifier,
  );
});

// ===== 認証統合プロバイダー =====

/// グローバル認証状態プロバイダー（他のmoduleから参照する用）
final globalAuthStateProvider = Provider<app_auth.AuthState>((ref) {
  return ref.watch(authViewModelProvider);
});

/// グローバル現在ユーザープロバイダー（他のmoduleから参照する用）
final globalCurrentUserProvider = Provider<AppUser?>((ref) {
  final authViewModel = ref.watch(authViewModelProvider.notifier);
  return authViewModel.currentUser;
});

/// 認証状態の変更ストリームプロバイダー
final authStateStreamProvider = StreamProvider<AppUser?>((ref) {
  final authRemoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return authRemoteDataSource.authStateChanges;
});

/// 認証初期化プロバイダー（Supabase + SharedPreferences両方の初期化を待つ）
final authInitializationProvider = FutureProvider<void>((ref) async {
  // Supabaseの初期化を待つ
  await ref.watch(supabaseInitProvider.future);

  // SharedPreferencesの初期化を待つ
  await ref.watch(sharedPreferencesProvider.future);

  // 認証ViewModelの初期化
  final authViewModel = ref.watch(authViewModelProvider.notifier);
  await authViewModel.initialize();
});

/// 認証が完全に初期化されているかの状態プロバイダー
final authReadyProvider = StateProvider<bool>((ref) {
  final initAsyncValue = ref.watch(authInitializationProvider);
  return initAsyncValue.when(
    data: (_) => true,
    loading: () => false,
    error: (_, __) => false,
  );
});

// SharedPreferencesのプロバイダー
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});

// SharedPreferencesの初期化状態プロバイダー
final sharedPreferencesInitializedProvider = StateProvider<bool>((ref) {
  final asyncValue = ref.watch(sharedPreferencesProvider);
  return asyncValue.when(
    data: (_) => true,
    loading: () => false,
    error: (_, __) => false,
  );
});
