// Lokasi: lib/services/currency_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  // --- GANTI DENGAN API KEY ANDA ---
  final String _apiKey = 'f406abc8849c6b06ff90431d';
  final String _baseUrl = 'https://v6.exchangerate-api.com/v6/';

  // Cache sederhana untuk menyimpan rates agar tidak selalu panggil API
  Map<String, dynamic>? _ratesCache;

  Future<Map<String, dynamic>?> getRates(String baseCurrency) async {
    // Jika cache sudah ada, langsung kembalikan
    if (_ratesCache != null) return _ratesCache;

    final url = Uri.parse('$_baseUrl$_apiKey/latest/$baseCurrency');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success') {
          _ratesCache = data['conversion_rates']; // Simpan ke cache
          return _ratesCache;
        }
      }
    } catch (e) {
      print('Error fetching currency rates: $e');
    }
    return null; // Kembalikan null jika gagal
  }

  // Helper untuk menyimpan preferensi currency
  Future<void> saveUserCurrency(String currencyCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_currency', currencyCode);
  }

  // Helper untuk mengambil preferensi currency
  Future<String> getUserCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    // Default ke IDR jika belum pernah diatur
    return prefs.getString('user_currency') ?? 'IDR';
  }
}
