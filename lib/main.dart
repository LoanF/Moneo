import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl_standalone.dart';
import 'package:moneo/presentation/view_models/home_view_model.dart';
import 'package:moneo/presentation/view_models/stats_view_model.dart';
import 'package:provider/provider.dart';

import 'core/di.dart';
import 'core/notifiers/auth_notifier.dart';
import 'core/routes/app_router.dart';
import 'core/themes/app_theme.dart';
import 'firebase_options.dart';
import 'presentation/view_models/auth_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  configureDependencies();

  final String systemLocale = await findSystemLocale();
  await initializeDateFormatting(systemLocale, null);
  Intl.defaultLocale = systemLocale;
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<AuthViewModel>()),
        ChangeNotifierProvider(create: (_) => getIt<HomeViewModel>()),
        ChangeNotifierProvider(create: (_) => getIt<StatsViewModel>()),
        ChangeNotifierProvider(create: (_) => getIt<AuthNotifier>()),
      ],
      child: const Moneo(),
    ),
  );
}

class Moneo extends StatelessWidget {
  const Moneo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Moneo',
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}