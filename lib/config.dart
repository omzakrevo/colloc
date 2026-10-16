/// Configuration injectée au build avec --dart-define.
///
/// Sans SUPABASE_URL / SUPABASE_ANON_KEY l'application tourne en **mode démo**
/// (données en mémoire, paiement simulé) : idéal pour tester avant AWS.
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Version affichée dans l'app (injectée par la CI : --dart-define=APP_VERSION=...).
  static const appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: 'dev',
  );

  /// Prix d'une mise en contact, en FCFA.
  static const contactFeeFcfa = 1000;

  static bool get isDemo => supabaseUrl.isEmpty || supabaseAnonKey.isEmpty;
}
