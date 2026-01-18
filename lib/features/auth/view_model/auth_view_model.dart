import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  AuthViewModel({SupabaseAuthDatasource? authDatasource}) {
    _authDatasource = authDatasource ??
        SupabaseAuthDatasource(supabase: Supabase.instance.client);
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

      if (result) {
        _status.value = AuthStatus.success;
        AppLogger.instance.i('Googleアカウント連携成功');
      } else {
        _status.value = AuthStatus.initial;
        AppLogger.instance.w('Googleアカウント連携がキャンセルされました');
      }

      update();
      return result;
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

      if (result) {
        _status.value = AuthStatus.success;
        AppLogger.instance.i('Appleアカウント連携成功');
      } else {
        _status.value = AuthStatus.initial;
        AppLogger.instance.w('Appleアカウント連携がキャンセルされました');
      }

      update();
      return result;
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

  /// サインアウト
  Future<void> signOut() async {
    try {
      _status.value = AuthStatus.loading;
      update();

      await _authDatasource.signOut();

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
}
