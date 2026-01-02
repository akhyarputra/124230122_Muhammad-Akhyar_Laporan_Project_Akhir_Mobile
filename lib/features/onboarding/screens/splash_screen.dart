// Lokasi: lib/features/onboarding/screens/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plantify_app/service/auth/auth_service.dart';

// --- PERUBAHAN 1: Tambahkan import untuk NotificationService ---
import 'package:plantify_app/features/info/services/notification_service.dart';

import '../../auth/screens/plantify_login_screen.dart';
import '../../home/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  // --- PERUBAHAN 2: Buat instance dari NotificationService ---
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // Ganti nama fungsi menjadi lebih deskriptif
    _initializeAppAndNavigate();
  }

  // --- PERUBAHAN 3: Modifikasi total fungsi ini untuk menyertakan tugas baru ---
  void _initializeAppAndNavigate() async {
    // Jalankan pengecekan sesi dan jeda minimal secara bersamaan untuk efisiensi.
    final Future<bool> isLoggedInFuture = _authService.isLoggedIn();
    final Future<void> delay = Future.delayed(const Duration(seconds: 3));

    // Tunggu hasil pengecekan sesi selesai.
    final bool isLoggedIn = await isLoggedInFuture;

    // Sekarang, lakukan tugas persiapan "di belakang layar"
    if (isLoggedIn) {
      // Jika pengguna sudah login, ada dua tugas penting:

      // 1. Jadwalkan ulang notifikasi sapaan harian. Kita tidak perlu 'await'
      //    karena kita ingin navigasi terjadi secepat mungkin. Ini akan berjalan
      //    di latar belakang.
      _notificationService.scheduleDailyGreetingNotifications();

      // 2. Muat data sesi dari SharedPreferences ke dalam cache memori AuthService.
      //    Ini akan membuat ProfileScreen dan EditProfileScreen terbuka instan.
      await _authService.loadUserFromSession();
    }

    // Pastikan jeda minimal 3 detik sudah berlalu sebelum pindah halaman.
    await delay;

    // Setelah semua siap, navigasi ke halaman yang benar.
    if (mounted) {
      if (isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2C6E49);
    const Color backgroundColor = Color(0xFFFAF3E0);
    const Color textColor = Color(0xFF3E3636);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco, size: 120, color: primaryColor),
            const SizedBox(height: 24),
            Text(
              'Plantify',
              style: GoogleFonts.poppins(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Grow It. Love It. Share It.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                letterSpacing: 1.5,
                color: textColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
