import 'package:blast_buddies/core/auth/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Access token of the signed-in player, or null for a guest. May be about to
/// expire: ask `authProvider.notifier.freshToken()` right before connecting.
final authTokenProvider = Provider<String?>((ref) => ref.watch(authProvider).session?.accessToken);
