class ReminderTask {
  final String id;
  final int notificationId; // شناسه عددی یکتا برای سیستم اعلان گوشی
  final String title; // مثلاً: نوبت دوم واکسن آنتروتوکسمی
  final String? description;
  final DateTime dueDate; // تاریخ و ساعت دقیق یادآوری
  final bool isCompleted;
  final DateTime? completedAt;
  final String? relatedRecordId; // اتصال به رکورد واکسن/داروی قبلی
  final String? animalId;
  final String? groupId;
  final DateTime createdAt;

  const ReminderTask({
    required this.id,
    required this.notificationId,
    required this.title,
    this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.completedAt,
    this.relatedRecordId,
    this.animalId,
    this.groupId,
    required this.createdAt,
  });

  ReminderTask copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return ReminderTask(
      id: id,
      notificationId: notificationId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      relatedRecordId: relatedRecordId,
      animalId: animalId,
      groupId: groupId,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notificationId': notificationId,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'relatedRecordId': relatedRecordId,
      'animalId': animalId,
      'groupId': groupId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReminderTask.fromMap(Map<dynamic, dynamic> map) {
    return ReminderTask(
      id: map['id'] as String,
      notificationId: (map['notificationId'] as num).toInt(),
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDate: DateTime.parse(map['dueDate'] as String),
      isCompleted: (map['isCompleted'] as bool?) ?? false,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      relatedRecordId: map['relatedRecordId'] as String?,
      animalId: map['animalId'] as String?,
      groupId: map['groupId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
