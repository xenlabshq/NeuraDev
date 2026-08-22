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

  // google-services.json / firebase_options.dart are already in the repo
  // with a real Firebase project, so this defaults to true. Only pass
  // --dart-define=FIREBASE_CONFIGURED=false for a Firebase-less dev build
  // (e.g. `flutter build linux` on a machine without Firebase set up).
  static const bool firebaseConfigured = bool.fromEnvironment(
    'FIREBASE_CONFIGURED',
    defaultValue: true,
  );

  // google_sign_in 7.x Android'de Credential Manager kullanıyor — bu akış
  // google-services.json'daki Android OAuth client'ını OTOMATİK okumuyor,
  // "Web" tipli (client_type: 3) OAuth client'ı `serverClientId` olarak
  // açıkça istiyor. Verilmezse "No credential available" hatasıyla sessizce
  // başarısız olur. Client ID gizli bir bilgi değil (public, client-side
  // kullanım için tasarlanmış), bu yüzden burada sabit olarak tutulabilir.
  static const String googleServerClientId =
      '526177330312-r7sb1ojjn2tmu1u5fb9avcdc0h99vur0.apps.googleusercontent.com';
}
