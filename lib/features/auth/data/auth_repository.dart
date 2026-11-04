import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  User? get currentUser;

  Stream<AuthState> get authStateChanges;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  });

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) async {
    final normalizedMetadata = <String, dynamic>{};

    for (final entry in metadata.entries) {
      final key = entry.key.trim();
      if (key.isEmpty) {
        continue;
      }

      if (key == 'status' || key == 'is_admin') {
        throw const FormatException(
          'status and admin flags are managed by the backend and cannot be set from the client.',
        );
      }

      normalizedMetadata[key] = entry.value;
    }

    final role = normalizedMetadata['role'];
    final normalizedRole = role is String ? role.trim().toLowerCase() : null;
    const allowedRoles = {'customer', 'technician'};

    if (normalizedRole == null || !allowedRoles.contains(normalizedRole)) {
      throw const FormatException(
        'Registration role must be either "customer" or "technician".',
      );
    }

    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: normalizedMetadata,
    );
  }

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}
