// Lokasi: lib/features/my_garden/models/my_plant_model.dart

import 'package:flutter/material.dart';
import '../../info/models/plant_model.dart'; // Sesuaikan path ini jika lokasi model Plant Anda berbeda

/// Model `MyPlant` merepresentasikan satu tanaman yang dimiliki oleh pengguna.
/// Ia "membungkus" data asli tanaman (`plantInfo`) dan menambahkan
/// informasi spesifik pengguna, yaitu jadwal alarm penyiraman.
class MyPlant {
  // Data asli tanaman dari katalog (dari file JSON).
  final Plant plantInfo;

  // Waktu spesifik untuk alarm (misalnya: 08:30). Bisa null jika tidak diatur.
  TimeOfDay? alarmTime;

  // Kumpulan hari di mana alarm akan aktif.
  // Menggunakan Set agar tidak ada duplikasi hari (misal: 1=Senin, 2=Selasa, ..., 7=Minggu).
  Set<int> alarmDays;

  // --- PERUBAHAN 1: TAMBAHKAN FIELD BARU UNTUK MENYIMPAN ID TIMEZONE ---
  /// Menyimpan ID zona waktu IANA saat alarm dibuat, contoh: 'Asia/Jakarta' atau 'Europe/London'.
  /// Bisa null jika tidak ada alarm yang diatur.
  String? alarmTimezoneId;

  MyPlant({
    required this.plantInfo,
    this.alarmTime,
    this.alarmDays = const {}, // Defaultnya adalah Set kosong
    this.alarmTimezoneId, // --- PERUBAHAN 2: TAMBAHKAN KE CONSTRUCTOR ---
  });

  /// Method `toJson` untuk mengubah objek `MyPlant` menjadi `Map`.
  /// Ini sangat penting agar data bisa di-encode ke JSON string dan
  /// disimpan di dalam SharedPreferences.
  Map<String, dynamic> toJson() {
    return {
      // Data asli tanaman disimpan sebagai nested object
      'plantInfo': plantInfo.toJson(),

      // TimeOfDay tidak bisa langsung di-encode ke JSON,
      // jadi kita ubah menjadi format String 'hour:minute'.
      'alarmTime': alarmTime != null
          ? '${alarmTime!.hour}:${alarmTime!.minute}'
          : null,

      // Set juga tidak bisa langsung di-encode, jadi kita ubah menjadi List.
      'alarmDays': alarmDays.toList(),

      // --- PERUBAHAN 3: TAMBAHKAN FIELD TIMEZONE KE DALAM JSON SAAT MENYIMPAN ---
      'alarmTimezoneId': alarmTimezoneId,
    };
  }

  /// Factory constructor `fromJson` untuk membuat objek `MyPlant` dari `Map`.
  /// Ini adalah kebalikan dari `toJson`, digunakan saat memuat data dari SharedPreferences.
  factory MyPlant.fromJson(Map<String, dynamic> json) {
    TimeOfDay? time;
    // Jika ada data 'alarmTime', kita parse kembali dari String menjadi TimeOfDay.
    if (json['alarmTime'] != null) {
      final parts = (json['alarmTime'] as String).split(':');
      time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return MyPlant(
      // Buat ulang objek Plant dari data nested 'plantInfo'.
      plantInfo: Plant.fromJson(
        json['plantInfo'],
        json['plantInfo']['asal'] ?? '',
      ),

      alarmTime: time,

      // Konversi kembali dari List<dynamic> (yang dibaca dari JSON) menjadi Set<int>.
      alarmDays: Set<int>.from(json['alarmDays']),

      // --- PERUBAHAN 4: BACA FIELD TIMEZONE DARI JSON SAAT MEMUAT DATA ---
      alarmTimezoneId:
          json['alarmTimezoneId'], // Akan null jika data lama belum memilikinya, dan itu tidak masalah.
    );
  }
}
