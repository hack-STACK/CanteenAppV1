// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:flutter_slidable/flutter_slidable.dart';

// class MenuManagementScreen extends StatefulWidget {
//   const MenuManagementScreen({Key? key}) : super(key: key);

//   @override
//   State<MenuManagementScreen> createState() => _MenuManagementScreenState();
// }

// class _MenuManagementScreenState extends State<MenuManagementScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   bool isDarkMode = false;
//   bool isGridView = true;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 4, vsync: this);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Theme(
//       data: isDarkMode ? ThemeData.dark() : ThemeData.light(),
//       child: Scaffold(
//         body: NestedScrollView(
//           headerSliverBuilder: (context, innerBoxIsScrolled) => [
//             _buildAppBar(),
//             _buildTabBar(),
//           ],
//           body: _buildBody(),
//         ),
//         floatingActionButton: _buildFloatingActionButton(),
//       ),
//     );
//   }

//   Widget _buildAppBar() {
//     return SliverAppBar(
//       expandedHeight: 200,
//       pinned: true,
//       flexibleSpace: FlexibleSpaceBar(
//         background: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Theme.of(context).primaryColor,
//                 Theme.of(context).primaryColor.withOpacity(0.7),
//               ],
//             ),
//           ),
//           child: _buildHeaderContent(),
//         ),
//       ),
//       actions: [
//         IconButton(
//           icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
//           onPressed: () => setState(() => isDarkMode = !isDarkMode),
//         ),
//         IconButton(
//           icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
//           onPressed: () => setState(() => isGridView = !isGridView),
//         ),
//         PopupMenuButton(
//           itemBuilder: (context) => [
//             PopupMenuItem(
//               child: ListTile(
//                 leading: Icon(Icons.import_export),
//                 title: Text('Import/Export'),
//               ),
//             ),
//             PopupMenuItem(
//               child: ListTile(
//                 leading: Icon(Icons.language),
//                 title: Text('Language'),
//               ),
//             ),
//             PopupMenuItem(
//               child: ListTile(
//                 leading: Icon(Icons.settings),
//                 title: Text('Settings'),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildHeaderContent() {
//     return SafeArea(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Menu Management',
//               style: GoogleFonts.poppins(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Manage your menu items, add-ons, and pricing',
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 color: Colors.white70,
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildQuickStats(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildQuickStats() {
//     return Container(
//       height: 60,
//       child: ListView(
//         scrollDirection: Axis.horizontal,
//         children: [
//           _buildStatCard('Active Items', '24', Icons.restaurant_menu),
//           _buildStatCard('Today\'s Sales', 'Rp 1.2M', Icons.payments),
//           _buildStatCard('Popular Items', '5', Icons.trending_up),
//           _buildStatCard('Low Stock', '3', Icons.warning),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatCard(String title, String value, IconData icon) {
//     return Card(
//       color: Colors.white.withOpacity(0.15),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, color: Colors.white, size: 20),
//             const SizedBox(width: 8),
//             Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   value,
//                   style: GoogleFonts.poppins(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//                 Text(
//                   title,
//                   style: GoogleFonts.poppins(
//                     color: Colors.white70,
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTabBar() {
//     return SliverPersistentHeader(
//       pinned: true,
//       delegate: _SliverAppBarDelegate(
//         TabBar(
//           controller: _tabController,
//           isScrollable: true,
//           tabs: [
//             Tab(text: 'All Items'),
//             Tab(text: 'Categories'),
//             Tab(text: 'Add-ons'),
//             Tab(text: 'Analytics'),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBody() {
//     return TabBarView(
//       controller: _tabController,
//       children: [
//         _buildMenuItemsGrid(),
//         _buildCategoriesPage(),
//         _buildAddonsPage(),
//         _buildAnalyticsPage(),
//       ],
//     );
//   }

//   Widget _buildMenuItemsGrid() {
//     return isGridView ? _buildGridView() : _buildListView();
//   }

//   Widget _buildGridView() {
//     // Implementation for grid view of menu items
//     return GridView.builder(
//       padding: const EdgeInsets.all(16),
//       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         childAspectRatio: 0.8,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//       ),
//       itemBuilder: (context, index) => _buildMenuItemCard(),
//       itemCount: 10, // Replace with actual item count
//     );
//   }

//   Widget _buildListView() {
//     // Implementation for list view of menu items
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemBuilder: (context, index) => _buildMenuItemListTile(),
//       itemCount: 10, // Replace with actual item count
//     );
//   }

//   Widget _buildMenuItemCard() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Menu item image
//           ClipRRect(
//             borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
//             child: AspectRatio(
//               aspectRatio: 1.5,
//               child: Image.network(
//                 'https://placeholder.com/300',
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Menu Item Name',
//                   style: GoogleFonts.poppins(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//                 Text(
//                   'Rp 50.000',
//                   style: GoogleFonts.poppins(
//                     color: Theme.of(context).primaryColor,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       '12 Add-ons',
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                     Switch(
//                       value: true,
//                       onChanged: (value) {},
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMenuItemListTile() {
//     return Slidable(
//       endActionPane: ActionPane(
//         motion: ScrollMotion(),
//         children: [
//           SlidableAction(
//             onPressed: (context) {},
//             backgroundColor: Colors.blue,
//             foregroundColor: Colors.white,
//             icon: Icons.edit,
//             label: 'Edit',
//           ),
//           SlidableAction(
//             onPressed: (context) {},
//             backgroundColor: Colors.red,
//             foregroundColor: Colors.white,
//             icon: Icons.delete,
//             label: 'Delete',
//           ),
//         ],
//       ),
//       actionPane: null,
//       child: ListTile(
//         leading: ClipRRect(
//           borderRadius: BorderRadius.circular(8),
//           child: Image.network(
//             'https://placeholder.com/100',
//             width: 56,
//             height: 56,
//             fit: BoxFit.cover,
//           ),
//         ),
//         title: Text('Menu Item Name'),
//         subtitle: Text('Rp 50.000'),
//         trailing: Switch(
//           value: true,
//           onChanged: (value) {},
//         ),
//       ),
//     );
//   }

//   Widget _buildCategoriesPage() {
//     // Implementation for categories management
//     return Center(child: Text('Categories Page'));
//   }

//   Widget _buildAddonsPage() {
//     // Implementation for add-ons management
//     return Center(child: Text('Add-ons Page'));
//   }

//   Widget _buildAnalyticsPage() {
//     // Implementation for analytics dashboard
//     return Center(child: Text('Analytics Page'));
//   }

//   Widget _buildFloatingActionButton() {
//     return FloatingActionButton.extended(
//       onPressed: () {
//         // Show add menu item dialog/screen
//       },
//       icon: Icon(Icons.add),
//       label: Text('Add Item'),
//     );
//   }
// }

// class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
//   final TabBar _tabBar;

//   _SliverAppBarDelegate(this._tabBar);

//   @override
//   double get minExtent => _tabBar.preferredSize.height;
//   @override
//   double get maxExtent => _tabBar.preferredSize.height;

//   @override
//   Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
//     return Container(
//       color: Theme.of(context).scaffoldBackgroundColor,
//       child: _tabBar,
//     );
//   }

//   @override
//   bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
//     return false;
//   }
// }
