import 'dart:math';
import 'dart:ui' show PlatformDispatcher;

import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/net/protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How the player is signed in. Only [guest] exists until the Apple and
/// Google sign-in credentials are set up; [ProfileNotifier.linkAccount] is the
/// single place those flows will call.
enum AuthKind {
  /// Plays without an account.
  guest,

  /// Signed in with Apple.
  apple,

  /// Signed in with Google.
  google,
}

/// Rules and generators for player names.
class PlayerNames {
  PlayerNames._();

  /// Shortest accepted name.
  static const int minLength = 2;

  /// Longest accepted name (same limit the server enforces).
  static const int maxLength = Limits.name;

  static final RegExp _allowed = RegExp(r'^[\p{L}\p{N} _.\-]+$', unicode: true);

  /// Trims and collapses inner whitespace.
  static String clean(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Whether [raw] is acceptable once cleaned.
  static bool isValid(String raw) {
    final n = clean(raw);
    return n.length >= minLength && n.length <= maxLength && _allowed.hasMatch(n);
  }

  static const _adjectivesEn = ['Cool', 'Swift', 'Lucky', 'Sneaky', 'Brave', 'Fuzzy', 'Spicy', 'Mighty'];
  static const _adjectivesTr = ['Cesur', 'Hızlı', 'Şanslı', 'Sinsi', 'Tatlı', 'Güçlü', 'Neşeli', 'Atik'];
  static const _nounsEn = ['Buddy', 'Bomber', 'Blaster', 'Boomer', 'Fuse', 'Sparky'];
  static const _nounsTr = ['Buddy', 'Bombacı', 'Patlatıcı', 'Fitil', 'Kıvılcım', 'Usta'];

  /// A fresh default name: `Guest_4821` / `Misafir_4821` for guests, a friendlier
  /// `SwiftBuddy_4821` once the player has an account.
  static String suggest(AuthKind kind, {Random? rng, bool? turkish}) {
    final r = rng ?? Random();
    final tr = turkish ?? PlatformDispatcher.instance.locale.languageCode == 'tr';
    final n = 1000 + r.nextInt(9000);
    if (kind == AuthKind.guest) return '${tr ? 'Misafir' : 'Guest'}_$n';
    final adj = (tr ? _adjectivesTr : _adjectivesEn)[r.nextInt(_adjectivesEn.length)];
    final noun = (tr ? _nounsTr : _nounsEn)[r.nextInt(_nounsEn.length)];
    final name = '$adj$noun';
    final out = '${name}_$n';
    // Stay within the length limit.
    return out.length <= maxLength ? out : '${name.substring(0, maxLength - 5)}_$n';
  }
}

/// The player's identity.
class ProfileData {
  /// Creates a profile.
  const ProfileData({required this.name, this.kind = AuthKind.guest, this.customName = false});

  /// Display name (also used in online matches).
  final String name;

  /// Sign-in state.
  final AuthKind kind;

  /// The player picked this name themselves (so it is never overwritten).
  final bool customName;
}

/// Persists the profile; creates the default guest name on first launch.
class ProfileNotifier extends Notifier<ProfileData> {
  /// Random source (overridable in tests).
  Random rng = Random();

  @override
  ProfileData build() {
    final p = ref.watch(prefsProvider);
    final kind = AuthKind.values.firstWhere(
      (k) => k.name == p.getString('authKind'),
      orElse: () => AuthKind.guest,
    );
    final saved = p.getString('username');
    if (saved != null && saved.isNotEmpty) {
      return ProfileData(name: saved, kind: kind, customName: p.getBool('usernameCustom') ?? false);
    }
    // Players of earlier versions already typed a name for online play.
    final legacy = PlayerNames.clean(p.getString('onlineName') ?? '');
    if (PlayerNames.isValid(legacy)) {
      p
        ..setString('username', legacy)
        ..setBool('usernameCustom', true);
      return ProfileData(name: legacy, kind: kind, customName: true);
    }
    final name = PlayerNames.suggest(kind, rng: rng);
    p
      ..setString('username', name)
      ..setBool('usernameCustom', false);
    return ProfileData(name: name, kind: kind);
  }

  /// Sets a name chosen by the player. Returns false if it is not valid.
  Future<bool> rename(String raw) async {
    if (!PlayerNames.isValid(raw)) return false;
    final name = PlayerNames.clean(raw);
    state = ProfileData(name: name, kind: state.kind, customName: true);
    final p = ref.read(prefsProvider);
    await p.setString('username', name);
    await p.setBool('usernameCustom', true);
    return true;
  }

  /// Replaces the name with a fresh suggestion (still counts as the player's
  /// own choice afterwards only if they edit it).
  Future<String> randomize() async {
    final name = PlayerNames.suggest(state.kind, rng: rng);
    state = ProfileData(name: name, kind: state.kind);
    final p = ref.read(prefsProvider);
    await p.setString('username', name);
    await p.setBool('usernameCustom', false);
    return name;
  }

  /// Called after a successful Apple/Google sign-in. A name the player chose
  /// is kept; an auto-generated guest name becomes an account-style default.
  Future<void> linkAccount(AuthKind kind) async {
    final name = state.customName ? state.name : PlayerNames.suggest(kind, rng: rng);
    state = ProfileData(name: name, kind: kind, customName: state.customName);
    final p = ref.read(prefsProvider);
    await p.setString('authKind', kind.name);
    await p.setString('username', name);
  }
}

/// Profile provider.
final profileProvider = NotifierProvider<ProfileNotifier, ProfileData>(ProfileNotifier.new);
