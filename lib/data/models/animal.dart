import 'livestock_enums.dart';

class Animal {
  final String id;
  final String tagNumber; // شماره پلاک یا کد شناسایی
  final String? name;     // نام اختیاری (مثلاً برای گاوهای شیری)
  final SpeciesType species;
  final AnimalGender gender;
  final HealthStatus status;
  final String? groupId;  // اتصال اختیاری به یک گله/گروه
  final DateTime? birthDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Animal({
    required this.id,
    required this.tagNumber,
    this.name,
    required this.species,
    required this.gender,
    this.status = HealthStatus.healthy,
    this.groupId,
    this.birthDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Animal copyWith({
    String? tagNumber,
    String? name,
    SpeciesType? species,
    AnimalGender? gender,
    HealthStatus? status,
    String? groupId,
    DateTime? birthDate,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Animal(
      id: id,
      tagNumber: tagNumber ?? this.tagNumber,
      name: name ?? this.name,
      species: species ?? this.species,
      gender: gender ?? this.gender,
      status: status ?? this.status,
      groupId: groupId ?? this.groupId,
      birthDate: birthDate ?? this.birthDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tagNumber': tagNumber,
      'name': name,
      'species': species.name,
      'gender': gender.name,
      'status': status.name,
      'groupId': groupId,
      'birthDate': birthDate?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Animal.fromMap(Map<dynamic, dynamic> map) {
    return Animal(
      id: map['id'] as String,
      tagNumber: map['tagNumber'] as String,
      name: map['name'] as String?,
      species: SpeciesType.values.byName(map['species'] as String),
      gender: AnimalGender.values.byName(map['gender'] as String),
      status: HealthStatus.values.byName(map['status'] as String),
      groupId: map['groupId'] as String?,
      birthDate: map['birthDate'] != null
          ? DateTime.parse(map['birthDate'] as String)
          : null,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}