/// Lightweight input validators. The backend is authoritative (it re-validates
/// and normalizes), so these are for fast client-side feedback only.
class Validators {
  Validators._();

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Iraqi mobile: `07XXXXXXXXX`, `7XXXXXXXXX`, or `+9647XXXXXXXXX`.
  /// Lenient — the server normalizes via `phone:IQ`.
  static final RegExp _iraqiPhone = RegExp(r'^(?:\+?964|0)?7\d{9}$');

  static bool isEmail(String v) => _email.hasMatch(v.trim());

  static bool isIraqiPhone(String v) =>
      _iraqiPhone.hasMatch(v.replaceAll(RegExp(r'[\s-]'), ''));

  /// Canonicalizes any user-entered Iraqi number to `+9647XXXXXXXXX`, so the
  /// country code is never doubled (a pasted `+9647700000001` stays
  /// `+9647700000001`, not `+964+9647…`). Strips `+964`/`00964`/`964` prefixes,
  /// a national trunk-prefix `0`, and any spaces/symbols.
  static String normalizeIraqiPhone(String raw) {
    var d = raw.replaceAll(RegExp(r'\D'), ''); // digits only — drops + and spaces
    if (d.startsWith('00964')) {
      d = d.substring(5);
    } else if (d.startsWith('964')) {
      d = d.substring(3);
    }
    if (d.startsWith('0')) d = d.substring(1);
    return '+964$d';
  }

  static bool isOtp(String v, {int length = 6}) =>
      RegExp('^\\d{$length}\$').hasMatch(v);

  static bool isNotBlank(String? v) => v != null && v.trim().isNotEmpty;
}
