class Logger {
  static final Logger _instance = Logger._internal();

  factory Logger() {
    return _instance;
  }

  Logger._internal();

  // Log levels
  static const int ERROR = 0;
  static const int WARN = 1;
  static const int INFO = 2;
  static const int DEBUG = 3;

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log('ERROR', message, error, stackTrace);
  }

  void warn(String message, [dynamic error]) {
    _log('WARN', message, error);
  }

  void info(String message) {
    _log('INFO', message);
  }

  void debug(String message) {
    _log('DEBUG', message);
  }

  void _log(String level, String message,
      [dynamic error, StackTrace? stackTrace]) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] $level: $message');
    if (error != null) {
      print('Error details: $error');
    }
    if (stackTrace != null) {
      print('Stack trace:\n$stackTrace');
    }
  }
}
