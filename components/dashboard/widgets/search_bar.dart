import 'package:flutter/material.dart';

class SearchBar extends StatelessWidget {
  const SearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 68),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.43),
        borderRadius: BorderRadius.circular(1000),
        border: Border.all(
          color: const Color(0xFFFF542D).withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        children: const [
          Icon(Icons.search, color: Color(0xFF4F4F4F)),
          SizedBox(width: 10),
          Text(
            'Search',
            style: TextStyle(
              color: Color(0xFF4F4F4F),
              fontSize: 16,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}