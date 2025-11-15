import '../repositories/auth_repository.dart';

/// サインアウトするユースケース
class SignOutUseCase {
  final AuthRepository _repository;

  SignOutUseCase(this._repository);

  /// サインアウト実行
  Future<void> call() async {
    try {
      await _repository.signOut();
    } catch (e) {
      throw Exception('サインアウトに失敗しました: ${e.toString()}');
    }
  }
}
