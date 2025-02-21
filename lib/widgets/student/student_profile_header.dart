import 'package:flutter/material.dart';
import 'package:kantin/Models/student_models.dart';

class StudentProfileHeader extends StatelessWidget {
  final StudentModel? student;
  final bool isLoading;
  final VoidCallback onProfileComplete;
  final Future<void> Function() onRefresh;

  const StudentProfileHeader({
    Key? key,
    required this.student,
    required this.isLoading,
    required this.onProfileComplete,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          InkWell(
            onTap: student == null ? onProfileComplete : null,
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              backgroundImage: student?.studentImage != null &&
                      student!.studentImage!.isNotEmpty
                  ? NetworkImage(student!.studentImage!)
                  : null,
              child: student?.studentImage == null ||
                      student!.studentImage!.isEmpty
                  ? Text(
                      student?.studentName?.substring(0, 1).toUpperCase() ??
                          '?',
                      style: TextStyle(
                        fontSize: 24,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: student == null ? onProfileComplete : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    student?.studentName ?? 'Complete your profile',
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    student?.studentAddress ?? 'Click here to setup',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
