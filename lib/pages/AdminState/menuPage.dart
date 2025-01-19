// import 'package:flutter/material.dart';
// import 'package:kantin/Models/menu.dart';
// import 'package:kantin/Services/Database/menu_service.dart';
// import 'package:kantin/models/menu.dart';
// import 'package:kantin/Services/database/menu_service.dart';
// import 'package:provider/provider.dart';

// class MenuPage extends StatefulWidget {
//   const MenuPage({super.key});

//   @override
//   _MenuPageState createState() => _MenuPageState();
// }

// class _MenuPageState extends State<MenuPage> {
//   final MenuService _menuService = MenuService();
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _priceController = TextEditingController();
//   final TextEditingController _imagePathController = TextEditingController();

//   void _addMenu() {
//     final String name = _nameController.text;
//     final String description = _descriptionController.text;
//     final double price = double.tryParse(_priceController.text) ?? 0.0;
//     final String imagePath = _imagePathController.text;

//     if (name.isNotEmpty && description.isNotEmpty && price > 0) {
//       final newMenu = Menu(
//         id: '', // ID will be generated by Firestore
//         name: name,
//         description: description,
//         price: price,
//         imagePath: imagePath,
//       );
//       _menuService.createMenu(newMenu);
//       _nameController.clear();
//       _descriptionController.clear();
//       _priceController.clear();
//       _imagePathController.clear();
//       Navigator.pop(context); // Close the dialog after adding
//     }
//   }

//   void _showAddMenuDialog() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Add Menu Item'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: _nameController,
//                 decoration: InputDecoration(labelText: 'Name'),
//               ),
//               TextField(
//                 controller: _descriptionController,
//                 decoration: InputDecoration(labelText: 'Description'),
//               ),
//               TextField(
//                 controller: _priceController,
//                 decoration: InputDecoration(labelText: 'Price'),
//                 keyboardType: TextInputType.number,
//               ),
//               TextField(
//                 controller: _imagePathController,
//                 decoration: InputDecoration(labelText: 'Image Path'),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 _addMenu();
//               },
//               child: Text('Add'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: Text('Cancel'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Menu Management'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.add),
//             onPressed: _showAddMenuDialog,
//           ),
//         ],
//       ),
//       body: StreamBuilder<List<Menu>>(
//         stream: _menuService.getMenus(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
//           final menus = snapshot.data ?? [];
//           return ListView.builder(
//             itemCount: menus.length,
//             itemBuilder: (context, index) {
//               final menu = menus[index];
//               return ListTile(
//                 title: Text(menu.name),
//                 subtitle: Text('${menu.description} - \$${menu.price}'),
//                 trailing: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     IconButton(
//                       icon: Icon(Icons.edit),
//                       onPressed: () {
//                         // Implement update functionality
//                       },
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.delete),
//                       onPressed: () {
//                         _menuService.deleteMenu(menu.id);
//                       },
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
