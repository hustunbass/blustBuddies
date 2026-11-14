import 'dart:io' show Platform;
import 'dart:math';

import 'package:blast_buddies/core/auth/auth_service.dart';
import 'package:blast_buddies/core/auth/supabase_config.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Keeps the session in the Keychain (iOS) / Keystore (Android).
class SecureSessionStore implements SessionStore {
  /// Creates the store.
  const SecureSessionStore();

  static const _key = 'boompals_session';
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> write(String? value) async {
    try {
      if (value == null) {
        await _storage.delete(key: _key);
      } else {
        await _storage.write(key: _key, value: value);
      }
    } on Object {
      // Not being able to remember the session only means signing in again.
    }
  }
}

/// Apple and Google system sheets.
class PlatformIdTokens implements IdTokenSource {
  /// Creates the source.
  PlatformIdTokens();

  bool _googleReady = false;

  @override
  bool isSupported(AuthProvider provider) {
    if (kIsWeb) return false;
    return switch (provider) {
      AuthProvider.apple => Platform.isIOS || Platform.isMacOS,
      AuthProvider.google => SupabaseConfig.googleConfigured && (Platform.isIOS || Platform.isAndroid),
    };
  }

  static String _nonce() {
    final r = Random.secure();
    return List.generate(32, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  Future<IdCredential?> obtain(AuthProvider provider) async {
    switch (provider) {
      case AuthProvider.apple:
        // Apple puts the *hash* of the nonce into the token; Supabase wants
        // the raw value to compare.
        final raw = _nonce();
        try {
          final c = await SignInWithApple.getAppleIDCredential(
            scopes: const [],
            nonce: sha256.convert(raw.codeUnits).toString(),
          );
          final t = c.identityToken;
          if (t == null) throw AuthFailure('Apple returned no token');
          return IdCredential(t, nonce: raw);
        } on SignInWithAppleAuthorizationException catch (e) {
          if (e.code == AuthorizationErrorCode.canceled) return null;
          throw AuthFailure('Apple: ${e.code.name}');
        }
      case AuthProvider.google:
        try {
          if (!_googleReady) {
            await GoogleSignIn.instance.initialize(
              clientId: Platform.isIOS && SupabaseConfig.googleIosClientId.isNotEmpty
                  ? SupabaseConfig.googleIosClientId
                  : null,
              serverClientId: SupabaseConfig.googleWebClientId,
            );
            _googleReady = true;
          }
          final account = await GoogleSignIn.instance.authenticate();
          final t = account.authentication.idToken;
          if (t == null) throw AuthFailure('Google returned no token');
          return IdCredential(t);
        } on GoogleSignInException catch (e) {
          if (e.code == GoogleSignInExceptionCode.canceled) return null;
          throw AuthFailure('Google: ${e.code.name}');
        }
    }
  }

  @override
  Future<void> signOut(AuthProvider provider) async {
    if (provider == AuthProvider.google && _googleReady) {
      try {
        await GoogleSignIn.instance.signOut();
      } on Object {
        // Nothing to clean up.
      }
    }
  }
}
