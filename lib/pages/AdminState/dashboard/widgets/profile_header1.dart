import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.network(
          'https://cdn.builder.io/api/v1/image/assets/TEMP/981d143d10164cb0959451253294fc7eeda8ebdbfe8e3f4ff657e56a05e54a97?apiKey=48fea1f8f2d745ba95f928cb00bf0ebc&',
          width: 107,
          height: 107,
          fit: BoxFit.contain,
          semanticLabel: 'Profile picture',
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Lorem ipsum',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
            Text(
              '@Lorem ipsum',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
