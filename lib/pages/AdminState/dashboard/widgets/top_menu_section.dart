import 'package:flutter/material.dart';
import 'menu_item.dart';

class TopMenuSection extends StatefulWidget {
  final String title;
  final List<String> filterOptions;
  final int itemCount;
  final Color accentColor;
  final VoidCallback? onSeeAllTap;

  const TopMenuSection({
    Key? key,
    this.title = 'Top menus',
    this.filterOptions = const ['Latest', 'Popular', 'Trending'],
    this.itemCount = 3,
    this.accentColor = const Color(0xFFFF542D),
    this.onSeeAllTap,
  }) : super(key: key);

  @override
  State<TopMenuSection> createState() => _TopMenuSectionState();
}

class _TopMenuSectionState extends State<TopMenuSection> {
  String _selectedFilter = 'Latest';
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Figtree',
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Discover your favorite meals',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Figtree',
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterDropdown(),
              if (widget.onSeeAllTap != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: widget.onSeeAllTap,
                  style: TextButton.styleFrom(
                    foregroundColor: widget.accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(60, 36),
                  ),
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 80,
          minHeight: 36,
        ),
        decoration: BoxDecoration(
          color: widget.accentColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _selectedFilter,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  size: 20,
                  color: widget.accentColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.accentColor.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isExpanded) _buildFilterOptions(),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.itemCount,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) => const MenuItem(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.filterOptions.map((filter) {
          final isSelected = filter == _selectedFilter;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
                _isExpanded = false;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? widget.accentColor.withOpacity(0.08) : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? widget.accentColor : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}