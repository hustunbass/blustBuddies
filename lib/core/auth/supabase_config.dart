/// Supabase project the app signs in to. These are the *public* values (the
/// project url and the publishable key may ship inside the app); the secret
/// key lives only on the game server.
class SupabaseConfig {
  SupabaseConfig._();

  /// Project url.
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mzdlpndqukaeqnsqjijp.supabase.co',
  );

  /// Publishable (public) key.
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_lBN4RL7ka0vXiDm9rLI9rA_KLqv6xPm',
  );

  /// Google OAuth *Web* client id (also the audience Supabase checks).
  static const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  /// Google OAuth *iOS* client id.
  static const googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  /// Google sign-in works only once the client ids are filled in.
  static bool get googleConfigured => googleWebClientId.isNotEmpty;
}
