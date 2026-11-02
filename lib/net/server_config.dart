/// Address of the hosted online battle server that players connect to by
/// default. Change it here after deploying the server (see README "Online"),
/// or override at build time with `--dart-define=BLAST_SERVER=wss://...`.
const String defaultServerUrl = String.fromEnvironment(
  'BLAST_SERVER',
  defaultValue: 'wss://blast-buddies-server.onrender.com',
);
