import '../entities/app_user.dart';

/// 認証リポジトリのインターフェース
abstract class AuthRepository {
  /// 認証状態の変更を監視
  Stream<AppUser?> get authStateChanges;

  /// 現在のユーザーを取得
  Future<AppUser?> getCurrentUser();

  /// メールアドレスとパスワードでログイン
  Future<AppUser> signInWithEmail(String email, String password);

  /// メールアドレスとパスワードでサインアップ
  Future<AppUser> signUpWithEmail(
    String email,
    String password,
    String displayName,
  );

  /// Googleアカウントでログイン
  Future<AppUser> signInWithGoogle();

  /// Appleアカウントでログイン
  Future<AppUser> signInWithApple();

  /// サインアウト
  Future<void> signOut();

  /// パスワードリセットメールを送信
  Future<void> sendPasswordResetEmail(String email);

  /// メール確認を送信
  Future<void> sendEmailVerification();

  /// メールが確認済みかチェック
  Future<bool> isEmailVerified();
}
