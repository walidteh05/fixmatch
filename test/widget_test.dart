import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fixmatch/app/app.dart';
import 'package:fixmatch/features/auth/presentation/screens/login_email_screen.dart';
import 'package:fixmatch/features/auth/presentation/screens/login_password_screen.dart';
import 'package:fixmatch/features/auth/presentation/screens/register_email_screen.dart';
import 'package:fixmatch/features/technician/data/technician_registration_repository.dart';
import 'package:fixmatch/features/technician/presentation/screens/technician_application_screen.dart';
import 'package:fixmatch/features/technician/technician_providers.dart';

void main() {
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

  testWidgets('FixMatch app opens the welcome screen', (tester) async {
    await tester.pumpWidget(const FixMatchApp());

    expect(find.text('บริการซ่อมบ้าน เริ่มต้นได้ที่นี่'), findsOneWidget);
  });

  test('login email validation rejects invalid email', () {
    expect(validateLoginEmail('invalid-email'), 'รูปแบบอีเมลไม่ถูกต้อง');
  });

  test('login password validation rejects short password', () {
    expect(validateLoginPassword('123'), 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร');
  });

  test('email availability parser treats new email as available', () {
    final result = EmailAvailabilityResult.fromJson({'exists': false});

    expect(result.exists, isFalse);
    expect(result.isPendingTechnician, isFalse);
  });

  test('email availability parser recognizes pending technician email', () {
    final result = EmailAvailabilityResult.fromJson({
      'exists': true,
      'account_type': 'technician',
      'technician_status': 'pending',
    });

    expect(result.exists, isTrue);
    expect(result.accountType, 'technician');
    expect(result.technicianStatus, 'pending');
    expect(result.isPendingTechnician, isTrue);
  });

  test(
    'email availability parser rejects already-used non-pending account',
    () {
      final result = EmailAvailabilityResult.fromJson({
        'exists': true,
        'account_type': 'customer',
      });

      expect(result.exists, isTrue);
      expect(result.isPendingTechnician, isFalse);
    },
  );

  testWidgets('technician form allows selecting multiple service categories', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          technicianRegistrationRepositoryProvider.overrideWithValue(
            _FakeTechnicianRegistrationRepository([
              const ServiceCategory(
                id: 'air-conditioning',
                name: 'Air Conditioning',
                slug: 'air-conditioning',
                isActive: true,
              ),
              const ServiceCategory(
                id: 'electrical',
                name: 'Electrical',
                slug: 'electrical',
                isActive: true,
              ),
            ]),
          ),
        ],
        child: const MaterialApp(
          home: TechnicianApplicationScreen(email: 'tech@example.com'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final airConditioningFinder = find.text('Air Conditioning');
    final electricalFinder = find.text('Electrical');

    await tester.ensureVisible(airConditioningFinder);
    await tester.tap(airConditioningFinder);
    await tester.pumpAndSettle();
    await tester.ensureVisible(electricalFinder);
    await tester.tap(electricalFinder);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle_outline_rounded), findsNWidgets(2));
  });
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

class _FakeTechnicianRegistrationRepository
    implements TechnicianRegistrationRepository {
  _FakeTechnicianRegistrationRepository(this.categories);

  final List<ServiceCategory> categories;

  @override
  Future<List<ServiceCategory>> loadActiveServiceCategories() async =>
      categories;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
