import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/models/users/users_model.dart';
import '../../../../core/data/repositories/users/users_repository.dart';
import '../../../../core/data/datasources/supabase/users/supabase_users_datasource.dart';
import '../../../../core/provider/sync_state_provider.dart';
import '../../../../core/utils/app_logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// ユーザー名を更新するユースケース（非同期処理版）
class UpdateUsernameUseCase {
  final AuthRepository _authRepository;
  final UsersRepository _usersRepository;
  final SupabaseUsersDatasource _remoteDatasource;
  final SyncStateNotifier _syncNotifier;

  UpdateUsernameUseCase(
    this._authRepository,
    this._usersRepository,
    this._remoteDatasource,
    this._syncNotifier,
  );

  /// ユーザー名を更新（非同期処理版 - 最適化）
  Future<AppUser> execute(String userId, String newUsername) async {
    try {
      AppLogger.instance.i('ユーザー名更新開始: ID=$userId, 新しい名前=$newUsername');

      // 1. 【必須・即座】ローカル（UsersModel）を更新
      final userProfile = await _usersRepository.getUserById(userId);
      if (userProfile != null) {
        final updatedProfile = userProfile.copyWith(
          displayName: newUsername,
          updatedAt: DateTime.now(),
        );
        await _usersRepository.updateUser(updatedProfile);
        AppLogger.instance.i('UsersModel（ローカル）更新完了');
      }

      // 2. 【必須・即座】Supabase Authのメタデータを更新
      final updatedAuthUser = await _authRepository.updateUserInfo({
        'display_name': newUsername,
      });
      AppLogger.instance.i('Supabase Auth（リモート）更新完了');

      // 3. 【重要・非同期】Supabase usersテーブルをメインスレッドで非同期更新
      if (userProfile != null) {
        final updatedProfile = userProfile.copyWith(
          displayName: newUsername,
          updatedAt: DateTime.now(),
        );
        await _saveToSupabaseUsersAsync(updatedProfile);
      }

      AppLogger.instance.i('ユーザー名更新完了（即座）: $newUsername');
      return updatedAuthUser;
    } catch (e, stackTrace) {
      AppLogger.instance.e('ユーザー名更新エラー: ID=$userId', e, stackTrace);
      rethrow;
    }
  }

  /// Supabase usersテーブルにメインスレッドで非同期保存
  Future<void> _saveToSupabaseUsersAsync(UsersModel userProfile) async {
    try {
      AppLogger.instance.i('Supabase users非同期更新開始: ID=${userProfile.id}');

      // ネットワーク接続確認
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        AppLogger.instance.w('オフライン状態のため、Supabase users更新をスキップ');
        _syncNotifier.setUnsynced();
        return;
      }

      // Supabase usersテーブルに直接保存
      await _remoteDatasource.updateUser(userProfile);
      AppLogger.instance.i('Supabase users非同期更新完了: ID=${userProfile.id}');

      // 同期完了状態に設定
      _syncNotifier.setSynced();
    } catch (e, stackTrace) {
      AppLogger.instance.e(
        'Supabase users非同期更新エラー: ID=${userProfile.id}',
        e,
        stackTrace,
      );
      // エラーが発生した場合は未同期として記録
      _syncNotifier.setUnsynced();
      AppLogger.instance.i('未同期として記録、後で同期処理により再試行されます');
      // エラーをログに記録するが、メイン処理は継続
    }
  }
}
