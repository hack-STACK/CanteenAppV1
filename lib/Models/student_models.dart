class StudentModels {
  final String studentName;        // Maps to 'nama_siswa'
  final String studentAddress;     // Maps to 'alamat'
  final String studentPhoneNumber; // Maps to 'telp'
  final int userId;                // Maps to 'id_user'
  final String studentImage;       // Maps to 'foto'

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
      'nama_siswa': studentName,        // Updated to match the database column name
      'alamat': studentAddress,          // Updated to match the database column name
      'telp': studentPhoneNumber,        // Updated to match the database column name
      'id_user': userId,                 // Updated to match the database column name
      'foto': studentImage,              // Updated to match the database column name
    };
  }

  // Create instance from JSON data
  factory StudentModels.fromMap(Map<String, dynamic> map) {
    return StudentModels(
      studentName: map['nama_siswa'] ?? '',                // Updated to match the database column name
      studentAddress: map['alamat'] ?? '',                 // Updated to match the database column name
      studentPhoneNumber: map['telp']?.toString() ?? '',   // Updated to match the database column name
      userId: map['id_user'] as int? ?? 0,                  // Updated to match the database column name
      studentImage: map['foto'] ?? '',                      // Updated to match the database column name
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