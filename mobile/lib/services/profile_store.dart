import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile_models.dart';
import '../services/device_id_service.dart';
import '../services/profile_api.dart';

/// Tek kaynak: Profil bilgisini hem local cache'de tutar, hem server ile sync eder.
/// - Uygulama açıldığında init() çağırınca local hızlı yükler
/// - İstersen refreshFromServer() ile Railway'den günceller
class ProfileStore extends ChangeNotifier {
  ProfileStore._();
  static final ProfileStore instance = ProfileStore._();

  static const _kName = 'profile_name';
  static const _kBirthDate = 'profile_birth_date';
  static const _kBirthPlace = 'profile_birth_place';
  static const _kBirthTime = 'profile_birth_time';

  bool _inited = false;
  bool _syncing = false;

  bool get syncing => _syncing;

  ProfileMe? _me;
  ProfileMe? get me => _me;

  /// Local cache'den okur (hızlı açılış) + isterse server sync.
  Future<void> init({bool alsoSyncServer = true}) async {
    if (_inited) return;
    _inited = true;

    await _loadLocal();

    if (alsoSyncServer) {
      // server yoksa da sorun değil: sessizce geçer
      await refreshFromServer(silent: true);
    }
  }

  Future<void> _loadLocal() async {
    final sp = await SharedPreferences.getInstance();
    final deviceId = await DeviceIdService.getOrCreate();

    final name = (sp.getString(_kName) ?? '').trim();
    final bd = (sp.getString(_kBirthDate) ?? '').trim();
    final bp = (sp.getString(_kBirthPlace) ?? '').trim();
    final bt = (sp.getString(_kBirthTime) ?? '').trim();

    _me = ProfileMe(
      deviceId: deviceId,
      displayName: name.isEmpty ? 'Misafir' : name,
      birthDate: bd.isEmpty ? null : bd,
      birthPlace: bp.isEmpty ? null : bp,
      birthTime: bt.isEmpty ? null : bt,
    );

    notifyListeners();
  }

  Future<void> _saveLocal(ProfileMe me) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kName, me.displayName.trim());
    await sp.setString(_kBirthDate, (me.birthDate ?? '').trim());
    await sp.setString(_kBirthPlace, (me.birthPlace ?? '').trim());
    await sp.setString(_kBirthTime, (me.birthTime ?? '').trim());
  }

  /// Railway'den güncel profili çeker ve local'e yazar.
  Future<void> refreshFromServer({bool silent = false}) async {
    if (_syncing) return;
    _syncing = true;
    if (!silent) notifyListeners();

    try {
      final deviceId = await DeviceIdService.getOrCreate();
      final remote = await ProfileApi.getMe(deviceId: deviceId);

      // Remote "Misafir" ise local'i bozmayalım (senin mevcut ProfileScreen mantığıyla uyumlu)
      final current = _me;

      final newMe = ProfileMe(
        deviceId: deviceId,
        displayName: (remote.displayName.trim().isNotEmpty && remote.displayName != 'Misafir')
            ? remote.displayName.trim()
            : (current?.displayName.trim().isNotEmpty == true ? current!.displayName : 'Misafir'),
        birthDate: (remote.birthDate ?? '').trim().isEmpty ? current?.birthDate : remote.birthDate,
        birthPlace: (remote.birthPlace ?? '').trim().isEmpty ? current?.birthPlace : remote.birthPlace,
        birthTime: (remote.birthTime ?? '').trim().isEmpty ? current?.birthTime : remote.birthTime,
      );

      _me = newMe;
      await _saveLocal(newMe);
    } catch (_) {
      // offline vs. sessiz geç
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  /// Profil kaydet: local + server
  Future<ProfileMe> save(ProfileUpsertRequest req) async {
    final deviceId = await DeviceIdService.getOrCreate();

    // önce local hızlı yaz
    final localMe = ProfileMe(
      deviceId: deviceId,
      displayName: req.displayName.trim().isEmpty ? 'Misafir' : req.displayName.trim(),
      birthDate: (req.birthDate ?? '').trim().isEmpty ? null : req.birthDate!.trim(),
      birthPlace: (req.birthPlace ?? '').trim().isEmpty ? null : req.birthPlace!.trim(),
      birthTime: (req.birthTime ?? '').trim().isEmpty ? null : req.birthTime!.trim(),
    );
    _me = localMe;
    await _saveLocal(localMe);
    notifyListeners();

    // sonra server
    final remote = await ProfileApi.upsertMe(deviceId: deviceId, req: req);

    _me = remote;
    await _saveLocal(remote);
    notifyListeners();

    return remote;
  }

  /// Kullanıcı “başkasına bakacaksa” hızlı temizleme:
  /// Bu SADECE form alanlarını boş bırakmak içindir.
  /// Profil ekranında tekrar kaydederse geri gelir.
  Future<void> clearLocalOnly() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kName, '');
    await sp.setString(_kBirthDate, '');
    await sp.setString(_kBirthPlace, '');
    await sp.setString(_kBirthTime, '');

    final deviceId = await DeviceIdService.getOrCreate();
    _me = ProfileMe(
      deviceId: deviceId,
      displayName: 'Misafir',
      birthDate: null,
      birthPlace: null,
      birthTime: null,
    );
    notifyListeners();
  }

  /// Form doldurmada işine yarar: profil dolu mu?
  bool get hasMeaningfulProfile {
    final m = _me;
    if (m == null) return false;
    final nameOk = m.displayName.trim().isNotEmpty && m.displayName != 'Misafir';
    final bdOk = (m.birthDate ?? '').trim().isNotEmpty;
    return nameOk || bdOk;
  }
}
