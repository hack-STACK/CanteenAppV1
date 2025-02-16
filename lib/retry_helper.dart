import 'dart:async';

Future<T> retry<T>(
  Future<T> Function() action, {
  int retries = 5, // Increase the number of retries
  Duration delay =
      const Duration(seconds: 3), // Increase the delay between retries
}) async {
  for (int attempt = 0; attempt < retries; attempt++) {
    try {
      return await action();
    } catch (e) {
      print('Attempt ${attempt + 1} failed: $e');
      if (attempt == retries - 1) rethrow;
      await Future.delayed(delay);
    }
  }
  throw Exception('Failed after $retries attempts');
}
