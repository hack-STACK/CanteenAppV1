import 'package:flutter/material.dart';
import 'package:kantin/Models/menus_addon.dart';

class AddonEditor extends StatefulWidget {
  final List<FoodAddon> addons;
  final Function(List<FoodAddon>) onAddonsChanged;

  const AddonEditor({
    super.key,
    required this.addons,
    required this.onAddonsChanged,
  });

  @override
  State<AddonEditor> createState() => _AddonEditorState();
}

class _AddonEditorState extends State<AddonEditor> {
  late List<FoodAddon> _addons;

  @override
  void initState() {
    super.initState();
    _addons = List.from(widget.addons);
  }

  void _addAddon() {
    showDialog(
      context: context,
      builder: (context) => _AddonDialog(
        onSave: (addon) {
          setState(() {
            _addons.add(addon);
            widget.onAddonsChanged(_addons);
          });
        },
      ),
    );
  }

  void _editAddon(int index) {
    showDialog(
      context: context,
      builder: (context) => _AddonDialog(
        addon: _addons[index],
        onSave: (addon) {
          setState(() {
            _addons[index] = addon;
            widget.onAddonsChanged(_addons);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Add-ons',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton.icon(
              onPressed: _addAddon,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        if (_addons.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No add-ons yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _addons.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final addon = _addons.removeAt(oldIndex);
                _addons.insert(newIndex, addon);
                widget.onAddonsChanged(_addons);
              });
            },
            itemBuilder: (context, index) {
              final addon = _addons[index];
              return Card(
                key: ValueKey(addon.id),
                child: ListTile(
                  title: Text(addon.addonName),
                  subtitle: Text('Rp ${addon.price.toStringAsFixed(0)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editAddon(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _addons.removeAt(index);
                            widget.onAddonsChanged(_addons);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _AddonDialog extends StatefulWidget {
  final FoodAddon? addon;
  final Function(FoodAddon) onSave;

  const _AddonDialog({
    super.key,
    this.addon,
    required this.onSave,
  });

  @override
  State<_AddonDialog> createState() => _AddonDialogState();
}

class _AddonDialogState extends State<_AddonDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.addon?.addonName);
    _priceController = TextEditingController(
      text: widget.addon?.price.toStringAsFixed(0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.addon == null ? 'Add Add-on' : 'Edit Add-on'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Price is required';
                if (double.tryParse(value!) == null) return 'Invalid price';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              widget.onSave(
                FoodAddon(
                  id: widget.addon?.id,
                  addonName: _nameController.text,
                  price: double.parse(_priceController.text),
                  menuId: widget.addon!.menuId,
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
