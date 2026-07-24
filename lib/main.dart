import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/supabase/supabase_client.dart';
import 'shared/repositories/app_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeSupabase();

  final container = ProviderContainer();
  await container.read(appRepositoryProvider).initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const OslandApp(),
    ),
  );
}
