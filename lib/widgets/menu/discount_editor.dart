import 'package:flutter/material.dart';
import 'package:kantin/Models/time_based_discount.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DiscountEditor extends StatefulWidget {
  final TimeBasedDiscount? initialDiscount;
  final Function(TimeBasedDiscount) onSave;

  const DiscountEditor({
    super.key,
    this.initialDiscount,
    required this.onSave,
  });

  @override
  State<DiscountEditor> createState() => _DiscountEditorState();
}

class _DiscountEditorState extends State<DiscountEditor> {
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
      text: discount?.discountPercentage.toString() ?? '',
    );
    _startTime = TimeOfDay.fromDateTime(
      discount?.startTime ?? DateTime.now(),
    );
    _endTime = TimeOfDay.fromDateTime(
      discount?.endTime ?? DateTime.now().add(const Duration(hours: 1)),
    );
    _isActive = discount?.isActive ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Discount Name',
                border: OutlineInputBorder(),
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _discountController,
                    decoration: const InputDecoration(
                      labelText: 'Discount %',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    const Text('Active'),
                    Switch(
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                  ],
                ),
              ],
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text('Start: ${_startTime.format(context)}'),
                    onPressed: () => _selectTime(context, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text('End: ${_endTime.format(context)}'),
                    onPressed: () => _selectTime(context, false),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveDiscount,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Save Discount'),
            ).animate().fadeIn(duration: 300.ms).scale(),
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
    // Implementation
  }

  @override
  void dispose() {
    _nameController.dispose();
    _discountController.dispose();
    super.dispose();
  }
}
