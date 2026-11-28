import 'package:supabase_flutter/supabase_flutter.dart';

class RecommendedTechnician {
  const RecommendedTechnician({
    required this.profileId,
    required this.fullName,
    required this.bio,
    required this.serviceArea,
    required this.serviceCategories,
  });

  final String profileId;
  final String fullName;
  final String? bio;
  final String? serviceArea;
  final Set<String> serviceCategories;
}

abstract interface class CustomerMarketplaceRepository {
  Future<List<RecommendedTechnician>> loadRecommendedTechnicians();
}

class SupabaseCustomerMarketplaceRepository
    implements CustomerMarketplaceRepository {
  SupabaseCustomerMarketplaceRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<RecommendedTechnician>> loadRecommendedTechnicians() async {
    final technicianRows = await _client
        .from('technician_profiles')
        .select('profile_id, bio, service_area')
        .eq('status', 'approved')
        .order('profile_id');

    final ids = technicianRows
        .map((row) => row['profile_id'])
        .whereType<String>()
        .toSet();
    if (ids.isEmpty) return const [];

    final profiles = await _client
        .from('profiles')
        .select('id, full_name')
        .inFilter('id', ids.toList());
    final namesById = <String, String>{
      for (final row in profiles)
        if (row['id'] is String && row['full_name'] is String)
          row['id'] as String: (row['full_name'] as String).trim(),
    };

    final assignments = await _client
        .from('technician_service_categories')
        .select('technician_profile_id, category_id')
        .inFilter('technician_profile_id', ids.toList());
    final categoryIds = assignments
        .map((row) => row['category_id'])
        .whereType<Object>()
        .toSet();
    final categoriesById = <Object, String>{};
    if (categoryIds.isNotEmpty) {
      final categoryRows = await _client
          .from('service_categories')
          .select('id, name')
          .inFilter('id', categoryIds.toList());
      for (final row in categoryRows) {
        final id = row['id'];
        final name = row['name'];
        if ((id is String || id is num) && name is String) {
          categoriesById[id] = name;
        }
      }
    }

    final categoriesByTechnician = <String, Set<String>>{};
    for (final row in assignments) {
      final profileId = row['technician_profile_id'];
      final categoryName = categoriesById[row['category_id']];
      if (profileId is String && categoryName != null) {
        categoriesByTechnician
            .putIfAbsent(profileId, () => <String>{})
            .add(categoryName);
      }
    }

    return [
      for (final row in technicianRows)
        if (row['profile_id'] is String &&
            (namesById[row['profile_id']]?.isNotEmpty ?? false))
          RecommendedTechnician(
            profileId: row['profile_id'] as String,
            fullName: namesById[row['profile_id']]!,
            bio: row['bio'] as String?,
            serviceArea: row['service_area'] as String?,
            serviceCategories:
                categoriesByTechnician[row['profile_id']] ?? const <String>{},
          ),
    ];
  }
}
