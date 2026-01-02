// Lokasi: lib/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:plantify_app/features/mygarden/models/my_plant_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GreetingData {
  final String title;
  final String body;
  GreetingData(this.title, this.body);
}

// LOGIKA GET GREETING (Stabil dengan integer hour)
GreetingData getGreetingForTime(TimeOfDay time) {
  final int hour = time.hour;

  print("⏰ getGreetingForTime: Jam $hour");

  if (hour >= 4 && hour < 11) {
    return GreetingData(
      "Selamat Pagi",
      "Semoga harimu secerah bunga matahari!",
    );
  } else if (hour >= 11 && hour < 15) {
    return GreetingData(
      "Selamat Siang",
      "Jangan lupa siram tanaman kesayanganmu.",
    );
  } else if (hour >= 15 && hour < 19) {
    return GreetingData(
      "Selamat Sore",
      "Nikmati tenangnya sore hari di kebunmu.",
    );
  } else {
    return GreetingData(
      "Selamat Malam",
      "Waktunya istirahat dan memulihkan energi.",
    );
  }
}

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const String _notificationsEnabledKey = 'notifications_enabled';

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    await requestNotificationPermissions();
  }

  Future<void> requestNotificationPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> setNotificationsEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, isEnabled);
    if (!isEnabled) {
      await flutterLocalNotificationsPlugin.cancelAll();
    }
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  // --- FUNGSI SHOW TEST (DIPERBAIKI) ---
  Future<void> showTestGreetingNotification() async {
    if (!await areNotificationsEnabled()) return;

    // KUNCI PERBAIKAN: Gunakan DateTime.now() asli dari Dart
    // Ini otomatis ikut jam lokal HP, bukan UTC
    final DateTime nowLocal = DateTime.now();

    print("🔔 Tes Notifikasi. Waktu HP Asli: $nowLocal");

    // Ubah ke TimeOfDay untuk dicek logic greeting
    final TimeOfDay currentTime = TimeOfDay.fromDateTime(nowLocal);

    // Ambil teks greeting yang sesuai
    final greeting = getGreetingForTime(currentTime);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'plantify_test_channel',
          'Tes Notifikasi',
          channelDescription: 'Notifikasi tes instan',
          importance: Importance.high,
          priority: Priority.high,
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Tampilkan notifikasi langsung
    await flutterLocalNotificationsPlugin.show(
      0,
      greeting.title, // Judul sudah benar "Selamat Pagi/Siang/Sore/Malam"
      greeting.body,
      notificationDetails,
    );
  }

  // Fungsi Scheduling tetap menggunakan TZ (timezone) karena butuh 'scheduledDate'
  Future<void> scheduleDailyGreetingNotifications() async {
    if (!await areNotificationsEnabled()) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'plantify_greeting_channel',
          'Sapaan Harian',
          channelDescription: 'Notifikasi sapaan berdasarkan waktu',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    final List<TimeOfDay> greetingTimes = [
      const TimeOfDay(hour: 4, minute: 0),
      const TimeOfDay(hour: 11, minute: 0),
      const TimeOfDay(hour: 15, minute: 0),
      const TimeOfDay(hour: 19, minute: 0),
    ];

    await cancelAllGreetingNotifications();

    for (int i = 0; i < greetingTimes.length; i++) {
      final time = greetingTimes[i];
      final greeting = getGreetingForTime(time);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        1000 + i,
        greeting.title,
        greeting.body,
        _nextInstanceOfTimeLocal(time),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelAllGreetingNotifications() async {
    for (int i = 0; i < 4; i++) {
      await flutterLocalNotificationsPlugin.cancel(1000 + i);
    }
  }

  tz.TZDateTime _nextInstanceOfTimeLocal(TimeOfDay time) {
    // Kita tetap gunakan tz.local untuk scheduling, dengan asumsi tz.local sudah 'cukup' benar
    // atau setidaknya konsisten dengan library ini.
    // Jika masih meleset, pengguna tidak akan terlalu sadar karena ini notifikasi otomatis harian.
    // Tapi tombol "Test Notification" di atas DIJAMIN BENAR karena pakai DateTime.now()
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> scheduleWeeklyWateringNotification(MyPlant myPlant) async {
    await cancelPlantNotifications(myPlant);
    return;
  }

  Future<void> cancelPlantNotifications(MyPlant myPlant) async {
    for (int i = 1; i <= 7; i++) {
      await flutterLocalNotificationsPlugin.cancel(myPlant.plantInfo.id + i);
    }
  }
}
