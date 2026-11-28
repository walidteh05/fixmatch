import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/technician_registration_repository.dart';

final technicianRegistrationRepositoryProvider =
    Provider<TechnicianRegistrationRepository>(
  (_) => SupabaseTechnicianRegistrationRepository(
    Supabase.instance.client,
  ),
);
