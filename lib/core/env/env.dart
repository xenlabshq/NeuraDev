abstract class Env {
  static const String appName = 'Neuroup';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.neuroup.app/v1',
  );
  static const String openAiKey = String.fromEnvironment('OPENAI_KEY');
  static const String geminiKey = String.fromEnvironment('GEMINI_KEY');
  static const String streamApiKey = String.fromEnvironment('STREAM_API_KEY');
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: true,
  );
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
  );

  // Set to true via --dart-define=FIREBASE_CONFIGURED=true once
  // google-services.json / firebase_options.dart are added.
  static const bool firebaseConfigured = bool.fromEnvironment(
    'FIREBASE_CONFIGURED',
  );

  static Future<void> load() async {}
}
