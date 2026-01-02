// Lokasi: lib/features/profile/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plantify_app/features/info/services/notification_service.dart';
import '../../../service/currency/currency_service.dart';
import '../../../service/timezone/timezone_service.dart';
// ignore: unused_import
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- INSTANCE UNTUK SETIAP SERVICE ---
  final CurrencyService _currencyService = CurrencyService();
  final TimezoneService _timezoneService = TimezoneService();
  final NotificationService _notificationService = NotificationService();

  // State untuk UI
  bool _isNotificationOn = true;
  String _selectedCurrency = 'IDR';
  String _selectedTimezone = 'Asia/Jakarta';

  // Data statis untuk pilihan timezone
  final Map<String, String> _indonesianTimezones = {
    'WIB (Waktu Indonesia Barat)': 'Asia/Jakarta',
    'WITA (Waktu Indonesia Tengah)': 'Asia/Makassar',
    'WIT (Waktu Indonesia Timur)': 'Asia/Jayapura',
  };
  final Map<String, String> _worldTimezones = {
    'Waktu London': 'Europe/London',
    'Waktu Washington DC': 'America/New_York',
    'Waktu Meksiko': 'America/Mexico_City',
    'Waktu Cape Town': 'Africa/Johannesburg',
    'Waktu Melbourne': 'Australia/Melbourne',
    'Waktu Wellington': 'Pacific/Auckland',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final results = await Future.wait([
      _currencyService.getUserCurrency(),
      _timezoneService.getUserTimezone(),
      _notificationService.areNotificationsEnabled(),
    ]);

    if (mounted) {
      setState(() {
        _selectedCurrency = results[0] as String;
        _selectedTimezone = results[1] as String;
        _isNotificationOn = results[2] as bool;
      });
    }
  }

  Future<void> _onNotificationToggle(bool isEnabled) async {
    setState(() {
      _isNotificationOn = isEnabled;
    });
    await _notificationService.setNotificationsEnabled(isEnabled);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEnabled ? 'Notifikasi diaktifkan' : 'Notifikasi dimatikan',
          ),
          backgroundColor: isEnabled ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _onCurrencyChanged(String? newCurrency) async {
    if (newCurrency != null) {
      await _currencyService.saveUserCurrency(newCurrency);
      setState(() {
        _selectedCurrency = newCurrency;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mata uang diubah ke $newCurrency'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _onTimezoneChanged(String? newTimezone) async {
    if (newTimezone != null) {
      await _timezoneService.saveUserTimezone(newTimezone);
      setState(() {
        _selectedTimezone = newTimezone;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zona waktu berhasil diubah'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2C6E49);
    const Color backgroundColor = Color(0xFFFAF3E0);
    const Color textColor = Color(0xFF3E3636);

    bool isIndonesiaSelected = _indonesianTimezones.values.contains(
      _selectedTimezone,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          _buildSettingsTile(
            leadingIcon: Icons.notifications_outlined,
            title: 'Notification',
            primaryColor: primaryColor,
            trailingWidget: Switch(
              value: _isNotificationOn,
              onChanged: _onNotificationToggle,
              activeColor: primaryColor,
            ),
          ),
          if (_isNotificationOn)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton(
                onPressed: () {
                  _notificationService.showTestGreetingNotification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifikasi tes telah dikirim!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  foregroundColor: primaryColor,
                  elevation: 0,
                ),
                child: Text(
                  "Kirim Notifikasi Tes Sekarang",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          const Divider(),
          _buildSettingsTile(
            leadingIcon: Icons.currency_exchange,
            title: 'Currency',
            primaryColor: primaryColor,
            trailingWidget: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCurrency,
                onChanged: _onCurrencyChanged,
                items: <String>['IDR', 'USD', 'EUR', 'JPY']
                    .map<DropdownMenuItem<String>>((v) {
                      return DropdownMenuItem<String>(
                        value: v,
                        child: Text(
                          v,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    })
                    .toList(),
              ),
            ),
          ),
          const Divider(height: 32, thickness: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'Zona Waktu',
              style: GoogleFonts.poppins(
                color: textColor.withOpacity(0.7),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: isIndonesiaSelected,
              leading: Icon(
                Icons.flag_outlined,
                color: isIndonesiaSelected ? primaryColor : Colors.grey,
              ),
              title: Text(
                'Indonesia',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: const EdgeInsets.only(left: 40),
              children: _indonesianTimezones.entries.map((entry) {
                return RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.key, style: GoogleFonts.poppins()),
                  value: entry.value,
                  groupValue: _selectedTimezone,
                  onChanged: _onTimezoneChanged,
                  activeColor: primaryColor,
                );
              }).toList(),
            ),
          ),
          ..._worldTimezones.entries.map((entry) {
            return RadioListTile<String>(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              secondary: Icon(
                Icons.public,
                color: entry.value == _selectedTimezone
                    ? primaryColor
                    : Colors.grey,
              ),
              title: Text(entry.key, style: GoogleFonts.poppins()),
              value: entry.value,
              groupValue: _selectedTimezone,
              onChanged: _onTimezoneChanged,
              activeColor: primaryColor,
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData leadingIcon,
    required String title,
    required Color primaryColor,
    required Widget trailingWidget,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      leading: Icon(leadingIcon, color: primaryColor),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      trailing: trailingWidget,
      onTap: onTap,
    );
  }
}
