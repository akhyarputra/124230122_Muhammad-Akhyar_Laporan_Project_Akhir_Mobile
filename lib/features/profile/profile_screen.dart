// Lokasi: lib/features/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import 'package:plantify_app/service/auth/auth_service.dart';
import 'package:plantify_app/features/home/widgets/bottom_nav_bar.dart';
import '../auth/screens/plantify_login_screen.dart';
import 'setting_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _picker = ImagePicker();

  // Variabel untuk menampilkan preview lokal sementara
  File? _localPickedImage;

  String? _userId;
  String? _username;
  String? _namaLengkap;
  String? _profileImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserDataFromCache();
  }

  void _loadUserDataFromCache() {
    final userData = _authService.getCurrentUserFromCache();

    if (userData != null && mounted) {
      setState(() {
        _userId = userData['id']?.toString();
        _username = userData['username'];
        _namaLengkap = userData['nama_lengkap'];

        // Simpan URL. Jika ada, tambahkan cache buster nanti di widget image
        _profileImageUrl =
            userData['profile_image_url'] ?? userData['profileImageUrl'];
      });
    }
  }

  Future<void> _handleImagePick(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 50, // Kompresi untuk mempercepat upload
      preferredCameraDevice: CameraDevice.rear,
    );

    if (pickedFile != null && _userId != null) {
      // 1. Tampilkan preview lokal segera agar user tahu foto terpilih
      setState(() {
        _localPickedImage = File(pickedFile.path);
        _isUploading = true;
      });

      try {
        final result = await _authService.uploadProfilePicture(
          _userId!,
          pickedFile,
        );

        if (mounted) {
          if (result['success']) {
            // Ambil URL baru dari respon server
            // Server harus mengembalikan URL lengkap atau path relatif yang benar
            final newImageUrl =
                result['data']?['profile_image_url'] ??
                result['data']?['profileImageUrl'];

            // Update Session di AuthService agar sinkron
            // (Asumsi: AuthService.uploadProfilePicture sudah mengupdate cache internal,
            //  tapi kita loadUserFromSession lagi untuk double check)
            await _authService.loadUserFromSession();

            setState(() {
              // Update state UI dengan URL baru
              _profileImageUrl = newImageUrl;

              // 2. Kunci sukses: HAPUS _localPickedImage setelah berhasil.
              // Kita ganti menampilkan NetworkImage dari URL baru.
              _localPickedImage = null;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message']),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Gagal di sisi server
            setState(() {
              _localPickedImage = null; // Reset preview
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message']),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _localPickedImage = null; // Reset preview
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terjadi kesalahan koneksi saat upload.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    }
  }

  void _showImageSourceChooser() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.of(context).pop();
                _handleImagePick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih Dari Galeri'),
              onTap: () {
                Navigator.of(context).pop();
                _handleImagePick(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Logout', style: GoogleFonts.poppins()),
        content: Text(
          'Anda yakin ingin keluar dari akun Anda?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Ya, Keluar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  void _showSaranKesanDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.school_outlined, color: Color(0xFF2C6E49)),
            const SizedBox(width: 10),
            Text(
              'Saran & Kesan',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            'Nothing here',
            style: GoogleFonts.poppins(height: 1.6),
            textAlign: TextAlign.justify,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // --- SOLUSI: Fungsi Helper untuk Memaksa Gambar Reload ---
  // Fungsi ini menambahkan timestamp ke akhir URL.
  // Contoh: gambar.jpg -> gambar.jpg?t=123456789
  // Server mengabaikan parameter 't', tapi Flutter menganggap ini URL baru
  // sehingga men-download ulang gambarnya (bypass cache).
  String _getSecureUrl(String url) {
    if (url.isEmpty) return "";
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Cek apakah url sudah punya parameter query (?)
    return url.contains('?') ? '$url&t=$timestamp' : '$url?t=$timestamp';
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2C6E49);
    const Color backgroundColor = Color(0xFFFAF3E0);
    const Color textColor = Color(0xFF3E3636);

    return Scaffold(
      bottomNavigationBar: PlantifyBottomNavBar(
        currentIndex: 4,
        primaryColor: primaryColor,
      ),
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Akun Saya',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Paksa load ulang, ini juga akan memicu _getSecureUrl baru karena build() dipanggil lagi
          _loadUserDataFromCache();
        },
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  _buildProfileHeader(),
                  const SizedBox(height: 40),
                  _buildProfileMenu(primaryColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    ImageProvider backgroundImage;

    // LOGIKA PENENTUAN GAMBAR:
    if (_localPickedImage != null) {
      // 1. Jika user baru pilih gambar (sedang proses/belum selesai), tampilkan file lokal
      backgroundImage = FileImage(_localPickedImage!);
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      // 2. Jika URL tersedia, gunakan NetworkImage DENGAN CACHE BUSTING (_getSecureUrl)
      //    Juga gunakan key unik agar widget dibangun ulang saat URL berubah
      backgroundImage = NetworkImage(_getSecureUrl(_profileImageUrl!));
    } else {
      // 3. Fallback ke gambar asset jika belum ada foto
      backgroundImage = const AssetImage('assets/profile_placeholder.png');
    }

    return Column(
      children: [
        Stack(
          children: [
            // Kontainer Lingkaran untuk Gambar
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: backgroundImage,
              // Tampilkan child loading HANYA jika sedang uploading
              child: _isUploading ? const CircularProgressIndicator() : null,
            ),
            // Tombol Kamera Kecil
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C6E49),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFAF3E0), width: 3),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: _isUploading ? null : _showImageSourceChooser,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          _namaLengkap ?? 'Memuat Nama...',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3E3636),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '@${_username ?? '...'}',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildProfileMenu(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
              if (result == true) {
                _loadUserDataFromCache();
              }
            },
          ),
          const Divider(indent: 15, endIndent: 15),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const Divider(indent: 15, endIndent: 15),
          _buildMenuItem(
            icon: Icons.school_outlined,
            title: 'Saran & Kesan Perkuliahan',
            onTap: _showSaranKesanDialog,
          ),
          const Divider(indent: 15, endIndent: 15),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Log Out',
            textColor: Colors.red,
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    const Color primaryColor = Color(0xFF2C6E49);
    final Color color = textColor ?? const Color(0xFF3E3636);

    return ListTile(
      leading: Icon(icon, color: textColor ?? primaryColor),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: color),
      ),
      trailing: textColor == null
          ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
          : null,
      onTap: onTap,
    );
  }
}
