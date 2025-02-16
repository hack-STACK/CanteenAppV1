import 'package:flutter/material.dart';
import 'package:kantin/Models/time_based_discount.dart';

class TimeDiscountEditor extends StatefulWidget {
  final TimeBasedDiscount? initialDiscount;
  final Function(TimeBasedDiscount) onSave;

  const TimeDiscountEditor({
    super.key,
    this.initialDiscount,
    required this.onSave,
  });

  @override
  State<TimeDiscountEditor> createState() => _TimeDiscountEditorState();
}

class _TimeDiscountEditorState extends State<TimeDiscountEditor> {
  late TextEditingController _nameController;
  late TextEditingController _discountController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final discount = widget.initialDiscount;
    _nameController = TextEditingController(text: discount?.name ?? '');
    _discountController = TextEditingController(
        text: discount?.discountPercentage.toString() ?? '');
    _startTime = TimeOfDay.fromDateTime(discount?.startTime ?? DateTime.now());
    _endTime = TimeOfDay.fromDateTime(discount?.endTime ?? DateTime.now());
    _isActive = discount?.isActive ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Discount Name'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _discountController,
                    decoration: InputDecoration(
                      labelText: 'Discount %',
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                Switch(
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: Icon(Icons.access_time),
                    label: Text('Start: ${_startTime.format(context)}'),
                    onPressed: () => _selectTime(context, true),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    icon: Icon(Icons.access_time),
                    label: Text('End: ${_endTime.format(context)}'),
                    onPressed: () => _selectTime(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveDiscount,
              child: Text('Save Discount'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );

    if (time != null) {
      setState(() {
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  void _saveDiscount() {
    final name = _nameController.text;
    final discount = double.tryParse(_discountController.text) ?? 0;

    if (name.isEmpty || discount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields correctly')),
      );
      return;
    }

    final now = DateTime.now();
    final startTime = DateTime(
      now.year,
      now.month,
      now.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endTime = DateTime(
      now.year,
      now.month,
      now.day,
      _endTime.hour,
      _endTime.minute,
    );

    widget.onSave(TimeBasedDiscount(
      name: name,
      discountPercentage: discount,
      startTime: startTime,
      endTime: endTime,
      isActive: _isActive,
    ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _discountController.dispose();
    super.dispose();
  }
}
