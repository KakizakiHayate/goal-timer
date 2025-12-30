import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// メールアドレスとパスワードでログインするユースケース
class SignInWithEmailUseCase {
  final AuthRepository _repository;

  SignInWithEmailUseCase(this._repository);

  /// メールアドレスとパスワードでログイン実行
  Future<AppUser> call(String email, String password) async {
    // バリデーション
    if (email.trim().isEmpty) {
      throw Exception('メールアドレスを入力してください');
    }

    if (password.trim().isEmpty) {
      throw Exception('パスワードを入力してください');
    }

    if (!_isValidEmail(email)) {
      throw Exception('正しいメールアドレスを入力してください');
    }

    if (password.length < 6) {
      throw Exception('パスワードは6文字以上で入力してください');
    }

    try {
      return await _repository.signInWithEmail(email.trim(), password);
    } catch (e) {
      throw Exception('ログインに失敗しました: ${e.toString()}');
    }
  }

  /// メールアドレスの形式チェック
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }
}
