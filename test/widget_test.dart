import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixmatch/app/app.dart';
import 'package:fixmatch/features/auth/presentation/screens/login_email_screen.dart';
import 'package:fixmatch/features/auth/presentation/screens/login_password_screen.dart';
import 'package:fixmatch/features/auth/presentation/screens/register_email_screen.dart';
import 'package:fixmatch/features/auth/presentation/screens/technician_application_screen.dart';

void main() {
  testWidgets('FixMatch app opens the welcome screen', (tester) async {
    await tester.pumpWidget(const FixMatchApp());

    expect(find.text('บริการซ่อมบ้าน เริ่มต้นได้ที่ FixMatch'), findsOneWidget);
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
      const MaterialApp(
        home: TechnicianApplicationScreen(email: 'tech@example.com'),
      ),
    );

    final airConditioningChipFinder = find.widgetWithText(
      FilterChip,
      'Air Conditioning',
    );
    final electricalChipFinder = find.widgetWithText(FilterChip, 'Electrical');

    await tester.scrollUntilVisible(airConditioningChipFinder, 100);
    await tester.tap(airConditioningChipFinder);
    await tester.scrollUntilVisible(electricalChipFinder, 100);
    await tester.tap(electricalChipFinder);
    await tester.pump();

    final airConditioningChip = tester.widget<FilterChip>(
      airConditioningChipFinder,
    );
    final electricalChip = tester.widget<FilterChip>(electricalChipFinder);

    expect(airConditioningChip.selected, isTrue);
    expect(electricalChip.selected, isTrue);
  });
}
