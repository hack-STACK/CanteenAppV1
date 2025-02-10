class Stan {
  final int id;
  final String stanName;
  final String ownerName;
  final String phone;
  final String slot;
  final String description;
  final String? imageUrl;
  final int userId;

  Stan({
    required this.id,
    required this.stanName,
    required this.ownerName,
    required this.phone,
    required this.slot,
    required this.description,
    required this.userId,
    this.imageUrl,
  });

  factory Stan.fromMap(Map<String, dynamic> map) {
    return Stan(
      id: map['id'],
      stanName: map['nama_stalls'],
      ownerName: map['nama_pemilik'],
      phone: map['no_telp'],
      slot: map['slot'],
      description: map['deskripsi'],
      imageUrl: map['image_url'],
      userId: map['id_user'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_stalls': stanName,
      'nama_pemilik': ownerName,
      'no_telp': phone,
      'slot': slot,
      'deskripsi': description,
      'id_user': userId,
      'image_url': imageUrl,
    };
  }

  @override
  String toString() {
    return 'Stan{id: $id, stanName: $stanName, ownerName: $ownerName, phone: $phone, slot: $slot, description: $description, userId: $userId, imageUrl: $imageUrl}';
  }
}
