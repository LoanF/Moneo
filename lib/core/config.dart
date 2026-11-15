/// Configuration injectée à la compilation (`--dart-define=CLE=valeur`).
abstract final class AppConfig {
  static const apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://moneo-app.com/api/v1',
  );
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '1048208899254-9i5pcch2vcgapa352e88re81bumcrsqg.apps.googleusercontent.com',
  );
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
}
