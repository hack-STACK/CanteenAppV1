class RevenueData {
  final DateTime date;
  final double totalRevenue;
  final String? menuName;
  final String? stallName;

  RevenueData({
    required this.date,
    required this.totalRevenue,
    this.menuName,
    this.stallName,
  });

  factory RevenueData.fromJson(Map<String, dynamic> json) {
    return RevenueData(
      date: DateTime.parse(json['transaction_date']),
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      menuName: json['menu_name'],
      stallName: json['stall_name'],
    );
  }
}
