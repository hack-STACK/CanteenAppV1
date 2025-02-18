import 'package:flutter/material.dart';
import 'package:kantin/Models/menus_addon.dart';

class AddonDialog extends StatefulWidget {
  final FoodAddon? addon;
  final int menuId;

  const AddonDialog({
    super.key,
    this.addon,
    required this.menuId,
  });

  @override
  State<AddonDialog> createState() => _AddonDialogState();
}

class _AddonDialogState extends State<AddonDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  bool _isRequired = false;
  bool _showHints = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.addon?.addonName);
    _priceController =
        TextEditingController(text: widget.addon?.price.toString());
    _descriptionController =
        TextEditingController(text: widget.addon?.description);
    _isRequired = widget.addon?.isRequired ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.addon != null;
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    // Calculate responsive width
    final dialogWidth = size.width > 600 
        ? 400.0  // Desktop/tablet width
        : size.width * 0.9; // Mobile width (90% of screen)

    return Center(
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: size.height * 0.9, // Max 90% of screen height
          maxWidth: 400, // Max width 400
        ),
        margin: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          color: Colors.transparent,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient background
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.1),
                        theme.colorScheme.primary.withOpacity(0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        child: Icon(
                          isEditing ? Icons.edit : Icons.add,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Edit Add-on' : 'New Add-on',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isEditing
                                  ? 'Update your add-on details'
                                  : 'Create a new add-on option',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Help Button
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () =>
                                setState(() => _showHints = !_showHints),
                            icon: Icon(
                              _showHints
                                  ? Icons.visibility_off
                                  : Icons.help_outline,
                              size: 18,
                            ),
                            label: Text(_showHints ? 'Hide Tips' : 'Show Tips'),
                          ),
                        ),

                        // Name Field
                        _buildTextField(
                          controller: _nameController,
                          label: 'Add-on Name',
                          hint: 'e.g., Extra Cheese',
                          helperText: _showHints
                              ? 'Give your add-on a clear, descriptive name'
                              : null,
                          icon: Icons.label_outline,
                          validator: (value) => value?.trim().isEmpty ?? true
                              ? 'Name is required'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Price Field
                        _buildTextField(
                          controller: _priceController,
                          label: 'Price',
                          hint: '0',
                          prefixText: 'Rp ',
                          helperText: _showHints
                              ? 'Amount to be added to base menu price'
                              : null,
                          icon: Icons.payments_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: _validatePrice,
                        ),
                        const SizedBox(height: 16),

                        // Description Field
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Description',
                          hint: 'e.g., Premium mozzarella cheese topping',
                          helperText: _showHints
                              ? 'Help customers understand this add-on'
                              : null,
                          icon: Icons.description_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),

                        // Required Switch
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: const Text('Required Add-on'),
                                subtitle: Text(
                                  _isRequired
                                      ? 'Customers must select this add-on'
                                      : 'Optional for customers',
                                  style: TextStyle(fontSize: 13),
                                ),
                                value: _isRequired,
                                onChanged: (value) =>
                                    setState(() => _isRequired = value),
                              ),
                              if (_isRequired && _showHints)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.orange.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.orange[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Required add-ons must be selected to complete an order',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange[900],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(isEditing ? 'Update' : 'Add'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEditing, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            child: Icon(
              isEditing ? Icons.edit : Icons.add,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit Add-on' : 'New Add-on',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEditing
                      ? 'Update your add-on details'
                      : 'Create a new add-on option',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? helperText,
    required IconData icon,
    String? prefixText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        helperMaxLines: 2,
        prefixIcon: Icon(icon),
        prefixText: prefixText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines ?? 1,
    );
  }

  String? _validatePrice(String? value) {
    if (value?.trim().isEmpty ?? true) return 'Price is required';
    final price = double.tryParse(value!);
    if (price == null) return 'Invalid price';
    if (price <= 0) return 'Price must be greater than 0';
    return null;
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final addon = FoodAddon(
      id: widget.addon?.id,
      menuId: widget.menuId,
      addonName: _nameController.text.trim(),
      price: double.parse(_priceController.text),
      description: _descriptionController.text.trim(),
      isRequired: _isRequired,
    );

    Navigator.pop(context, addon);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
