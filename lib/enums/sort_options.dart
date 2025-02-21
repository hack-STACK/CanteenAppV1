enum SortOption {
  recommended,
  priceAsc,
  priceDesc,
  nameAsc,
  nameDesc,
  ratingDesc;

  String get label {
    switch (this) {
      case SortOption.recommended:
        return 'Recommended';
      case SortOption.priceAsc:
        return 'Price: Low to High';
      case SortOption.priceDesc:
        return 'Price: High to Low';
      case SortOption.nameAsc:
        return 'Name: A to Z';
      case SortOption.nameDesc:
        return 'Name: Z to A';
      case SortOption.ratingDesc:
        return 'Highest Rated';
    }
  }
}
