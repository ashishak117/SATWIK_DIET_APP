import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'pages/auth_page.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'services/notification_service.dart';
import 'services/reminder_service.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize notifications (timezones etc.)
  await NotificationService().init();

  // Query native side for boot flag
  const platform = MethodChannel('satwik/boot');
  bool bootResync = false;
  try {
    final res = await platform.invokeMethod('getBootExtra');
    if (res is bool) bootResync = res;
  } catch (_) {
    bootResync = false;
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeController(),
      child: MyApp(bootResync: bootResync),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool bootResync;
  const MyApp({super.key, required this.bootResync});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (bootResync) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            await ReminderService().resyncAllForUser(user.uid);
          } catch (_) {}
        }
      }
    });

    final themeCtrl = Provider.of<ThemeController>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Satwik Diet App',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeCtrl.mode,
      home: const AuthPage(),
    );
  }
}
