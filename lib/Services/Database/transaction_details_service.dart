import 'package:kantin/Models/menu_cart_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/utils/logger.dart';
import 'package:kantin/Models/transaction_detail.dart';
import 'package:kantin/Models/menus.dart';

class TransactionDetailsService {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();

  Future<Map<String, dynamic>> getTransactionDetails(int transactionId) async {
    try {
      final result = await _supabase
          .from('transaction_details')
          .select('*, menu:menu_id(*)')
          .eq('transaction_id', transactionId);

      return {'success': true, 'items': result};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> prepareTransactionDetails(
    List<CartItem> items, {
    bool enableDebug = false,
  }) async {
    try {
      return items.map((item) {
        if (enableDebug) {
          _logger.debug('Preparing details for ${item.menu.foodName}');
          _logger.debug('Original price: ${item.originalPrice}');
          _logger.debug('Discounted price: ${item.discountedPrice}');
          _logger.debug('Quantity: ${item.quantity}');
        }

        // Validate menu details
        final menuName = item.menu.foodName.trim();
        if (menuName.isEmpty) {
          throw Exception(
              'Menu name cannot be empty for menu ID: ${item.menu.id}');
        }

        final Map<String, dynamic> detail = {
          'menu_id': item.menu.id,
          'menu_name': menuName, // Using validated menu name
          'menu_price': item.menu.price,
          'menu_photo': item.menu.photo ?? '', // Provide empty string fallback
          'quantity': item.quantity,
          'unit_price': item.discountedPrice ?? item.menu.price,
          'subtotal': (item.discountedPrice ?? item.menu.price) * item.quantity,
          'notes': item.note ?? '',
          'applied_discount_percentage': item.discountPercentage ?? 0.0,
          'original_price': item.originalPrice ?? item.menu.price,
          'discounted_price': item.discountedPrice ?? item.menu.price,
        };

        // Add addon information with validation
        if (item.selectedAddons.isNotEmpty) {
          final addon = item.selectedAddons.first;
          if (addon.addonName.trim().isEmpty) {
            throw Exception(
                'Addon name cannot be empty for addon ID: ${addon.id}');
          }

          detail.addAll({
            'addon_name': addon.addonName.trim(),
            'addon_price': addon.price,
            'addon_quantity': item.quantity,
            'addon_subtotal': addon.price * item.quantity,
          });
        }

        _validateTransactionDetail(detail);
        return detail;
      }).toList();
    } catch (e) {
      _logger.error('Error preparing transaction details', e);
      throw Exception('Failed to prepare transaction details: $e');
    }
  }

  // Add new validation method
  void _validateTransactionDetail(Map<String, dynamic> detail) {
    final requiredFields = {
      'menu_id': 'Menu ID',
      'menu_name': 'Menu Name',
      'menu_price': 'Menu Price',
      'quantity': 'Quantity',
      'unit_price': 'Unit Price',
      'subtotal': 'Subtotal',
    };

    for (var entry in requiredFields.entries) {
      if (detail[entry.key] == null) {
        throw Exception('${entry.value} is required');
      }
    }

    // Validate numeric fields are positive
    final numericFields = ['menu_price', 'quantity', 'unit_price', 'subtotal'];
    for (var field in numericFields) {
      if (detail[field] <= 0) {
        throw Exception('${requiredFields[field]} must be greater than 0');
      }
    }

    // Validate strings are not empty
    if (detail['menu_name'].toString().trim().isEmpty) {
      throw Exception('Menu name cannot be empty');
    }
  }

  Future<Map<String, dynamic>> getTransactionItemDetails(
      int transactionId) async {
    try {
      final response = await _supabase.from('transaction_details').select('''
        id,
        transaction_id,
        menu_id,
        menu_name,
        menu_price,
        menu_photo,
        quantity,
        unit_price,
        subtotal,
        notes,
        addon_name,
        addon_price,
        addon_quantity,
        addon_subtotal,
        original_price,
        discounted_price,
        applied_discount_percentage,
        menu:menu_id (*)
      ''').eq('transaction_id', transactionId);

      return {
        'success': true,
        'items': response,
      };
    } catch (e) {
      _logger.error('Error fetching transaction details', e);
      return {
        'success': false,
        'error': e.toString(),
        'items': [],
      };
    }
  }
}
