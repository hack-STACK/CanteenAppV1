class AppConstants {
  static const bool isDebugMode = false;
  static const int requestTimeout = 30; // seconds
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}