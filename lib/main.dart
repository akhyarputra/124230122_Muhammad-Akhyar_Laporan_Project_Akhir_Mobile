// Lokasi: lib/main.dart

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'features/onboarding/screens/splash_screen.dart';

import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:flutter_timezone/flutter_timezone.dart'; // <--- SUDAH DIHAPUS

import 'package:plantify_app/features/info/services/notification_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
import 'service/auth/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  tz.initializeTimeZones();

  // BAGIAN INI KITA HAPUS BIAR GAK ERROR
  // try {
  //   final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  //   ...
  // } catch (e) { ... }

  await NotificationService().init();

  await initializeDateFormatting('id_ID', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(AuthService())..init(),
        ),
      ],
      child: const PlantifyApp(),
    ),
  );
}

class PlantifyApp extends StatelessWidget {
  const PlantifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plantify',
      theme: ThemeData(primaryColor: const Color(0xFF2C6E49)),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
