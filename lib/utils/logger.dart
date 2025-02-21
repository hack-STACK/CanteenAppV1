import 'package:flutter/foundation.dart';

class Logger {
  final String tag;
  final bool showDebug;

  Logger([this.tag = '', this.showDebug = !kReleaseMode]);

  void debug(String message) {
    if (showDebug) {
      _log('DEBUG', message);
    }
  }

  void info(String message) {
    _log('INFO', message);
  }

  void warn(String message) {
    _log('WARN', message);
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log('ERROR', message);
    if (error != null) {
      _log('ERROR', 'Error details: $error');
    }
    if (stackTrace != null) {
      _log('ERROR', 'Stack trace:\n$stackTrace');
    }
  }

  void _log(String level, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final prefix = tag.isNotEmpty ? '[$tag]' : '';
    print('$timestamp $level$prefix: $message');
  }
}
