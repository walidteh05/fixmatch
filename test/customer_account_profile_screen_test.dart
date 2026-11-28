import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fixmatch/app/router/app_routes.dart';
import 'package:fixmatch/features/auth/application/auth_providers.dart';
import 'package:fixmatch/features/auth/data/auth_repository.dart';
import 'package:fixmatch/features/customer/application/customer_account_providers.dart';
import 'package:fixmatch/features/customer/data/customer_account_repository.dart';
import 'package:fixmatch/features/customer/presentation/screens/customer_account_profile_screen.dart';

void main() {
  late User user;
  late _FakeAuthRepository authRepository;
  late _FakeCustomerAccountRepository accountRepository;

  setUpAll(() async {
    await Supabase.initialize(
      url: 'http://localhost:54321',
      publishableKey: 'test-publishable-key',
      authOptions: const FlutterAuthClientOptions(
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
        pkceAsyncStorage: _NoopPkceStorage(),
      ),
      debug: false,
    );
  });

  setUp(() {
    user = User.fromJson({
      'id': 'customer-profile-test',
      'app_metadata': <String, dynamic>{},
      'user_metadata': {'full_name': 'Test Customer'},
      'aud': 'authenticated',
      'email': 'customer@example.com',
      'created_at': '2026-01-01T00:00:00.000Z',
    })!;
    authRepository = _FakeAuthRepository(user);
    accountRepository = _FakeCustomerAccountRepository(
      const CustomerProfileRecord(
        fullName: 'Test Customer',
        phone: '0812345678',
      ),
    );
  });

  testWidgets('loads profile data and saves changes to the existing profile', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(user),
          authRepositoryProvider.overrideWithValue(authRepository),
          customerAccountRepositoryProvider.overrideWithValue(
            accountRepository,
          ),
        ],
        child: const MaterialApp(home: CustomerAccountProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test Customer'), findsWidgets);
    expect(find.text('customer@example.com'), findsWidgets);

    await tester.tap(
      find.byTooltip(
        '\u{0e41}\u{0e01}\u{0e49}\u{0e44}\u{0e02}\u{0e42}\u{0e1b}\u{0e23}\u{0e44}\u{0e1f}\u{0e25}\u{0e4c}',
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Updated Customer',
    );
    await tester.tap(
      find.text(
        '\u{0e1a}\u{0e31}\u{0e19}\u{0e17}\u{0e36}\u{0e01}\u{0e02}\u{0e49}\u{0e2d}\u{0e21}\u{0e39}\u{0e25}',
      ),
    );
    await tester.pumpAndSettle();

    expect(accountRepository.updatedFullName, 'Updated Customer');
    expect(find.text('Updated Customer'), findsWidgets);
  });

  testWidgets('sign out clears the session and navigates to login', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const CustomerAccountProfileScreen(),
        ),
        GoRoute(
          path: '/login',
          name: AppRoute.loginEmail,
          builder: (context, state) =>
              const Scaffold(body: Text('Login route')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(user),
          authRepositoryProvider.overrideWithValue(authRepository),
          customerAccountRepositoryProvider.overrideWithValue(
            accountRepository,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final logoutIcon = find.byIcon(Icons.logout_rounded);
    await tester.scrollUntilVisible(
      logoutIcon,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(logoutIcon);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(authRepository.didSignOut, isTrue);
    expect(find.text('Login route'), findsOneWidget);
  });
}

class _FakeCustomerAccountRepository implements CustomerAccountRepository {
  _FakeCustomerAccountRepository(this.profile);

  CustomerProfileRecord profile;
  String? updatedFullName;

  @override
  Future<CustomerProfileRecord?> loadProfile({
    required String profileId,
  }) async => profile;

  @override
  Future<CustomerProfileRecord> updateProfile({
    required String profileId,
    required String fullName,
    required String phone,
  }) async {
    updatedFullName = fullName;
    profile = CustomerProfileRecord(fullName: fullName, phone: phone);
    return profile;
  }
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.user);

  final User user;
  bool didSignOut = false;

  @override
  User? get currentUser => user;

  @override
  Session? get currentSession => null;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) => throw UnimplementedError();

  @override
  Future<bool> emailExists(String email) => throw UnimplementedError();

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async {
    didSignOut = true;
  }
}

class _NoopPkceStorage extends GotrueAsyncStorage {
  const _NoopPkceStorage();

  @override
  Future<String?> getItem({required String key}) async => null;

  @override
  Future<void> setItem({required String key, required String value}) async {}

  @override
  Future<void> removeItem({required String key}) async {}
}
