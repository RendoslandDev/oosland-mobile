import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!Env.isSupabaseConfigured) return null;
  return Supabase.instance.client;
});

final isDemoModeProvider = Provider<bool>((ref) {
  return !Env.isSupabaseConfigured;
});

Future<void> initializeSupabase() async {
  if (!Env.isSupabaseConfigured) return;
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
}
