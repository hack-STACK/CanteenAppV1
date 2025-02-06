import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kantin/Models/menus_addon.dart';
import 'package:kantin/Services/Database/foodService.dart';

class MenuAddonsScreen extends StatefulWidget {
  final int menuId;
  final FoodService foodService;

  const MenuAddonsScreen({
    super.key,
    required this.menuId,
    required this.foodService,
  });

  @override
  State<MenuAddonsScreen> createState() => _MenuAddonsScreenState();
}

class _MenuAddonsScreenState extends State<MenuAddonsScreen> {
  final List<FoodAddon> _addons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddons();
  }

  Future<void> _loadAddons() async {
    try {
      setState(() => _isLoading = true);
      final addons = await widget.foodService.getAddonsForMenu(widget.menuId);
      setState(() {
        _addons.clear();
        _addons.addAll(addons);
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading add-ons: $e')),
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
          id: existing!.id,
          menuId: widget.menuId,
          addonName: result['name'],
          price: result['price'],
          isRequired: result['isRequired'],
        );

        if (existing != null) {
          await widget.foodService.updateFoodAddon(addon);
        } else {
          await widget.foodService.createFoodAddon(addon);
        }

        await _loadAddons();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving add-on: $e')),
        );
      }
    }
  }

  Future<void> _deleteAddon(FoodAddon addon) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Add-on'),
        content: Text('Are you sure you want to delete "${addon.addonName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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
          SnackBar(content: Text('Error deleting add-on: $e')),
        );
      }
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
        title: const Text(
          'Manage Add-ons',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add-ons',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Customize your menu item with optional add-ons',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.black54,
                              ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= _addons.length) return null;
                        final addon = _addons[index];
                        return AddonCard(
                          addon: addon,
                          onEdit: () => _showAddAddonDialog(addon),
                          onDelete: () => _deleteAddon(addon),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAddonDialog(),
        backgroundColor: const Color(0xFFFF542D),
        child: const Icon(Icons.add),
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
                  Text(
                    addon.addonName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
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
                      child: Text(
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
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
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
      title: Text(
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
              title: const Text('Required'),
              subtitle: const Text('Customers must select this add-on'),
              value: _isRequired,
              onChanged: (value) => setState(() => _isRequired = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
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
          child: const Text('Save'),
        ),
      ],
    );
  }
}