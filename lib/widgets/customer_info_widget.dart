import 'package:flutter/material.dart';
import 'package:kantin/Models/student_models.dart';
import 'package:kantin/Services/Database/studentService.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomerInfoWidget extends StatefulWidget {
  final int studentId;

  const CustomerInfoWidget({
    super.key,
    required this.studentId,
  });

  @override
  State<CustomerInfoWidget> createState() => _CustomerInfoWidgetState();
}

class _CustomerInfoWidgetState extends State<CustomerInfoWidget> {
  final StudentService _studentService = StudentService();
  StudentModel? _student;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final student = await _studentService.getStudentById(widget.studentId);
      if (mounted) {
        setState(() {
          _student = student;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildAvatar(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isLoading
                    ? 'Loading...'
                    : (_student?.studentName ?? 'Unknown Customer'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (_student?.studentPhoneNumber != null)
                Text(
                  _student!.studentPhoneNumber,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    if (_isLoading) {
      return const CircleAvatar(
        radius: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // Check if student image URL is valid
    if (_student?.studentImage != null && 
        _student!.studentImage!.startsWith('http')) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: CachedNetworkImageProvider(
          _student!.studentImage!,
        ),
        backgroundColor: Colors.grey[200],
        onBackgroundImageError: (_, __) {
          // Fallback to initials on image error
          if (mounted) {
            setState(() {
              _student = StudentModel(
                id: _student!.id,
                studentName: _student!.studentName,
                studentAddress: _student!.studentAddress,
                studentPhoneNumber: _student!.studentPhoneNumber,
                userId: _student!.userId,
                studentImage: null,
              );
            });
          }
        },
      );
    }

    // Show initials avatar if no valid image
    return CircleAvatar(
      radius: 20,
      backgroundColor: _getAvatarColor(_student?.studentName ?? '?'),
      child: Text(
        _getInitials(_student?.studentName ?? '?'),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) return '?';

    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    }

    return '${nameParts[0][0]}${nameParts[nameParts.length - 1][0]}'.toUpperCase();
  }

  Color _getAvatarColor(String name) {
    if (name.isEmpty) return Colors.grey;

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    final index = name.codeUnits.fold<int>(
      0,
      (prev, curr) => prev + curr,
    ) % colors.length;

    return colors[index];
  }
}