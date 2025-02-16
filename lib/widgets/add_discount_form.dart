import 'package:flutter/material.dart';
import 'package:kantin/Models/discount.dart';
import 'package:kantin/Models/discount_type.dart';

class AddDiscountForm extends StatefulWidget {
  final Function(Discount) onSave;

  const AddDiscountForm({super.key, required this.onSave});

  @override
  State<AddDiscountForm> createState() => _AddDiscountFormState();
}

class _AddDiscountFormState extends State<AddDiscountForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _percentageController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  DiscountType _selectedType = DiscountType.mainPrice;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Discount Name'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _percentageController,
            decoration: InputDecoration(
              labelText: 'Discount Percentage',
              suffixText: '%',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a percentage';
              }
              final number = double.tryParse(value);
              if (number == null || number <= 0 || number > 100) {
                return 'Please enter a valid percentage between 0 and 100';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<DiscountType>(
            value: _selectedType,
            decoration: InputDecoration(labelText: 'Applies To'),
            items: DiscountType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.display),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedType = value);
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  icon: Icon(Icons.calendar_today),
                  label: Text(
                    'Start: ${_startDate.toString().split(' ')[0]}',
                  ),
                  onPressed: () => _selectDate(true),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  icon: Icon(Icons.calendar_today),
                  label: Text(
                    'End: ${_endDate.toString().split(' ')[0]}',
                  ),
                  onPressed: () => _selectDate(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            child: Text('Save Discount'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
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
    if (_formKey.currentState?.validate() ?? false) {
      final discount = Discount(
        id: 0,
        discountName: _nameController.text,
        discountPercentage: double.parse(_percentageController.text),
        startDate: _startDate,
        endDate: _endDate,
        type: _selectedType.value, // Convert enum to string value
      );
      widget.onSave(discount);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _percentageController.dispose();
    super.dispose();
  }
}
