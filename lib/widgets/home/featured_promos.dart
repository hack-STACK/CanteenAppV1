import 'package:flutter/material.dart';
import 'package:kantin/Models/Stan_model.dart';

class FeaturedPromos extends StatelessWidget {
  final List<Stan> stalls;

  const FeaturedPromos({
    super.key,
    required this.stalls,
  });

  @override
  Widget build(BuildContext context) {
    final stallsWithPromos =
        stalls.where((s) => s.hasActivePromotions()).toList();

    if (stallsWithPromos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Special Offers 🔥',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: stallsWithPromos.length,
            itemBuilder: (context, index) {
              final stall = stallsWithPromos[index];
              final discount = stall.activeDiscounts?.first;

              return Container(
                width: 300,
                margin: const EdgeInsets.only(right: 16),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        stall.imageUrl ?? '',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(Icons.restaurant,
                                size: 48, color: Colors.grey[400]),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stall.stanName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (discount != null)
                            Text(
                              '${discount.discountPercentage}% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
