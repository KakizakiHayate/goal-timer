import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/local/app_database.dart';
import '../../../core/data/local/local_users_datasource.dart';
import '../../../core/data/supabase/supabase_auth_datasource.dart';
import '../../../core/utils/app_logger.dart';

/// 認証の状態
enum AuthStatus {
  /// 初期状態
  initial,

  /// 処理中
  loading,

  /// 成功
  success,

  /// エラー
  error,
}

/// 認証ViewModel
class AuthViewModel extends GetxController {
  late final SupabaseAuthDatasource _authDatasource;
  late final LocalUsersDatasource _usersDatasource;

  AuthViewModel({
    SupabaseAuthDatasource? authDatasource,
    LocalUsersDatasource? usersDatasource,
  }) {
    _authDatasource = authDatasource ??
        SupabaseAuthDatasource(supabase: Supabase.instance.client);
    _usersDatasource =
        usersDatasource ?? LocalUsersDatasource(database: AppDatabase());
  }

  /// 現在の状態
  final _status = AuthStatus.initial.obs;
  AuthStatus get status => _status.value;

  /// エラーメッセージ
  final _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  /// ユーザーが匿名かどうか
  bool get isAnonymous => _authDatasource.isAnonymous;

  /// 処理中かどうか
  bool get isLoading => _status.value == AuthStatus.loading;

  /// エラーかどうか
  bool get hasError => _status.value == AuthStatus.error;

  /// 連携ボタンを表示するかどうか
  bool get showLinkButton => isAnonymous;

  /// Googleアカウントと連携
  Future<bool> linkWithGoogle() async {
    try {
      _status.value = AuthStatus.loading;
      _errorMessage.value = '';
      update();

      final result = await _authDatasource.linkWithGoogle();

      if (result.success) {
        // displayNameを保存
        await _saveDisplayName(result.displayName);

        _status.value = AuthStatus.success;
        AppLogger.instance.i('Googleアカウント連携成功');
        update();
        return true;
      } else if (result.cancelled) {
        _status.value = AuthStatus.initial;
        AppLogger.instance.w('Googleアカウント連携がキャンセルされました');
        update();
        return false;
      }

      update();
      return false;
    } catch (error, stackTrace) {
      AppLogger.instance.e('Googleアカウント連携に失敗しました', error, stackTrace);
      _status.value = AuthStatus.error;
      _errorMessage.value = 'Googleアカウント連携に失敗しました';
      update();
      return false;
    }
  }

  /// Appleアカウントと連携
  Future<bool> linkWithApple() async {
    try {
      _status.value = AuthStatus.loading;
      _errorMessage.value = '';
      update();

      final result = await _authDatasource.linkWithApple();

      if (result.success) {
        // displayNameを保存
        await _saveDisplayName(result.displayName);

        _status.value = AuthStatus.success;
        AppLogger.instance.i('Appleアカウント連携成功');
        update();
        return true;
      } else if (result.cancelled) {
        _status.value = AuthStatus.initial;
        AppLogger.instance.w('Appleアカウント連携がキャンセルされました');
        update();
        return false;
      }

      update();
      return false;
    } catch (error, stackTrace) {
      AppLogger.instance.e('Appleアカウント連携に失敗しました', error, stackTrace);
      _status.value = AuthStatus.error;
      _errorMessage.value = 'Appleアカウント連携に失敗しました';
      update();
      return false;
    }
  }

  /// エラー状態をクリア
  void clearError() {
    _status.value = AuthStatus.initial;
    _errorMessage.value = '';
    update();
  }

  /// Googleアカウントでログイン（既存アカウント）
  Future<bool> loginWithGoogle() async {
    try {
      _status.value = AuthStatus.loading;
      _errorMessage.value = '';
      update();

      final result = await _authDatasource.signInWithGoogle();

      if (result.success) {
        // displayNameを保存
        await _saveDisplayName(result.displayName);

        _status.value = AuthStatus.success;
        AppLogger.instance.i('Googleログイン成功');
        update();
        return true;
      } else if (result.cancelled) {
        _status.value = AuthStatus.initial;
        AppLogger.instance.w('Googleログインがキャンセルされました');
        update();
        return false;
      }

      update();
      return false;
    } catch (error, stackTrace) {
      AppLogger.instance.e('Googleログインに失敗しました', error, stackTrace);
      _status.value = AuthStatus.error;
      _errorMessage.value = 'ログインに失敗しました。アカウントが存在しない可能性があります。';
      update();
      return false;
    }
  }

  /// Appleアカウントでログイン（既存アカウント）
  Future<bool> loginWithApple() async {
    try {
      _status.value = AuthStatus.loading;
      _errorMessage.value = '';
      update();

      final result = await _authDatasource.signInWithApple();

      if (result.success) {
        // displayNameを保存
        await _saveDisplayName(result.displayName);

        _status.value = AuthStatus.success;
        AppLogger.instance.i('Appleログイン成功');
        update();
        return true;
      } else if (result.cancelled) {
        _status.value = AuthStatus.initial;
        AppLogger.instance.w('Appleログインがキャンセルされました');
        update();
        return false;
      }

      update();
      return false;
    } catch (error, stackTrace) {
      AppLogger.instance.e('Appleログインに失敗しました', error, stackTrace);
      _status.value = AuthStatus.error;
      _errorMessage.value = 'ログインに失敗しました。アカウントが存在しない可能性があります。';
      update();
      return false;
    }
  }

  /// アカウント削除
  Future<bool> deleteAccount() async {
    try {
      _status.value = AuthStatus.loading;
      _errorMessage.value = '';
      update();

      await _authDatasource.deleteAccount();

      // ローカルDBのユーザーデータをリセット
      await _usersDatasource.resetDisplayName();

      _status.value = AuthStatus.success;
      AppLogger.instance.i('アカウント削除成功');
      update();
      return true;
    } catch (error, stackTrace) {
      AppLogger.instance.e('アカウント削除に失敗しました', error, stackTrace);
      _status.value = AuthStatus.error;
      _errorMessage.value = 'アカウント削除に失敗しました';
      update();
      return false;
    }
  }

  /// サインアウト
  Future<void> signOut() async {
    try {
      _status.value = AuthStatus.loading;
      update();

      await _authDatasource.signOut();

      // ローカルDBのユーザーデータをリセット
      await _usersDatasource.resetDisplayName();

      _status.value = AuthStatus.initial;
      AppLogger.instance.i('サインアウト完了');
      update();
    } catch (error, stackTrace) {
      AppLogger.instance.e('サインアウトに失敗しました', error, stackTrace);
      _status.value = AuthStatus.error;
      _errorMessage.value = 'サインアウトに失敗しました';
      update();
    }
  }

  /// displayNameをローカルDBに保存
  Future<void> _saveDisplayName(String? displayName) async {
    if (displayName == null || displayName.isEmpty) {
      AppLogger.instance.i('displayNameが取得できなかったため保存をスキップ');
      return;
    }

    try {
      await _usersDatasource.updateDisplayName(displayName);
      AppLogger.instance.i('displayNameを保存しました: $displayName');
    } catch (error, stackTrace) {
      // displayName保存の失敗はログイン処理全体を失敗させない
      AppLogger.instance.e('displayNameの保存に失敗しました', error, stackTrace);
    }
  }
}
