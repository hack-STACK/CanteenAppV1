class StudentModel {
  final int? id; // Make id nullable
  final String studentName;
  final String studentAddress;
  final String studentPhoneNumber;
  final int userId;
  final String? studentImage;

  StudentModel({
    this.id, // Now optional
    required this.studentName,
    required this.studentAddress,
    required this.studentPhoneNumber,
    required this.userId,
    this.studentImage,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] as int?,
      studentName: map['nama_siswa'] as String? ?? '',
      studentAddress: map['alamat'] as String? ?? '',
      studentPhoneNumber: map['telp'] as String? ?? '',
      userId: map['id_user'] as int,
      studentImage: map['foto'] as String?,
    );
  }

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'],
      studentName: json['nama_siswa'],
      studentAddress: json['alamat'],
      studentPhoneNumber: json['telp'],
      userId: json['id_user'],
      studentImage: json['foto'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'nama_siswa': studentName,
      'alamat': studentAddress,
      'telp': studentPhoneNumber,
      'id_user': userId,
      'foto': studentImage,
    };

    // Only include ID if it's not null (important for updates vs inserts)
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  Map<String, dynamic> toJson() {
    final map = {
      'nama_siswa': studentName,
      'alamat': studentAddress,
      'telp': studentPhoneNumber,
      'id_user': userId,
      'foto': studentImage,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  StudentModel copyWith({
    int? id,
    String? studentName,
    String? studentAddress,
    String? studentPhoneNumber,
    int? userId,
    String? studentImage,
  }) {
    return StudentModel(
      id: id ?? this.id,
      studentName: studentName ?? this.studentName,
      studentAddress: studentAddress ?? this.studentAddress,
      studentPhoneNumber: studentPhoneNumber ?? this.studentPhoneNumber,
      userId: userId ?? this.userId,
      studentImage: studentImage,
    );
  }
}
