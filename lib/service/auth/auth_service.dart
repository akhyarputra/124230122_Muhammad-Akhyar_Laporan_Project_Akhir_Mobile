// Lokasi: lib/services/auth_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plantify_app/config/dev_constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Use a direct base URL here to support manual IP edits in the service file.
// Change this string to point to your PHP backend when debugging on a device.
// Base URL taken from lib/config/dev_constants.dart -> API_BASE_URL

class AuthService {
  static Map<String, dynamic>? _currentUserDataCache;
  // Using a direct base URL set in lib/config/dev_constants.dart -> API_BASE_URL

  // --- FUNGSI BARU UNTUK KONEKSI TERKELOLA ---
  Future<Map<String, dynamic>> _performPostRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final client = http.Client(); // 1. Buat "saluran telepon" baru
    try {
      final baseUrl = API_BASE_URL;
      final uri = Uri.parse("${baseUrl}$endpoint");

      // Print basic diagnostic info (always print to ensure visibility on device logs)
      // ignore: avoid_print
      print('AuthService: Preparing POST to $uri');
      // Also show the JSON body we will try
      print('AuthService: JSON body: ${jsonEncode(body)}');

      // persist last request to SharedPreferences for on-device diagnostics
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'last_api_request',
          jsonEncode({
            'endpoint': endpoint,
            'uri': uri.toString(),
            'body': body,
            'timestamp': DateTime.now().toIso8601String(),
          }),
        );
      } catch (_) {}

      // Quick connectivity probe: try a simple GET to the base URL to confirm reachability
      try {
        final probeUri = Uri.parse(baseUrl);
        final probeResp = await client
            .get(probeUri)
            .timeout(const Duration(seconds: 5));
        // ignore: avoid_print
        print('AuthService: Probe GET ${probeUri} -> ${probeResp.statusCode}');
      } catch (probeErr) {
        // ignore: avoid_print
        print('AuthService: Probe GET failed: $probeErr');
      }

      // First try: send JSON body
      http.Response? response;
      try {
        response = await client.post(
          uri,
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode(body),
        );
        // ignore: avoid_print
        print('AuthService: Response ${response.statusCode} for $uri');
        // ignore: avoid_print
        print('AuthService: Response body: ${response.body}');
        // persist last response
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'last_api_response',
            jsonEncode({
              'endpoint': endpoint,
              'status': response.statusCode,
              'body': response.body,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          );
        } catch (_) {}
      } catch (jsonPostErr) {
        // JSON POST failed; attempt a fallback using form-encoded body
        // ignore: avoid_print
        print('AuthService: JSON POST failed: $jsonPostErr');
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'last_api_error',
            jsonEncode({
              'endpoint': endpoint,
              'error': jsonPostErr.toString(),
              'timestamp': DateTime.now().toIso8601String(),
            }),
          );
        } catch (_) {}
        try {
          // Prepare form-encoded map (values must be strings)
          final formBody = body.map((k, v) => MapEntry(k, v.toString()));
          final formResp = await client.post(
            uri,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: formBody,
          );
          response = formResp;
          // ignore: avoid_print
          print(
            'AuthService: Fallback form POST ${response.statusCode} for $uri',
          );
          // ignore: avoid_print
          print('AuthService: Fallback body: ${response.body}');
        } catch (formErr) {
          // Both attempts failed
          // ignore: avoid_print
          print('AuthService: Fallback form POST failed: $formErr');
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'last_api_error',
              jsonEncode({
                'endpoint': endpoint,
                'error': formErr.toString(),
                'timestamp': DateTime.now().toIso8601String(),
              }),
            );
          } catch (_) {}
          throw formErr; // rethrow so outer catch can handle
        }
      }

      try {
        return jsonDecode(response.body);
      } catch (e) {
        // ignore: avoid_print
        print('AuthService: Failed to parse JSON response: $e');
        return {
          'success': false,
          'message': 'Server returned invalid response.',
        };
      }
    } catch (e) {
      // ensure we always log the exception for diagnosis
      // ignore: avoid_print
      print('AuthService: Exception when posting to $endpoint: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'last_api_error',
          jsonEncode({
            'endpoint': endpoint,
            'error': e.toString(),
            'timestamp': DateTime.now().toIso8601String(),
          }),
        );
      } catch (_) {}
      return {
        'success': false,
        'message':
            'Tidak dapat terhubung ke server. Periksa koneksi Anda. (${e.toString()})',
      };
    } finally {
      // 2. APA PUN YANG TERJADI (sukses atau gagal), SELALU tutup koneksi!
      client.close();
      print("Koneksi HTTP untuk $endpoint telah ditutup.");
    }
  }

  // --- DEBUG HELPERS: store and validate a hashed credential in SharedPreferences
  // This is used only for local debugging (kDebugMode) to allow offline login
  // if the device is connected via USB but server unreachable.
  String _generateSalt({int length = 8}) {
    final rnd = Random.secure();
    final bytes = List<int>.generate(length, (_) => rnd.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hashPassword(String salt, String password) {
    final bytes = utf8.encode('$salt$password');
    final digest = crypto.sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _saveDebugCredential(String username, String password) async {
    if (!kDebugMode) return;
    final prefs = await SharedPreferences.getInstance();
    final enable = prefs.getBool('debug_auto_save_credentials') ?? false;
    if (!enable) return; // only save if user enabled it in settings
    final salt = _generateSalt();
    final hash = _hashPassword(salt, password);
    await prefs.setString('debug_username', username);
    await prefs.setString('debug_salt', salt);
    await prefs.setString('debug_passhash', hash);
  }

  Future<bool> _verifyDebugCredential(String username, String password) async {
    if (!kDebugMode) return false;
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('debug_username');
    final salt = prefs.getString('debug_salt');
    final savedHash = prefs.getString('debug_passhash');
    if (savedUser == null || salt == null || savedHash == null) return false;
    if (savedUser != username) return false;
    final hash = _hashPassword(salt, password);
    return hash == savedHash;
  }

  Future<Map<String, dynamic>> register({
    required String namaLengkap,
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    return _performPostRequest('register.php', {
      'nama_lengkap': namaLengkap,
      'username': username,
      'email': email,
      'phone_number': phoneNumber,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final responseBody = await _performPostRequest('login.php', {
      'username': username,
      'password': password,
    });

    if (responseBody['success']) {
      final prefs = await SharedPreferences.getInstance();
      final userData = responseBody['data'];
      _currentUserDataCache = userData;
      await prefs.setInt('userId', int.parse(userData['id'].toString()));
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', userData['username']);
      await prefs.setString('namaLengkap', userData['nama_lengkap']);
      await prefs.setString('email', userData['email']);
      await prefs.setString('phone_number', userData['phone_number']);
      await prefs.setString(
        'profileImageUrl',
        userData['profile_image_url'] ?? '',
      );
      // Save debug credential for offline login (debug builds only)
      if (kDebugMode) {
        await _saveDebugCredential(username, password);
      }
    } else {
      // If server isn't reachable and we're in debug, allow offline login
      final msg = (responseBody['message'] ?? '').toString().toLowerCase();
      if (kDebugMode &&
          (msg.contains('tidak dapat terhubung') || msg.contains('koneksi'))) {
        final ok = await _verifyDebugCredential(username, password);
        if (ok) {
          final prefs = await SharedPreferences.getInstance();
          // Restore cached user data if present
          final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
          if (isLoggedIn) {
            await loadUserFromSession();
          } else {
            // Provide basic fallback user data
            _currentUserDataCache = {
              'id': prefs.getInt('userId')?.toString() ?? '0',
              'username': username,
              'nama_lengkap': prefs.getString('namaLengkap') ?? username,
              'email': prefs.getString('email') ?? '',
              'phone_number': prefs.getString('phone_number') ?? '',
              'profile_image_url': prefs.getString('profileImageUrl') ?? '',
            };
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('username', username);
          }
          return {
            'success': true,
            'message':
                'Login offline (debug): menggunakan credential yang tersimpan',
            'offline': true,
          };
        }
      }
    }
    return responseBody;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserDataCache = null;
    await prefs.remove('userId');
    await prefs.remove('isLoggedIn');
    await prefs.remove('username');
    await prefs.remove('namaLengkap');
    await prefs.remove('email');
    await prefs.remove('phone_number');
    await prefs.remove('profileImageUrl');
    // Remove debug credential (if any)
    await prefs.remove('debug_username');
    await prefs.remove('debug_salt');
    await prefs.remove('debug_passhash');
    await prefs.remove('debug_auto_save_credentials');
    await Hive.close();
  }

  Map<String, dynamic>? getCurrentUserFromCache() {
    return _currentUserDataCache;
  }

  Future<void> loadUserFromSession() async {
    if (_currentUserDataCache != null) return;
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      _currentUserDataCache = {
        'id': prefs.getInt('userId').toString(),
        'username': prefs.getString('username'),
        'nama_lengkap': prefs.getString('namaLengkap'),
        'email': prefs.getString('email'),
        'phone_number': prefs.getString('phone_number'),
        'profile_image_url': prefs.getString('profileImageUrl'),
      };
    }
  }

  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String id,
    required String namaLengkap,
    required String username,
    required String email,
    required String phoneNumber,
  }) async {
    final responseBody = await _performPostRequest('update_profile.php', {
      'id': id,
      'nama_lengkap': namaLengkap,
      'username': username,
      'email': email,
      'phone_number': phoneNumber,
    });
    if (responseBody['success']) {
      final prefs = await SharedPreferences.getInstance();
      final updatedData = responseBody['data'];
      _currentUserDataCache = updatedData;
      await prefs.setString('namaLengkap', updatedData['nama_lengkap']);
      await prefs.setString('username', updatedData['username']);
      await prefs.setString('email', updatedData['email']);
      await prefs.setString('phone_number', updatedData['phone_number']);
    }
    return responseBody;
  }

  // Fungsi upload foto lebih kompleks, jadi kita tangani terpisah
  Future<Map<String, dynamic>> uploadProfilePicture(
    String id,
    XFile imageFile,
  ) async {
    final client = http.Client();
    try {
      final baseUrl = API_BASE_URL;
      var uri = Uri.parse("${baseUrl}upload_profile_picture.php");
      var request = http.MultipartRequest('POST', uri);
      request.fields['id'] = id;
      request.files.add(
        await http.MultipartFile.fromPath('profile_picture', imageFile.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final responseBody = jsonDecode(response.body);

      if (responseBody['success']) {
        final prefs = await SharedPreferences.getInstance();
        final newImageUrl = responseBody['data']['profile_image_url'];
        if (_currentUserDataCache != null) {
          _currentUserDataCache!['profile_image_url'] = newImageUrl;
        }
        await prefs.setString('profileImageUrl', newImageUrl);
      }
      return responseBody;
    } catch (e) {
      return {'success': false, 'message': 'Terjadi error: $e'};
    } finally {
      client.close();
      print("Koneksi HTTP untuk uploadProfilePicture telah ditutup.");
    }
  }
}
