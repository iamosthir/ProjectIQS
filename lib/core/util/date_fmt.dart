import 'package:intl/intl.dart';

/// Date/time formatting helpers. ISO strings from the API are parsed to local
/// time; relative ("time ago") strings are produced in Arabic or English.
class DateFmt {
  DateFmt._();

  static DateTime? tryParse(String? iso) =>
      iso == null ? null : DateTime.tryParse(iso)?.toLocal();

  static String date(DateTime? dt, {String locale = 'ar'}) =>
      dt == null ? '' : DateFormat('d MMM y', locale).format(dt);

  static String time(DateTime? dt, {String locale = 'ar'}) =>
      dt == null ? '' : DateFormat('h:mm a', locale).format(dt);

  static String dateTime(DateTime? dt, {String locale = 'ar'}) =>
      dt == null ? '' : DateFormat('d MMM y · h:mm a', locale).format(dt);

  /// Relative "time ago", e.g. `منذ 2 ساعة` / `2 h ago`.
  static String relative(DateTime? dt, {String locale = 'ar'}) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    final ar = locale == 'ar';
    if (diff.isNegative) return ar ? 'الآن' : 'just now';
    if (diff.inMinutes < 1) return ar ? 'الآن' : 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return ar ? 'منذ $m دقيقة' : '$m min ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return ar ? 'منذ $h ساعة' : '$h h ago';
    }
    if (diff.inDays < 30) {
      final d = diff.inDays;
      return ar ? 'منذ $d يوم' : '$d d ago';
    }
    final mo = (diff.inDays / 30).floor();
    return ar ? 'منذ $mo شهر' : '$mo mo ago';
  }
}
