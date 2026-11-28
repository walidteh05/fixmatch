import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fixmatch/features/auth/application/auth_providers.dart';
import 'package:fixmatch/features/customer/application/customer_marketplace_providers.dart';
import 'package:fixmatch/features/customer/data/customer_marketplace_repository.dart';
import 'package:fixmatch/features/customer/presentation/screens/customer_home_screen.dart';

void main() {
  Future<void> pumpCustomerHome(
    WidgetTester tester, {
    User? user,
    List<RecommendedTechnician> technicians = const [],
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(user),
          recommendedTechniciansProvider.overrideWith(
            (ref) async => technicians,
          ),
        ],
        child: const MaterialApp(home: CustomerHomeScreen()),
      ),
    );
  }

  testWidgets('shows the signed-in customer name in the greeting', (
    tester,
  ) async {
    final user = User.fromJson({
      'id': 'customer-id',
      'app_metadata': <String, dynamic>{},
      'user_metadata': {
        'full_name': '\u{e2a}\u{e21}\u{e0a}\u{e32}\u{e22}\u{20}\u{e43}\u{e08}\u{e14}\u{e35}',
      },
      'aud': 'authenticated',
      'created_at': '2026-01-01T00:00:00.000Z',
    });

    await pumpCustomerHome(tester, user: user);

    expect(
      find.text(
        '\u{e2a}\u{e27}\u{e31}\u{e2a}\u{e14}\u{e35}, \u{e2a}\u{e21}\u{e0a}\u{e32}\u{e22}\u{20}\u{e43}\u{e08}\u{e14}\u{e35}',
      ),
      findsOneWidget,
    );
    expect(
      find.byTooltip(
        '\u{e01}\u{e32}\u{e23}\u{e41}\u{e08}\u{e49}\u{e07}\u{e40}\u{e15}\u{e37}\u{e2d}\u{e19}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('promotional banner focuses the existing search field', (
    tester,
  ) async {
    await pumpCustomerHome(tester);

    expect(find.text('มีปัญหาเรื่องบ้านใช่ไหม?'), findsOneWidget);
    expect(
      find.text('ค้นหาช่างที่เหมาะกับงานของคุณได้ที่ FixMatch'),
      findsOneWidget,
    );

    await tester.tap(find.text('ค้นหาช่างเลย'));
    await tester.pump();

    final searchField = tester.widget<TextField>(
      find.byKey(const ValueKey('customerHomeSearchField')),
    );
    expect(searchField.focusNode?.hasFocus, isTrue);
  });

  testWidgets(
    'recommended technician data opens details without invented ratings',
    (tester) async {
      await pumpCustomerHome(
        tester,
        technicians: const [
          RecommendedTechnician(
            profileId: 'technician-1',
            fullName: '\u{e0a}\u{e48}\u{e32}\u{e07}\u{e2a}\u{e21}\u{e0a}\u{e32}\u{e22}',
            bio: 'Air conditioner maintenance',
            serviceArea: '\u{e01}\u{e23}\u{e38}\u{e07}\u{e40}\u{e17}\u{e1e}',
            serviceCategories: {
              '\u{e0a}\u{e48}\u{e32}\u{e07}\u{e41}\u{e2d}\u{e23}\u{e4c}',
            },
          ),
        ],
      );
      await tester.pumpAndSettle();
      final homeScrollable = find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text(
          '\u{e0a}\u{e48}\u{e32}\u{e07}\u{e2a}\u{e21}\u{e0a}\u{e32}\u{e22}',
        ),
        180,
        scrollable: homeScrollable,
      );
      expect(
        find.text(
          '\u{e0a}\u{e48}\u{e32}\u{e07}\u{e2a}\u{e21}\u{e0a}\u{e32}\u{e22}',
        ),
        findsOneWidget,
      );
      expect(
        find.text('\u{e01}\u{e23}\u{e38}\u{e07}\u{e40}\u{e17}\u{e1e}'),
        findsOneWidget,
      );

      await tester.tap(
        find.text(
          '\u{e0a}\u{e48}\u{e32}\u{e07}\u{e2a}\u{e21}\u{e0a}\u{e32}\u{e22}',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('4.9'), findsNothing);
    },
  );

  testWidgets('bottom navigation opens all four destinations', (tester) async {
    await pumpCustomerHome(tester);
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(
      find.text('\u0e04\u0e49\u0e19\u0e2b\u0e32\u0e0a\u0e48\u0e32\u0e07'),
      findsOneWidget,
    );

    await tester.tap(find.text('Bookings'));
    await tester.pumpAndSettle();
    expect(find.text('\u0e01\u0e32\u0e23\u0e08\u0e2d\u0e07'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(
      find.text('\u0e42\u0e1b\u0e23\u0e44\u0e1f\u0e25\u0e4c'),
      findsOneWidget,
    );

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('customerHomeSearchField')),
      findsOneWidget,
    );
  });

  testWidgets('filter sheet exposes supported service and area filters', (
    tester,
  ) async {
    await pumpCustomerHome(tester);
    await tester.tap(
      find.byTooltip('\u0e15\u0e31\u0e27\u0e01\u0e23\u0e2d\u0e07'),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        '\u0e15\u0e31\u0e27\u0e01\u0e23\u0e2d\u0e07\u0e0a\u0e48\u0e32\u0e07',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        '\u0e1e\u0e37\u0e49\u0e19\u0e17\u0e35\u0e48\u0e43\u0e2b\u0e49\u0e1a\u0e23\u0e34\u0e01\u0e32\u0e23',
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.text(
        '\u0e25\u0e49\u0e32\u0e07\u0e15\u0e31\u0e27\u0e01\u0e23\u0e2d\u0e07',
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('search filters categories and clear restores them', (
    tester,
  ) async {
    await pumpCustomerHome(tester);
    final searchField = find.byKey(const ValueKey('customerHomeSearchField'));

    expect(
      find.text('\u{e0a}\u{e48}\u{e32}\u{e07}\u{e41}\u{e2d}\u{e23}\u{e4c}'),
      findsOneWidget,
    );
    await tester.enterText(searchField, '\u{e01}\u{e38}\u{e0d}\u{e41}\u{e08}');
    await tester.pump();
    expect(
      find.text(
        '\u{e0a}\u{e48}\u{e32}\u{e07}\u{e01}\u{e38}\u{e0d}\u{e41}\u{e08}',
      ),
      findsOneWidget,
    );
    expect(
      find.text('\u{e0a}\u{e48}\u{e32}\u{e07}\u{e41}\u{e2d}\u{e23}\u{e4c}'),
      findsNothing,
    );

    await tester.enterText(
      searchField,
      '\u{e44}\u{e21}\u{e48}\u{e21}\u{e35}\u{e2b}\u{e21}\u{e27}\u{e14}\u{e19}\u{e35}\u{e49}',
    );
    await tester.pump();
    expect(
      find.text(
        '\u{e44}\u{e21}\u{e48}\u{e1e}\u{e1a}\u{e2b}\u{e21}\u{e27}\u{e14}\u{e2b}\u{e21}\u{e39}\u{e48}\u{e17}\u{e35}\u{e48}\u{e04}\u{e49}\u{e19}\u{e2b}\u{e32}',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byTooltip(
        '\u{e25}\u{e49}\u{e32}\u{e07}\u{e04}\u{e33}\u{e04}\u{e49}\u{e19}\u{e2b}\u{e32}',
      ),
    );
    await tester.pump();
    expect(
      find.text('\u{e0a}\u{e48}\u{e32}\u{e07}\u{e41}\u{e2d}\u{e23}\u{e4c}'),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.text(
        '\u{e14}\u{e39}\u{e17}\u{e31}\u{e49}\u{e07}\u{e2b}\u{e21}\u{e14}',
      ),
    );
    await tester.tap(
      find.text(
        '\u{e14}\u{e39}\u{e17}\u{e31}\u{e49}\u{e07}\u{e2b}\u{e21}\u{e14}',
      ),
    );
    await tester.pump();
    expect(
      find.text(
        '\u{e0a}\u{e48}\u{e32}\u{e07}\u{e01}\u{e38}\u{e0d}\u{e41}\u{e08}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('selecting a category shows selected state', (tester) async {
    await pumpCustomerHome(tester);
    await tester.tap(
      find.text('\u0e0a\u0e48\u0e32\u0e07\u0e41\u0e2d\u0e23\u0e4c'),
    );
    await tester.pump();
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('report CTA opens an informational form without submitting', (
    tester,
  ) async {
    await pumpCustomerHome(tester);
    final reportButton = find.text(
      '\u0e40\u0e23\u0e34\u0e48\u0e21\u0e15\u0e49\u0e19\u0e41\u0e08\u0e49\u0e07\u0e1b\u0e31\u0e0d\u0e2b\u0e32',
    );
    final homeScrollable = find
        .descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      reportButton,
      240,
      scrollable: homeScrollable,
    );
    await tester.ensureVisible(reportButton);
    await tester.pumpAndSettle();
    await tester.tap(reportButton);
    await tester.pumpAndSettle();
    expect(
      find.text(
        '\u0e41\u0e08\u0e49\u0e07\u0e1b\u0e31\u0e0d\u0e2b\u0e32\u0e07\u0e32\u0e19\u0e0b\u0e48\u0e2d\u0e21',
      ),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsOneWidget);
  });
}
