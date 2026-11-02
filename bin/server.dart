import 'dart:io';

import 'package:blast_buddies/net/protocol.dart';
import 'package:blast_buddies/net/server/blast_server.dart';

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
  final server = BlastServer(log: (m) => stdout.writeln('[${DateTime.now().toIso8601String()}] $m'));
  await server.start(port: port);
  Future<void> shutdown(ProcessSignal _) async {
    await server.close();
    exit(0);
  }

  ProcessSignal.sigint.watch().listen(shutdown);
  if (!Platform.isWindows) ProcessSignal.sigterm.watch().listen(shutdown);
}
