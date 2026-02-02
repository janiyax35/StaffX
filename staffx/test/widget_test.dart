import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staffx/main.dart';
import 'package:staffx/src/utils/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mocktail/mocktail.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  testWidgets('App starts and shows Login screen', (tester) async {
    // Mock Supabase
    final mockSupabase = MockSupabaseClient();
    final mockAuth = MockGoTrueClient();
    when(() => mockSupabase.auth).thenReturn(mockAuth);
    when(() => mockAuth.onAuthStateChange).thenAnswer(
      (_) =>
          Stream.value(const AuthState(AuthChangeEvent.initialSession, null)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [supabaseProvider.overrideWithValue(mockSupabase)],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();
    // Should see Login
    expect(find.text('Login'), findsOneWidget);
  });
}
