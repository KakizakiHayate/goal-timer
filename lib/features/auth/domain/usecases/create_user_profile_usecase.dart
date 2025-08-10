import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/models/users/users_model.dart';
import '../../../../core/data/repositories/users/users_repository.dart';
import '../../../../core/utils/app_logger.dart';

/// 新規ユーザー登録時にプロファイルを作成するユースケース
class CreateUserProfileUseCase {
  final UsersRepository _usersRepository;

  CreateUserProfileUseCase(
    AuthRepository authRepository,
    this._usersRepository,
  );

  /// 認証されたユーザーのプロファイルを作成
  Future<UsersModel> execute(AppUser authUser) async {
    try {
      AppLogger.instance.i('ユーザープロファイル作成を開始: ID=${authUser.id}, Email=${authUser.email}');
      
      final now = DateTime.now();

      final userProfile = UsersModel(
        id: authUser.id,
        email: authUser.email,
        displayName: authUser.displayName ?? '',
        createdAt: now,
        updatedAt: now,
        lastLogin: now,
      );

      AppLogger.instance.d('ユーザープロファイルデータ: ${userProfile.toString()}');

      // Supabaseのusersテーブルにプロファイルを作成
      final result = await _usersRepository.createUser(userProfile);
      
      AppLogger.instance.i('ユーザープロファイル作成完了: ID=${result.id}');
      return result;
    } catch (e, stackTrace) {
      AppLogger.instance.e('ユーザープロファイル作成エラー: ID=${authUser.id}', e, stackTrace);
      rethrow;
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
      AppLogger.instance.e('プロファイルの取得または作成に失敗: ID=${authUser.id}', e, stackTrace);
      throw Exception('プロファイルの取得または作成に失敗しました: ${e.toString()}');
    }
  }
}
