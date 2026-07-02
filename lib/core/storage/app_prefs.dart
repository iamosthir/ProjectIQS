import 'package:shared_preferences/shared_preferences.dart';

/// Non-secret persisted preferences: chosen locale, cached config/governorates,
/// onboarding flags. (Secrets live in [SecureTokenStore].)
class AppPrefs {
  AppPrefs(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppPrefs> create() async =>
      AppPrefs(await SharedPreferences.getInstance());

  static const _kLocale = 'locale_code';
  static const _kGovernorates = 'cached_governorates_json';
  static const _kSeenOnboarding = 'seen_onboarding';
  static const _kNotifications = 'notifications_enabled';

  /// `ar` | `en` | null (not yet chosen → default to device/`ar`).
  String? get localeCode => _prefs.getString(_kLocale);
  Future<void> setLocaleCode(String code) => _prefs.setString(_kLocale, code);

  /// Local push/banner preference (default on). The banner is suppressed when
  /// off; the OS permission is the real gate.
  bool get notificationsEnabled => _prefs.getBool(_kNotifications) ?? true;
  Future<void> setNotificationsEnabled(bool value) =>
      _prefs.setBool(_kNotifications, value);

  String? get cachedGovernoratesJson => _prefs.getString(_kGovernorates);
  Future<void> setCachedGovernoratesJson(String json) =>
      _prefs.setString(_kGovernorates, json);

  bool get seenOnboarding => _prefs.getBool(_kSeenOnboarding) ?? false;
  Future<void> setSeenOnboarding(bool value) =>
      _prefs.setBool(_kSeenOnboarding, value);

  // --- OTP resend cooldown (per phone) -------------------------------------
  // Stores the epoch-seconds at which a resend becomes allowed, so the
  // countdown survives leaving the OTP screen / an app restart.
  static String _resendKey(String phone) => 'otp_resend_until_$phone';

  int? otpResendUntil(String phone) => _prefs.getInt(_resendKey(phone));
  Future<void> setOtpResendUntil(String phone, int epochSeconds) =>
      _prefs.setInt(_resendKey(phone), epochSeconds);
  Future<void> clearOtpResendUntil(String phone) =>
      _prefs.remove(_resendKey(phone));
}
