import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (_) => SupabaseAuthRepository(Supabase.instance.client),
);

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final sessionUser = authState.maybeWhen(
    data: (state) => state.session?.user,
    orElse: () => null,
  );

  return sessionUser ?? ref.watch(authRepositoryProvider).currentUser;
});
