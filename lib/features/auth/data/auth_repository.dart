import 'package:supabase_flutter/supabase_flutter.dart';

bool isAuthSessionFailure(Object error) {
  if (error is AuthSessionMissingException ||
      error is AuthInvalidJwtException ||
      error is AuthRetryableFetchException) {
    return true;
  }

  if (error is AuthException) {
    const invalidSessionCodes = {
      'bad_jwt',
      'invalid_jwt',
      'session_expired',
      'session_missing',
      'session_not_found',
      'refresh_token_not_found',
      'refresh_token_already_used',
    };
    return error.statusCode == '401' ||
        (error.code != null && invalidSessionCodes.contains(error.code));
  }

  if (error is PostgrestException) {
    return error.code == '401' || error.code == 'PGRST301';
  }

  if (error is StorageException) {
    return error.statusCode == '401';
  }

  return false;
}

abstract class AuthRepository {
  User? get currentUser;

  Session? get currentSession;

  Stream<AuthState> get authStateChanges;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  });

  Future<bool> emailExists(String email);

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
  Session? get currentSession => _client.auth.currentSession;

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
  Future<bool> emailExists(String email) async {
    final response = await _client.functions.invoke(
      'check-email',
      body: {'email': email.trim().toLowerCase()},
    );
    final data = response.data;
    final exists = data is Map ? data['exists'] : null;

    if (exists is! bool) {
      throw const FormatException(
        'The check-email function returned an invalid response.',
      );
    }

    return exists;
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
