// ignore_for_file: deprecated_member_use

import 'package:dam_yar/core/services/local_notification_service.dart';
import 'package:dam_yar/features/navigation/main_shell.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/storage/local_storage_service.dart';
import 'onboarding_page.dart';

class SplashPage extends StatefulWidget {
  final LocalStorageService storageService;
  final LocalNotificationService notificationService;

  const SplashPage({
    super.key,
    required this.storageService,
    required this.notificationService,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await widget.storageService.init();
    await widget.notificationService.init();
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    final nextPage = widget.storageService.isOnboardingCompleted
? MainShell(
            storageService: widget.storageService,
            notificationService: widget.notificationService,
          )
        : OnboardingPage(
            storageService: widget.storageService,
            notificationService: widget.notificationService,
          );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => nextPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.pets_rounded,
                size: 44,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'مدیریت هوشمند دامداری',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'گاو • گوسفند • بز — کاملاً آفلاین',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}