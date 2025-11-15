import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// メールアドレスとパスワードでサインアップするユースケース
class SignUpWithEmailUseCase {
  final AuthRepository _repository;

  SignUpWithEmailUseCase(this._repository);

  /// メールアドレスとパスワードでサインアップ実行
  Future<AppUser> call(
    String email,
    String password,
    String displayName,
  ) async {
    // バリデーション
    if (email.trim().isEmpty) {
      throw Exception('メールアドレスを入力してください');
    }

    if (password.trim().isEmpty) {
      throw Exception('パスワードを入力してください');
    }

    if (displayName.trim().isEmpty) {
      throw Exception('ユーザー名を入力してください');
    }

    if (!_isValidEmail(email)) {
      throw Exception('正しいメールアドレスを入力してください');
    }

    if (password.length < 6) {
      throw Exception('パスワードは6文字以上で入力してください');
    }

    if (displayName.trim().length < 2) {
      throw Exception('ユーザー名は2文字以上で入力してください');
    }

    try {
      return await _repository.signUpWithEmail(
        email.trim(),
        password,
        displayName.trim(),
      );
    } catch (e) {
      throw Exception('アカウント作成に失敗しました: ${e.toString()}');
    }
  }

  /// メールアドレスの形式チェック
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }
}
