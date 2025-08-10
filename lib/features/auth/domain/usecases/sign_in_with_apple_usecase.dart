import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Appleアカウントでログインするユースケース
class SignInWithAppleUseCase {
  final AuthRepository _repository;

  SignInWithAppleUseCase(this._repository);

  /// Appleアカウントでログイン実行
  Future<AppUser> call() async {
    try {
      return await _repository.signInWithApple();
    } catch (e) {
      throw Exception('Appleログインに失敗しました: ${e.toString()}');
    }
  }
}
