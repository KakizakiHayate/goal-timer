import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';

/// 環境変数へのアクセスを提供するクラス
class EnvConfig {
  /// Supabase URLを取得
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  /// Supabase Anon Keyを取得
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// アプリケーション環境を取得
  static String get appEnv => dotenv.env['APP_ENV'] ?? 'development';

  /// デバッグモードかどうかを取得
  static bool get isDebugMode =>
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';

  /// 開発環境かどうかを確認
  static bool get isDevelopment => appEnv == 'development';

  /// 本番環境かどうかを確認
  static bool get isProduction => appEnv == 'production';

  /// iOS版RevenueCatのAPIキー
  static String get revenueCatApplePublicApiKey => dotenv.env['REVENUECAT_APPLE_PUBLIC_API_KEY'] ?? '';

  /// デバイス固有のIDを取得（未設定の場合は新規生成）
  static String get deviceId {
    final storedId = dotenv.env['LOCAL_DEVICE_ID'];
    if (storedId != null && storedId.isNotEmpty) {
      return storedId;
    }
    // 未設定の場合はUUIDを生成
    return const Uuid().v4();
  }

  /// 環境変数が正しく設定されているかを確認
  static bool validateSupabaseConfig() {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }
}
