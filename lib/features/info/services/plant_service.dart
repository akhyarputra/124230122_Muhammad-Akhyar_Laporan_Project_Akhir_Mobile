// Lokasi: lib/features/info/services/plant_service.dart

import 'dart:convert'; // Diperlukan untuk JSON
import 'package:http/http.dart'
    as http; // Diperlukan untuk membuat panggilan API
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant_model.dart';

// Use a direct base URL so developers can change the server IP in this file.
import 'package:plantify_app/config/dev_constants.dart';

const String _plantBaseUrl = API_BASE_URL;

/// Service ini sekarang bertanggung jawab untuk mengambil data tanaman
/// dari API Endpoint di server Anda. Base URL didefinisikan oleh `API_BASE_URL` in
/// `lib/config/dev_constants.dart` so developers edit one place.
class PlantService {
  // Base URL is now a compile-time constant from `lib/config/dev_constants.dart`.

  // Variabel untuk menyimpan cache data tanaman dalam satu sesi aplikasi.
  // Ini mencegah aplikasi memanggil API berulang kali jika tidak perlu.
  List<Plant>? _plantCache;

  /// Memuat SEMUA tanaman dari satu API Endpoint.
  Future<List<Plant>> loadAllPlants() async {
    // 1. Jika data sudah ada di cache, langsung kembalikan data tersebut.
    if (_plantCache != null) {
      // Mengembalikan salinan list agar list asli di cache tidak termodifikasi
      return List<Plant>.from(_plantCache!);
    }

    // 2. Siapkan URL lengkap ke endpoint PHP Anda.
    final url = Uri.parse('${_plantBaseUrl}get_plants.php');

    try {
      // 3. Buat permintaan GET ke API Anda dan tunggu responsnya.
      // Diagnostic log
      print('PlantService: GET $url');

      // persist last request for diagnostics
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'last_api_request',
          jsonEncode({
            'endpoint': 'get_plants.php',
            'uri': url.toString(),
            'method': 'GET',
            'timestamp': DateTime.now().toIso8601String(),
          }),
        );
      } catch (_) {}

      final response = await http.get(url).timeout(const Duration(seconds: 8));

      // Diagnostic response
      print('PlantService: Response ${response.statusCode}');
      print('PlantService: Body: ${response.body}');

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'last_api_response',
          jsonEncode({
            'endpoint': 'get_plants.php',
            'status': response.statusCode,
            'body': response.body,
            'timestamp': DateTime.now().toIso8601String(),
          }),
        );
      } catch (_) {}

      // 4. Periksa apakah permintaan berhasil (status code 200).
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Handle a few possible response shapes:
        // 1) { 'success': true, 'data': [ ... ] }
        if (decoded is Map &&
            decoded['success'] == true &&
            decoded['data'] is List) {
          final List<dynamic> plantListJson = decoded['data'];
          final plants = plantListJson.map((jsonItem) {
            return Plant.fromJson(jsonItem, jsonItem['asal'] ?? '');
          }).toList();
          _plantCache = plants;
          return plants;
        }

        // 2) Direct list returned: [ {...}, {...} ]
        if (decoded is List) {
          final plants = decoded.map((jsonItem) {
            return Plant.fromJson(jsonItem, jsonItem['asal'] ?? '');
          }).toList();
          _plantCache = plants;
          return plants;
        }

        // Unknown shape
        // ignore: avoid_print
        print('PlantService: Unrecognized response shape');
        return [];
      } else {
        // Menangani kasus jika terjadi error HTTP (misal: 404 Not Found, 500 Server Error).
        // ignore: avoid_print
        print('PlantService: Non-200 status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      // Menangani kasus jika terjadi error koneksi (misal: tidak ada internet, DNS error).
      // ignore: avoid_print
      print('PlantService: Exception while loading plants: $e');
      return [];
    }
  }
}
