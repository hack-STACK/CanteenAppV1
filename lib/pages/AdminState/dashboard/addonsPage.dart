import 'package:flutter/material.dart' hide Text;
import 'package:flutter/material.dart' as material show Text;
import 'package:flutter/services.dart';
import 'package:kantin/Models/addon_template.dart';
import 'package:kantin/Models/menus_addon.dart';
import 'package:kantin/Services/Database/foodService.dart';
import 'dart:async';

import 'package:kantin/widgets/AddonTemplateSelector.dart';

class MenuAddonsScreen extends StatefulWidget {
  final int? menuId; // Make menuId optional
  final List<FoodAddon>? tempAddons; // Add tempAddons parameter
  final FoodService foodService;
  final bool isTemporary; // Add flag for temporary mode

  const MenuAddonsScreen({
    super.key,
    this.menuId,
    this.tempAddons,
    required this.foodService,
    this.isTemporary = false,
  });

  @override
  State<MenuAddonsScreen> createState() => _MenuAddonsScreenState();
}

class _MenuAddonsScreenState extends State<MenuAddonsScreen> {
  // Cache addons to avoid unnecessary rebuilds
  final ValueNotifier<List<FoodAddon>> _addonsNotifier =
      ValueNotifier<List<FoodAddon>>([]);

  // Debounce search
  Timer? _debouncer;
  final TextEditingController _searchController = TextEditingController();
  List<AddonTemplate> _templates = [];

  @override
  void dispose() {
    _debouncer?.cancel();
    _searchController.dispose();
    _addonsNotifier.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debouncer?.isActive ?? false) _debouncer!.cancel();
    _debouncer = Timer(const Duration(milliseconds: 500), () {
      // Implement search logic
    });
  }

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    if (widget.isTemporary) {
      setState(() {
        _addonsNotifier.value = widget.tempAddons ?? [];
        _isLoading = false;
      });
    } else {
      _loadAddons();
    }
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await widget.foodService.getAddonTemplates();
      setState(() {
        _templates = templates;
      });
    } catch (e) {
      print('Error loading templates: $e');
    }
  }

  Future<void> _loadAddons() async {
    try {
      setState(() => _isLoading = true);
      final addons = await widget.foodService.getAddonsForMenu(widget.menuId!);
      setState(() {
        _addonsNotifier.value = addons;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: material.Text('Error loading add-ons: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddAddonDialog([FoodAddon? existing]) async {
    final nameController = TextEditingController(text: existing?.addonName);
    final priceController = TextEditingController(
      text: existing?.price.toString() ?? '',
    );
    bool isRequired = existing?.isRequired ?? false;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddonDialog(
        nameController: nameController,
        priceController: priceController,
        initialIsRequired: isRequired,
      ),
    );

    if (result != null) {
      try {
        final addon = FoodAddon(
          id: existing?.id, // Make it nullable here
          menuId: widget.menuId ?? 0, // Use 0 for temporary addons
          addonName: result['name'],
          price: result['price'],
          isRequired: result['isRequired'],
        );

        if (widget.isTemporary) {
          // Just update the local list for temporary mode
          setState(() {
            if (existing != null) {
              final index = _addonsNotifier.value
                  .indexWhere((a) => a.addonName == existing.addonName);
              if (index != -1) {
                _addonsNotifier.value[index] = addon;
              }
            } else {
              _addonsNotifier.value = [..._addonsNotifier.value, addon];
            }
          });
        } else {
          // Update database for permanent mode
          if (existing != null) {
            await widget.foodService.updateFoodAddon(addon);
          } else {
            await widget.foodService.createFoodAddon(addon);
          }
          await _loadAddons();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: material.Text(
                  existing != null ? 'Add-on updated!' : 'Add-on created!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: material.Text('Error saving add-on: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteAddon(FoodAddon addon) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const material.Text('Delete Add-on'),
        content: material.Text(
            'Are you sure you want to delete "${addon.addonName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const material.Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const material.Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.foodService.deleteFoodAddon(addon.id!);
        await _loadAddons();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: material.Text('Error deleting add-on: $e')),
        );
      }
    }
  }

  void _showTemplateSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            material.Text(
              'Popular Add-ons',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AddonTemplateSelector(
                templates: _templates,
                onSelect: _useTemplate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _useTemplate(AddonTemplate template) {
    if (widget.isTemporary) {
      setState(() {
        _addonsNotifier.value = [
          ..._addonsNotifier.value,
          template.toFoodAddon(widget.menuId ?? 0),
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: const Color(0xFFFF542D),
          onPressed: () => Navigator.pop(context),
        ),
        title: const material.Text(
          'Manage Add-ons',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (widget.isTemporary)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => Navigator.pop(context, _addonsNotifier.value),
            ),
        ],
      ),
      body: Column(
        children: [
          // Add search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search add-ons...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          // Use ValueListenableBuilder for efficient updates
          Expanded(
            child: ValueListenableBuilder<List<FoodAddon>>(
              valueListenable: _addonsNotifier,
              builder: (context, addons, _) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  itemCount: addons.length,
                  itemBuilder: (context, index) => AddonCard(
                    addon: addons[index],
                    onEdit: () => _showAddAddonDialog(addons[index]),
                    onDelete: () => _deleteAddon(addons[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Template button
          FloatingActionButton.extended(
            heroTag: 'templates',
            onPressed: _showTemplateSelector,
            label: const material.Text('Templates'),
            icon: const Icon(Icons.copy),
            backgroundColor: Colors.blue,
          ),
          const SizedBox(width: 16),
          // Existing add button
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _showAddAddonDialog(),
            backgroundColor: const Color(0xFFFF542D),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class AddonCard extends StatelessWidget {
  final FoodAddon addon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AddonCard({
    super.key,
    required this.addon,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  material.Text(
                    addon.addonName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  material.Text(
                    'Rp ${addon.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (addon.isRequired)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: material.Text(
                        'Required',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      material.Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      material.Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddonDialog extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController priceController;
  final bool initialIsRequired;

  const AddonDialog({
    super.key,
    required this.nameController,
    required this.priceController,
    this.initialIsRequired = false,
  });

  @override
  State<AddonDialog> createState() => _AddonDialogState();
}

class _AddonDialogState extends State<AddonDialog> {
  late bool _isRequired;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _isRequired = widget.initialIsRequired;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: material.Text(
        widget.nameController.text.isEmpty ? 'Add New Add-on' : 'Edit Add-on',
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: widget.nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter add-on name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                hintText: 'Enter price',
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const material.Text('Required'),
              subtitle:
                  const material.Text('Customers must select this add-on'),
              value: _isRequired,
              onChanged: (value) => setState(() => _isRequired = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const material.Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': widget.nameController.text,
                'price': double.parse(widget.priceController.text),
                'isRequired': _isRequired,
              });
            }
          },
          child: const material.Text('Save'),
        ),
      ],
    );
  }
}
