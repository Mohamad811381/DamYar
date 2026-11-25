import 'package:shamsi_date/shamsi_date.dart';

class JalaliHelper {
  static const List<String> _monthNames = [
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

  static const List<String> _weekDayNames = [
    'شنبه',
    'یک‌شنبه',
    'دوشنبه',
    'سه‌شنبه',
    'چهارشنبه',
    'پنج‌شنبه',
    'جمعه',
  ];

  /// تبدیل DateTime به Jalali
  static Jalali toJalali(DateTime dateTime) {
    return Jalali.fromDateTime(dateTime);
  }

  /// قالب کوتاه عددی مثل: 1405/09/04
  static String formatShort(DateTime dateTime) {
    final j = toJalali(dateTime);
    final m = j.month.toString().padLeft(2, '0');
    final d = j.day.toString().padLeft(2, '0');
    return '${j.year}/$m/$d';
  }

  /// قالب خوانا با نام ماه مثل: ۴ آذر ۱۴۰۵
  static String formatReadable(DateTime dateTime) {
    final j = toJalali(dateTime);
    final monthName = _monthNames[j.month - 1];
    return '${j.day} $monthName ${j.year}';
  }

  /// قالب کامل با نام روز هفته و ساعت: چهارشنبه ۴ آذر ۱۴۰۵ - ۰۸:۳۰
  static String formatFullWithTime(DateTime dateTime) {
    final j = toJalali(dateTime);
    final weekDay = _weekDayNames[j.weekDay - 1];
    final monthName = _monthNames[j.month - 1];
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '$weekDay ${j.day} $monthName ${j.year} - $hh:$mm';
  }

  /// اضافه کردن تعداد روز به یک تاریخ و حفظ ساعت فعلی
  static DateTime addDays(DateTime baseDate, int days) {
    return baseDate.add(Duration(days: days));
  }

  /// محاسبه تعداد روز باقی‌مانده تا یک تاریخ نسبت به امروز (صفر یعنی امروز)
  static int daysRemainingFromToday(DateTime targetDate, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final todayStart = DateTime(current.year, current.month, current.day);
    final targetStart = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return targetStart.difference(todayStart).inDays;
  }
}