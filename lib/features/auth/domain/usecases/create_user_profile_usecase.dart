import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/models/users/users_model.dart';
import '../../../../core/data/repositories/users/users_repository.dart';
import '../../../../core/data/datasources/local/users/local_users_datasource.dart';
import '../../../../core/data/datasources/supabase/users/supabase_users_datasource.dart';
import '../../../../core/provider/sync_state_provider.dart';
import '../../../../core/utils/app_logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 新規ユーザー登録時にプロファイルを作成するユースケース
class CreateUserProfileUseCase {
  final AuthRepository _authRepository;
  final UsersRepository _usersRepository;
  final LocalUsersDatasource _localDatasource;
  final SupabaseUsersDatasource _remoteDatasource;
  final SyncStateNotifier _syncNotifier;

  CreateUserProfileUseCase(
    this._authRepository,
    this._usersRepository,
    this._localDatasource,
    this._remoteDatasource,
    this._syncNotifier,
  );

  /// 認証されたユーザーのプロファイルを作成（メインスレッド非同期版）
  Future<UsersModel> execute(AppUser authUser) async {
    try {
      AppLogger.instance.i(
        'ユーザープロファイル作成を開始: ID=${authUser.id}, Email=${authUser.email}',
      );

      final now = DateTime.now();

      // displayNameが空の場合のフォールバック処理
      String displayName = authUser.displayName ?? '';
      if (displayName.isEmpty) {
        // メールアドレスの@より前の部分をデフォルト名として使用
        displayName = authUser.email.split('@').first;

        // Supabase Authのメタデータも更新
        await _authRepository.updateUserInfo({'display_name': displayName});

        AppLogger.instance.i('空のdisplayNameをデフォルト値で更新: $displayName');
      }

      final userProfile = UsersModel(
        id: authUser.id,
        email: authUser.email,
        displayName: displayName, // 改善された値を使用
        createdAt: now,
        updatedAt: now,
        lastLogin: now,
      );

      AppLogger.instance.d('ユーザープロファイルデータ: ${userProfile.toString()}');

      // 1. 重要な処理を順次実行（メインスレッド）
      final localResult = await _localDatasource.upsertUser(userProfile);
      AppLogger.instance.i('ローカルプロファイル作成完了: ID=${localResult.id}');

      // 2. Supabase usersテーブルをメインスレッドで非同期保存
      await _saveToSupabaseUsersAsync(userProfile);

      return localResult;
    } catch (e, stackTrace) {
      AppLogger.instance.e('ユーザープロファイル作成エラー: ID=${authUser.id}', e, stackTrace);
      rethrow;
    }
  }

  /// Supabase usersテーブルにメインスレッドで非同期保存
  Future<void> _saveToSupabaseUsersAsync(UsersModel userProfile) async {
    try {
      AppLogger.instance.i('Supabase users非同期保存開始: ID=${userProfile.id}');

      // ネットワーク接続確認
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        AppLogger.instance.w('オフライン状態のため、Supabase users保存をスキップ');
        // オフライン時は未同期として記録
        _syncNotifier.setUnsynced();
        return;
      }

      // Supabase usersテーブルに直接保存
      await _remoteDatasource.createUser(userProfile);
      AppLogger.instance.i('Supabase users非同期保存完了: ID=${userProfile.id}');

      // ローカルの同期済みフラグを更新
      await _localDatasource.markAsSynced(userProfile.id);
    } catch (e, stackTrace) {
      AppLogger.instance.e(
        'Supabase users非同期保存エラー: ID=${userProfile.id}',
        e,
        stackTrace,
      );
      // エラーが発生した場合は未同期として記録
      _syncNotifier.setUnsynced();
      AppLogger.instance.i('未同期として記録、後で同期処理により再試行されます');
      // エラーをログに記録するが、メイン処理は継続
    }
  }

  /// プロファイルが既に存在するかチェック
  Future<bool> profileExists(String userId) async {
    try {
      final profile = await _usersRepository.getUserById(userId);
      return profile != null;
    } catch (e) {
      return false;
    }
  }

  /// プロファイルを取得または作成
  Future<UsersModel> getOrCreateProfile(AppUser authUser) async {
    try {
      AppLogger.instance.d('プロファイル存在チェック開始: ID=${authUser.id}');

      // 既存のプロファイルを確認
      final existingProfile = await _usersRepository.getUserById(authUser.id);
      if (existingProfile != null) {
        AppLogger.instance.i('既存プロファイルを発見: ID=${existingProfile.id}');
        return existingProfile;
      }

      AppLogger.instance.i('プロファイルが存在しないため新規作成します: ID=${authUser.id}');
      // プロファイルが存在しない場合は作成
      return await execute(authUser);
    } catch (e, stackTrace) {
      AppLogger.instance.e(
        'プロファイルの取得または作成に失敗: ID=${authUser.id}',
        e,
        stackTrace,
      );
      throw Exception('プロファイルの取得または作成に失敗しました: ${e.toString()}');
    }
  }
}
