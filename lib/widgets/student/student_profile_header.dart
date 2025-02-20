import 'package:flutter/material.dart';
import 'package:kantin/Models/student_models.dart';
import 'package:kantin/utils/avatar_generator.dart';
import 'package:kantin/pages/StudentState/profile_page.dart';

class StudentProfileHeader extends StatelessWidget {
  final StudentModel? student;
  final bool isLoading;
  final VoidCallback onProfileComplete;
  final VoidCallback onRefresh;

  const StudentProfileHeader({
    super.key,
    required this.student,
    required this.isLoading,
    required this.onProfileComplete,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isLoading ? _buildLoadingState() : _buildProfileContent(context),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          ShimmerCircle(size: 60),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLine(width: 150, height: 20),
                SizedBox(height: 8),
                ShimmerLine(width: 100, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleProfileTap(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildName(),
                    if (student != null) ...[
                      const SizedBox(height: 4),
                      _buildStudentInfo(),
                    ],
                  ],
                ),
              ),
              _buildActionButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Hero(
      tag: 'profileAvatar',
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.blue.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey[100],
          child: _getProfileImage(),
        ),
      ),
    );
  }

  Widget _getProfileImage() {
    if (student?.studentImage != null && student!.studentImage!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          student!.studentImage!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return AvatarGenerator.generateStallAvatar(
              student?.studentName ?? 'Profile',
              size: 60,
            );
          },
        ),
      );
    }
    return AvatarGenerator.generateStallAvatar(
      student?.studentName ?? 'Profile',
      size: 60,
    );
  }

  Widget _buildName() {
    return Text(
      student?.studentName ?? 'Complete Your Profile',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStudentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (student?.studentAddress != null)
          Text(
            student!.studentAddress,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.chevron_right),
      color: Colors.grey[400],
      onPressed: () => _handleProfileTap(context),
    );
  }

  void _handleProfileTap(BuildContext context) {
    if (student != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudentProfilePage(student: student!),
        ),
      ).then((_) => onRefresh());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please complete your profile'),
          action: SnackBarAction(
            label: 'Complete',
            onPressed: onProfileComplete,
          ),
        ),
      );
    }
  }
}

class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
      ),
    );
  }
}

class ShimmerLine extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerLine({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
