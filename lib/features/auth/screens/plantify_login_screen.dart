// Lokasi file: lib/features/auth/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plantify_app/service/auth/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:plantify_app/config/dev_constants.dart';
import 'package:plantify_app/features/profile/setting_screen.dart';
import 'signup_screen.dart';
import '../../home/screens/home_screen.dart';

// --- PERUBAHAN 1: Hapus import NotificationService ---
// Kita tidak akan menjadwalkan notifikasi dari layar ini lagi.
// import 'package:plantify_app/features/info/services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  // --- PERUBAHAN 2: Hapus instance dari NotificationService ---
  // final _notificationService = NotificationService();

  // -- STATE MANAGEMENT --
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        Map<String, dynamic> result = await _authService.login(
          username: _usernameController.text,
          password: _passwordController.text,
        );

        if (!mounted) return;

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login berhasil!'),
              backgroundColor: Colors.green,
            ),
          );
          if (result['offline'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Login offline'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          final String message =
              result['message'] ?? 'Terjadi kesalahan saat login.';
          // If the error seems like a connectivity issue, provide diagnostic options
          if (message.toLowerCase().contains('tidak dapat terhubung') ||
              message.toLowerCase().contains('koneksi')) {
            await _showNetworkErrorDialog(message);
          } else {
            _showError(message);
          }
        }
      } catch (e) {
        // On exception, offer the network dialog and offline options
        await _showNetworkErrorDialog(
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _showNetworkErrorDialog(String message) async {
    final bool canUseCached = await _authService.isLoggedIn();

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tidak dapat terhubung ke server'),
          content: Text(
            '$message\n\nCoba salah satu opsi: ulangi, diagnosa koneksi, atau gunakan sesi lokal (offline).',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Retry the login flow (note: reuses current inputs)
                await _handleLogin();
              },
              child: const Text('Ulangi'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final resp = await http
                      .get(Uri.parse('${API_BASE_URL}time.php'))
                      .timeout(const Duration(seconds: 3));
                  final ok = resp.statusCode == 200;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Terkoneksi: ${API_BASE_URL}'
                            : 'Gagal terhubung ke ${API_BASE_URL}',
                      ),
                      backgroundColor: ok ? Colors.green : Colors.red,
                    ),
                  );
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal terhubung ke ${API_BASE_URL}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Diagnosa'),
            ),
            if (canUseCached)
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _authService.loadUserFromSession();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Masuk menggunakan sesi lokal'),
                    ),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                child: const Text('Gunakan Sesi Lokal'),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              child: const Text('Buka Settings'),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2C6E49);
    const Color backgroundColor = Color.fromARGB(255, 17, 0, 255);
    const Color textColor = Color(0xFF3E3636);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Form(
          key: _formKey,
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                Icon(Icons.eco, color: primaryColor, size: 80),
                const SizedBox(height: 20),
                Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sign in to continue',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 50),
                TextFormField(
                  controller: _usernameController,
                  keyboardType: TextInputType.text,
                  decoration: _getTextFieldDecoration(
                    label: 'Username or Email',
                    icon: Icons.person_outline,
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Field ini tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _getTextFieldDecoration(
                    label: 'Password',
                    icon: Icons.lock_outline,
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Password tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 40),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                          shadowColor: primaryColor.withOpacity(0.4),
                        ),
                        child: Text(
                          'SIGN IN',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.poppins(color: textColor),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFB46B54),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _getTextFieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        color: const Color(0xFF3E3636).withOpacity(0.6),
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF2C6E49)),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF2C6E49), width: 2),
      ),
    );
  }
}
