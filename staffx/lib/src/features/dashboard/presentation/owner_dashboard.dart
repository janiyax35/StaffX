import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/data/auth_repository.dart';

class OwnerDashboard extends ConsumerWidget {
  const OwnerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Owner Dashboard')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
          child: const Text('Logout'),
        ),
      ),
    );
  }
}
