// lib/widgets/menu_section.dart
import 'package:flutter/material.dart';
import 'package:kantin/constants/colors.dart';
import 'package:kantin/constants/text_styles.dart';
import 'package:kantin/pages/AdminState/dashboard/widgets/menu_item.dart';

class MenuSection extends StatelessWidget {
  final String title;
  final List<MenuItem> items;

  const MenuSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTextStyles.sectionTitle),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list_rounded),
                  label: const Text("Filter"),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 20, endIndent: 20),
            itemBuilder: (context, index) => MenuItemCard(item: items[index]),
          ),
        ],
      ),
    );
  }
}
