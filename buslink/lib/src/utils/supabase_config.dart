import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'supabase_config.g.dart';

@Riverpod(keepAlive: true)
SupabaseClient supabase(Ref ref) {
  return Supabase.instance.client;
}

class SupabaseConfig {
  static const String url = 'https://scatrogjswkdfahyxrbs.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNjYXRyb2dqc3drZGZhaHl4cmJzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxMTk4MjEsImV4cCI6MjA4NTY5NTgyMX0.fm_jcxP0MUXsIrRzWbHaPTrJH3A7MboJrp9eWx-m9Ew';
}
