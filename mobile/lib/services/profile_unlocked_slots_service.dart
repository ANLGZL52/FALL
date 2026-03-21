import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile_models.dart';

/// "Kilidi açılmış" listesi: en fazla 5 kayıt; kullanıcı birini silince geçmişten
/// otomatik doldurulmaz. Yalnızca **yeni** tamamlanan (created_at önceki maksimumdan büyük)
/// ödemeli okumalar listeye eklenir (en fazla 5).
class ProfileUnlockedSlotsService {
  ProfileUnlockedSlotsService._();
  static final ProfileUnlockedSlotsService instance = ProfileUnlockedSlotsService._();

  static const _kVisible = 'profile_unlocked_visible_ids_v1';
  static const _kMaxPaidAt = 'profile_unlocked_max_paid_created_at_v1';
  /// İlk kez "kilidi açılmış" listesi dolduruldu mu (boşaltıldıysa geçmişten 5 çekilmez)
  static const _kSeeded = 'profile_unlocked_slots_seeded_v1';

  List<String> _dedupeKeepOrder(List<String> ids) {
    final seen = <String>{};
    final out = <String>[];
    for (final id in ids) {
      if (seen.add(id)) out.add(id);
    }
    return out;
  }

  /// history çekildikten sonra çağır; görünür kilidi açılmış id sırasını döner (≤5).
  Future<List<String>> syncAfterHistoryFetch(List<ProfileReadingItem> all) async {
    final prefs = await SharedPreferences.getInstance();
    final paid = all.where((r) => r.isPaid).toList()
      ..sort((a, b) {
        final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

    if (paid.isEmpty) {
      await prefs.setStringList(_kVisible, []);
      await prefs.remove(_kMaxPaidAt);
      await prefs.setBool(_kSeeded, false);
      return [];
    }

    final times = paid.map((r) => r.createdAt).whereType<DateTime>().toList();
    final currentMax = times.reduce((a, b) => a.isAfter(b) ? a : b);

    var visible = prefs.getStringList(_kVisible) ?? [];
    final seeded = prefs.getBool(_kSeeded) ?? false;
    final prevMaxStr = prefs.getString(_kMaxPaidAt);
    DateTime? prevMax = prevMaxStr != null ? DateTime.tryParse(prevMaxStr) : null;

    final paidIds = paid.map((r) => r.id).toSet();
    visible = visible.where((id) => paidIds.contains(id)).toList();

    if (visible.isEmpty) {
      if (!seeded) {
        visible = paid.take(5).map((r) => r.id).toList();
        await prefs.setBool(_kSeeded, true);
        await prefs.setStringList(_kVisible, visible);
        await prefs.setString(_kMaxPaidAt, currentMax.toIso8601String());
        return visible;
      }
      // Kullanıcı listeyi boşalttı / sildi: geçmişten 5 çekme; yalnızca yeni okumalar eklenecek
    }

    if (prevMax == null) {
      prevMax = currentMax;
      await prefs.setString(_kMaxPaidAt, currentMax.toIso8601String());
    }

    final newOnes = paid.where((r) {
      final ca = r.createdAt;
      if (ca == null) return false;
      return ca.isAfter(prevMax!);
    }).toList()
      ..sort((a, b) {
        final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ad.compareTo(bd);
      });

    for (final r in newOnes) {
      if (!visible.contains(r.id)) {
        visible.insert(0, r.id);
      }
    }
    visible = _dedupeKeepOrder(visible);
    if (visible.length > 5) {
      visible = visible.sublist(0, 5);
    }

    await prefs.setStringList(_kVisible, visible);
    await prefs.setString(_kMaxPaidAt, currentMax.toIso8601String());
    return visible;
  }

  /// Sunucudan silinen veya kullanıcının gizlediği kilidi açılmış kayıt.
  Future<void> removeVisibleId(String readingId) async {
    final prefs = await SharedPreferences.getInstance();
    final visible = prefs.getStringList(_kVisible) ?? [];
    await prefs.setStringList(_kVisible, visible.where((id) => id != readingId).toList());
  }
}
