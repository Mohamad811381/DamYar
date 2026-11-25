// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use

import 'package:dam_yar/core/utils/services/local_notification_service.dart';
import 'package:dam_yar/features/finance/inventory_finance_page.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/jalali_helper.dart';
import '../../data/models/animal.dart';
import '../../data/models/livestock_enums.dart';
import '../../data/models/livestock_group.dart';
import '../../data/models/reminder_task.dart';
import '../../data/storage/local_storage_service.dart';
import '../health/quick_health_sheet.dart';
import '../livestock/livestock_page.dart';

class HomePage extends StatefulWidget {
  final LocalStorageService storageService;
  final LocalNotificationService notificationService;

  const HomePage({
    super.key,
    required this.storageService,
    required this.notificationService,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Uuid _uuid = const Uuid();

  List<Animal> _animals = [];
  List<LivestockGroup> _groups = [];
  List<ReminderTask> _reminders = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _animals = widget.storageService.getAllAnimals();
      _groups = widget.storageService.getAllGroups();
      _reminders = widget.storageService.getAllReminders();
    });
  }

  Future<void> _openLivestockPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LivestockPage(
          storageService: widget.storageService,
          onAddAnimalTap: _showAddAnimalDialog,
          onAddGroupTap: _showAddGroupDialog,
          onDataChanged: _refreshData,
        ),
      ),
    );
    _refreshData();
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

    _refreshData();
  }

  void _openQuickHealthSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => QuickHealthSheet(
        storageService: widget.storageService,
        notificationService: widget.notificationService,
        onSaved: _refreshData,
      ),
    );
  }

  Future<void> _showAddAnimalDialog() async {
    final tagController = TextEditingController();
    SpeciesType selectedSpecies = _preferredSpeciesOrDefault();
    AnimalGender selectedGender = AnimalGender.female;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('ثبت دام جدید'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tagController,
                    decoration: const InputDecoration(
                      labelText: 'شماره پلاک (مثلاً ۱۰۵)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SpeciesType>(
                    value: selectedSpecies,
                    decoration: const InputDecoration(labelText: 'نوع دام'),
                    items: SpeciesType.values
                        .map(
                          (s) => DropdownMenuItem<SpeciesType>(
                            value: s,
                            child: Text(s.label),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null)
                        setDialogState(() => selectedSpecies = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AnimalGender>(
                    value: selectedGender,
                    decoration: const InputDecoration(labelText: 'جنسیت'),
                    items: AnimalGender.values
                        .map(
                          (g) => DropdownMenuItem<AnimalGender>(
                            value: g,
                            child: Text(g.label),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null)
                        setDialogState(() => selectedGender = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('انصراف'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('ذخیره'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true && tagController.text.trim().isNotEmpty) {
      final now = DateTime.now();
      final animal = Animal(
        id: _uuid.v4(),
        tagNumber: tagController.text.trim(),
        species: selectedSpecies,
        gender: selectedGender,
        createdAt: now,
        updatedAt: now,
      );
      await widget.storageService.upsertAnimal(animal);
      _refreshData();
    }

    tagController.dispose();
  }

  // متد باز کردن صفحه در _HomePageState:
  Future<void> _openInventoryFinancePage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InventoryFinancePage(
          storageService: widget.storageService,
          onDataChanged: _refreshData,
        ),
      ),
    );
    _refreshData();
  }

  Future<void> _showAddGroupDialog() async {
    final nameController = TextEditingController();
    final countController = TextEditingController(text: '20');
    SpeciesType selectedSpecies = _preferredSpeciesOrDefault();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('ثبت گروه یا گله جدید'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'نام گروه (مثلاً بره‌های بهاره)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SpeciesType>(
                    value: selectedSpecies,
                    decoration: const InputDecoration(labelText: 'نوع دام'),
                    items: SpeciesType.values
                        .map(
                          (s) => DropdownMenuItem<SpeciesType>(
                            value: s,
                            child: Text(s.label),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null)
                        setDialogState(() => selectedSpecies = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: countController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'تعداد تقریبی رأس',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('انصراف'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('ذخیره'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true && nameController.text.trim().isNotEmpty) {
      final now = DateTime.now();
      final count = int.tryParse(countController.text.trim()) ?? 0;
      final group = LivestockGroup(
        id: _uuid.v4(),
        name: nameController.text.trim(),
        species: selectedSpecies,
        headCount: count < 0 ? 0 : count,
        createdAt: now,
        updatedAt: now,
      );
      await widget.storageService.upsertGroup(group);
      _refreshData();
    }

    nameController.dispose();
    countController.dispose();
  }

  SpeciesType _preferredSpeciesOrDefault() {
    final stored = widget.storageService.preferredSpecies;
    if (stored == null) return SpeciesType.sheep;
    for (final s in SpeciesType.values) {
      if (s.name == stored) return s;
    }
    return SpeciesType.sheep;
  }

  @override
  Widget build(BuildContext context) {
    final activeReminders = _reminders.where((r) => !r.isCompleted).toList();
    final todayStr = JalaliHelper.formatReadable(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('داشبورد دامداری'),
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
              const ListTile(
                leading: Icon(Icons.pets_rounded, color: AppTheme.primaryGreen),
                title: Text(
                  'مدیریت هوشمند دامداری',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('گاو • گوسفند • بز'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.vaccines_outlined),
                title: const Text('ثبت سریع دارو / واکسن'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openQuickHealthSheet();
                },
              ),
              ListTile(
                leading: const Icon(Icons.pets_outlined),
                title: const Text('دام‌ها، گله‌ها و پرونده سلامت'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openLivestockPage();
                },
              ),

              // داخل ListView داشبورد، بعد از باکس دام‌ها و گله‌ها:
              const SizedBox(height: 12),
              _ActionBox(
                title: 'انبار خوراک و دخل‌وخرج',
                subtitle: 'موجودی انبار و ثبت هزینه‌ها و درآمدها',
                icon: Icons.inventory_2_rounded,
                color: AppTheme.primaryGreen,
                onTap: _openInventoryFinancePage,
              ),

              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('افزودن تک‌دام جدید'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddAnimalDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: const Text('افزودن گروه / گله'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddGroupDialog();
                },
              ),

              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('انبار خوراک و دخل‌وخرج'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openInventoryFinancePage();
                },
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
            Text(
              'امروز: $todayStr',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionBox(
                    title: 'ثبت واکسن / دارو',
                    subtitle: 'تکرار خودکار و منع مصرف',
                    icon: Icons.vaccines_rounded,
                    color: AppTheme.primaryGreen,
                    onTap: _openQuickHealthSheet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionBox(
                    title: 'افزودن دام',
                    subtitle: '${_animals.length} دام ثبت‌شده',
                    icon: Icons.add_box_rounded,
                    color: AppTheme.secondaryTeal,
                    onTap: _showAddAnimalDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ActionBox(
              title: 'دام‌ها، گله‌ها و پرونده سلامت',
              subtitle:
                  '${_animals.length} تک‌دام • ${_groups.length} گروه (گاو، گوسفند، بز)',
              icon: Icons.groups_rounded,
              color: AppTheme.warmAmber,
              onTap: () => _openLivestockPage(),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'یادآورهای پیش‌رو',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${activeReminders.length} مورد فعال',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (activeReminders.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: const Text(
                    'یادآور فعالی ثبت نشده است. با زدن «ثبت واکسن / دارو»، نوبت تکرار بعدی خودکار اینجا اضافه می‌شود.',
                    style: TextStyle(color: AppTheme.textMuted, height: 1.5),
                  ),
                ),
              )
            else
              ...activeReminders.map((task) {
                final daysLeft = JalaliHelper.daysRemainingFromToday(
                  task.dueDate,
                );
                final statusLabel = daysLeft < 0
                    ? 'عقب‌افتاده (${daysLeft.abs()} روز)'
                    : daysLeft == 0
                    ? 'موعد امروز'
                    : '$daysLeft روز دیگر';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: CheckboxListTile(
                      value: task.isCompleted,
                      onChanged: (_) => _toggleReminder(task),
                      title: Text(
                        task.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${JalaliHelper.formatReadable(task.dueDate)} • $statusLabel',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ActionBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBox({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
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
    );
  }
}
