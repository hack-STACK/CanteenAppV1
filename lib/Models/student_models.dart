class StudentModels {
  final String studentName;
  final String studentAddress;
  final String studentPhoneNumber; // Changed to String to preserve formatting
  final int userId; // Changed to camelCase for Dart conventions
  final String studentImage;

  StudentModels({
    required this.studentName,
    required this.studentAddress,
    required this.studentPhoneNumber,
    required this.userId,
    required this.studentImage,
  });

  // Convert to JSON format for database operations
  Map<String, dynamic> toMap() {
    return {
      'student_name': studentName,
      'student_address': studentAddress,
      'student_phone': studentPhoneNumber,
      'user_id': userId,
      'student_image': studentImage,
    };
  }

  // Create instance from JSON data
  factory StudentModels.fromMap(Map<String, dynamic> map) {
    return StudentModels(
      studentName: map['student_name'] ?? '',
      studentAddress: map['student_address'] ?? '',
      studentPhoneNumber: map['student_phone']?.toString() ?? '',
      userId: map['user_id'] as int? ?? 0,
      studentImage: map['student_image'] ?? '',
    );
  }

  // Optional: CopyWith method for updates
  StudentModels copyWith({
    String? studentName,
    String? studentAddress,
    String? studentPhoneNumber,
    int? userId,
    String? studentImage,
  }) {
    return StudentModels(
      studentName: studentName ?? this.studentName,
      studentAddress: studentAddress ?? this.studentAddress,
      studentPhoneNumber: studentPhoneNumber ?? this.studentPhoneNumber,
      userId: userId ?? this.userId,
      studentImage: studentImage ?? this.studentImage,
    );
  }
}
