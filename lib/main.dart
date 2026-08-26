import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'models/api_error.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/unlock_screen.dart';
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

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _offeringBiometric = false;

  Future<void> _offerBiometricIfNeeded(AuthController auth) async {
    if (_offeringBiometric || !auth.justLoggedInWithPassword) return;
    auth.clearJustLoggedInFlag();
    final offer = await auth.offerBiometricIfAvailable();
    if (!offer || !mounted) return;
    _offeringBiometric = true;
    try {
      final enable = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('간편 열기', style: TextStyle(fontWeight: FontWeight.w800)),
          content: const Text(
            '다음부터는 지문이나 얼굴로 앱을 열 수 있습니다.\n켜 둘까요?',
            style: TextStyle(height: 1.4, fontSize: 16),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('나중에')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('켜기')),
          ],
        ),
      );
      if (enable == true && mounted) {
        try {
          await auth.enableBiometric();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('지문·얼굴로 열기가 켜졌습니다. 앱을 다시 열 때 사용됩니다.')),
          );
        } catch (e) {
          if (!mounted) return;
          final msg = e is ApiException ? e.message : '생체 설정을 완료하지 못했습니다.';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    } finally {
      _offeringBiometric = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (!auth.ready) {
      return const Scaffold(
        backgroundColor: AppColors.navy,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (auth.locked) {
      return const UnlockScreen();
    }
    if (auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PushService.instance.consumePending();
        _offerBiometricIfNeeded(auth);
      });
      return const ShellScreen();
    }
    return const LoginScreen();
  }
}
