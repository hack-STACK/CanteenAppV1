class Store {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final bool isOpen;

  Store({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.isOpen = true,
    required location,
  });

  get location => null;
}
