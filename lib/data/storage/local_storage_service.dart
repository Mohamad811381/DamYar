import 'package:dam_yar/data/models/finance_inventory_models.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/animal.dart';
import '../models/health_record.dart';
import '../models/livestock_group.dart';
import '../models/reminder_task.dart';

class LocalStorageService {
  static const String _settingsBoxName = 'settings_box';
  static const String _groupsBoxName = 'livestock_groups_box';
  static const String _animalsBoxName = 'animals_box';
  static const String _healthRecordsBoxName = 'health_records_box';
  static const String _remindersBoxName = 'reminders_box';

  static const String _onboardingDoneKey = 'onboarding_completed';
  static const String _preferredSpeciesKey = 'preferred_species';
  static const String _inventoryBoxName = 'inventory_box';
static const String _financeBoxName = 'finance_box';
  

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    await Future.wait([
      Hive.openBox(_settingsBoxName),
      Hive.openBox(_groupsBoxName),
      Hive.openBox(_animalsBoxName),
      Hive.openBox(_healthRecordsBoxName),
      Hive.openBox(_remindersBoxName),
      Hive.openBox(_inventoryBoxName),
Hive.openBox(_financeBoxName),
    ]);

    _initialized = true;
  }

  Box get _settingsBox => Hive.box(_settingsBoxName);
  Box get _groupsBox => Hive.box(_groupsBoxName);
  Box get _animalsBox => Hive.box(_animalsBoxName);
  Box get _healthRecordsBox => Hive.box(_healthRecordsBoxName);
  Box get _remindersBox => Hive.box(_remindersBoxName);
  Box get _inventoryBox => Hive.box(_inventoryBoxName);
Box get _financeBox => Hive.box(_financeBoxName);

  Map<dynamic, dynamic>? _asMap(dynamic value) {
    if (value == null) return null;
    if (value is Map) return Map<dynamic, dynamic>.from(value);
    return null;
  }

  // --- تنظیمات اولیه برنامه ---

  bool get isOnboardingCompleted =>
      (_settingsBox.get(_onboardingDoneKey) as bool?) ?? false;

  Future<void> setOnboardingCompleted(bool value) async {
    await _settingsBox.put(_onboardingDoneKey, value);
  }

  String? get preferredSpecies =>
      _settingsBox.get(_preferredSpeciesKey) as String?;

  Future<void> setPreferredSpecies(String? speciesName) async {
    await _settingsBox.put(_preferredSpeciesKey, speciesName);
  }

  // --- گروه‌ها / گله‌ها ---

  Future<void> upsertGroup(LivestockGroup group) async {
    await _groupsBox.put(group.id, group.toMap());
  }

  List<LivestockGroup> getAllGroups() {
    final result = <LivestockGroup>[];
    for (final raw in _groupsBox.values) {
      final map = _asMap(raw);
      if (map != null) {
        result.add(LivestockGroup.fromMap(map));
      }
    }
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  Future<void> deleteGroup(String groupId) async {
    await _groupsBox.delete(groupId);
  }

  // --- تک‌دام‌ها ---

  Future<void> upsertAnimal(Animal animal) async {
    await _animalsBox.put(animal.id, animal.toMap());
  }

  List<Animal> getAllAnimals() {
    final result = <Animal>[];
    for (final raw in _animalsBox.values) {
      final map = _asMap(raw);
      if (map != null) {
        result.add(Animal.fromMap(map));
      }
    }
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  Animal? getAnimalById(String animalId) {
    final map = _asMap(_animalsBox.get(animalId));
    if (map == null) return null;
    return Animal.fromMap(map);
  }

  Future<void> deleteAnimal(String animalId) async {
    await _animalsBox.delete(animalId);
  }

  // --- سوابق دارو و واکسن ---

  Future<void> addHealthRecord(HealthRecord record) async {
    await _healthRecordsBox.put(record.id, record.toMap());
  }

  List<HealthRecord> getAllHealthRecords() {
    final result = <HealthRecord>[];
    for (final raw in _healthRecordsBox.values) {
      final map = _asMap(raw);
      if (map != null) {
        result.add(HealthRecord.fromMap(map));
      }
    }
    result.sort((a, b) => b.administeredAt.compareTo(a.administeredAt));
    return result;
  }

  Future<void> deleteHealthRecord(String recordId) async {
    await _healthRecordsBox.delete(recordId);
  }

  // --- یادآورهای هوشمند ---

  Future<void> upsertReminder(ReminderTask reminder) async {
    await _remindersBox.put(reminder.id, reminder.toMap());
  }

  List<ReminderTask> getAllReminders() {
    final result = <ReminderTask>[];
    for (final raw in _remindersBox.values) {
      final map = _asMap(raw);
      if (map != null) {
        result.add(ReminderTask.fromMap(map));
      }
    }
    result.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return result;
  }

  Future<void> deleteReminder(String reminderId) async {
    await _remindersBox.delete(reminderId);
  }



// --- اقلام انبار ---
Future<void> upsertInventoryItem(InventoryItem item) async {
  await _inventoryBox.put(item.id, item.toMap());
}

List<InventoryItem> getAllInventoryItems() {
  final result = <InventoryItem>[];
  for (final raw in _inventoryBox.values) {
    final map = _asMap(raw);
    if (map != null) {
      result.add(InventoryItem.fromMap(map));
    }
  }
  result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return result;
}

Future<void> deleteInventoryItem(String id) async {
  await _inventoryBox.delete(id);
}

// --- تراکنش‌های مالی (دخل و خرج) ---
Future<void> addFinancialEntry(FinancialEntry entry) async {
  await _financeBox.put(entry.id, entry.toMap());
}

List<FinancialEntry> getAllFinancialEntries() {
  final result = <FinancialEntry>[];
  for (final raw in _financeBox.values) {
    final map = _asMap(raw);
    if (map != null) {
      result.add(FinancialEntry.fromMap(map));
    }
  }
  result.sort((a, b) => b.date.compareTo(a.date));
  return result;
}

Future<void> deleteFinancialEntry(String id) async {
  await _financeBox.delete(id);
}


}
