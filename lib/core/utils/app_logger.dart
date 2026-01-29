import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// アプリケーション全体で使用するロガー
///
/// リリースビルドではログ出力を無効化し、
/// PIIなどの機密情報がログに残らないようにする。
class AppLogger {
  final Logger _logger;

  AppLogger._internal() : _logger = Logger(printer: PrettyPrinter());

  static final AppLogger _instance = AppLogger._internal();

  static AppLogger get instance => _instance;

  void d(dynamic message) {
    if (kDebugMode) {
      _logger.d(message);
    }
  }

  void i(dynamic message) {
    if (kDebugMode) {
      _logger.i(message);
    }
  }

  void w(dynamic message) {
    if (kDebugMode) {
      _logger.w(message);
    }
  }

  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.e(message, error: error, stackTrace: stackTrace);
    }
  }
}
