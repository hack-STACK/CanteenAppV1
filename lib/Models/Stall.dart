class Stall {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final bool isOpen;
  final List<String> categories;

  Stall({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.isOpen,
    required this.categories,
  });
}
