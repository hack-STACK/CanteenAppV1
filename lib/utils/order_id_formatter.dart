class OrderIdFormatter {
  static String format(int id) {
    // Ensure the ID is padded with zeros to at least 4 digits
    return '#${id.toString().padLeft(4, '0')}';
  }
}

extension OrderMapperExtension on List<Map<String, dynamic>> {
  List<Map<String, dynamic>> withVirtualIds() {
    // Sort orders by creation date to ensure consistent ordering
    final sorted = [...this]..sort((a, b) => DateTime.parse(b['created_at'])
        .toLocal()
        .compareTo(DateTime.parse(a['created_at']).toLocal()));

    // Add virtual IDs starting from most recent
    for (var i = 0; i < sorted.length; i++) {
      sorted[i] = {
        ...sorted[i],
        'virtual_id': sorted.length - i,
      };
    }

    return sorted;
  }
}
