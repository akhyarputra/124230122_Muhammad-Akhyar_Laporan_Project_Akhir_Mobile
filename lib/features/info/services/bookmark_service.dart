// Lokasi: lib/services/bookmark_service.dart

import 'dart:convert';
import 'package:plantify_app/features/info/models/plant_model.dart';

// --- PERUBAHAN 1: Ganti SharedPreferences dengan Hive ---
import 'package:hive_flutter/hive_flutter.dart';

class BookmarkService {
  // --- PERUBAHAN 2: Hapus key SharedPreferences lama, ganti dengan helper Hive ---
  // Fungsi helper untuk menciptakan nama Box yang unik untuk setiap pengguna.
  // Contoh: 'bookmarks_123' untuk user dengan ID 123.
  String _getBoxName(int userId) => 'bookmarks_$userId';

  // Key yang akan kita gunakan untuk menyimpan daftar bookmark di dalam Box.
  static const _listKey = 'bookmarksList';

  // --- PERUBAHAN 3: Modifikasi semua fungsi untuk menerima `userId` ---
  /// Mengambil daftar semua tanaman yang telah di-bookmark oleh PENGGUNA SPESIFIK.
  Future<List<Plant>> getBookmarkedPlants(int userId) async {
    // 1. Buka "laci" yang benar berdasarkan userId.
    final box = await Hive.openBox(_getBoxName(userId));

    // 2. Ambil data mentah (berupa satu string JSON yang berisi list).
    final String? bookmarksJsonString = box.get(_listKey);

    // 3. Jika tidak ada data, kembalikan list kosong.
    if (bookmarksJsonString == null) {
      return [];
    }

    // 4. Decode string JSON utama menjadi List<dynamic> (yang berisi string JSON per tanaman).
    final List<dynamic> rawList = json.decode(bookmarksJsonString);

    // 5. Decode setiap string JSON tanaman menjadi objek Plant.
    return rawList
        .map((jsonString) => Plant.fromJson(json.decode(jsonString), ''))
        .toList();
  }

  /// Menambah atau menghapus tanaman dari daftar bookmark PENGGUNA SPESIFIK.
  Future<void> toggleBookmark(Plant plant, int userId) async {
    // Panggil fungsi getBookmarkedPlants yang sudah di-refactor dengan userId.
    List<Plant> bookmarks = await getBookmarkedPlants(userId);

    final isAlreadyBookmarked = bookmarks.any((p) => p.id == plant.id);

    if (isAlreadyBookmarked) {
      bookmarks.removeWhere((p) => p.id == plant.id); // Jika ada, hapus
    } else {
      bookmarks.add(plant); // Jika tidak ada, tambahkan
    }

    // Panggil helper _saveBookmarks yang sudah di-refactor dengan userId.
    await _saveBookmarks(bookmarks, userId);
  }

  /// Memeriksa apakah suatu tanaman ada di daftar bookmark PENGGUNA SPESIFIK.
  Future<bool> isBookmarked(int plantId, int userId) async {
    final bookmarks = await getBookmarkedPlants(userId);
    return bookmarks.any((p) => p.id == plantId);
  }

  /// Fungsi helper privat untuk menyimpan list bookmark PENGGUNA SPESIFIK.
  Future<void> _saveBookmarks(List<Plant> bookmarks, int userId) async {
    // 1. Buka "laci" yang benar berdasarkan userId.
    final box = await Hive.openBox(_getBoxName(userId));

    // 2. Ubah List<Plant> menjadi List<String> yang berisi JSON.
    List<String> bookmarksJson = bookmarks
        .map((plant) => json.encode(plant.toJson()))
        .toList();

    // 3. Encode seluruh list di atas menjadi SATU string JSON tunggal lalu simpan.
    await box.put(_listKey, json.encode(bookmarksJson));
  }
}
