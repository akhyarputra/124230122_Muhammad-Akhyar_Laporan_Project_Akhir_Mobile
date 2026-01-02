// Lokasi file: lib/features/auth/screens/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import service, sesuaikan path jika perlu
import 'package:plantify_app/service/auth/auth_service.dart';
// Import halaman Home, sesuaikan path
import 'package:plantify_app/features/home/screens/home_screen.dart';

enum PasswordStrength { Empty, Weak, Medium, Strong }

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // -- CONTROLLERS & KEYS --
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService(); // Instance dari AuthService

  // -- STATE MANAGEMENT --
  bool _isLoading = false;
  PasswordStrength _passwordStrength = PasswordStrength.Empty;
  double _strengthValue = 0.0;
  String _strengthText = '';
  Color _strengthColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
  }

  void _checkPasswordStrength() {
    String password = _passwordController.text;
    setState(() {
      if (password.isEmpty) {
        _passwordStrength = PasswordStrength.Empty;
        _strengthValue = 0;
        _strengthText = '';
      } else {
        double score = 0;
        if (password.length >= 8) score += 0.2;
        if (RegExp(r'[a-z]').hasMatch(password)) score += 0.2;
        if (RegExp(r'[A-Z]').hasMatch(password)) score += 0.2;
        if (RegExp(r'[0-9]').hasMatch(password)) score += 0.2;
        if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 0.2;
        _strengthValue = score;
        if (_strengthValue <= 0.4) {
          _passwordStrength = PasswordStrength.Weak;
          _strengthText = 'Rendah';
          _strengthColor = const Color(0xFFB46B54);
        } else if (_strengthValue <= 0.8) {
          _passwordStrength = PasswordStrength.Medium;
          _strengthText = 'Sedang';
          _strengthColor = Colors.orange.shade700;
        } else {
          _passwordStrength = PasswordStrength.Strong;
          _strengthText = 'Kuat';
          _strengthColor = const Color(0xFF2C6E49);
        }
      }
    });
  }

  // --- FUNGSI UTAMA UNTUK SIGN UP ---
  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        Map<String, dynamic> result = await _authService.register(
          namaLengkap: _namaController.text,
          username: _usernameController.text,
          email: _emailController.text,
          phoneNumber: _phoneController.text,
          password: _passwordController.text,
        );

        if (!mounted) return;

        if (result['success']) {
          // Jika registrasi berhasil, otomatis login
          Map<String, dynamic> loginResult = await _authService.login(
            username: _usernameController.text,
            password: _passwordController.text,
          );

          if (!mounted) return;

          if (loginResult['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registrasi & Login berhasil!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else {
            _showError(
              loginResult['message'] ?? 'Gagal login setelah registrasi.',
            );
          }
        } else {
          _showError(result['message'] ?? 'Terjadi kesalahan saat registrasi.');
        }
      } catch (e) {
        _showError(
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... UI (widget build) tidak berubah signifikan ...
    const Color primaryColor = Color(0xFF2C6E49);
    const Color backgroundColor = Color(0xFFFAF3E0);
    const Color textColor = Color(0xFF3E3636);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Form(
          // Menggunakan widget Form
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Create Account',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Let\'s get you started!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: textColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 40),

              _buildTextField(
                label: 'Nama Lengkap',
                icon: Icons.person_outline,
                controller: _namaController,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: 'Username',
                icon: Icons.badge_outlined,
                controller: _usernameController,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: 'Email',
                icon: Icons.alternate_email,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: _getTextFieldDecoration(
                  label: 'Password',
                  icon: Icons.lock_outline,
                ),
                validator: (value) => value == null || value.length < 8
                    ? 'Password minimal 8 karakter'
                    : null,
              ),
              const SizedBox(height: 12),

              if (_passwordStrength != PasswordStrength.Empty)
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: _strengthValue,
                        backgroundColor: Colors.grey[300],
                        color: _strengthColor,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _strengthText,
                      style: GoogleFonts.poppins(
                        color: _strengthColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: _getTextFieldDecoration(
                  label: 'Re-type Password',
                  icon: Icons.lock_reset_outlined,
                ),
                validator: (value) => value != _passwordController.text
                    ? 'Password tidak cocok'
                    : null,
              ),
              const SizedBox(height: 40),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _handleSignup,
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
                        'SIGN UP',
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
                    "Already have an account? ",
                    style: GoogleFonts.poppins(color: textColor),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Sign In',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFB46B54),
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: _getTextFieldDecoration(label: label, icon: icon),
      validator: (value) =>
          value == null || value.isEmpty ? '$label tidak boleh kosong' : null,
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
