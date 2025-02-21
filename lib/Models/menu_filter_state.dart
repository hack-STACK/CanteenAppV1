import 'package:flutter/material.dart';

class MenuFilterState {
  final RangeValues priceRange;
  final Set<String> selectedTags;
  final String? searchQuery;
  final String sortBy;

  MenuFilterState({
    RangeValues? priceRange,
    Set<String>? selectedTags,
    this.searchQuery,
    String? sortBy,
  })  : priceRange = priceRange ?? const RangeValues(0, 1000000),
        selectedTags = selectedTags ?? {},
        sortBy = sortBy ?? 'recommended';

  MenuFilterState copyWith({
    RangeValues? priceRange,
    Set<String>? selectedTags,
    String? searchQuery,
    String? sortBy,
  }) {
    return MenuFilterState(
      priceRange: priceRange ?? this.priceRange,
      selectedTags: selectedTags ?? this.selectedTags,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}
