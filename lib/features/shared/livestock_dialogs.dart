// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/animal.dart';
import '../../data/models/livestock_enums.dart';
import '../../data/models/livestock_group.dart';
import '../../data/storage/local_storage_service.dart';

const Uuid _uuid = Uuid();

SpeciesType preferredSpeciesOrDefault(LocalStorageService storage) {
  final stored = storage.preferredSpecies;
  if (stored == null) return SpeciesType.sheep;
  for (final s in SpeciesType.values) {
    if (s.name == stored) return s;
  }
  return SpeciesType.sheep;
}

/// برمی‌گرداند: آیا دام ذخیره شد یا نه
Future<bool> showAddAnimalDialog(
  BuildContext context,
  LocalStorageService storageService,
) async {
  final tagController = TextEditingController();
  SpeciesType selectedSpecies = preferredSpeciesOrDefault(storageService);
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
                    if (val != null) {
                      setDialogState(() => selectedSpecies = val);
                    }
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
                    if (val != null) {
                      setDialogState(() => selectedGender = val);
                    }
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

  var didSave = false;
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
    await storageService.upsertAnimal(animal);
    didSave = true;
  }

  tagController.dispose();
  return didSave;
}

/// برمی‌گرداند: آیا گروه ذخیره شد یا نه
Future<bool> showAddGroupDialog(
  BuildContext context,
  LocalStorageService storageService,
) async {
  final nameController = TextEditingController();
  final countController = TextEditingController(text: '20');
  SpeciesType selectedSpecies = preferredSpeciesOrDefault(storageService);

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
                    if (val != null) {
                      setDialogState(() => selectedSpecies = val);
                    }
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

  var didSave = false;
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
    await storageService.upsertGroup(group);
    didSave = true;
  }

  nameController.dispose();
  countController.dispose();
  return didSave;
}