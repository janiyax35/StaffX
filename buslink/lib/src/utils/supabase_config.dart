import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'supabase_config.g.dart';

@Riverpod(keepAlive: true)
SupabaseClient supabase(Ref ref) {
  return Supabase.instance.client;
}

class SupabaseConfig {
  static const String url = 'https://fwltzkvxldqoeutnikwb.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ3bHR6a3Z4bGRxb2V1dG5pa3diIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxMzc1NjUsImV4cCI6MjA4NTcxMzU2NX0.BYSUblpEAbFj48JvnggXzGoJJ_1tiLLuHUa6Qz4Ah-8';
}
