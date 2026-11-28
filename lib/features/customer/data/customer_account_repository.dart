import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerProfileRecord {
  const CustomerProfileRecord({required this.fullName, required this.phone});

  final String? fullName;
  final String? phone;

  factory CustomerProfileRecord.fromRow(Map<String, dynamic> row) {
    return CustomerProfileRecord(
      fullName: row['full_name']?.toString(),
      phone: row['phone']?.toString(),
    );
  }
}

abstract interface class CustomerAccountRepository {
  Future<CustomerProfileRecord?> loadProfile({required String profileId});

  Future<CustomerProfileRecord> updateProfile({
    required String profileId,
    required String fullName,
    required String phone,
  });
}

class SupabaseCustomerAccountRepository implements CustomerAccountRepository {
  SupabaseCustomerAccountRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<CustomerProfileRecord?> loadProfile({
    required String profileId,
  }) async {
    final row = await _client
        .from('profiles')
        .select('full_name, phone')
        .eq('id', profileId)
        .maybeSingle();
    if (row == null) return null;
    return CustomerProfileRecord.fromRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<CustomerProfileRecord> updateProfile({
    required String profileId,
    required String fullName,
    required String phone,
  }) async {
    final row = await _client
        .from('profiles')
        .update({'full_name': fullName, 'phone': phone})
        .eq('id', profileId)
        .select('full_name, phone')
        .single();
    return CustomerProfileRecord.fromRow(Map<String, dynamic>.from(row));
  }
}
