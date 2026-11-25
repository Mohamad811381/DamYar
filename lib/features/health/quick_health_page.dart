// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../core/services/local_notification_service.dart';
import '../../data/storage/local_storage_service.dart';
import 'quick_health_sheet.dart';

class QuickHealthPage extends StatelessWidget {
  final LocalStorageService storageService;
  final LocalNotificationService notificationService;
  final VoidCallback onSaved;

  const QuickHealthPage({
    super.key,
    required this.storageService,
    required this.notificationService,
    required this.onSaved,
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
          storageService: storageService,
          notificationService: notificationService,
          onSaved: onSaved,
        ),
      ),
    );
  }
}
