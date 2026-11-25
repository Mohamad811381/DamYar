enum InventoryUnit {
  kilogram, // کیلوگرم
  sack, // کیسه
  dose, // دوز
  pack, // بسته
}

extension InventoryUnitX on InventoryUnit {
  String get label {
    switch (this) {
      case InventoryUnit.kilogram:
        return 'کیلوگرم';
      case InventoryUnit.sack:
        return 'کیسه';
      case InventoryUnit.dose:
        return 'دوز';
      case InventoryUnit.pack:
        return 'بسته';
    }
  }
}

class InventoryItem {
  final String id;
  final String name;
  final InventoryUnit unit;
  final double quantity;
  final double lowStockThreshold;
  final DateTime updatedAt;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.quantity,
    this.lowStockThreshold = 0,
    required this.updatedAt,
  });

  bool get isLowStock => lowStockThreshold > 0 && quantity <= lowStockThreshold;

  InventoryItem copyWith({
    String? name,
    InventoryUnit? unit,
    double? quantity,
    double? lowStockThreshold,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit.name,
      'quantity': quantity,
      'lowStockThreshold': lowStockThreshold,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory InventoryItem.fromMap(Map<dynamic, dynamic> map) {
    return InventoryItem(
      id: map['id'] as String,
      name: map['name'] as String,
      unit: InventoryUnit.values.byName(map['unit'] as String),
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      lowStockThreshold: (map['lowStockThreshold'] as num?)?.toDouble() ?? 0,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

enum FinanceType {
  income, // درآمد
  expense, // هزینه
}

extension FinanceTypeX on FinanceType {
  String get label => this == FinanceType.income ? 'درآمد' : 'هزینه';
}

enum FinanceCategory {
  feed, // خوراک دام
  health, // دارو و واکسن
  milkSale, // فروش شیر
  livestockSale, // فروش دام
  other, // سایر
}

extension FinanceCategoryX on FinanceCategory {
  String get label {
    switch (this) {
      case FinanceCategory.feed:
        return 'خوراک دام';
      case FinanceCategory.health:
        return 'دارو و واکسن';
      case FinanceCategory.milkSale:
        return 'فروش شیر';
      case FinanceCategory.livestockSale:
        return 'فروش دام';
      case FinanceCategory.other:
        return 'سایر';
    }
  }
}

class FinancialEntry {
  final String id;
  final FinanceType type;
  final FinanceCategory category;
  final double amount;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  const FinancialEntry({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'category': category.name,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FinancialEntry.fromMap(Map<dynamic, dynamic> map) {
    return FinancialEntry(
      id: map['id'] as String,
      type: FinanceType.values.byName(map['type'] as String),
      category: FinanceCategory.values.byName(map['category'] as String),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
