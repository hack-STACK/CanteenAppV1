import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 47,
              height: 47,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFF542D),
              ),
              child: Center(
                child: Image.network(
                  'https://cdn.builder.io/api/v1/image/assets/TEMP/98d6544dbf1a02138680226e928ad841a4f81bb221a40f8bc59b4fe2031a5879?placeholderIfAbsent=true&apiKey=48fea1f8f2d745ba95f928cb00bf0ebc',
                  width: 7,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const SizedBox(width: 87, height: 50),
          ],
        ),
        const SizedBox(height: 31),
        Column(
          children: [
            Image.network(
              'https://cdn.builder.io/api/v1/image/assets/TEMP/7294bd5036b52c64d12c4f5b2bdd085f9130a992bdda883e17f854434464a81a?placeholderIfAbsent=true&apiKey=48fea1f8f2d745ba95f928cb00bf0ebc',
              width: 157,
              height: 157,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            const Text(
              'Lorem ipsum',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
            const Text(
              '@Lorem ipsum',
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Image.network(
              'https://cdn.builder.io/api/v1/image/assets/TEMP/7a84a452fd41d141dfce936f4707b887664f1ae419a1a86714af273d60c11ff5?placeholderIfAbsent=true&apiKey=48fea1f8f2d745ba95f928cb00bf0ebc',
              width: 10,
              height: 10,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}
