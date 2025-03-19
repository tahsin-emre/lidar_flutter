import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final logger = Logger('LidarFlutter');

void initLogger() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    }
    if (record.error != null) {
      if (kDebugMode) {
        print('Error: ${record.error}');
      }
    }
  });
}

extension LoggerExtension on Logger {
  void debug(String message, {String? tag}) {
    fine('${tag != null ? '[$tag] ' : ''}$message');
  }

  void logInfo(String message, {String? tag}) {
    Level.INFO.value;
    log(Level.INFO, '${tag != null ? '[$tag] ' : ''}$message');
  }

  void logWarning(String message, {String? tag}) {
    log(Level.WARNING, '${tag != null ? '[$tag] ' : ''}$message');
  }

  void logError(String message, {String? tag, Object? exception}) {
    log(Level.SEVERE, '${tag != null ? '[$tag] ' : ''}$message');
    if (exception != null) {
      log(Level.SEVERE, 'Exception: $exception');
    }
  }
}
