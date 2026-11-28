import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/customer_account_repository.dart';

final customerAccountRepositoryProvider = Provider<CustomerAccountRepository>(
  (_) => SupabaseCustomerAccountRepository(Supabase.instance.client),
);

final customerProfileRecordProvider =
    FutureProvider.family<CustomerProfileRecord?, String>((ref, profileId) {
      return ref
          .watch(customerAccountRepositoryProvider)
          .loadProfile(profileId: profileId);
    });
