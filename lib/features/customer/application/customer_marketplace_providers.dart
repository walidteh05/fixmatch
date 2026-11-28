import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/customer_marketplace_repository.dart';

final customerMarketplaceRepositoryProvider =
    Provider<CustomerMarketplaceRepository>(
      (_) => SupabaseCustomerMarketplaceRepository(Supabase.instance.client),
    );

final recommendedTechniciansProvider =
    FutureProvider<List<RecommendedTechnician>>((ref) {
      return ref
          .watch(customerMarketplaceRepositoryProvider)
          .loadRecommendedTechnicians();
    });
