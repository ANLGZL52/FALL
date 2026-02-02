import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  static const _key = 'fall_device_id';
  static const _uuid = Uuid();

  /// Cihaz bazlı ID üretir ve kalıcı saklar.
  /// - Android/iOS: aynı cihazda aynı kalır
  /// - App silinirse değişebilir (normal)
  static Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();

    final existing = (prefs.getString(_key) ?? '').trim();
    if (existing.isNotEmpty && existing.length >= 8) {
      return existing;
    }

    // UUID v4 üretip "DEV-" ile prefixleyelim (backend loglarında okunur)
    final id = 'DEV-${_uuid.v4()}';
    await prefs.setString(_key, id);
    return id;
  }

  /// Debug amaçlı: device id’yi sıfırlamak istersen
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
