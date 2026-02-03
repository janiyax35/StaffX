import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../utils/supabase_config.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  final SupabaseClient _supabase;
  AuthRepository(this._supabase);

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  User? get currentUser => _supabase.auth.currentUser;

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail(
    String email,
    String password,
    Map<String, dynamic> data,
  ) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(ref.watch(supabaseProvider));
}

@Riverpod(keepAlive: true)
Stream<AuthState> authStateChanges(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}
