class Stan {
  final int? id; // Make id nullable for new entries
  final String stanName;
  final String ownerName;
  final String phone;
  final int userId;
  final String description;
  final String slot; // Add slot field

  Stan({
    this.id, // Now this can be null for new entries
    required this.stanName,
    required this.ownerName,
    required this.phone,
    required this.userId,
    required this.description,
    required this.slot, // Include slot in the constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id, // This can be null
      'nama_stan': stanName,
      'nama_pemilik': ownerName,
      'telp': phone,
      'id_user': userId,
      'deskripsi': description,
      'slot': slot, // Include slot in the map
    };
  }

  factory Stan.fromMap(Map<String, dynamic> map) {
    return Stan(
      id: map['id'], // This can be null
      stanName: map['nama_stan'] ?? '', // Provide a default value if null
      ownerName: map['nama_pemilik'] ?? '', // Provide a default value if null
      phone: map['telp'] ?? '', // Provide a default value if null
      userId: map['id_user'] ??
          0, // Provide a default value if null (assuming userId should not be null)
      description: map['deskripsi'] ?? '', // Provide a default value if null
      slot: map['slot'] ?? '', // Provide a default value if null
    );
  }
}
