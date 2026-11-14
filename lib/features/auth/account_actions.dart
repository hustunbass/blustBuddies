import 'package:blast_buddies/core/auth/auth_provider.dart';
import 'package:blast_buddies/core/auth/auth_service.dart';
import 'package:blast_buddies/core/profile/profile.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/features/online/online_screen.dart';
import 'package:blast_buddies/net/online_client.dart';
import 'package:blast_buddies/net/server_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Drops the online connection and connects again with the current sign-in,
/// so the server knows who the player is now.
Future<bool> reconnectOnline(ProviderContainer c, OnlineClient client) async {
  final prefs = c.read(prefsProvider);
  final name = c.read(profileProvider).name;
  final st = c.read(settingsProvider);
  final custom = (prefs.getString('onlineCustomServer') ?? '').trim();
  await client.disconnect();
  final token = await c.read(authProvider.notifier).freshToken();
  return client.connect(
    custom.isEmpty ? defaultServerUrl : custom,
    name,
    skin: [st.hat, st.face, st.color],
    authToken: token,
  );
}

/// After the sign-in changed: an open online connection is renewed so the
/// server sees the new identity; a closed one simply connects as the player
/// is next time.
Future<void> refreshOnlineIdentity(ProviderContainer c) async {
  final client = c.read(onlineClientProvider);
  if (client.status == OnlineStatus.connected) await reconnectOnline(c, client);
}

/// Signs in with [provider]; on success the online connection is renewed.
Future<SignInResult> signInFlow(ProviderContainer c, AuthProvider provider) async {
  final result = await c.read(authProvider.notifier).signIn(provider);
  if (result == SignInResult.ok) await refreshOnlineIdentity(c);
  return result;
}

/// Signs out; the online connection (if any) continues as a guest.
Future<void> signOutFlow(ProviderContainer c) async {
  await c.read(authProvider.notifier).signOut();
  await refreshOnlineIdentity(c);
}

/// Deletes the signed-in player's account on the server, then signs out.
/// Connects first if needed (the deletion goes through the game server).
/// False if it did not work; nothing is changed then.
Future<bool> deleteAccountFlow(ProviderContainer c) async {
  final client = c.read(onlineClientProvider);
  if (client.status != OnlineStatus.connected || client.rank == null) {
    if (!await reconnectOnline(c, client)) return false;
  }
  if (!await client.deleteAccount()) return false;
  await c.read(authProvider.notifier).signOut();
  await client.disconnect();
  return true;
}
