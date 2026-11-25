// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/local_notification_service.dart';
import '../../core/theme/app_theme.dart';
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
  final _notesController = TextEditingController();
  final Uuid _uuid = const Uuid();

  late List<Animal> _animals;
  late List<LivestockGroup> _groups;

  bool _isGroupTarget = false;
  String? _selectedAnimalId;
  String? _selectedGroupId;
  HealthActionType _actionType = HealthActionType.vaccine;
  DateTime _administeredAt = DateTime.now();
  bool _enableReminder = true;
  int _repeatDays = 0;
  int _milkDays = 0;
  int _meatDays = 0;
  bool _isSaving = false;

  DateTime? get _nextReminderDate => _repeatDays > 0
      ? JalaliHelper.addDays(_administeredAt, _repeatDays)
      : null;

  @override
  void initState() {
    super.initState();
    _animals = widget.storageService.getAllAnimals();
    _groups = widget.storageService.getAllGroups();

    if (_animals.isNotEmpty) _selectedAnimalId = _animals.first.id;
    if (_groups.isNotEmpty) _selectedGroupId = _groups.first.id;
    if (_animals.isEmpty && _groups.isNotEmpty) _isGroupTarget = true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _titleController.clear();
    _dosageController.clear();
    _notesController.clear();
    _administeredAt = DateTime.now();
    _repeatDays = 0;
    _milkDays = 0;
    _meatDays = 0;
  }

  Future<void> _pickDate({
    required DateTime initialDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _JalaliCalendar(initialDate: initialDate),
    );
    if (picked != null) onPicked(picked);
  }

  String _targetSummaryLabel() {
    if (_isGroupTarget) {
      final group = _groups.where((g) => g.id == _selectedGroupId).firstOrNull;
      return group != null ? 'گله: ${group.name}' : 'گله';
    }
    final animal = _animals.where((a) => a.id == _selectedAnimalId).firstOrNull;
    return animal != null
        ? 'پلاک ${animal.tagNumber} (${animal.species.label})'
        : 'تک‌دام';
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final recordId = _uuid.v4();
      final title = _titleController.text.trim();
      final dosageText = _dosageController.text.trim();
      final notesText = _notesController.text.trim();

      final record = HealthRecord(
        id: recordId,
        actionType: _actionType,
        title: title,
        dosage: dosageText.isEmpty ? null : dosageText,
        animalId: _isGroupTarget ? null : _selectedAnimalId,
        groupId: _isGroupTarget ? _selectedGroupId : null,
        administeredAt: _administeredAt,
        milkWithdrawalDays: _milkDays,
        meatWithdrawalDays: _meatDays,
        notes: notesText.isEmpty ? null : notesText,
        createdAt: now,
      );

      await widget.storageService.addHealthRecord(record);

      final reminderDate = _nextReminderDate;
      if (_enableReminder && reminderDate != null) {
        final notifId = DateTime.now().millisecondsSinceEpoch.remainder(
          1000000000,
        );
        final reminder = ReminderTask(
          id: _uuid.v4(),
          notificationId: notifId,
          title: 'تکرار ${_actionType.label}: $title',
          description:
              '${_targetSummaryLabel()} • انجام قبلی: ${JalaliHelper.formatShort(_administeredAt)}',
          dueDate: reminderDate,
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
          body: reminder.description ?? 'زمان تکرار دارو یا واکسن است.',
          scheduledDate: reminderDate,
        );
      }

      widget.onSaved();
      if (!mounted) return;
      setState(_resetForm);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ثبت شد و روی گوشی ذخیره شد.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasNoTarget =
        (_isGroupTarget && _groups.isEmpty) ||
        (!_isGroupTarget && _animals.isEmpty);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionCard(
                    icon: Icons.pets_rounded,
                    title: 'این کار برای کیست؟',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment<bool>(
                              value: false,
                              label: Text('تک‌دام'),
                              icon: Icon(Icons.pets_outlined),
                            ),
                            ButtonSegment<bool>(
                              value: true,
                              label: Text('گله'),
                              icon: Icon(Icons.groups_outlined),
                            ),
                          ],
                          selected: {_isGroupTarget},
                          onSelectionChanged: (s) =>
                              setState(() => _isGroupTarget = s.first),
                        ),
                        const SizedBox(height: 12),
                        if (!_isGroupTarget && _animals.isNotEmpty)
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedAnimalId,
                            decoration: const InputDecoration(
                              labelText: 'شماره پلاک',
                            ),
                            items: _animals
                                .map(
                                  (a) => DropdownMenuItem<String>(
                                    value: a.id,
                                    child: Text(
                                      'پلاک ${a.tagNumber} — ${a.species.label}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedAnimalId = v),
                          ),
                        if (_isGroupTarget && _groups.isNotEmpty)
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedGroupId,
                            decoration: const InputDecoration(
                              labelText: 'نام گله',
                            ),
                            items: _groups
                                .map(
                                  (g) => DropdownMenuItem<String>(
                                    value: g.id,
                                    child: Text(
                                      '${g.name} (${g.species.label})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedGroupId = v),
                          ),
                        if (hasNoTarget) ...[
                          const SizedBox(height: 10),
                          const _Notice(
                            text: 'هنوز دام یا گله‌ای ثبت نشده. این کار بدون پلاک یا گله ذخیره می‌شود.',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    icon: Icons.vaccines_rounded,
                    title: 'چه کاری انجام شد؟',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: HealthActionType.values.map((t) {
                        final selected = t == _actionType;
                        return ChoiceChip(
                          label: Text(
                            t.label,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          selected: selected,
                          showCheckmark: false,
                          selectedColor: AppTheme.primaryGreen,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppTheme.textDark,
                          ),
                          onSelected: (_) => setState(() => _actionType = t),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    icon: Icons.edit_note_rounded,
                    title: 'نام و مقدار',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'نام دارو یا واکسن',
                            hintText: 'مثلاً آنتروتوکسمی',
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
                            labelText: 'مقدار دوز (اختیاری)',
                            hintText: 'مثلاً ۲ سی‌سی',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    icon: Icons.calendar_month_rounded,
                    title: 'تاریخ انجام کار',
                    child: _DateTile(
                      label: 'تاریخ انجام',
                      date: _administeredAt,
                      onTap: () => _pickDate(
                        initialDate: _administeredAt,
                        onPicked: (d) => setState(() => _administeredAt = d),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    icon: Icons.notifications_active_rounded,
                    title: 'یادآور نوبت بعدی',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'یادآور فعال باشد',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          value: _enableReminder,
                          onChanged: (v) => setState(() => _enableReminder = v),
                        ),
                        if (_enableReminder) ...[
                          const SizedBox(height: 8),
                          _DaysStepper(
                            label: 'تکرار بعد از',
                            value: _repeatDays,
                            min: 0,
                            onChanged: (v) => setState(() => _repeatDays = v),
                          ),
                          if (_repeatDays == 0)
                            const Padding(
                              padding: EdgeInsets.only(top: 8, bottom: 4),
                              child: Text(
                                'تعداد روز تا نوبت بعدی را انتخاب کنید.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          _DateTile(
                            label: 'موعد یادآور',
                            date: _nextReminderDate ?? _administeredAt,
                            onTap: () => _pickDate(
                              initialDate: _nextReminderDate ?? _administeredAt,
                              onPicked: (d) {
                                final diff = d
                                    .difference(_administeredAt)
                                    .inDays;
                                setState(() {
                                  _repeatDays = diff < 1 ? 1 : diff;
                                });
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    icon: Icons.block_rounded,
                    title: 'منع مصرف',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DaysStepper(
                          label: 'منع شیر',
                          value: _milkDays,
                          min: 0,
                          onChanged: (v) => setState(() => _milkDays = v),
                        ),
                        const SizedBox(height: 12),
                        _DaysStepper(
                          label: 'منع گوشت',
                          value: _meatDays,
                          min: 0,
                          onChanged: (v) => setState(() => _meatDays = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    icon: Icons.notes_rounded,
                    title: 'یادداشت (اختیاری)',
                    child: TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'هر توضیحی که لازم است',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: const Icon(Icons.save_rounded, size: 24),
                      label: Text(
                        _isSaving ? 'در حال ذخیره...' : 'ثبت کار',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceLight,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.edit_calendar_rounded,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      JalaliHelper.formatReadable(date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaysStepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final ValueChanged<int> onChanged;

  const _DaysStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
          ),
          IconButton.filledTonal(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 70,
            child: Text(
              '$value روز',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
          ),
          IconButton.filledTonal(
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final String text;

  const _Notice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warmAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13, height: 1.5)),
    );
  }
}

class _JalaliCalendar extends StatefulWidget {
  final DateTime initialDate;

  const _JalaliCalendar({required this.initialDate});

  @override
  State<_JalaliCalendar> createState() => _JalaliCalendarState();
}

class _JalaliCalendarState extends State<_JalaliCalendar> {
  static const _monthNames = [
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
  static const _weekDays = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

  late Jalali _shown;
  late Jalali _selected;
  late final Jalali _today;

  @override
  void initState() {
    super.initState();
    _selected = JalaliHelper.toJalali(widget.initialDate);
    _shown = Jalali(_selected.year, _selected.month, 1);
    _today = JalaliHelper.toJalali(DateTime.now());
  }

  String _fa(int n) {
    const digits = '۰۱۲۳۴۵۶۷۸۹';
    return n.toString().split('').map((c) => digits[int.parse(c)]).join();
  }

  void _moveMonth(int delta) {
    var y = _shown.year;
    var m = _shown.month + delta;
    while (m < 1) {
      m += 12;
      y--;
    }
    while (m > 12) {
      m -= 12;
      y++;
    }
    setState(() => _shown = Jalali(y, m, 1));
  }

  void _pick(int day) {
    final g = Jalali(_shown.year, _shown.month, day).toDateTime();
    Navigator.of(context).pop(
      DateTime(
        g.year,
        g.month,
        g.day,
        widget.initialDate.hour,
        widget.initialDate.minute,
      ),
    );
  }

  Widget _dayCell(int day) {
    final isSelected =
        _selected.year == _shown.year &&
        _selected.month == _shown.month &&
        _selected.day == day;
    final isToday =
        _today.year == _shown.year &&
        _today.month == _shown.month &&
        _today.day == day;

    return Material(
      color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pick(day),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isToday && !isSelected
                ? Border.all(color: AppTheme.primaryGreen, width: 1.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            _fa(day),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : AppTheme.textDark,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxDays = _shown.monthLength;
    // شنبه اولین ستون است. Dart: دوشنبه=1 ... یکشنبه=7
    final offset = (_shown.toDateTime().weekday + 1) % 7;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => _moveMonth(-1),
                  icon: const Icon(Icons.chevron_right_rounded, size: 30),
                ),
                Expanded(
                  child: Text(
                    '${_monthNames[_shown.month - 1]} ${_fa(_shown.year)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _moveMonth(1),
                  icon: const Icon(Icons.chevron_left_rounded, size: 30),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: _weekDays
                  .map(
                    (w) => Expanded(
                      child: Center(
                        child: Text(
                          w,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 6),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 7,
              childAspectRatio: 1.1,
              children: [
                for (var i = 0; i < offset; i++) const SizedBox.shrink(),
                for (var d = 1; d <= maxDays; d++) _dayCell(d),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  final g = DateTime.now();
                  Navigator.of(context).pop(
                    DateTime(
                      g.year,
                      g.month,
                      g.day,
                      widget.initialDate.hour,
                      widget.initialDate.minute,
                    ),
                  );
                },
                child: const Text(
                  'امروز',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
