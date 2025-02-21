import 'package:flutter/material.dart';

class MenuFilterState {
  final Set<String> selectedTags;
  final String? searchQuery;
  final String? sortBy;
  final RangeValues priceRange;
  final bool isGridView;

  const MenuFilterState({
    this.selectedTags = const {},
    this.searchQuery,
    this.sortBy,
    this.priceRange = const RangeValues(0, 1000000),
    this.isGridView = false,
  });

  MenuFilterState copyWith({
    Set<String>? selectedTags,
    String? searchQuery,
    String? sortBy,
    RangeValues? priceRange,
    bool? isGridView,
  }) {
    return MenuFilterState(
      selectedTags: selectedTags ?? this.selectedTags,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      priceRange: priceRange ?? this.priceRange,
      isGridView: isGridView ?? this.isGridView,
    );
  }
}
