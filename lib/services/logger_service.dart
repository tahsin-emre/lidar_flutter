import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();

  factory LoggerService() {
    return _instance;
  }

  LoggerService._internal();

  final bool _enableConsoleOutput = kDebugMode;
  LogLevel _currentLevel = LogLevel.debug;

  void setLogLevel(LogLevel level) {
    _currentLevel = level;
  }

  void debug(String message, {String tag = 'DEBUG'}) {
    if (_currentLevel.index <= LogLevel.debug.index) {
      _log(message, tag: tag);
    }
  }

  void info(String message, {String tag = 'INFO'}) {
    if (_currentLevel.index <= LogLevel.info.index) {
      _log(message, tag: tag);
    }
  }

  void warning(String message, {String tag = 'WARNING'}) {
    if (_currentLevel.index <= LogLevel.warning.index) {
      _log(message, tag: tag);
    }
  }

  void error(String message,
      {String tag = 'ERROR', Object? exception, StackTrace? stackTrace}) {
    if (_currentLevel.index <= LogLevel.error.index) {
      _log(message, tag: tag);
      if (exception != null) {
        _log('Exception: $exception', tag: tag);
      }
      if (stackTrace != null) {
        _log('StackTrace: $stackTrace', tag: tag);
      }
    }
  }

  void _log(String message, {required String tag}) {
    final String timestamp = DateTime.now().toIso8601String();
    final String formattedMessage = '[$timestamp] [$tag] $message';

    if (_enableConsoleOutput) {
      print(formattedMessage);
    }

    // Burada ileride dosyaya yazma, servis gönderme gibi işlemler eklenebilir
  }
}

final logger = LoggerService();
