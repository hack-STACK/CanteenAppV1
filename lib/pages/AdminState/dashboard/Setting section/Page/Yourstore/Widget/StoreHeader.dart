// // lib/widgets/store_header.dart
// import 'package:flutter/material.dart';
// import 'package:kantin/constants/colors.dart';
// import 'package:kantin/widgets/circular_button.dart';
// import 'package:kantin/widgets/store_profile.dart';

// class StoreHeader extends StatelessWidget {
//   const StoreHeader({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return SliverAppBar(
//       expandedHeight: 400,
//       floating: false,
//       pinned: true,
//       stretch: true,
//       backgroundColor: AppColors.gradientStart,
//       flexibleSpace: FlexibleSpaceBar(
//         stretchModes: const [
//           StretchMode.zoomBackground,
//           StretchMode.blurBackground,
//         ],
//         background: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 AppColors.gradientStart,
//                 AppColors.gradientEnd,
//               ],
//             ),
//           ),
//           child: Row(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: CircularButton(
//                   icon: "assets/images/img_icon_nav_arrow.svg",
//                   onPressed: () => Navigator.pop(context),
//                 ),
//               ),
//               const StoreProfile(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
