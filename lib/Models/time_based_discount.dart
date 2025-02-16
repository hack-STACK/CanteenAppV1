class TimeBasedDiscount {
  final String name;
  final double discountPercentage;
  final DateTime startTime;
  final DateTime endTime;
  final bool isActive;

  TimeBasedDiscount({
    required this.name,
    required this.discountPercentage,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
  });
}
