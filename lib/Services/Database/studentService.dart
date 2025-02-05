import 'dart:io';

import 'package:kantin/Models/student_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentService {
  final _supabaseClient = Supabase.instance.client;

  Future<StudentModels> createStudent(StudentModels newStudent) async {
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
      return StudentModels.fromMap(response);
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

  Future<StudentModels?> getStudentById(int id) async {
    try {
      final response =
          await _supabaseClient.from('students').select().eq('id', id).single();

      return StudentModels.fromMap(response);
    } catch (e) {
      print('Error getting student by ID: $e');
      if (e is PostgrestException && e.code == 'PGRST116') {
        return null; // Return null if no student found
      }
      throw Exception('Failed to fetch student: $e');
    }
  }

  Future<List<StudentModels>> getAllStudents() async {
    try {
      final response = await _supabaseClient
          .from('students')
          .select()
          .order('id', ascending: true);

      return (response as List)
          .map((studentMap) => StudentModels.fromMap(studentMap))
          .toList();
    } catch (e) {
      print('Error getting all students: $e');
      throw Exception('Failed to fetch students: $e');
    }
  }

  Future<List<StudentModels>> getStudentsByUserId(int userId) async {
    try {
      final response = await _supabaseClient
          .from('students')
          .select()
          .eq('user_id', userId)
          .order('id', ascending: true);

      return (response as List)
          .map((studentMap) => StudentModels.fromMap(studentMap))
          .toList();
    } catch (e) {
      print('Error getting students by user ID: $e');
      throw Exception('Failed to fetch students: $e');
    }
  }

  Future<StudentModels> updateStudent(StudentModels updatedStudent) async {
    try {
      // Validate required fields
      if (updatedStudent.studentName.isEmpty ||
          updatedStudent.studentAddress.isEmpty ||
          updatedStudent.studentPhoneNumber.isEmpty) {
        throw Exception('Student name, address, and phone number are required');
      }

      final response = await _supabaseClient
          .from('students')
          .update(updatedStudent.toMap())
          .eq('user_id', updatedStudent.userId)
          .select()
          .single();

      return StudentModels.fromMap(response);
    } catch (e) {
      print('Error updating student: $e');
      throw Exception('Failed to update student: $e');
    }
  }

  Future<void> deleteStudent(int userId) async {
    try {
      final result =
          await _supabaseClient.from('students').delete().eq('user_id', userId);

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
          .select('id_user') // Change 'user_id' to 'id_user'
          .eq('nama_siswa',
              studentName) // Ensure you're using the correct column name for student name
          .eq('id_user', userId) // Change 'user_id' to 'id_user'
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking student existence: $e');
      throw Exception('Failed to check student existence: $e');
    }
  }

  Future<String?> uploadStudentImage(String filePath, String fileName) async {
    try {
      final response = await _supabaseClient.storage
          .from('student-images')
          .upload(fileName, File(filePath));

      throw response;

      // Get the public URL of the uploaded image
      final imageUrl =
          _supabaseClient.storage.from('student-images').getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      print('Error uploading student image: $e');
      throw Exception('Failed to upload student image: $e');
    }
  }
}
