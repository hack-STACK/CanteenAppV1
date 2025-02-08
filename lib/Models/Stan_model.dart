class Stan {
  final int? id;
  final String stanName;
  final String ownerName;
  final String phone;
  final int userId;
  final String description;
  final String slot;
  final String? imageUrl;

  Stan({
    this.id,
    required this.stanName,
    required this.ownerName,
    required this.phone,
    required this.userId,
    required this.description,
    required this.slot,
    this.imageUrl,
  });

  factory Stan.fromMap(Map<String, dynamic> map) {
    return Stan(
      id: map['id'],
      stanName: map['nama_stalls'],
      ownerName: map['nama_pemilik'],
      phone: map['no_telp'],
      userId: map['id_user'],
      description: map['deskripsi'],
      slot: map['slot'],
      imageUrl: map['image_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_stalls': stanName,
      'nama_pemilik': ownerName,
      'no_telp': phone,
      'id_user': userId,
      'deskripsi': description,
      'slot': slot,
      'image_url': imageUrl,
    };
  }
}
