import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'services/api_client.dart';
import 'services/push_service.dart';
import 'services/token_store.dart';
import 'state/auth_controller.dart';
import 'state/jobs_controller.dart';
import 'state/notifications_controller.dart';
import 'state/profile_controller.dart';
import 'state/schedules_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko');

  final store = TokenStore();
  await store.init();
  final api = ApiClient(store);
  final auth = AuthController(api, store);
  auth.onSessionReady = () => PushService.instance.syncToken();

  runApp(
    MultiProvider(
      providers: [
        Provider<TokenStore>.value(value: store),
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider<AuthController>.value(value: auth),
        ChangeNotifierProvider(create: (_) => JobsController(api)),
        ChangeNotifierProvider(create: (_) => SchedulesController(api)),
        ChangeNotifierProvider(create: (_) => NotificationsController(api)),
        ChangeNotifierProvider(create: (_) => ProfileController(api)),
      ],
      child: const CaregiverApp(),
    ),
  );

  await auth.bootstrap();
  await PushService.instance.init(auth);
}

class CaregiverApp extends StatelessWidget {
  const CaregiverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '요양보호사',
      debugShowCheckedModeBanner: false,
      navigatorKey: PushService.instance.navigatorKey,
      theme: buildAppTheme(),
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (!auth.ready) {
      return const Scaffold(
        backgroundColor: AppColors.navy,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PushService.instance.consumePending();
      });
      return const ShellScreen();
    }
    return const LoginScreen();
  }
}
