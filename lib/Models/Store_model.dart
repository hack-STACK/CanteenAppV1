class Store {
  final String id;
  final String name;
  final String description;
  final String ownerName;
  final String location;
  final String imageUrl;
  final String phone;
  final bool isOpen;

  Store({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerName,
    required this.location,
    required this.imageUrl,
    required this.phone,
    this.isOpen = true,
  });
}
