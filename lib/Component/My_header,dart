import 'package:flutter/material.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 47,
          height: 47,
          decoration: const BoxDecoration(
            color: Color(0xFFFF542D),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.person_outline,
              color: Colors.white,
              semanticLabel: 'Personal Information Icon',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Personal\nInformation',
       style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
            semanticsLabel: 'Personal Information Section',
          ),
        ),
      ],
    );
  }
}