// Lokasi: lib/features/profile/screens/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Hapus SharedPreferences, karena kita tidak akan menggunakannya lagi di sini.
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:plantify_app/service/auth/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _authService = AuthService();

  String? _userId;
  // --- PERUBAHAN UTAMA 1: Ubah _isLoading menjadi false di awal ---
  // Karena kita memuat dari cache, tidak ada lagi penundaan.
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // --- PERUBAHAN UTAMA 2: Panggil fungsi baru yang membaca dari cache ---
    _loadInitialDataFromCache();
  }

  // --- FUNGSI BARU (SINKRON): Mengambil data dari cache memori AuthService ---
  void _loadInitialDataFromCache() {
    final userData = _authService.getCurrentUserFromCache();
    if (userData != null) {
      // Tidak perlu setState karena ini terjadi di initState sebelum build pertama.
      _userId = userData['id']?.toString();
      _namaController.text = userData['nama_lengkap'] ?? '';
      _usernameController.text = userData['username'] ?? '';
      _emailController.text = userData['email'] ?? '';
      _phoneController.text = userData['phone_number'] ?? '';
    }
  }

  // Fungsi untuk mengirim data yang diubah ke backend (tidak ada perubahan signifikan)
  Future<void> _handleUpdateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await _authService.updateProfile(
          id: _userId!,
          namaLengkap: _namaController.text,
          username: _usernameController.text,
          email: _emailController.text,
          phoneNumber: _phoneController.text,
        );

        if (mounted) {
          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message']),
                backgroundColor: Colors.green,
              ),
            );
            // Kembali ke halaman profil dengan membawa sinyal 'sukses' (true)
            Navigator.pop(context, true);
          } else {
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat terhubung ke server.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2C6E49);
    const Color backgroundColor = Color(0xFFFAF3E0);
    const Color textColor = Color(0xFF3E3636);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // --- PERUBAHAN UTAMA 3: Hapus pengecekan _isLoading di body ---
      // Karena data sudah dimuat secara instan.
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildEditTextField(
                controller: _namaController,
                label: 'Nama Lengkap',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 25),
              _buildEditTextField(
                controller: _usernameController,
                label: 'Username',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 25),
              _buildEditTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.alternate_email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 25),
              _buildEditTextField(
                controller: _phoneController,
                label: 'Nomor Telepon',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleUpdateProfile,
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
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        'Simpan Perubahan',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: const Color(0xFF3E3636).withOpacity(0.6),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF2C6E49)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF2C6E49), width: 2),
        ),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? '$label tidak boleh kosong' : null,
    );
  }
}
