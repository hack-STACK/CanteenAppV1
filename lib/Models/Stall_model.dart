// class Stall {
//   final int id;
//   final String stallName;
//   final String ownerName;
//   final String phone;
//   final String slot;
//   final String description;
//   final String? photo;
//   final int idUser;

//   Stall({
//     required this.id,
//     required this.stallName,
//     required this.ownerName,
//     required this.phone,
//     required this.slot,
//     required this.description,
//     this.photo,
//     required this.idUser,
//   });

//   factory Stall.fromMap(Map<String, dynamic> map) {
//     return Stall(
//       id: map['id'] as int,
//       stallName: map['stall_name']?.toString() ?? '',
//       ownerName: map['owner_name']?.toString() ?? '',
//       phone: map['phone']?.toString() ?? '',
//       slot: map['slot']?.toString() ?? '',
//       description: map['description']?.toString() ?? '',
//       photo: map['photo']?.toString(),
//       idUser: map['id_user'] as int,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'stall_name': stallName,
//       'owner_name': ownerName,
//       'phone': phone,
//       'slot': slot,
//       'description': description,
//       'photo': photo,
//       'id_user': idUser,
//     };
//   }

//   // For compatibility with existing code
//   factory Stall.fromJson(Map<String, dynamic> json) => Stall.fromMap(json);
//   Map<String, dynamic> toJson() => toMap();

//   @override
//   String toString() {
//     return 'Stall{id: $id, stallName: $stallName, ownerName: $ownerName, phone: $phone, slot: $slot, description: $description, photo: $photo, idUser: $idUser}';
//   }
// }
