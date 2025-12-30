import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// ローカル認証情報を管理するデータソース
abstract class AuthLocalDataSource {
  /// 認証トークンを保存
  Future<void> saveAuthToken(String token);

  /// 認証トークンを取得
  Future<String?> getAuthToken();

  /// 認証トークンを削除
  Future<void> deleteAuthToken();

  /// リフレッシュトークンを保存
  Future<void> saveRefreshToken(String token);

  /// リフレッシュトークンを取得
  Future<String?> getRefreshToken();

  /// リフレッシュトークンを削除
  Future<void> deleteRefreshToken();

  /// ユーザー情報を保存
  Future<void> saveUserInfo(Map<String, dynamic> userInfo);

  /// ユーザー情報を取得
  Future<Map<String, dynamic>?> getUserInfo();

  /// ユーザー情報を削除
  Future<void> deleteUserInfo();

  /// すべての認証データを削除
  Future<void> clearAll();
}

/// ローカル認証データソースの実装
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userInfoKey = 'user_info';

  /// SharedPreferencesインスタンスを取得するヘルパーメソッド
  Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  @override
  Future<void> saveAuthToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_authTokenKey, token);
  }

  @override
  Future<String?> getAuthToken() async {
    final prefs = await _prefs;
    return prefs.getString(_authTokenKey);
  }

  @override
  Future<void> deleteAuthToken() async {
    final prefs = await _prefs;
    await prefs.remove(_authTokenKey);
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_refreshTokenKey, token);
  }

  @override
  Future<String?> getRefreshToken() async {
    final prefs = await _prefs;
    return prefs.getString(_refreshTokenKey);
  }

  @override
  Future<void> deleteRefreshToken() async {
    final prefs = await _prefs;
    await prefs.remove(_refreshTokenKey);
  }

  @override
  Future<void> saveUserInfo(Map<String, dynamic> userInfo) async {
    final prefs = await _prefs;
    final jsonString = jsonEncode(userInfo);
    await prefs.setString(_userInfoKey, jsonString);
  }

  @override
  Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await _prefs;
    final userInfoString = prefs.getString(_userInfoKey);
    if (userInfoString == null) return null;

    try {
      return jsonDecode(userInfoString) as Map<String, dynamic>;
    } catch (e) {
      // JSON解析に失敗した場合はnullを返す
      return null;
    }
  }

  @override
  Future<void> deleteUserInfo() async {
    final prefs = await _prefs;
    await prefs.remove(_userInfoKey);
  }

  @override
  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.remove(_authTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userInfoKey);
  }
}
