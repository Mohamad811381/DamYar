// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'package:dam_yar/core/services/local_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'data/storage/local_storage_service.dart';
import 'features/startup/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = LocalStorageService();
  final notificationService = LocalNotificationService();

  runApp(
    LivestockApp(
      storageService: storageService,
      notificationService: notificationService,
    ),
  );
}

class LivestockApp extends StatelessWidget {
  final LocalStorageService storageService;
  final LocalNotificationService notificationService;

  const LivestockApp({
    super.key,
    required this.storageService,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدیریت دامداری',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: SplashPage(
        storageService: storageService,
        notificationService: notificationService,
      ),
    );
  }
}
