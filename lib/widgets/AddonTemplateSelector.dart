import 'package:flutter/material.dart' hide Text;
import 'package:flutter/material.dart' as material show Text;
import 'package:kantin/Models/addon_template.dart';

class AddonTemplateSelector extends StatelessWidget {
  final List<AddonTemplate> templates;
  final Function(AddonTemplate) onSelect;

  const AddonTemplateSelector({
    super.key,
    required this.templates,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return ListTile(
          title: material.Text(template.addonName),
          subtitle: material.Text('Used ${template.useCount} times'),
          trailing: material.Text('Rp ${template.price.toStringAsFixed(0)}'),
          leading: Icon(
            template.isRequired ? Icons.check_circle : Icons.add_circle_outline,
            color: const Color(0xFFFF542D),
          ),
          onTap: () {
            Navigator.pop(context);
            onSelect(template);
          },
        );
      },
    );
  }
}
