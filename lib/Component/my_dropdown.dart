import 'package:flutter/material.dart';

class MyDropdown extends StatelessWidget {
  final String? value;
  final String? hintText;
  final Color? hintColor;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final EdgeInsetsGeometry? padding;
  final InputDecoration? decoration;
  final bool isExpanded;
  final double? height;

  const MyDropdown({
    super.key,
    this.value,
    this.hintText,
    this.hintColor,
    required this.items,
    this.onChanged,
    this.validator,
    this.onSaved,
    this.padding,
    this.decoration,
    this.isExpanded = true,
    this.height, // Custom height for the dropdown
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: height ?? 56, // Default height, but can be overridden
        child: DropdownButtonFormField<String>(
          value: value,
          isExpanded: isExpanded,
          decoration: decoration ??
              InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                hintText: hintText,
                hintStyle: TextStyle(color: hintColor ?? Colors.grey),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16, // Default padding
                  horizontal: 16,
                ),
              ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
          onSaved: onSaved,
        ),
      ),
    );
  }
}
