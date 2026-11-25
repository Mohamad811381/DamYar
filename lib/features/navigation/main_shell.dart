// ignore_for_file: deprecated_member_use

import 'package:dam_yar/features/health/quick_health_page.dart';
import 'package:dam_yar/features/navigation/app_bottom_nav.dart';
import 'package:flutter/material.dart';

import '../../core/services/local_notification_service.dart';
import '../../data/storage/local_storage_service.dart';
import '../finance/inventory_finance_page.dart';
import '../home/home_page.dart';
import '../livestock/livestock_page.dart';

class MainShell extends StatefulWidget {
  final LocalStorageService storageService;
  final LocalNotificationService notificationService;

  const MainShell({
    super.key,
    required this.storageService,
    required this.notificationService,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _dataVersion = 0;

  /// هر بار که یکی از صفحات داده را تغییر می‌دهد، این شمارنده بالا می‌رود
  /// تا بقیه صفحات در didUpdateWidget داده‌هایشان را دوباره بخوانند.
  void _onDataChanged() {
    setState(() => _dataVersion++);
  }

  void _selectTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(
            storageService: widget.storageService,
            notificationService: widget.notificationService,
            dataVersion: _dataVersion,
            onDataChanged: _onDataChanged,
            onSelectTab: _selectTab,
          ),
          LivestockPage(
            storageService: widget.storageService,
            dataVersion: _dataVersion,
            onDataChanged: _onDataChanged,
          ),
          InventoryFinancePage(
            storageService: widget.storageService,
            dataVersion: _dataVersion,
            onDataChanged: _onDataChanged,
          ),
          QuickHealthPage(
            storageService: widget.storageService,
            notificationService: widget.notificationService,
            onSaved: _onDataChanged,
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onChanged: _selectTab,
      ),
    );
  }
}
