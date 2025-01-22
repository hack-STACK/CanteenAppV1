import 'package:flutter/material.dart';

class AdminTheme {
  static const Color primary = Color(0xFF0B4AF5);
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color background = Color(0xFFF8FAFF);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF1A1F36);
  static const Color textSecondary = Color(0xFF6B7280);

  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

class StatsRow extends StatelessWidget {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // For smaller screens, stack vertically
          return Column(
            children: [
              AverageOrderCard(),
              const SizedBox(height: 16),
              TopMenuCard(),
            ],
          );
        } else {
          // For wider screens, use row
          return Row(
            children: [
              Expanded(child: AverageOrderCard()),
              const SizedBox(width: 16),
              Expanded(child: TopMenuCard()),
            ],
          );
        }
      },
    );
  }
}

class AverageOrderCard extends StatelessWidget {
  const AverageOrderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AdminTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Average Order',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AdminTheme.textPrimary,
                ),
              ),
              _buildTrendBadge(isPositive: true, percentage: "12%"),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '₹20',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AdminTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'per order',
                style: TextStyle(
                  fontSize: 14,
                  color: AdminTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetricRow('Daily Orders', '156'),
        ],
      ),
    );
  }

  Widget _buildTrendBadge(
      {required bool isPositive, required String percentage}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPositive
            ? AdminTheme.success.withOpacity(0.1)
            : AdminTheme.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: isPositive ? AdminTheme.success : AdminTheme.warning,
          ),
          const SizedBox(width: 4),
          Text(
            percentage,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPositive ? AdminTheme.success : AdminTheme.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AdminTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AdminTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class TopMenuCard extends StatelessWidget {
  const TopMenuCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AdminTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Menu Items',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AdminTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildMenuItem(
            rank: 1,
            name: 'Nasi Goreng',
            orders: '245',
            trend: '+15%',
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            rank: 2,
            name: 'Mie Goreng',
            orders: '180',
            trend: '+8%',
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            rank: 2,
            name: 'Mie Goreng',
            orders: '180',
            trend: '+8%',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required int rank,
    required String name,
    required String orders,
    required String trend,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: rank == 1
                ? AdminTheme.primary.withOpacity(0.1)
                : AdminTheme.background,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    rank == 1 ? AdminTheme.primary : AdminTheme.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AdminTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    '$orders orders',
                    style: TextStyle(
                      fontSize: 12,
                      color: AdminTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    trend,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AdminTheme.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
