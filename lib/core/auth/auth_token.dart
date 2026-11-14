import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the access token of the signed-in player (Supabase), or null for a
/// guest. The online screen sends it in `hello`; changing it needs a reconnect.
class AuthTokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Stores the token (null = signed out).
  void set(String? token) => state = token;
}

/// See [AuthTokenNotifier].
final authTokenProvider = NotifierProvider<AuthTokenNotifier, String?>(AuthTokenNotifier.new);
