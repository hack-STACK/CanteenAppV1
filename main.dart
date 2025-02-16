import 'network_helper.dart';

void fetchData() async {
  const String url =
      'https://hmmahzohkafghtdjbkqi.supabase.co/rest/v1/users?select=id&firebase_uid=eq.w6cwtdphtEMPhqCyPjuvE8nj2QG2';
  NetworkHelper networkHelper = NetworkHelper(url);

  try {
    final response = await networkHelper.getData();
    // Process the response
    print('Data fetched successfully: ${response.body}');
  } catch (e) {
    print('Error fetching data: $e');
  }
}
