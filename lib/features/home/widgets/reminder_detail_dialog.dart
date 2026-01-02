// Lokasi: lib/features/home/widgets/reminder_detail_dialog.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:plantify_app/features/info/widgets/plant_image.dart';
import 'package:plantify_app/features/mygarden/models/my_plant_model.dart';

// --- PERUBAHAN 1: Tambahkan import untuk package timezone ---
import 'package:timezone/timezone.dart' as tz;

// Helper Map untuk menampilkan nama hari (Tidak berubah)
const Map<int, String> dayNames = {
  1: 'SEN',
  2: 'SEL',
  3: 'RAB',
  4: 'KAM',
  5: 'JUM',
  6: 'SAB',
  7: 'MIN',
};

class ReminderDetailDialog extends StatefulWidget {
  final MyPlant myPlant;
  final DateTime
  initialCurrentTime; // Ini adalah waktu dalam zona waktu aktif pengguna
  final String timezoneName; // Nama zona waktu aktif pengguna, misal "London"

  const ReminderDetailDialog({
    super.key,
    required this.myPlant,
    required this.initialCurrentTime,
    required this.timezoneName,
  });

  @override
  State<ReminderDetailDialog> createState() => _ReminderDetailDialogState();
}

class _ReminderDetailDialogState extends State<ReminderDetailDialog> {
  late Timer _timer;
  late DateTime _liveCurrentTime;

  // --- PERUBAHAN 2: Tipe data diubah menjadi TZDateTime untuk kesadaran zona waktu ---
  tz.TZDateTime? _nextAlarmTime;

  @override
  void initState() {
    super.initState();
    // Inisialisasi waktu live & hitung waktu alarm berikutnya
    _liveCurrentTime = widget.initialCurrentTime;

    // Panggil fungsi kalkulasi yang baru dan sudah cerdas
    _nextAlarmTime = _calculateNextAlarm(widget.myPlant);

    // Buat timer yang akan update UI setiap detik
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _liveCurrentTime = _liveCurrentTime.add(const Duration(seconds: 1));
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Wajib untuk membatalkan timer
    super.dispose();
  }

  // --- PERUBAHAN 3 (INTI PERUBAHAN): Logika kalkulasi alarm yang baru ---
  /// Menghitung momen absolut (TZDateTime) kapan alarm berikutnya akan berbunyi,
  /// berdasarkan waktu dan zona waktu ASLI saat alarm diatur.
  tz.TZDateTime? _calculateNextAlarm(MyPlant plant) {
    // 1. Guard Clause: Jika data alarm tidak lengkap, hentikan.
    if (plant.alarmTime == null ||
        plant.alarmDays.isEmpty ||
        plant.alarmTimezoneId == null) {
      return null;
    }

    // 2. Dapatkan lokasi/zona waktu asli tempat alarm dibuat (misal: 'Asia/Jakarta').
    final tz.Location originalLocation = tz.getLocation(plant.alarmTimezoneId!);
    final TimeOfDay alarmTime = plant.alarmTime!;
    final List<int> sortedDays = plant.alarmDays.toList()..sort();

    // 3. Dapatkan waktu "sekarang" di dalam zona waktu asli tersebut.
    final tz.TZDateTime nowInOriginalTz = tz.TZDateTime.now(originalLocation);

    // 4. Cari jadwal valid berikutnya dari hari ini hingga 7 hari ke depan.
    for (int i = 0; i < 7; i++) {
      final checkDate = nowInOriginalTz.add(Duration(days: i));
      if (sortedDays.contains(checkDate.weekday)) {
        final nextAlarm = tz.TZDateTime(
          originalLocation,
          checkDate.year,
          checkDate.month,
          checkDate.day,
          alarmTime.hour,
          alarmTime.minute,
        );
        // Jika jadwal ini masih di masa depan, kita menemukannya!
        if (nextAlarm.isAfter(nowInOriginalTz)) {
          return nextAlarm; // Kembalikan momen absolut ini.
        }
      }
    }

    // 5. Jika semua jadwal minggu ini sudah lewat, cari jadwal pertama di minggu depan.
    for (int i = 0; i < 7; i++) {
      final checkDate = nowInOriginalTz.add(Duration(days: i));
      if (sortedDays.contains(checkDate.weekday)) {
        final nextWeekDate = checkDate.add(const Duration(days: 7));
        return tz.TZDateTime(
          originalLocation,
          nextWeekDate.year,
          nextWeekDate.month,
          nextWeekDate.day,
          alarmTime.hour,
          alarmTime.minute,
        );
      }
    }

    return null; // Fallback jika terjadi error
  }

  /// Format durasi untuk countdown (tidak berubah, tapi sekarang lebih akurat)
  String _formatDuration(Duration duration) {
    if (duration.isNegative) return "Waktunya Menyiram!";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return "${twoDigits(hours)} : ${twoDigits(minutes)} : ${twoDigits(seconds)}";
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2C6E49);
    const Color textColor = Color(0xFF3E3636);

    Duration timeLeft = const Duration(seconds: 0);
    if (_nextAlarmTime != null) {
      // Hitung selisih antara momen absolut alarm dengan waktu aktif pengguna.
      timeLeft = _nextAlarmTime!.difference(_liveCurrentTime);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Gambar dan Nama Tanaman
            Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: PlantImage(
                      assetPath: widget.myPlant.plantInfo.gambar,
                      imageUrl: widget.myPlant.plantInfo.gambarUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.myPlant.plantInfo.namaTanaman,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // Info Jadwal Siram
            _buildInfoRow(
              icon: Icons.alarm,
              title: 'Jadwal Siram',
              contentWidget: Text(
                // --- PERUBAHAN 4: Tampilkan waktu yang sudah dikonversi ---
                // DateFormat secara otomatis akan menampilkan TZDateTime
                // dalam format waktu lokal perangkat, sesuai yang kita mau.
                _nextAlarmTime != null
                    ? DateFormat('HH:mm').format(_nextAlarmTime!)
                    : '--:--',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildDaySelector(primaryColor),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Countdown Timer
            Text(
              'WAKTU MUNDUR',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: textColor.withOpacity(0.5),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDuration(timeLeft),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 32,
                color: textColor,
                letterSpacing: 2,
              ),
            ),

            // Info Current Time
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.public, size: 14, color: Colors.grey.shade700),
                  const SizedBox(width: 6),
                  Text(
                    '${DateFormat('HH:mm').format(_liveCurrentTime)} (${widget.timezoneName})',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Tutup',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required Widget contentWidget,
  }) {
    // ... (Tidak ada perubahan di widget helper ini)
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          '$title:',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade700),
        ),
        const Spacer(),
        contentWidget,
      ],
    );
  }

  Widget _buildDaySelector(Color primaryColor) {
    // ... (Tidak ada perubahan di widget helper ini)
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: dayNames.entries.map((entry) {
        final int dayIndex = entry.key;
        final String dayName = entry.value;
        final bool isActive = widget.myPlant.alarmDays.contains(dayIndex);
        return CircleAvatar(
          radius: 18,
          backgroundColor: isActive ? primaryColor : Colors.grey.shade200,
          child: Text(
            dayName,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: isActive ? Colors.white : Colors.grey.shade500,
            ),
          ),
        );
      }).toList(),
    );
  }
}
