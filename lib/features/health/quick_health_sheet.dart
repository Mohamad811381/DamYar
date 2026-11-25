// ignore_for_file: deprecated_member_use

import 'package:dam_yar/core/services/local_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/jalali_helper.dart';
import '../../data/models/animal.dart';
import '../../data/models/health_record.dart';
import '../../data/models/livestock_enums.dart';
import '../../data/models/livestock_group.dart';
import '../../data/models/reminder_task.dart';
import '../../data/storage/local_storage_service.dart';

class QuickHealthSheet extends StatefulWidget {
  final LocalStorageService storageService;
  final LocalNotificationService notificationService;
  final VoidCallback onSaved;

  const QuickHealthSheet({
    super.key,
    required this.storageService,
    required this.notificationService,
    required this.onSaved,
  });

  @override
  State<QuickHealthSheet> createState() => _QuickHealthSheetState();
}

class _QuickHealthSheetState extends State<QuickHealthSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dosageController = TextEditingController();
  final _repeatDaysController = TextEditingController(text: '21');
  final _milkDaysController = TextEditingController(text: '0');
  final _meatDaysController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  final Uuid _uuid = const Uuid();

  late List<Animal> _animals;
  late List<LivestockGroup> _groups;

  bool _isGroupTarget = false;
  String? _selectedAnimalId;
  String? _selectedGroupId;
  HealthActionType _actionType = HealthActionType.vaccine;
  DateTime _administeredAt = DateTime.now();
  bool _enableRepeatReminder = true;
  DateTime _nextReminderDate = DateTime.now().add(const Duration(days: 21));
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _animals = widget.storageService.getAllAnimals();
    _groups = widget.storageService.getAllGroups();

    if (_animals.isNotEmpty) {
      _selectedAnimalId = _animals.first.id;
    }
    if (_groups.isNotEmpty) {
      _selectedGroupId = _groups.first.id;
    }
    if (_animals.isEmpty && _groups.isNotEmpty) {
      _isGroupTarget = true;
    }

    _repeatDaysController.addListener(_recalculateReminderFromDays);
  }

  @override
  void dispose() {
    _repeatDaysController.removeListener(_recalculateReminderFromDays);
    _titleController.dispose();
    _dosageController.dispose();
    _repeatDaysController.dispose();
    _milkDaysController.dispose();
    _meatDaysController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _recalculateReminderFromDays() {
    final days = int.tryParse(_repeatDaysController.text.trim());
    if (days == null || days <= 0) return;
    setState(() {
      _nextReminderDate = JalaliHelper.addDays(_administeredAt, days);
    });
  }

  Future<void> _pickJalaliDate({
    required DateTime initialDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final initialJalali = JalaliHelper.toJalali(initialDate);
    int selectedYear = initialJalali.year;
    int selectedMonth = initialJalali.month;
    int selectedDay = initialJalali.day;

    const monthNames = [
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final maxDays = Jalali(selectedYear, selectedMonth, 1).monthLength;
            if (selectedDay > maxDays) {
              selectedDay = maxDays;
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'انتخاب تاریخ شمسی',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedDay,
                          decoration: const InputDecoration(labelText: 'روز'),
                          items: List.generate(maxDays, (index) => index + 1)
                              .map(
                                (d) => DropdownMenuItem<int>(
                                  value: d,
                                  child: Text('$d'),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            setModalState(() => selectedDay = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          value: selectedMonth,
                          decoration: const InputDecoration(labelText: 'ماه'),
                          items: List.generate(12, (index) => index + 1)
                              .map(
                                (m) => DropdownMenuItem<int>(
                                  value: m,
                                  child: Text(monthNames[m - 1]),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            setModalState(() => selectedMonth = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedYear,
                          decoration: const InputDecoration(labelText: 'سال'),
                          items: [selectedYear - 1, selectedYear, selectedYear + 1]
                              .map(
                                (y) => DropdownMenuItem<int>(
                                  value: y,
                                  child: Text('$y'),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            setModalState(() => selectedYear = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      final jDate = Jalali(selectedYear, selectedMonth, selectedDay);
                      final gDate = jDate.toDateTime();
                      final combined = DateTime(
                        gDate.year,
                        gDate.month,
                        gDate.day,
                        initialDate.hour,
                        initialDate.minute,
                      );
                      Navigator.of(ctx).pop(combined);
                    },
                    child: const Text('تایید تاریخ'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      onPicked(picked);
    }
  }

  String _targetSummaryLabel() {
    if (_isGroupTarget) {
      final group = _groups.where((g) => g.id == _selectedGroupId).firstOrNull;
      return group != null ? 'گروه: ${group.name}' : 'گروه دام';
    } else {
      final animal = _animals.where((a) => a.id == _selectedAnimalId).firstOrNull;
      return animal != null
          ? 'پلاک ${animal.tagNumber} (${animal.species.label})'
          : 'تک‌دام';
    }
  }

  Future<void> _saveRecord() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_isGroupTarget && _selectedAnimalId == null && _animals.isNotEmpty) {
      _selectedAnimalId = _animals.first.id;
    }
    if (_isGroupTarget && _selectedGroupId == null && _groups.isNotEmpty) {
      _selectedGroupId = _groups.first.id;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final recordId = _uuid.v4();
      final title = _titleController.text.trim();
      final dosageText = _dosageController.text.trim();
      final milkDays = int.tryParse(_milkDaysController.text.trim()) ?? 0;
      final meatDays = int.tryParse(_meatDaysController.text.trim()) ?? 0;
      final notesText = _notesController.text.trim();

      final record = HealthRecord(
        id: recordId,
        actionType: _actionType,
        title: title,
        dosage: dosageText.isEmpty ? null : dosageText,
        animalId: _isGroupTarget ? null : _selectedAnimalId,
        groupId: _isGroupTarget ? _selectedGroupId : null,
        administeredAt: _administeredAt,
        milkWithdrawalDays: milkDays < 0 ? 0 : milkDays,
        meatWithdrawalDays: meatDays < 0 ? 0 : meatDays,
        notes: notesText.isEmpty ? null : notesText,
        createdAt: now,
      );

      await widget.storageService.addHealthRecord(record);

      if (_enableRepeatReminder) {
        final notifId = DateTime.now().millisecondsSinceEpoch.remainder(1000000000);
        final targetLabel = _targetSummaryLabel();
        final reminder = ReminderTask(
          id: _uuid.v4(),
          notificationId: notifId,
          title: 'تکرار ${_actionType.label}: $title',
          description: '$targetLabel • تاریخ انجام قبلی: ${JalaliHelper.formatShort(_administeredAt)}',
          dueDate: _nextReminderDate,
          isCompleted: false,
          relatedRecordId: recordId,
          animalId: _isGroupTarget ? null : _selectedAnimalId,
          groupId: _isGroupTarget ? _selectedGroupId : null,
          createdAt: now,
        );

        await widget.storageService.upsertReminder(reminder);
        await widget.notificationService.scheduleReminder(
          id: notifId,
          title: reminder.title,
          body: reminder.description ?? 'زمان تکرار دارو/واکسن فرا رسیده است.',
          scheduledDate: _nextReminderDate,
        );
      }

      widget.onSaved();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ثبت سریع واکسن یا دارو',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('تک‌دام (پلاک)'),
                    icon: Icon(Icons.pets_outlined),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('گروه / گله'),
                    icon: Icon(Icons.groups_outlined),
                  ),
                ],
                selected: {_isGroupTarget},
                onSelectionChanged: (selection) {
                  setState(() => _isGroupTarget = selection.first);
                },
              ),
              const SizedBox(height: 12),
              if (!_isGroupTarget && _animals.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedAnimalId,
                  decoration: const InputDecoration(labelText: 'انتخاب دام'),
                  items: _animals
                      .map(
                        (a) => DropdownMenuItem<String>(
                          value: a.id,
                          child: Text('پلاک ${a.tagNumber} — ${a.species.label}'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedAnimalId = val),
                ),
              if (_isGroupTarget && _groups.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedGroupId,
                  decoration: const InputDecoration(labelText: 'انتخاب گروه/گله'),
                  items: _groups
                      .map(
                        (g) => DropdownMenuItem<String>(
                          value: g.id,
                          child: Text('${g.name} (${g.species.label})'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedGroupId = val),
                ),
              if ((_isGroupTarget && _groups.isEmpty) ||
                  (!_isGroupTarget && _animals.isEmpty))
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'هنوز دام یا گروهی ثبت نشده؛ این ثبت بدون اتصال به پلاک/گروه ذخیره می‌شود.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<HealthActionType>(
                value: _actionType,
                decoration: const InputDecoration(labelText: 'نوع اقدام'),
                items: HealthActionType.values
                    .map(
                      (t) => DropdownMenuItem<HealthActionType>(
                        value: t,
                        child: Text(t.label),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _actionType = val);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'نام واکسن یا دارو (مثلاً آنتروتوکسمی)',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'نام دارو یا واکسن را وارد کنید';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'دوز مصرفی (اختیاری، مثلاً ۲ سی‌سی)',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _pickJalaliDate(
                  initialDate: _administeredAt,
                  onPicked: (picked) {
                    setState(() {
                      _administeredAt = picked;
                      _recalculateReminderFromDays();
                    });
                  },
                ),
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text('تاریخ انجام: ${JalaliHelper.formatReadable(_administeredAt)}'),
              ),
              const SizedBox(height: 14),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('یادآور تکرار نوبت بعدی'),
                value: _enableRepeatReminder,
                onChanged: (val) => setState(() => _enableRepeatReminder = val),
              ),
              if (_enableRepeatReminder) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _repeatDaysController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'تکرار بعد از (روز)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickJalaliDate(
                          initialDate: _nextReminderDate,
                          onPicked: (picked) {
                            setState(() => _nextReminderDate = picked);
                          },
                        ),
                        child: Text(
                          'موعد: ${JalaliHelper.formatShort(_nextReminderDate)}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _milkDaysController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'منع شیر (روز)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _meatDaysController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'منع گوشت (روز)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'یادداشت تکمیلی (اختیاری)',
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _isSaving ? null : _saveRecord,
                child: Text(_isSaving ? 'در حال ذخیره...' : 'ثبت و ذخیره آفلاین'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}