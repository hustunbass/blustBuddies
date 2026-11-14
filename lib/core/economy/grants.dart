import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:blast_buddies/core/auth/auth_provider.dart';
import 'package:blast_buddies/core/economy/wallet.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/net/online_client.dart' show parseServerAddress;
import 'package:blast_buddies/net/server_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A gift of coins from the admin.
class GrantItem {
  /// Creates a grant.
  const GrantItem(this.id, this.coins);

  /// Row id: used so a gift is never credited twice.
  final int id;

  /// Coins to add.
  final int coins;
}

/// Talks to the game server's `/grants` endpoints over HTTP(S).
class GrantsClient {
  /// Creates the client.
  GrantsClient({HttpClient? http}) : _http = http ?? (HttpClient()..connectionTimeout = const Duration(seconds: 8));

  final HttpClient _http;

  Future<(int, String)> _post(Uri uri, String token, [Object? body]) async {
    final req = await _http.postUrl(uri).timeout(const Duration(seconds: 10));
    req.headers
      ..set(HttpHeaders.authorizationHeader, 'Bearer $token')
      ..set(HttpHeaders.contentTypeHeader, 'application/json');
    req.add(utf8.encode(jsonEncode(body ?? const {})));
    final res = await req.close().timeout(const Duration(seconds: 10));
    final text = await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 10));
    return (res.statusCode, text);
  }

  /// Gifts waiting for the player behind [token].
  Future<List<GrantItem>> pending(Uri base, String token) async {
    final (status, body) = await _post(base.resolve('/grants'), token);
    if (status != 200) throw HttpException('grants answered $status');
    final j = jsonDecode(body);
    if (j is! Map || j['grants'] is! List) return const [];
    return [
      for (final g in j['grants'] as List)
        if (g is Map && g['id'] is int && g['coins'] is int) GrantItem(g['id'] as int, g['coins'] as int),
    ];
  }

  /// Tells the server that the gifts [ids] were credited.
  Future<void> ack(Uri base, String token, List<int> ids) async {
    final (status, _) = await _post(base.resolve('/grants/ack'), token, {'ids': ids});
    if (status != 200) throw HttpException('grants ack answered $status');
  }
}

/// The grants client; tests override it.
final grantsClientProvider = Provider<GrantsClient>((ref) => GrantsClient());

/// Coins credited by the last claim, for a toast. Reset by whoever shows it.
class GrantNoticeNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// Publishes [coins] (0 clears).
  void set(int coins) => state = coins;
}

/// See [GrantNoticeNotifier].
final grantNoticeProvider = NotifierProvider<GrantNoticeNotifier, int>(GrantNoticeNotifier.new);

/// Base url (http/https) of the game server the player uses.
Uri grantsBase(ProviderContainer c) {
  final custom = (c.read(prefsProvider).getString('onlineCustomServer') ?? '').trim();
  final ws = parseServerAddress(custom.isEmpty ? defaultServerUrl : custom) ?? Uri.parse(defaultServerUrl);
  return ws.replace(scheme: ws.scheme == 'wss' ? 'https' : 'http', path: '/');
}

bool _claiming = false;

/// Asks the server for gifts of the signed-in player, adds the coins to the
/// wallet and confirms them. A gift is credited at most once per device (its
/// id is remembered), even if confirming fails and the server offers it again.
/// Returns the coins added. Never throws: no network just means no gifts yet.
Future<int> claimGrants(ProviderContainer c) async {
  if (_claiming) return 0;
  _claiming = true;
  try {
    final token = await c.read(authProvider.notifier).freshToken();
    if (token == null) return 0;
    final base = grantsBase(c);
    final client = c.read(grantsClientProvider);
    final list = await client.pending(base, token);
    if (list.isEmpty) return 0;
    final prefs = c.read(prefsProvider);
    final applied = (prefs.getStringList('appliedGrants') ?? const <String>[]).toList();
    var total = 0;
    for (final g in list) {
      if (applied.contains('${g.id}')) continue;
      total += g.coins;
      applied.add('${g.id}');
    }
    if (total > 0) {
      await prefs.setStringList('appliedGrants', applied.length > 200 ? applied.sublist(applied.length - 200) : applied);
      await c.read(walletProvider.notifier).earn(total);
    }
    try {
      await client.ack(base, token, [for (final g in list) g.id]);
    } on Object {
      // Offered again next time; the remembered ids stop a double credit.
    }
    if (total > 0) c.read(grantNoticeProvider.notifier).set(total);
    return total;
  } on Object {
    return 0;
  } finally {
    _claiming = false;
  }
}
