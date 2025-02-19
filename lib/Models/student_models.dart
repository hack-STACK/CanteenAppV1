class StudentModel {
  final int id;
  final String studentName;
  final String studentAddress;
  final String studentPhoneNumber;
  final int userId;
  final String? studentImage;

  StudentModel({
    required this.id,
    required this.studentName,
    required this.studentAddress,
    required this.studentPhoneNumber,
    required this.userId,
    this.studentImage,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'],
      studentName: map['nama_siswa'],
      studentAddress: map['alamat'],
      studentPhoneNumber: map['telp'],
      userId: map['id_user'],
      studentImage: map['foto'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_siswa': studentName,
      'alamat': studentAddress,
      'telp': studentPhoneNumber,
      'id_user': userId,
      'foto': studentImage,
    };
  }
}
