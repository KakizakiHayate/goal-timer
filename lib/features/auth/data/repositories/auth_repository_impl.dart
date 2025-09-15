import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// 認証リポジトリの実装
class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource _localDataSource;
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._localDataSource, this._remoteDataSource);

  @override
  Stream<AppUser?> get authStateChanges {
    return _remoteDataSource.authStateChanges;
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    try {
      return await _remoteDataSource.getCurrentUser();
    } catch (e) {
      // リモートでエラーが発生した場合はローカルから取得を試みる
      try {
        final userInfo = await _localDataSource.getUserInfo();
        if (userInfo != null) {
          return AppUser.fromJson(userInfo);
        }
        return null;
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    try {
      final user = await _remoteDataSource.signInWithEmail(email, password);

      // ローカルにユーザー情報を保存
      await _localDataSource.saveUserInfo(user.toJson());

      return user;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AppUser> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final user = await _remoteDataSource.signUpWithEmail(
        email,
        password,
        displayName,
      );

      // ローカルにユーザー情報を保存
      await _localDataSource.saveUserInfo(user.toJson());

      return user;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      final user = await _remoteDataSource.signInWithGoogle();

      // ローカルにユーザー情報を保存
      await _localDataSource.saveUserInfo(user.toJson());

      return user;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AppUser> signInWithApple() async {
    try {
      final user = await _remoteDataSource.signInWithApple();

      // ローカルにユーザー情報を保存
      await _localDataSource.saveUserInfo(user.toJson());

      return user;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _remoteDataSource.signOut();
    } finally {
      // エラーが発生してもローカルデータはクリア
      await _localDataSource.clearAll();
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    return await _remoteDataSource.sendPasswordResetEmail(email);
  }

  @override
  Future<void> sendEmailVerification() async {
    return await _remoteDataSource.sendEmailVerification();
  }

  @override
  Future<bool> isEmailVerified() async {
    return await _remoteDataSource.isEmailVerified();
  }

  @override
  Future<AppUser> updateUserInfo(Map<String, dynamic> updates) async {
    try {
      final updatedUser = await _remoteDataSource.updateUserMetadata(updates);

      // ローカルにも保存
      await _localDataSource.saveUserInfo(updatedUser.toJson());

      return updatedUser;
    } catch (e) {
      rethrow;
    }
  }
}
