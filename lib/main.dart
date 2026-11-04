
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final url = dotenv.env['SUPABASE_URL'] ?? dotenv.env['NEXT_PUBLIC_SUPABASE_URL'];
  final anonKey =
      dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
      dotenv.env['NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY'];

  if (url == null || anonKey == null) {
    throw FlutterError(
      'Missing Supabase configuration in .env. Expected SUPABASE_URL/SUPABASE_PUBLISHABLE_KEY or NEXT_PUBLIC_SUPABASE_URL/NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY.',
    );
  }

  await Supabase.initialize(
    url: url,
    // ignore: deprecated_member_use
    anonKey: anonKey,
  );

  runApp(
    const ProviderScope(
      child: FixMatchApp(),
    ),
  );
}
