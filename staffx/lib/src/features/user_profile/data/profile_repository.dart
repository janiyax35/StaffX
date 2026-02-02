import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../utils/supabase_config.dart';
import '../../authentication/data/auth_repository.dart';
import '../domain/profile_model.dart';

part 'profile_repository.g.dart';

class ProfileRepository {
  final SupabaseClient _supabase;
  ProfileRepository(this._supabase);

  Future<Profile?> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return Profile.fromMap(response);
    } catch (e) {
      // Return null if profile doesn't exist yet (though it should via trigger)
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepository(ref.watch(supabaseProvider));
}

@Riverpod(keepAlive: true)
Future<Profile?> userProfile(Ref ref) async {
  final authState = await ref.watch(authStateChangesProvider.future);
  final user = authState.session?.user;

  if (user == null) return null;

  return ref.watch(profileRepositoryProvider).getProfile(user.id);
}
