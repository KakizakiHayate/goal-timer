import 'package:logger/logger.dart';

class AppLogger {
  final Logger _logger;

  AppLogger._internal() : _logger = Logger(printer: PrettyPrinter());

  static final AppLogger _instance = AppLogger._internal();

  static AppLogger get instance => _instance;

  void d(dynamic message) => _logger.d(message);
  void i(dynamic message) => _logger.i(message);
  void w(dynamic message) => _logger.w(message);
  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
