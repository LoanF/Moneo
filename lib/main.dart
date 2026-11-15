import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'core/config.dart';
import 'core/local_store.dart';
import 'data/models.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  Intl.defaultLocale = 'fr_FR';
  await initializeDateFormatting('fr_FR');

  // Les préférences de l'appareil sont lues avant le premier affichage : pas de flash de thème,
  // et le verrou est en place dès la première image.
  final store = FileLocalStore();
  final saved = await store.read('device_prefs');
  final prefs = saved is Json
      ? DevicePrefs.fromJson(saved)
      : const DevicePrefs();

  final app = ProviderScope(
    // Pas de nouvelle tentative automatique : les écrans proposent un bouton « Réessayer ».
    retry: (_, _) => null,
    overrides: [
      localStoreProvider.overrideWithValue(store),
      initialDevicePrefsProvider.overrideWithValue(prefs),
    ],
    child: const MoneoApp(),
  );

  if (AppConfig.sentryDsn.isEmpty) return runApp(app);
  await SentryFlutter.init((options) {
    options.dsn = AppConfig.sentryDsn;
    options.tracesSampleRate = 0.1;
    // Application financière : aucune donnée personnelle ne part dans les rapports d'erreur.
    options.sendDefaultPii = false;
    options.beforeSend = (event, hint) {
      event.request?.headers.remove('Authorization');
      return event;
    };
  }, appRunner: () => runApp(app));
}
