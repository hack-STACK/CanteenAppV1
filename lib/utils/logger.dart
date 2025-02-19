class Logger {
  static bool _isDebug = true;

  static void d(String tag, String message) {
    if (_isDebug) {
      print('DEBUG [$tag]: $message');
    }
  }

  static void e(String tag, String message,
      [dynamic error, StackTrace? stack]) {
    print('ERROR [$tag]: $message');
    if (error != null) {
      print('Error details: $error');
    }
    if (stack != null) {
      print('Stack trace: $stack');
    }
  }
}
