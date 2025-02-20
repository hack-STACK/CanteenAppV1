class Logger {
  static final Logger _instance = Logger._internal();
  
  factory Logger() {
    return _instance;
  }

  Logger._internal();

  static void info(String message) {
    print('INFO: $message');
  }

  static void debug(String message) {
    print('DEBUG: $message');
  }

  static void error(String message, [StackTrace? stackTrace]) {
    print('ERROR: $message');
    if (stackTrace != null) {
      print(stackTrace);
    }
  }
}
