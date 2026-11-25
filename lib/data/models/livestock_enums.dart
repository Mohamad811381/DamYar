enum SpeciesType {
  cattle, // گاو
  sheep,  // گوسفند
  goat,   // بز
}

extension SpeciesTypeX on SpeciesType {
  String get label {
    switch (this) {
      case SpeciesType.cattle:
        return 'گاو';
      case SpeciesType.sheep:
        return 'گوسفند';
      case SpeciesType.goat:
        return 'بز';
    }
  }

  /// میانگین طول دوره آبستنی بر حسب روز برای محاسبه خودکار زایش
  int get gestationDays {
    switch (this) {
      case SpeciesType.cattle:
        return 283;
      case SpeciesType.sheep:
        return 150;
      case SpeciesType.goat:
        return 150;
    }
  }
}

enum AnimalGender {
  female, // ماده
  male,   // نر
}

extension AnimalGenderX on AnimalGender {
  String get label => this == AnimalGender.female ? 'ماده' : 'نر';
}

enum HealthStatus {
  healthy,        // سالم
  underTreatment, // تحت درمان
  pregnant,       // آبستن
  quarantine,     // قرنطینه
}

extension HealthStatusX on HealthStatus {
  String get label {
    switch (this) {
      case HealthStatus.healthy:
        return 'سالم';
      case HealthStatus.underTreatment:
        return 'تحت درمان';
      case HealthStatus.pregnant:
        return 'آبستن';
      case HealthStatus.quarantine:
        return 'قرنطینه';
    }
  }
}