import 'dart:ui';

/// ロケール関連のヘルパークラス
/// BuildContextを持たない場所（通知サービスなど）でロケールを取得するために使用
class LocaleHelper {
  LocaleHelper._();

  /// システムロケールを取得
  static Locale get systemLocale => PlatformDispatcher.instance.locale;

  /// システムロケールが日本語かどうかを判定
  static bool get isJapanese => systemLocale.languageCode == 'ja';

  /// システムロケールが英語かどうかを判定
  static bool get isEnglish => systemLocale.languageCode == 'en';
}
