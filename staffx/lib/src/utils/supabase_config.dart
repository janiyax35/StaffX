import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'supabase_config.g.dart';

@Riverpod(keepAlive: true)
SupabaseClient supabase(Ref ref) {
  return Supabase.instance.client;
}

class SupabaseConfig {
  // TODO: Replace with your actual Supabase credentials
  static const String url = 'https://xyzcompany.supabase.co';
  static const String anonKey = 'public-anon-key';
}
