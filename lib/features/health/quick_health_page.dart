// ignore_for_file: unnecessary_brace_in_string_interps, deprecated_member_use

import 'package:flutter/material.dart';

import '../../core/services/local_notification_service.dart';
import '../../data/storage/local_storage_service.dart';
import 'quick_health_sheet.dart';

class QuickHealthPage extends StatelessWidget {
  final LocalStorageService storageService;
  final LocalNotificationService notificationService;
  final VoidCallback onSaved;
  final int refreshToken;

  const QuickHealthPage({
    super.key,
    required this.storageService,
    required this.notificationService,
    required this.onSaved,
    this.refreshToken = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'دادن دارو',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: QuickHealthSheet(
          key: ValueKey('quick-${refreshToken}'),
          storageService: storageService,
          notificationService: notificationService,
          onSaved: onSaved,
        ),
      ),
    );
  }
}
