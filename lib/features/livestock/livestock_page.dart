// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/jalali_helper.dart';
import '../../data/models/animal.dart';
import '../../data/models/health_record.dart';
import '../../data/models/livestock_enums.dart';
import '../../data/models/livestock_group.dart';
import '../../data/storage/local_storage_service.dart';

class LivestockPage extends StatefulWidget {
  final LocalStorageService storageService;
  final VoidCallback onAddAnimalTap;
  final VoidCallback onAddGroupTap;
  final VoidCallback onDataChanged;

  const LivestockPage({
    super.key,
    required this.storageService,
    required this.onAddAnimalTap,
    required this.onAddGroupTap,
    required this.onDataChanged,
  });

  @override
  State<LivestockPage> createState() => _LivestockPageState();
}

class _LivestockPageState extends State<LivestockPage> {
  List<Animal> _animals = [];
  List<LivestockGroup> _groups = [];
  List<HealthRecord> _healthRecords = [];

  bool _showGroupsTab = false;
  SpeciesType? _speciesFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _animals = widget.storageService.getAllAnimals();
      _groups = widget.storageService.getAllGroups();
      _healthRecords = widget.storageService.getAllHealthRecords();
    });
  }

  List<Animal> get _filteredAnimals {
    return _animals.where((a) {
      if (_speciesFilter != null && a.species != _speciesFilter) return false;
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      final tagMatch = a.tagNumber.toLowerCase().contains(q);
      final nameMatch = (a.name ?? '').toLowerCase().contains(q);
      return tagMatch || nameMatch;
    }).toList();
  }

  List<LivestockGroup> get _filteredGroups {
    return _groups.where((g) {
      if (_speciesFilter != null && g.species != _speciesFilter) return false;
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      return g.name.toLowerCase().contains(q);
    }).toList();
  }

  String _withdrawalSummary(HealthRecord record) {
    final parts = <String>[];

    if (record.milkSafeDate != null) {
      final daysLeft = JalaliHelper.daysRemainingFromToday(
        record.milkSafeDate!,
      );
      if (daysLeft > 0) {
        parts.add('منع شیر: $daysLeft روز مانده');
      } else {
        parts.add('منع شیر پایان یافته');
      }
    }

    if (record.meatSafeDate != null) {
      final daysLeft = JalaliHelper.daysRemainingFromToday(
        record.meatSafeDate!,
      );
      if (daysLeft > 0) {
        parts.add('منع گوشت: $daysLeft روز مانده');
      } else {
        parts.add('منع گوشت پایان یافته');
      }
    }

    return parts.join(' • ');
  }

  Future<void> _updateAnimalStatus(
    Animal animal,
    HealthStatus newStatus,
  ) async {
    final updated = animal.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
    await widget.storageService.upsertAnimal(updated);
    _reload();
    widget.onDataChanged();
  }

  void _openAnimalDossier(Animal animal) {
    final records = _healthRecords
        .where((r) => r.animalId == animal.id)
        .toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final currentAnimal =
                widget.storageService.getAnimalById(animal.id) ?? animal;

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.78,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'پلاک ${currentAnimal.tagNumber} (${currentAnimal.species.label})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'جنسیت: ${currentAnimal.gender.label} • وضعیت: ${currentAnimal.status.label}',
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
                    const SizedBox(height: 14),
                    DropdownButtonFormField<HealthStatus>(
                      value: currentAnimal.status,
                      decoration: const InputDecoration(
                        labelText: 'تغییر وضعیت سلامت دام',
                      ),
                      items: HealthStatus.values
                          .map(
                            (st) => DropdownMenuItem<HealthStatus>(
                              value: st,
                              child: Text(st.label),
                            ),
                          )
                          .toList(),
                      onChanged: (val) async {
                        if (val == null) return;
                        await _updateAnimalStatus(currentAnimal, val);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'سوابق دارو، واکسن و منع مصرف',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: records.isEmpty
                          ? const Center(
                              child: Text(
                                'هنوز سابقه دارو یا واکسنی برای این دام ثبت نشده است.',
                                style: TextStyle(color: AppTheme.textMuted),
                              ),
                            )
                          : ListView.separated(
                              itemCount: records.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, index) {
                                final r = records[index];
                                final withdrawal = _withdrawalSummary(r);

                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${r.actionType.label}: ${r.title}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'تاریخ: ${JalaliHelper.formatReadable(r.administeredAt)}'
                                          '${r.dosage != null ? ' • دوز: ${r.dosage}' : ''}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                        if (withdrawal.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            withdrawal,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.warmAmber,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openGroupRecords(LivestockGroup group) {
    final records = _healthRecords.where((r) => r.groupId == group.id).toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.72,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'گروه ${group.name} (${group.species.label})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تعداد تقریبی: ${group.headCount} رأس',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'اقدامات ثبت‌شده برای این گروه',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: records.isEmpty
                      ? const Center(
                          child: Text(
                            'اقدام گروهی ثبت‌شده‌ای برای این گله وجود ندارد.',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        )
                      : ListView.separated(
                          itemCount: records.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, index) {
                            final r = records[index];
                            final withdrawal = _withdrawalSummary(r);

                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${r.actionType.label}: ${r.title}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'تاریخ: ${JalaliHelper.formatReadable(r.administeredAt)}'
                                      '${r.dosage != null ? ' • دوز: ${r.dosage}' : ''}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                    if (withdrawal.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        withdrawal,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.warmAmber,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final animals = _filteredAnimals;
    final groups = _filteredGroups;

    return Scaffold(
      appBar: AppBar(
        title: const Text('دام‌ها و گله‌ها'),
        actions: [
          IconButton(
            onPressed: () async {
              if (_showGroupsTab) {
                widget.onAddGroupTap();
              } else {
                widget.onAddAnimalTap();
              }
              _reload();
            },
            icon: const Icon(Icons.add_rounded),
            tooltip: _showGroupsTab ? 'افزودن گروه' : 'افزودن دام',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: false,
                label: Text('تک‌دام‌ها'),
                icon: Icon(Icons.pets_outlined),
              ),
              ButtonSegment<bool>(
                value: true,
                label: Text('گروه‌ها / گله‌ها'),
                icon: Icon(Icons.groups_outlined),
              ),
            ],
            selected: {_showGroupsTab},
            onSelectionChanged: (val) =>
                setState(() => _showGroupsTab = val.first),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: _showGroupsTab
                  ? 'جست‌وجوی نام گروه...'
                  : 'جست‌وجوی شماره پلاک یا نام...',
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('همه'),
                  selected: _speciesFilter == null,
                  onSelected: (_) => setState(() => _speciesFilter = null),
                ),
                const SizedBox(width: 8),
                ...SpeciesType.values.map((species) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text(species.label),
                      selected: _speciesFilter == species,
                      onSelected: (_) => setState(() {
                        _speciesFilter = _speciesFilter == species
                            ? null
                            : species;
                      }),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (!_showGroupsTab) ...[
            if (animals.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'هیچ دامی با این فیلتر یافت نشد.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              )
            else
              ...animals.map((a) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      onTap: () => _openAnimalDossier(a),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryGreen.withValues(
                          alpha: 0.12,
                        ),
                        foregroundColor: AppTheme.primaryGreen,
                        child: Text(a.species.label.substring(0, 1)),
                      ),
                      title: Text(
                        'پلاک ${a.tagNumber}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${a.species.label} • ${a.gender.label} • ${a.status.label}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_left_rounded),
                    ),
                  ),
                );
              }),
          ] else ...[
            if (groups.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'هیچ گروهی با این فیلتر یافت نشد.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              )
            else
              ...groups.map((g) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      onTap: () => _openGroupRecords(g),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.secondaryTeal.withValues(
                          alpha: 0.12,
                        ),
                        foregroundColor: AppTheme.secondaryTeal,
                        child: const Icon(Icons.groups_rounded, size: 20),
                      ),
                      title: Text(
                        g.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${g.species.label} • حدود ${g.headCount} رأس',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_left_rounded),
                    ),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }
}
