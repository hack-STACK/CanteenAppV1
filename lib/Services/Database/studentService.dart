import 'dart:io';
import 'package:kantin/Models/student_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentService {
  final _supabaseClient = Supabase.instance.client;

  Future<StudentModel> createStudent(StudentModel newStudent) async {
    try {
      // Validate required fields
      if (newStudent.studentName.isEmpty ||
          newStudent.studentAddress.isEmpty ||
          newStudent.studentPhoneNumber.isEmpty) {
        throw Exception('Student name, address, and phone number are required');
      }

      // Insert student and get the created student data back
      final response = await _supabaseClient
          .from('students')
          .insert(newStudent.toMap())
          .select()
          .maybeSingle();

      // Check if the response is null
      if (response == null) {
        throw Exception('Failed to create student: No response received');
      }

      // Return the created student model
      return StudentModel.fromMap(response);
    } catch (e) {
      print('Error creating student: $e');
      if (e is PostgrestException) {
        if (e.code == '23505') {
          // Unique violation
          throw Exception('Student with this data already exists.');
        }
      }
      throw Exception('Failed to create student: $e');
    }
  }

  Future<StudentModel?> getStudentById(int id) async {
    try {
      print('Debug: Fetching student with ID: $id');

      final response = await _supabaseClient
          .from('students')
          .select()
          .eq('id', id) // Use 'id' not 'id_user'
          .single();

      print('Debug: Student response - $response');

      final student = StudentModel.fromMap(response);
      print(
          'Debug: Mapped student - ID: ${student.id}, Name: ${student.studentName}');

      return student;
    } catch (e) {
      print('Error getting student by ID: $e');
      if (e is PostgrestException && e.code == 'PGRST116') {
        return null;
      }
      throw Exception('Failed to fetch student: $e');
    }
  }

  Future<List<StudentModel>> getAllStudents() async {
    try {
      final response = await _supabaseClient
          .from('students')
          .select()
          .order('id', ascending: true);

      return (response as List)
          .map((studentMap) => StudentModel.fromMap(studentMap))
          .toList();
    } catch (e) {
      print('Error getting all students: $e');
      throw Exception('Failed to fetch students: $e');
    }
  }

  Future<List<StudentModel>> getStudentsByUserId(int userId) async {
    try {
      print('Debug: Fetching students for user ID - $userId');

      final response = await _supabaseClient
          .from('students')
          .select()
          .eq('id_user', userId); // This is correct for querying by user ID

      print('Debug: Raw response from students table - $response');

      return (response as List)
          .map((studentMap) => StudentModel.fromMap(studentMap))
          .toList();
    } catch (e) {
      print('Debug: Error getting students by user ID - $e');
      throw Exception('Failed to fetch students: $e');
    }
  }

  Future<StudentModel> updateStudent(StudentModel updatedStudent) async {
    try {
      if (updatedStudent.studentName.isEmpty ||
          updatedStudent.studentAddress.isEmpty ||
          updatedStudent.studentPhoneNumber.isEmpty) {
        throw Exception('Student name, address, and phone number are required');
      }

      final response = await _supabaseClient
          .from('students')
          .update(updatedStudent.toMap())
          .eq('id', updatedStudent.id) // Use 'id' instead of 'userId'
          .select()
          .single();

      return StudentModel.fromMap(response);
    } catch (e) {
      print('Error updating student: $e');
      throw Exception('Failed to update student: $e');
    }
  }

  Future<void> deleteStudent(int id) async {
    try {
      final result =
          await _supabaseClient.from('students').delete().eq('id', id);

      if (result == null) {
        throw Exception('Student not found');
      }
    } catch (e) {
      print('Error deleting student: $e');
      throw Exception('Failed to delete student: $e');
    }
  }

  Future<bool> checkStudentExists(String studentName, int userId) async {
    try {
      final response = await _supabaseClient
          .from('students')
          .select('id_user')
          .eq('nama_siswa', studentName)
          .eq('id_user', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking student existence: $e');
      throw Exception('Failed to check student existence: $e');
    }
  }

  Future<String?> uploadStudentImage(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      final fileSize = await file.length();

      // Check file size (limit to 5MB)
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception(
            'Image size too large. Please choose an image under 5MB.');
      }

      final response = await _supabaseClient.storage
          .from('student-images')
          .upload(fileName, file,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
              ));

      if (response.isEmpty) {
        // Get the public URL of the uploaded image
        final imageUrl = _supabaseClient.storage
            .from('student-images')
            .getPublicUrl(fileName);

        return imageUrl;
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      print('Error uploading student image: $e');
      throw Exception('Failed to upload student image: $e');
    }
  }
}
