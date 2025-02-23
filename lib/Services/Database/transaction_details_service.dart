import 'package:kantin/Models/menu_cart_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/utils/logger.dart';
import 'package:kantin/Models/transaction_detail.dart';
import 'package:kantin/Models/menus.dart';

class TransactionDetailsService {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();

  Future<List<TransactionDetail>> getTransactionDetails(
      int transactionId) async {
    try {
      _logger.debug('Fetching details for transaction: $transactionId');

      final response = await _supabase
          .from('transaction_details')
          .select('''
            *,
            menu:menu_id (*),
            transaction_addon_details (
              *,
              addon:addon_id (*)
            )
          ''')
          .eq('transaction_id', transactionId)
          .order('created_at', ascending: true);

      return (response as List).map((item) {
        _logger.debug('Processing detail item: ${item['menu']['food_name']}');

        final menuData = item['menu'];
        final menu = Menu.fromJson(menuData);

        return TransactionDetail(
          id: item['id'],
          transactionId: item['transaction_id'],
          menuId: item['menu_id'],
          quantity: item['quantity'],
          unitPrice: (item['unit_price'] as num).toDouble(),
          subtotal: (item['subtotal'] as num).toDouble(),
          notes: item['notes'],
          createdAt: DateTime.parse(item['created_at']),
          menu: menu,
          appliedDiscountPercentage:
              (item['applied_discount_percentage'] as num?)?.toDouble() ?? 0.0,
          originalPrice: (item['original_price'] as num).toDouble(),
          discountedPrice: (item['discounted_price'] as num).toDouble(),
        );
      }).toList();
    } catch (e, stack) {
      _logger.error('Failed to fetch transaction details', e, stack);
      throw Exception('Error fetching transaction details: $e');
    }
  }

  Future<List<Map<String, dynamic>>> prepareTransactionDetails(
      List<CartItem> cart,
      {required bool enableDebug}) async {
    if (enableDebug) {
      _logger.debug('\n=== Preparing Transaction Details ===');
    }

    return cart.map((item) {
      if (enableDebug) {
        _logger.debug('Processing item: ${item.menu.foodName}');
        _logger.debug('Original Price: ${item.originalPrice}');
        _logger.debug('Discounted Price: ${item.discountedPrice}');
        _logger.debug('Quantity: ${item.quantity}');
        _logger.debug('Discount %: ${item.discountPercentage}');
      }

      final addons = item.selectedAddons.map((addon) {
        final addonPrice = addon.price;
        final addonTotal = addonPrice * item.quantity;

        if (enableDebug) {
          _logger.debug('Addon: ${addon.addonName}');
          _logger
              .debug('  Price: $addonPrice x ${item.quantity} = $addonTotal');
        }

        return {
          'addon_id': addon.id,
          'addon_name': addon.addonName,
          'quantity': item.quantity,
          'unit_price': addonPrice,
          'subtotal': addonTotal,
        };
      }).toList();

      return {
        'menu_id': item.menu.id,
        'quantity': item.quantity,
        'unit_price': item.originalPrice,
        'subtotal': item.discountedPrice * item.quantity,
        'notes': item.note ?? '',
        'original_price': item.originalPrice,
        'discounted_price': item.discountedPrice,
        'applied_discount_percentage': item.discountPercentage,
        'addons': addons,
      };
    }).toList();
  }
}
