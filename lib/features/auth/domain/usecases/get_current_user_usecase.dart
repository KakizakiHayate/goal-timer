import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// 現在のユーザーを取得するユースケース
class GetCurrentUserUseCase {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  /// 現在のユーザーを取得
  Future<AppUser?> call() async {
    try {
      return await _repository.getCurrentUser();
    } catch (e) {
      // エラーの場合はnullを返す（ログアウト状態と同様に扱う）
      return null;
    }
  }
}
