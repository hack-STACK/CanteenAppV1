import 'dart:io';
import 'package:http/http.dart' as http;

class NetworkHelper {
  final String url;

  NetworkHelper(this.url);

  Future<http.Response> getData() async {
    int retryCount = 3;
    while (retryCount > 0) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          return response;
        } else {
          throw Exception('Failed to load data');
        }
      } on SocketException catch (e) {
        retryCount--;
        if (retryCount == 0) {
          throw Exception('Network error: $e');
        }
      }
    }
    throw Exception('Failed to load data after retries');
  }
}
