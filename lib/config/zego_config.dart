// ZEGO config:
// - Always provide `--dart-define` (avoid committing secrets to git).
int get zegoAppId {
  const fromEnv = int.fromEnvironment('ZEGO_APP_ID', defaultValue: 0);
  return fromEnv;
}

String get zegoAppSign {
  const fromEnv = String.fromEnvironment('ZEGO_APP_SIGN', defaultValue: '');
  return fromEnv;
}

void assertZegoConfig() {
  if (zegoAppId == 0 || zegoAppSign.isEmpty) {
    throw StateError(
      'Missing ZEGO config. Provide --dart-define=ZEGO_APP_ID and --dart-define=ZEGO_APP_SIGN.',
    );
  }
}
