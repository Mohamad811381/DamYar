import 'livestock_enums.dart';

class LivestockGroup {
  final String id;
  final String name;
  final SpeciesType species;
  final int headCount; // تعداد تقریبی دام در صورت مدیریت گروهی بدون پلاک
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LivestockGroup({
    required this.id,
    required this.name,
    required this.species,
    this.headCount = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  LivestockGroup copyWith({
    String? name,
    SpeciesType? species,
    int? headCount,
    String? notes,
    DateTime? updatedAt,
  }) {
    return LivestockGroup(
      id: id,
      name: name ?? this.name,
      species: species ?? this.species,
      headCount: headCount ?? this.headCount,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species.name,
      'headCount': headCount,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LivestockGroup.fromMap(Map<dynamic, dynamic> map) {
    return LivestockGroup(
      id: map['id'] as String,
      name: map['name'] as String,
      species: SpeciesType.values.byName(map['species'] as String),
      headCount: (map['headCount'] as num?)?.toInt() ?? 0,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}