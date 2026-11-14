import 'dart:io';

import 'package:blast_buddies/net/protocol.dart';
import 'package:blast_buddies/net/server/blast_server.dart';
import 'package:blast_buddies/net/server/supabase.dart';

/// Online battle server.
///
/// ```
/// dart run bin/server.dart [--port 8080]
/// ```
/// Port can also come from the `PORT` environment variable (cloud hosts).
Future<void> main(List<String> args) async {
  final i = args.indexOf('--port');
  final port = i >= 0 && i + 1 < args.length
      ? int.parse(args[i + 1])
      : int.tryParse(Platform.environment['PORT'] ?? '') ?? defaultServerPort;
  void log(String m) => stdout.writeln('[${DateTime.now().toIso8601String()}] $m');
  // Ranked play needs all three; without them the server is casual-only.
  final env = Platform.environment;
  final url = env['SUPABASE_URL'], anon = env['SUPABASE_ANON_KEY'], service = env['SUPABASE_SERVICE_KEY'];
  final rankedOn = [url, anon, service].every((e) => e != null && e.isNotEmpty);
  final server = BlastServer(
    log: log,
    auth: rankedOn ? SupabaseAuth(SupabaseApi(url!, anon!)) : null,
    ranks: rankedOn ? SupabaseRankStore(SupabaseApi(url!, service!)) : null,
  );
  log(rankedOn ? 'ranked play: ON (Supabase)' : 'ranked play: off (SUPABASE_URL / _ANON_KEY / _SERVICE_KEY not set)');
  await server.start(port: port);
  Future<void> shutdown(ProcessSignal _) async {
    await server.close();
    exit(0);
  }

  ProcessSignal.sigint.watch().listen(shutdown);
  if (!Platform.isWindows) ProcessSignal.sigterm.watch().listen(shutdown);
}
