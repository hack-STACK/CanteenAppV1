import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kantin/Services/Database/studentService.dart';
import 'package:kantin/Models/student_models.dart';

class UserAvatar extends StatelessWidget {
  final int studentId;
  final double size;

  const UserAvatar({
    Key? key,
    required this.studentId,
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final studentService = StudentService();

    return FutureBuilder<StudentModel?>(
      future: studentService.getStudentById(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton();
        }

        final student = snapshot.data;
        if (student == null) {
          return _buildDefaultAvatar();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (student.studentImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(size / 2),
                child: CachedNetworkImage(
                  imageUrl: student.studentImage!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildSkeleton(),
                  errorWidget: (context, url, error) => _buildDefaultAvatar(),
                ),
              )
            else
              _buildDefaultAvatar(),
            if (size > 30) ...[
              const SizedBox(height: 4),
              Text(
                student.studentName,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              Text(
                student.studentPhoneNumber,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: Colors.grey[400],
      ),
    );
  }
}