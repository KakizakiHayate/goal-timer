import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Googleアカウントでログインするユースケース
class SignInWithGoogleUseCase {
  final AuthRepository _repository;

  SignInWithGoogleUseCase(this._repository);

  /// Googleアカウントでログイン実行
  Future<AppUser> call() async {
    try {
      return await _repository.signInWithGoogle();
    } catch (e) {
      throw Exception('Googleログインに失敗しました: ${e.toString()}');
    }
  }
}
