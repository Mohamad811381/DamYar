enum HealthActionType {
  vaccine,   // واکسن
  medicine,  // دارو / درمان
  deworming, // ضدانگل
  checkup,   // معاینه / سایر
}

extension HealthActionTypeX on HealthActionType {
  String get label {
    switch (this) {
      case HealthActionType.vaccine:
        return 'واکسن';
      case HealthActionType.medicine:
        return 'دارو و درمان';
      case HealthActionType.deworming:
        return 'ضدانگل';
      case HealthActionType.checkup:
        return 'معاینه و سایر';
    }
  }
}

class HealthRecord {
  final String id;
  final HealthActionType actionType;
  final String title;              // نام دارو یا واکسن
  final String? dosage;            // دوز مصرفی (مثلاً ۲ سی‌سی)
  final String? animalId;          // اگر برای تک‌دام ثبت شده باشد
  final String? groupId;           // اگر برای کل گروه/گله ثبت شده باشد
  final DateTime administeredAt;   // تاریخ انجام
  final int milkWithdrawalDays;    // روزهای منع مصرف شیر (۰ یعنی ندارد)
  final int meatWithdrawalDays;    // روزهای منع مصرف گوشت (۰ یعنی ندارد)
  final String? notes;
  final DateTime createdAt;

  const HealthRecord({
    required this.id,
    required this.actionType,
    required this.title,
    this.dosage,
    this.animalId,
    this.groupId,
    required this.administeredAt,
    this.milkWithdrawalDays = 0,
    this.meatWithdrawalDays = 0,
    this.notes,
    required this.createdAt,
  });

  /// تاریخ پایان دوره منع مصرف شیر
  DateTime? get milkSafeDate => milkWithdrawalDays > 0
      ? administeredAt.add(Duration(days: milkWithdrawalDays))
      : null;

  /// تاریخ پایان دوره منع مصرف گوشت
  DateTime? get meatSafeDate => meatWithdrawalDays > 0
      ? administeredAt.add(Duration(days: meatWithdrawalDays))
      : null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actionType': actionType.name,
      'title': title,
      'dosage': dosage,
      'animalId': animalId,
      'groupId': groupId,
      'administeredAt': administeredAt.toIso8601String(),
      'milkWithdrawalDays': milkWithdrawalDays,
      'meatWithdrawalDays': meatWithdrawalDays,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HealthRecord.fromMap(Map<dynamic, dynamic> map) {
    return HealthRecord(
      id: map['id'] as String,
      actionType: HealthActionType.values.byName(map['actionType'] as String),
      title: map['title'] as String,
      dosage: map['dosage'] as String?,
      animalId: map['animalId'] as String?,
      groupId: map['groupId'] as String?,
      administeredAt: DateTime.parse(map['administeredAt'] as String),
      milkWithdrawalDays: (map['milkWithdrawalDays'] as num?)?.toInt() ?? 0,
      meatWithdrawalDays: (map['meatWithdrawalDays'] as num?)?.toInt() ?? 0,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}