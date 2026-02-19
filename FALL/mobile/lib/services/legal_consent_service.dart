import 'package:shared_preferences/shared_preferences.dart';

import 'device_id_service.dart';
import 'legal_api.dart';

/// Yasal metin (Kullanıcı Sözleşmesi) onayı: yerel + PostgreSQL.
class LegalConsentService {
  LegalConsentService._();
  static const _kAccepted = 'legal_consent_accepted';

  static Future<bool> hasUserAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAccepted) ?? false;
  }

  /// Onayı kaydeder: önce backend'e POST atar; ulaşılamazsa yerelde kaydedip kullanıcıyı geçirir.
  /// Returns: true = sunucuya kaydedildi, false = sadece cihazda kaydedildi (sunucu ulaşılamadı).
  static Future<bool> accept() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await DeviceIdService.getOrCreate();
    try {
      await LegalApi.recordConsent(deviceId: deviceId, documentType: 'terms');
      await prefs.setBool(_kAccepted, true);
      return true;
    } catch (_) {
      await prefs.setBool(_kAccepted, true);
      return false;
    }
  }

  /// Sadece test / geliştirme için: onayı sıfırlar (yerel).
  static Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccepted);
  }
}
