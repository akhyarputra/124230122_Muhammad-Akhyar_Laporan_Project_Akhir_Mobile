// Lokasi: lib/features/info/services/my_garden_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plantify_app/features/mygarden/models/my_plant_model.dart';

// --- PERUBAHAN 1: Tambahkan import untuk Hive ---
import 'package:hive_flutter/hive_flutter.dart';

/// Service ini bertanggung jawab untuk semua operasi penyimpanan data
/// yang terkait dengan fitur "Taman Saya". Data tanaman sekarang disimpan
/// per-akun menggunakan Hive.
class MyGardenService {
  // --- PERUBAHAN 2: Definisikan konstanta baru untuk Hive ---
  // Fungsi helper untuk menciptakan nama Box yang unik untuk setiap pengguna.
  // Contoh: 'garden_123', 'garden_456', dst.
  String _getBoxName(int userId) => 'garden_$userId';
  // Ini adalah 'key' yang akan kita gunakan untuk menyimpan daftar tanaman di dalam Box.
  static const _plantListKey = 'plantList';

  // --- PERUBAHAN 3: Ubah signature fungsi untuk menerima `userId` ---
  /// Menyimpan seluruh daftar tanaman milik PENGGUNA SPESIFIK ke penyimpanan lokal Hive.
  Future<void> saveMyPlants(List<MyPlant> myPlants, int userId) async {
    // 1. Buka "laci" atau Box yang benar berdasarkan userId.
    final box = await Hive.openBox(_getBoxName(userId));

    // 2. Ubah List<MyPlant> menjadi List<String> yang berisi JSON per tanaman.
    List<String> myPlantsJson = myPlants
        .map((plant) => json.encode(plant.toJson()))
        .toList();

    // 3. Encode seluruh list di atas menjadi SATU string JSON tunggal.
    //    Ini cara yang efisien untuk menyimpan seluruh state taman.
    await box.put(_plantListKey, json.encode(myPlantsJson));
  }

  // --- PERUBAHAN 4: Ubah signature fungsi untuk menerima `userId` ---
  /// Mengambil daftar tanaman milik PENGGUNA SPESIFIK dari penyimpanan lokal Hive.
  Future<List<MyPlant>> getMyPlants(int userId) async {
    // 1. Buka "laci" yang benar berdasarkan userId.
    final box = await Hive.openBox(_getBoxName(userId));

    // 2. Ambil string JSON tunggal yang berisi seluruh daftar tanaman.
    final String? listJsonString = box.get(_plantListKey);

    // 3. Jika tidak ada data (pengguna baru atau belum menambah tanaman), kembalikan list kosong.
    if (listJsonString == null) {
      return [];
    }

    // 4. Decode string JSON utama menjadi List<dynamic> (berisi string JSON per tanaman)
    List<dynamic> rawList = json.decode(listJsonString);

    // 5. Decode setiap string JSON tanaman menjadi objek MyPlant.
    return rawList
        .map((jsonString) => MyPlant.fromJson(json.decode(jsonString)))
        .toList();
  }

  // --- PERUBAHAN 5: Ubah signature fungsi untuk menerima `userId` ---
  /// Mengambil HANYA tanaman yang memiliki alarm aktif dari PENGGUNA SPESIFIK.
  Future<List<MyPlant>> getPlantsWithAlarms(int userId) async {
    // 1. Panggil fungsi yang sudah di-refactor untuk mendapatkan semua tanaman pengguna.
    final allMyPlants = await getMyPlants(userId);

    // 2. Logika filtering tidak perlu diubah sama sekali, karena sudah bekerja
    //    pada data yang benar.
    final plantsWithAlarms = allMyPlants.where((plant) {
      return plant.alarmTime != null && plant.alarmDays.isNotEmpty;
    }).toList();

    return plantsWithAlarms;
  }

  // --- TIDAK ADA PERUBAHAN ---
  // Fungsi save/getUserLocation adalah pengaturan umum aplikasi, bukan data aktivitas pengguna,
  // jadi tidak apa-apa jika tetap menggunakan SharedPreferences.
  static const _userLocationKey = 'user_continent_location';

  Future<void> saveUserLocation(String continent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userLocationKey, continent);
  }

  Future<String> getUserLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userLocationKey) ?? 'Asia';
  }
}
