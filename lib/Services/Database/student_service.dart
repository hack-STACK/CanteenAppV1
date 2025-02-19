// import 'package:kantin/Models/student_models.dart';

// class StudentService {
//   Future<List<StudentModel>> getStudentsByUserId(int userId) async {
//     try {
//       print('Debug: Fetching students for user ID - $userId'); // Debug print
      
//       final response = await _supabaseClient
//           .from('students')
//           .select()
//           .eq('id_user', userId) // Make sure this matches your database column name
//           .order('id', ascending: true);

//       print('Debug: Students response - $response'); // Debug print

//       return (response as List)
//           .map((studentMap) => StudentModel.fromMap(studentMap))
//           .toList();
//     } catch (e) {
//       print('Debug: Error getting students by user ID - $e'); // Debug print
//       throw Exception('Failed to fetch students: $e');
//     }
//   }
// }