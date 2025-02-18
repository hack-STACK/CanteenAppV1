import 'package:flutter/material.dart';
import 'package:kantin/Models/discount.dart';
import 'package:kantin/Models/discount_type.dart';
import 'package:kantin/Models/menu_discount.dart';
import 'package:kantin/services/database/discountService.dart';
import 'package:intl/intl.dart';
import 'package:kantin/widgets/edit_discount_dialog.dart'; // Ensure this import is added

class DiscountManagementScreen extends StatefulWidget {
  final List<int>? selectedMenuIds; // Optional: for mass discount application

  const DiscountManagementScreen({super.key, this.selectedMenuIds});

  @override
  State<DiscountManagementScreen> createState() =>
      _DiscountManagementScreenState();
}

class _DiscountManagementScreenState extends State<DiscountManagementScreen> {
  final DiscountService _discountService = DiscountService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discount Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addDiscount,
          ),
        ],
      ),
      body: FutureBuilder<List<Discount>>(
        future: _discountService.getDiscounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No discounts available'));
          } else {
            final discounts = snapshot.data!;
            return ListView.builder(
              itemCount: discounts.length,
              itemBuilder: (context, index) {
                final discount = discounts[index];
                return _buildDiscountCard(discount);
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildDiscountCard(Discount discount) {
    final isActive = discount.isActive &&
        discount.startDate.isBefore(DateTime.now()) &&
        discount.endDate.isAfter(DateTime.now());
    final discountType = DiscountType.fromString(discount.type);

    return Card(
      child: ListTile(
        title: Text(discount.discountName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${discount.discountPercentage}% off'),
            Text(
              'Applies to: ${discountType.display}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              'Valid: ${DateFormat('MMM dd').format(discount.startDate)} - ${DateFormat('MMM dd').format(discount.endDate)}',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: SizedBox(
          width: 100,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: isActive,
                onChanged: (value) async {
                  try {
                    await _discountService.toggleDiscountStatus(
                        discount.id, value);
                    if (mounted) {
                      setState(() {
                        discount.isActive = value;
                      });
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update status: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => _editDiscount(discount),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline),
                onPressed: () => _deleteDiscount(discount),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addDiscount() async {
    final DateTime now = DateTime.now();
    final discount = await showDialog<Discount>(
      context: context,
      builder: (context) => DiscountDialog(
        initialStartDate: now,
        initialEndDate: now.add(const Duration(days: 7)),
      ),
    );

    if (discount != null) {
      try {
        await _discountService.addDiscount(discount);
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        _showError('Failed to add discount: $e');
      }
    }
  }

  Future<void> _applyDiscountToMenus(Discount discount) async {
    if (widget.selectedMenuIds == null || widget.selectedMenuIds!.isEmpty) {
      _showError('No menus selected');
      return;
    }

    try {
      for (final menuId in widget.selectedMenuIds!) {
        await _discountService.addMenuDiscount(
          MenuDiscount(
            id: 0, // ID will be generated by the database
            menuId: menuId,
            discountId: discount.id,
            isActive: discount.isActive, // Add this line
          ),
        );
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Failed to apply discount: $e');
    }
  }

  Future<void> _deleteDiscount(Discount discount) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
            'Are you sure you want to delete the discount "${discount.discountName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _discountService.deleteDiscount(discount.id);
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        _showError('Failed to delete discount: $e');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _editDiscount(Discount discount) {
    showDialog(
      context: context,
      builder: (context) => EditDiscountDialog(
        discount: discount,
        onSave: (updatedDiscount) async {
          try {
            await _discountService.updateDiscount(updatedDiscount);
            if (mounted) {
              Navigator.pop(context); // Close dialog
              setState(() {});
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update discount: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }
}

class DiscountDialog extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;

  const DiscountDialog({
    super.key,
    required this.initialStartDate,
    required this.initialEndDate,
  });

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _percentageController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Discount'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Discount Name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _percentageController,
              decoration: const InputDecoration(
                labelText: 'Discount Percentage',
                suffixText: '%',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a percentage';
                }
                final percentage = double.tryParse(value);
                if (percentage == null || percentage <= 0 || percentage > 100) {
                  return 'Please enter a valid percentage between 0 and 100';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _selectDate(context, true),
                    child: Text(
                        'Start: ${DateFormat('MMM dd').format(_startDate)}'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => _selectDate(context, false),
                    child:
                        Text('End: ${DateFormat('MMM dd').format(_endDate)}'),
                  ),
                ),
              ],
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
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: isStart ? DateTime.now() : _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final discount = Discount(
        id: 0, // ID will be generated by the database
        discountName: _nameController.text,
        discountPercentage: double.parse(_percentageController.text),
        startDate: _startDate,
        endDate: _endDate,
        isActive: true, // Default to active
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        type: 'mainPrice', stallId: 0, // Default type
      );
      Navigator.pop(context, discount);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _percentageController.dispose();
    super.dispose();
  }
}
