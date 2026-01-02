// Lokasi: lib/services/history_service.dart

import 'dart:convert';
import '/features/info/models/plant_model.dart'; // Sesuaikan path jika model Anda ada di lokasi berbeda

// --- PERUBAHAN 1: Ganti SharedPreferences dengan Hive ---
import 'package:hive_flutter/hive_flutter.dart';

class HistoryService {
  static const _maxHistoryPerContinent = 3;

  // --- PERUBAHAN 2: Hapus key SharedPreferences lama, ganti dengan helper Hive ---
  // Fungsi helper untuk menciptakan nama Box yang unik untuk setiap pengguna.
  String _getBoxName(int userId) => 'history_$userId';

  // Key yang akan kita gunakan untuk menyimpan Map riwayat di dalam Box.
  static const _historyMapKey = 'historyMap';

  // --- PERUBAHAN 3: Modifikasi semua fungsi untuk menerima `userId` ---
  /// Menambahkan tanaman ke daftar riwayat PENGGUNA SPESIFIK.
  Future<void> addToHistory(Plant plant, int userId) async {
    // 1. Ambil data riwayat yang sudah ada untuk pengguna ini.
    final Map<String, List<Plant>> historyData = await getHistory(userId);

    // 2. Dapatkan list riwayat untuk benua tanaman ini.
    String continent = plant.asal;
    List<Plant> continentHistory = historyData[continent] ?? [];

    // 3. Hapus tanaman yang sama jika sudah ada (agar bisa pindah ke depan).
    continentHistory.removeWhere((p) => p.id == plant.id);

    // 4. Tambahkan tanaman baru di posisi paling awal.
    continentHistory.insert(0, plant);

    // 5. Batasi jumlah riwayat menjadi 3 item terbaru.
    if (continentHistory.length > _maxHistoryPerContinent) {
      continentHistory = continentHistory.sublist(0, _maxHistoryPerContinent);
    }

    // 6. Masukkan kembali list yang sudah dimodifikasi ke dalam Map utama.
    historyData[continent] = continentHistory;

    // 7. Panggil fungsi helper untuk menyimpan Map riwayat yang baru.
    await _saveHistory(historyData, userId);
  }

  /// Mengambil semua riwayat PENGGUNA SPESIFIK, dikelompokkan per benua.
  Future<Map<String, List<Plant>>> getHistory(int userId) async {
    // 1. Buka "laci" riwayat yang benar berdasarkan userId.
    final box = await Hive.openBox(_getBoxName(userId));

    // 2. Ambil data mentah (satu string JSON yang merepresentasikan seluruh Map).
    final String? rawJson = box.get(_historyMapKey);

    if (rawJson == null) {
      return {}; // Kembalikan map kosong jika tidak ada riwayat sama sekali.
    }

    // 3. Logika decoding dari sini sama persis seperti sebelumnya.
    Map<String, dynamic> historyMapJson = json.decode(rawJson);
    Map<String, List<Plant>> historyData = {};

    for (var entry in historyMapJson.entries) {
      final String continent = entry.key;
      final List<dynamic> plantListJson = entry.value;
      historyData[continent] = plantListJson
          .map((item) => Plant.fromJson(item, ''))
          .toList();
    }

    return historyData;
  }

  /// Fungsi helper privat untuk menyimpan Map riwayat PENGGUNA SPESIFIK.
  Future<void> _saveHistory(
    Map<String, List<Plant>> historyData,
    int userId,
  ) async {
    // 1. Buka "laci" riwayat yang benar.
    final box = await Hive.openBox(_getBoxName(userId));

    // 2. Konversi Map<String, List<Plant>> menjadi format yang bisa di-encode ke JSON,
    //    yaitu Map<String, List<Map<String, dynamic>>>.
    Map<String, dynamic> historyMapJson = historyData.map(
      (continent, plantList) =>
          MapEntry(continent, plantList.map((p) => p.toJson()).toList()),
    );

    // 3. Encode seluruh map tersebut menjadi satu string JSON dan simpan.
    await box.put(_historyMapKey, json.encode(historyMapJson));
  }
}
