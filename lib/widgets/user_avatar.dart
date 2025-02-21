import 'package:flutter/material.dart';
import 'package:kantin/Services/Database/studentService.dart';
import 'package:kantin/Models/student_models.dart';

class UserAvatar extends StatelessWidget {
  final int studentId;
  final double size;
  final bool showBorder; // Add this
  final _studentService = StudentService();

  UserAvatar({
    super.key,
    required this.studentId,
    this.size = 40,
    this.showBorder = false, // Add this
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StudentModel?>(
      future: _studentService.getStudentById(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder();
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _buildErrorAvatar();
        }

        final student = snapshot.data!;
        return _buildAvatar(student);
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.5,
          height: size * 0.5,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.error_outline,
        size: size * 0.5,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildAvatar(StudentModel student) {
    final String initials = _getInitials(student.studentName);
    final avatar = student.studentImage != null
        ? CircleAvatar(
            radius: size / 2,
            backgroundImage: NetworkImage(student.studentImage!),
            backgroundColor: Colors.grey[200],
            onBackgroundImageError: (_, __) => _buildInitialsAvatar(initials),
          )
        : _buildInitialsAvatar(initials);

    if (!showBorder) return avatar;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(50),
            blurRadius: 4,
          ),
        ],
      ),
      child: avatar,
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name.substring(0, min(2, name.length)).toUpperCase();
  }

  int min(int a, int b) => a < b ? a : b;
}
