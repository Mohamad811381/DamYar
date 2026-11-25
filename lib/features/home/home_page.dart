// ignore_for_file: deprecated_member_use

import 'package:dam_yar/data/models/livestock_enums.dart';
import 'package:flutter/material.dart';

import '../../core/services/local_notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/jalali_helper.dart';
import '../../data/models/health_record.dart';
import '../../data/models/reminder_task.dart';
import '../../data/storage/local_storage_service.dart';
import '../health/quick_health_sheet.dart';
import '../shared/livestock_dialogs.dart';

class HomePage extends StatefulWidget {
  final LocalStorageService storageService;
  final LocalNotificationService notificationService;
  final int dataVersion;
  final int refreshToken;
  final VoidCallback onDataChanged;
  final ValueChanged<int> onSelectTab;

  const HomePage({
    super.key,
    required this.storageService,
    required this.notificationService,
    required this.dataVersion,
    this.refreshToken = 0,
    required this.onDataChanged,
    required this.onSelectTab,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ReminderTask> _reminders = [];
  List<HealthRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  String _subtitleFor(ReminderTask task) {
    for (final a in widget.storageService.getAllAnimals()) {
      if (a.id == task.animalId) {
        return 'پلاک ${a.tagNumber} • ${a.species.label}';
      }
    }
    for (final g in widget.storageService.getAllGroups()) {
      if (g.id == task.groupId) {
        return 'گله ${g.name} • ${g.species.label}';
      }
    }
    return 'برای همه دام‌ها';
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataVersion != widget.dataVersion ||
        oldWidget.refreshToken != widget.refreshToken) {
      _refreshData();
    }
  }

  void _refreshData() {
    setState(() {
      _reminders = widget.storageService.getAllReminders();
      final records = List<HealthRecord>.from(
        widget.storageService.getAllHealthRecords(),
      );
      records.sort((a, b) => b.administeredAt.compareTo(a.administeredAt));
      _records = records;
    });
  }

  void _saveDone() {
    _refreshData();
    widget.onDataChanged();
  }

  Future<void> _toggleReminder(ReminderTask task) async {
    final updated = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: !task.isCompleted ? DateTime.now() : null,
    );
    await widget.storageService.upsertReminder(updated);

    if (updated.isCompleted) {
      await widget.notificationService.cancelReminder(task.notificationId);
    } else if (updated.dueDate.isAfter(DateTime.now())) {
      await widget.notificationService.scheduleReminder(
        id: updated.notificationId,
        title: updated.title,
        body: updated.description ?? 'یادآور دامداری',
        scheduledDate: updated.dueDate,
      );
    }

    _saveDone();
  }

