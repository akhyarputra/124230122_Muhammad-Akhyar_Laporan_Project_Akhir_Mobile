// Lokasi: lib/services/timezone_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plantify_app/config/dev_constants.dart';

// Use a direct base URL so developers can change the server IP in this file.
const String _timeBaseUrl = API_BASE_URL;

class TimezoneService {
  // URL ini akan menunjuk ke backend proxy Anda di XAMPP.
  // Gunakan 'localhost' jika debug di Chrome laptop.
  // Ganti dengan IP lokal Anda (misal: 'http://192.168.1.10/api/') jika debug di HP.
  // Base URL set in service file via `_timeBaseUrl` constant.

  /// Menyimpan identifier zona waktu yang dipilih pengguna.
  Future<void> saveUserTimezone(String timezoneIdentifier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_timezone', timezoneIdentifier);
  }

  /// Mengambil identifier zona waktu yang tersimpan. Default ke WIB.
  Future<String> getUserTimezone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_timezone') ?? 'Asia/Jakarta';
  }

  /// Mengambil waktu saat ini secara real-time melalui backend proxy Anda.
  ///
  /// [timezoneIdentifier] akan dikirim sebagai parameter ke `time.php`.
  Future<DateTime?> getConvertedTime(String timezoneIdentifier) async {
    // Membangun URL lengkap ke script PHP Anda.
    // Hasilnya akan menjadi: http://localhost/api/time.php?timezone=Europe/London
    final url = Uri.parse(
      '${_timeBaseUrl}time.php?timezone=$timezoneIdentifier',
    );

    try {
      // Diagnostic log
      // ignore: avoid_print
      print('TimezoneService: GET $url');

      final response = await http.get(url).timeout(const Duration(seconds: 8));

      // Diagnostic response
      print('TimezoneService: Response ${response.statusCode}');
      print('TimezoneService: Body: ${response.body}');

      // persist last request/response
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'last_api_request',
          jsonEncode({
            'endpoint': 'time.php',
            'uri': url.toString(),
            'method': 'GET',
            'timestamp': DateTime.now().toIso8601String(),
          }),
        );
        await prefs.setString(
          'last_api_response',
          jsonEncode({
            'endpoint': 'time.php',
            'status': response.statusCode,
            'body': response.body,
            'timestamp': DateTime.now().toIso8601String(),
          }),
        );
      } catch (_) {}

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Try multiple possible shapes the PHP might return
        // 1) { 'timeZone': '...', 'dateTime': '...' }
        if (data is Map && data['dateTime'] != null) {
          final String datetimeString = data['dateTime'];
          return DateTime.parse(datetimeString);
        }

        // 2) { 'success': true, 'data': { 'dateTime': '...' } }
        if (data is Map &&
            data['success'] == true &&
            data['data'] is Map &&
            data['data']['dateTime'] != null) {
          final String datetimeString = data['data']['dateTime'];
          return DateTime.parse(datetimeString);
        }

        // If no recognized format
        // ignore: avoid_print
        print('TimezoneService: Unrecognized response shape');
        return null;
      } else {
        // Gagal menghubungi server proxy Anda (misal: 404 atau 500).
        // ignore: avoid_print
        print('TimezoneService: Non-200 status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // Error jaringan atau timeout saat mencoba menghubungi server proxy Anda.
      // ignore: avoid_print
      print('TimezoneService: Exception while requesting time: $e');
      return null;
    }
  }
}
