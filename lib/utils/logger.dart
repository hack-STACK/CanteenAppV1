import 'package:flutter/foundation.dart';

class Logger {
  final String tag;
  final bool showDebug;

  Logger([this.tag = '', this.showDebug = !kReleaseMode]);

  void debug(String message) {
    if (!kReleaseMode) debugPrint('DEBUG: $message');
  }

  void info(String message) {
    if (!kReleaseMode) debugPrint('INFO: $message');
  }

  void warn(String message) {
    _log('WARN', message);
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!kReleaseMode) {
      debugPrint('ERROR: $message');
      if (error != null) debugPrint('Error details: $error');
      if (stackTrace != null) debugPrint('Stack trace: $stackTrace');
    }
  }

  void _log(String level, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final prefix = tag.isNotEmpty ? '[$tag]' : '';
    print('$timestamp $level$prefix: $message');
  }
}
