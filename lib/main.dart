import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl_standalone.dart';
import 'package:moneo/presentation/view_models/home_view_model.dart';
import 'package:moneo/presentation/view_models/stats_view_model.dart';
import 'package:provider/provider.dart';
import 'core/di.dart';
import 'core/notifiers/auth_notifier.dart';
import 'core/notifiers/lock_notifier.dart';
import 'core/routes/app_router.dart';
import 'core/themes/app_theme.dart';
import 'firebase_options.dart';
import 'presentation/view_models/auth_view_model.dart';
import 'presentation/views/lock_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  configureDependencies();
  await getIt<LockNotifier>().initialize();

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
        ChangeNotifierProvider(create: (_) => getIt<LockNotifier>()),
      ],
      child: const Moneo(),
    ),
  );
}

class Moneo extends StatefulWidget {
  const Moneo({super.key});

  @override
  State<Moneo> createState() => _MoneoState();
}

class _MoneoState extends State<Moneo> with WidgetsBindingObserver {
  DateTime? _lastBackgroundTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lastBackgroundTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      getIt<LockNotifier>().checkAutoLock(_lastBackgroundTime);
      _lastBackgroundTime = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Moneo',
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('es'),
        Locale('de'),
        Locale('it'),
        Locale('pt'),
        Locale('ar'),
        Locale('zh'),
        Locale('ja'),
      ],
      builder: (context, child) {
        return Consumer2<LockNotifier, AuthNotifier>(
          builder: (context, lockNotifier, authNotifier, _) {
            if (lockNotifier.isLocked && authNotifier.isAuthenticated) {
              return const LockScreen();
            }
            return child!;
          },
        );
      },
    );
  }
}