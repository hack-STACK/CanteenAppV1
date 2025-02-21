import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kantin/Models/Stan_model.dart';

class StallHeader extends StatelessWidget {
  final Stan stall;
  final ScrollController scrollController;
  final bool isCollapsed;

  const StallHeader({
    super.key,
    required this.stall,
    required this.scrollController,
    required this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      stretch: true,
      backgroundColor: Theme.of(context).primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isCollapsed ? 1.0 : 0.0,
          child: Text(
            stall.stanName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildBannerImage(),
            _buildGradientOverlay(),
            if (!isCollapsed) _buildStallInfo(),
          ],
        ),
      ),
      leading: BackButton(
        color: Colors.white,
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {
            // Implement share functionality
          },
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border, color: Colors.white),
          onPressed: () {
            // Implement favorite functionality
          },
        ),
      ],
    );
  }

  Widget _buildBannerImage() {
    return Hero(
      tag: 'stall_banner_${stall.id}',
      child: stall.Banner_img != null
          ? Image.network(
              stall.Banner_img!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildBannerPlaceholder(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    color: Colors.white,
                  ),
                );
              },
            )
          : _buildBannerPlaceholder(),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
    );
  }

  Widget _buildStallInfo() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: stall.imageUrl != null
                    ? NetworkImage(stall.imageUrl!)
                    : null,
                child: stall.imageUrl == null
                    ? Text(
                        stall.stanName[0],
                        style: const TextStyle(fontSize: 24),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stall.stanName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stall.ownerName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.star,
                label: '${stall.rating?.toStringAsFixed(1) ?? "N/A"} Rating',
                color: Colors.amber,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.access_time,
                label: stall.isCurrentlyOpen() ? 'Open Now' : 'Closed',
                color: stall.isCurrentlyOpen() ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.phone,
                label: stall.phone,
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.store,
          size: 64,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}
