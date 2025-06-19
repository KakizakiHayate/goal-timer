import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/models/users/users_model.dart';
import '../../../../core/data/repositories/users/users_repository.dart';

/// 新規ユーザー登録時にプロファイルを作成するユースケース
class CreateUserProfileUseCase {
  final UsersRepository _usersRepository;

  CreateUserProfileUseCase(
    AuthRepository authRepository,
    this._usersRepository,
  );

  /// 認証されたユーザーのプロファイルを作成
  Future<UsersModel> execute(AppUser authUser) async {
    final now = DateTime.now();

    final userProfile = UsersModel(
      id: authUser.id,
      email: authUser.email,
      displayName: authUser.displayName ?? '',
      createdAt: now,
      updatedAt: now,
      lastLogin: now,
    );

    // Supabaseのusersテーブルにプロファイルを作成
    return await _usersRepository.createUser(userProfile);
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
      // 既存のプロファイルを確認
      final existingProfile = await _usersRepository.getUserById(authUser.id);
      if (existingProfile != null) {
        return existingProfile;
      }

      // プロファイルが存在しない場合は作成
      return await execute(authUser);
    } catch (e) {
      throw Exception('プロファイルの取得または作成に失敗しました: ${e.toString()}');
    }
  }
}
