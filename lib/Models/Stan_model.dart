class Stan {
  final int id;
  final String stanName; // maps to nama_stalls
  final String ownerName; // maps to nama_pemilik
  final String phone; // maps to no_telp
  final int userId; // maps to id_user
  final String description; // maps to deskripsi
  final String slot; // maps to slot
  final String? imageUrl; // maps to image_url
  final String? Banner_img; // maps to Banner_img

  Stan({
    required this.id,
    required this.stanName,
    required this.ownerName,
    required this.phone,
    required this.userId,
    required this.description,
    required this.slot,
    this.imageUrl,
    this.Banner_img,
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
      Banner_img: map['Banner_img'],
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
      'Banner_img': Banner_img,
    };
  }

  Stan copyWith({
    int? id,
    String? stanName,
    String? ownerName,
    String? phone,
    int? userId,
    String? description,
    String? slot,
    String? imageUrl,
    String? Banner_img,
  }) {
    return Stan(
      id: id ?? this.id,
      stanName: stanName ?? this.stanName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      slot: slot ?? this.slot,
      imageUrl: imageUrl ?? this.imageUrl,
      Banner_img: Banner_img ?? this.Banner_img,
    );
  }
}
