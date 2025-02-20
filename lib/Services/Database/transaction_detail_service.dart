import 'package:kantin/Models/transaction_addon_detail_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/models/transaction_detail_model.dart';
import 'package:kantin/models/menu_model.dart';

class TransactionDetailService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<TransactionDetail>> getTransactionDetails(String transactionId) async {
    final response = await _supabase
        .from('transaction_details')
        .select('''
          *,
          menu:menu_id(*),
          addons:transaction_addon_details(
            *,
            addon:addon_id(*)
          )
        ''')
        .eq('transaction_id', transactionId);

    return (response as List)
        .map((detail) => TransactionDetail.fromJson(detail))
        .toList();
  }

  Future<Menu> getMenuById(int menuId) async {
    final response = await _supabase
        .from('menu')
        .select()
        .eq('id', menuId)
        .single();

    return Menu.fromJson(response);
  }

  Future<List<TransactionAddonDetail>> getTransactionAddons(int detailId) async {
    final response = await _supabase
        .from('transaction_addon_details')
        .select('''
          *,
          addon:addon_id(*)
        ''')
        .eq('transaction_detail_id', detailId);

    return (response as List)
        .map((addon) => TransactionAddonDetail.fromJson(addon))
        .toList();
  }

  Stream<List<TransactionDetail>> watchTransactionDetails(String transactionId) {
    return _supabase
        .from('transaction_details')
        .stream(primaryKey: ['id'])
        .eq('transaction_id', transactionId)
        .map((rows) => rows.map((row) => TransactionDetail.fromJson(row)).toList());
  }
}