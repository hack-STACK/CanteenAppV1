import 'package:flutter/material.dart';
import 'package:kantin/Models/discount.dart';
import 'package:kantin/Models/discount_type.dart';
import 'package:intl/intl.dart';

class EditDiscountDialog extends StatefulWidget {
  final Discount discount;
  final Function(Discount) onSave;
  final bool isExpiredUpdate;

  const EditDiscountDialog({
    super.key,
    required this.discount,
    required this.onSave,
    this.isExpiredUpdate = false,
  });

  @override
  State<EditDiscountDialog> createState() => _EditDiscountDialogState();
}

class _EditDiscountDialogState extends State<EditDiscountDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _percentageController;
  late DateTime _startDate;
  late DateTime _endDate;
  late DiscountType _selectedType;
  late bool _isActive;
  final _formKey = GlobalKey<FormState>();
  bool _hasShownDateWarning = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.discount.discountName);
    _percentageController = TextEditingController(
        text: widget.discount.discountPercentage.toString());
    _startDate = widget.discount.startDate;
    _endDate = widget.discount.endDate;
    _selectedType = DiscountType.fromString(widget.discount.type);
    _isActive = widget.discount.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.isExpiredUpdate ? 'Update Expired Discount' : 'Edit Discount'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isExpiredUpdate)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This discount has expired. Update the dates to reactivate it.',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Discount Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _percentageController,
                decoration: const InputDecoration(
                  labelText: 'Discount Percentage',
                  suffixText: '%',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final number = double.tryParse(value);
                  if (number == null || number <= 0 || number > 100) {
                    return 'Enter valid percentage (1-100)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<DiscountType>(
                value: _selectedType,
                items: DiscountType.values
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.display),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedType = value);
                },
                decoration: const InputDecoration(labelText: 'Applies To'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        DateFormat('MMM dd').format(_startDate),
                      ),
                      onPressed: () => _selectDate(true),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        DateFormat('MMM dd').format(_endDate),
                      ),
                      onPressed: () => _selectDate(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final now = DateTime.now();

    // Determine if the discount is expired
    final isExpired = widget.discount.isExpired;

    // For expired discounts, use today as the initialDate
    final initialDate = isStart
        ? (_startDate.isBefore(now) ? now : _startDate)
        : (_endDate.isBefore(now)
            ? now.add(const Duration(days: 1))
            : _endDate);

    // First date is always today for start date, or start date for end date
    final firstDate = isStart
        ? now
        : (_startDate.isBefore(now)
            ? now.add(const Duration(days: 1))
            : _startDate);

    // Show warning if dates are being adjusted
    if (isExpired && !_hasShownDateWarning) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'The discount dates have been adjusted because the original dates were in the past.'),
          duration: Duration(seconds: 5),
        ),
      );
      _hasShownDateWarning = true;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;

          // If end date is now before start date, adjust it
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _saveChanges() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedDiscount = widget.discount.copyWith(
        discountName: _nameController.text,
        discountPercentage: double.parse(_percentageController.text),
        startDate: _startDate,
        endDate: _endDate,
        type: _selectedType.value, // Convert enum to string value
        isActive: _isActive,
      );
      widget.onSave(updatedDiscount);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _percentageController.dispose();
    super.dispose();
  }
}