  void _openQuickHealthSheet() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (pageCtx) => Scaffold(
          appBar: AppBar(
            title: const Text(
              'دادن دارو',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          body: SafeArea(
            child: QuickHealthSheet(
              storageService: widget.storageService,
              notificationService: widget.notificationService,
              onSaved: _saveDone,
            ),
          ),
        ),
      ),
    );
  }

  void _openFromDrawer(VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  bool _isDueToday(ReminderTask r) {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return !r.dueDate.isAfter(endOfToday);
  }

  Future<void> _confirmDone(ReminderTask task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأیید انجام کار'),
        content: Text('«${task.title}» انجام شد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('نه'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('بله'),
          ),
        ],
      ),
    );
    if (ok == true) await _toggleReminder(task);
  }

  void _openTaskDetails(ReminderTask task) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.checklist_rounded,
                      color: AppTheme.primaryGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _DetailLine(
                label: 'مربوط به',
                value: _targetOf(
                  animalId: task.animalId,
                  groupId: task.groupId,
                ),
              ),
              _DetailLine(
                label: 'موعد',
                value: JalaliHelper.formatReadable(task.dueDate),
              ),
              if (task.description != null && task.description!.isNotEmpty)
                _DetailLine(label: 'توضیح', value: task.description!),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _confirmDone(task);
                  },
                  icon: const Icon(Icons.check_rounded, size: 24),
                  label: const Text(
                    'انجام شد',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'بستن',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _targetOf({String? animalId, String? groupId}) {
    for (final a in widget.storageService.getAllAnimals()) {
      if (a.id == animalId) {
        return 'پلاک ${a.tagNumber} • ${a.species.label}';
      }
    }
    for (final g in widget.storageService.getAllGroups()) {
      if (g.id == groupId) {
        return 'گله ${g.name} • ${g.species.label}';
      }
    }
    return 'برای همه دام‌ها';
  }

  void _openRecordDetails(HealthRecord record) {
    final target = _targetOf(
      animalId: record.animalId,
      groupId: record.groupId,
    );
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: AppTheme.primaryGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      record.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _DetailLine(label: 'مربوط به', value: target),
              _DetailLine(label: 'نوع کار', value: record.actionType.label),
              _DetailLine(
                label: 'تاریخ',
                value: JalaliHelper.formatReadable(record.administeredAt),
              ),
              if (record.dosage != null && record.dosage!.isNotEmpty)
                _DetailLine(label: 'دوز', value: '${record.dosage} سی‌سی'),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'بستن',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final openTasks = _reminders
        .where((r) => !r.isCompleted && _isDueToday(r))
        .toList();
    final recentRecords = _records.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'دام‌یار',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Chip(
              avatar: const Icon(
                Icons.offline_pin_rounded,
                size: 18,
                color: AppTheme.primaryGreen,
              ),
              label: const Text('آفلاین فعال', style: TextStyle(fontSize: 12)),
              side: BorderSide.none,
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              ListTile(
                leading: const Icon(Icons.vaccines_outlined),
                title: const Text('ثبت سریع دارو / واکسن'),
                onTap: () => _openFromDrawer(_openQuickHealthSheet),
              ),
              ListTile(
                leading: const Icon(Icons.pets_outlined),
                title: const Text('دام‌ها، گله‌ها و پرونده سلامت'),
                onTap: () => _openFromDrawer(() => widget.onSelectTab(1)),
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('انبار خوراک و دخل‌وخرج'),
                onTap: () => _openFromDrawer(() => widget.onSelectTab(2)),
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('افزودن تک‌دام جدید'),
                onTap: () => _openFromDrawer(() async {
                  final saved = await showAddAnimalDialog(
                    context,
                    widget.storageService,
                  );
                  if (saved) _saveDone();
                }),
              ),
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: const Text('افزودن گروه / گله'),
                onTap: () => _openFromDrawer(() async {
                  final saved = await showAddGroupDialog(
                    context,
                    widget.storageService,
                  );
                  if (saved) _saveDone();
                }),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _TodayCard(
              dateText: JalaliHelper.formatReadable(DateTime.now()),
              openCount: openTasks.length,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Tile(
                    title: 'دارو دادن',
                    icon: Icons.vaccines_rounded,
                    onTap: () => widget.onSelectTab(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Tile(
                    title: 'دام‌ها',
                    icon: Icons.pets_rounded,
                    onTap: () => widget.onSelectTab(1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Tile(
                    title: 'انبار و مالی',
                    icon: Icons.inventory_2_rounded,
                    onTap: () => widget.onSelectTab(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'برای ثبت واکسن یا دارو، دکمه «دادن دارو» را بزنید.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            const _SectionTitle(title: 'کارهای امروز (واکسن و دارو)'),
            const SizedBox(height: 10),
            if (openTasks.isEmpty)
              const _InfoBox(text: 'امروز کاری باقی نمانده است.')
            else
              ...openTasks.map(
                (task) => _TaskRow(
                  title: task.title,
                  subtitle: _subtitleFor(task),
                  onDone: () => _confirmDone(task),
                  onOpenDetails: () => _openTaskDetails(task),
                ),
              ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'آخرین ثبت‌ها'),
            const SizedBox(height: 10),
            if (recentRecords.isEmpty)
              const _InfoBox(text: 'هنوز چیزی ثبت نشده است.')
            else
              ...recentRecords.map(
                (r) => _RecordRow(
                  record: r,
                  onOpenDetails: () => _openRecordDetails(r),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final String dateText;
  final int openCount;

  const _TodayCard({required this.dateText, required this.openCount});

  @override
  Widget build(BuildContext context) {
    final hasOpen = openCount > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              hasOpen
                  ? Icons.assignment_late_outlined
                  : Icons.check_circle_outline_rounded,
              color: AppTheme.primaryGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateText,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasOpen ? '$openCount کار مانده' : 'امروز کاری نیست',
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _Tile({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppTheme.primaryGreen, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppTheme.textDark,
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;

  const _InfoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, color: AppTheme.textMuted),
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onDone;
  final VoidCallback onOpenDetails;
  const _TaskRow({
    required this.title,
    required this.subtitle,
    required this.onDone,
    required this.onOpenDetails,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onOpenDetails,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDone,
                  icon: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final HealthRecord record;
  final VoidCallback onOpenDetails;

  const _RecordRow({required this.record, required this.onOpenDetails});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onOpenDetails,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppTheme.primaryGreen,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${record.actionType.label} • '
                        '${JalaliHelper.formatReadable(record.administeredAt)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
