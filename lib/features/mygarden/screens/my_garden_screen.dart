// Lokasi: lib/features/my_garden/screens/my_garden_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plantify_app/features/info/widgets/plant_image.dart';

import 'dart:io' show Platform;
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

import '../../info/models/plant_model.dart';
import '../../info/services/plant_service.dart';
import '../models/my_plant_model.dart';
import 'package:plantify_app/features/info/services/my_garden_service.dart';
import '../widgets/set_alarm_sheet.dart';
import 'package:plantify_app/features/info/services/notification_service.dart';
import 'package:plantify_app/service/timezone/timezone_service.dart';
import 'package:plantify_app/service/auth/auth_service.dart';
import 'package:plantify_app/features/home/widgets/bottom_nav_bar.dart';

class MyGardenScreen extends StatefulWidget {
  const MyGardenScreen({super.key});
  @override
  State<MyGardenScreen> createState() => _MyGardenScreenState();
}

class _MyGardenScreenState extends State<MyGardenScreen> {
  final NotificationService _notificationService = NotificationService();
  final MyGardenService _gardenService = MyGardenService();
  final PlantService _plantService = PlantService();
  final TimezoneService _timezoneService = TimezoneService();
  final AuthService _authService = AuthService();
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<MyPlant> _myPlants = [];
  List<Plant> _allPlants = [];
  List<Plant> _searchResults = [];

  int? _currentUserId;
  bool _isLoading = true;
  bool _isSearching = false;
  String _userLocation = 'Asia';
  final List<String> _continents = [
    'Asia',
    'Amerika',
    'Afrika',
    'Australia',
    'Eropa',
  ];

  final Map<int, String> difficultyDescription = {
    0: 'Sangat Cocok',
    1: 'Adaptif',
    2: 'Menantang',
  };
  final Map<int, String> difficultyExplanation = {
    0: 'Berasal dari benua Anda, perawatan lebih mudah.',
    1: 'Dari benua dengan iklim mirip, butuh sedikit adaptasi.',
    2: 'Dari benua dengan iklim sangat berbeda, butuh perawatan khusus.',
  };
  final Map<int, Color> difficultyColor = {
    0: Colors.green,
    1: Colors.orange,
    2: Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _searchController.addListener(_filterCatalogResults);
  }

  Future<void> _initializeScreen() async {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    if (mounted) {
      setState(() {
        _currentUserId = userId;
        _isLoading = true;
      });
      await _loadInitialData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (_currentUserId == null) return;
    final results = await Future.wait([
      _gardenService.getMyPlants(_currentUserId!),
      _plantService.loadAllPlants(),
      _gardenService.getUserLocation(),
    ]);
    if (mounted) {
      setState(() {
        _myPlants = results[0] as List<MyPlant>;
        _allPlants = results[1] as List<Plant>;
        _userLocation = results[2] as String;
        _isLoading = false;
      });
    }
  }

  void _filterCatalogResults() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _searchResults = query.isEmpty
          ? []
          : _allPlants
                .where(
                  (p) =>
                      p.namaTanaman.toLowerCase().contains(query) ||
                      p.namaLatin.toLowerCase().contains(query),
                )
                .toList();
    });
  }

  int _calculateDifficulty(String plantOrigin) {
    if (plantOrigin == _userLocation) return 0;
    const tropical = {'Asia', 'Afrika', 'Amerika'};
    const temperate = {'Eropa', 'Australia'};
    if ((tropical.contains(plantOrigin) && tropical.contains(_userLocation)) ||
        (temperate.contains(plantOrigin) &&
            temperate.contains(_userLocation))) {
      return 1;
    }
    return 2;
  }

  void _addPlantToGarden(Plant plant) {
    if (_currentUserId == null) return;
    if (_myPlants.any((myPlant) => myPlant.plantInfo.id == plant.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanaman ini sudah ada di Taman Saya.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final newMyPlant = MyPlant(plantInfo: plant);
    setState(() {
      _myPlants.add(newMyPlant);
    });
    _gardenService.saveMyPlants(_myPlants, _currentUserId!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${plant.namaTanaman} berhasil ditambahkan!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // --- FUNGSI onAlarmSet DENGAN LOGIKA ALARM NATIVE YANG SUDAH DIPERBAIKI ---
  Future<void> _onAlarmSet(
    MyPlant myPlant,
    TimeOfDay newTime,
    Set<int> newDays,
  ) async {
    if (_currentUserId == null) return;

    final String userTimezoneId = await _timezoneService.getUserTimezone();

    setState(() {
      myPlant.alarmTime = newTime;
      myPlant.alarmDays = newDays;
      if (newDays.isNotEmpty) {
        myPlant.alarmTimezoneId = userTimezoneId;
      } else {
        myPlant.alarmTimezoneId = null;
      }
    });

    await _gardenService.saveMyPlants(_myPlants, _currentUserId!);
    await _notificationService.cancelPlantNotifications(myPlant);

    if (newDays.isNotEmpty) {
      if (Platform.isAndroid) {
        // Pemetaan hari dari format Dart (Senin=1) ke format Kalender Android (Minggu=1)
        final Map<int, int> dayMap = {1: 2, 2: 3, 3: 4, 4: 5, 5: 6, 6: 7, 7: 1};
        final List<int> intentDays = newDays.map((d) => dayMap[d]!).toList();

        final intent = AndroidIntent(
          action: 'android.intent.action.SET_ALARM',
          category: 'android.intent.category.DEFAULT',
          flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
          arguments: <String, dynamic>{
            'android.intent.extra.alarm.HOUR': newTime.hour,
            'android.intent.extra.alarm.MINUTES': newTime.minute,
            'android.intent.extra.alarm.MESSAGE':
                'Siram ${myPlant.plantInfo.namaTanaman}',
            'android.intent.extra.alarm.DAYS': intentDays,
            // 'SKIP_UI' dihapus untuk memastikan kompatibilitas maksimal
          },
        );
        try {
          await intent.launch();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal membuka aplikasi Jam: $e')),
            );
          }
        }
      } else {
        // Fallback untuk platform selain Android (misal: iOS)
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Atur Alarm Manual', style: GoogleFonts.poppins()),
              content: Text(
                'Buka aplikasi Jam di perangkat Anda dan buat alarm dengan:\n\n'
                '⏰ Waktu: ${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}\n'
                '🔔 Label: Siram ${myPlant.plantInfo.namaTanaman}\n'
                '📅 Hari: ${_getDayNames(newDays).join(', ')}',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  void _enterSearchMode() {
    setState(() => _isSearching = true);
    Future.delayed(
      const Duration(milliseconds: 100),
      () => _searchFocusNode.requestFocus(),
    );
  }

  Future<void> _removePlantFromGarden(MyPlant myPlant) async {
    if (_currentUserId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Tanaman', style: GoogleFonts.poppins()),
        content: Text(
          'Anda yakin ingin menghapus ${myPlant.plantInfo.namaTanaman} dari Taman Saya?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() {
      _myPlants.removeWhere((p) => p.plantInfo.id == myPlant.plantInfo.id);
    });
    await _gardenService.saveMyPlants(_myPlants, _currentUserId!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${myPlant.plantInfo.namaTanaman} dihapus dari Taman Saya.',
          ),
        ),
      );
    }
  }

  void _exitSearchMode() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2C6E49);
    const Color backgroundColor = Color(0xFFFAF3E0);

    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: PlantifyBottomNavBar(
        currentIndex: 2,
        primaryColor: primaryColor,
      ),
      appBar: AppBar(
        title: Text(
          'Taman Saya',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              color: primaryColor,
              child: Column(
                children: [
                  _buildHeader(primaryColor),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isSearching
            ? _buildActiveSearchBar()
            : _buildInactiveSearchBar(),
      ),
    );
  }

  Widget _buildInactiveSearchBar() {
    return Column(
      key: const ValueKey('inactive_search'),
      children: [
        Row(
          children: [
            const Icon(Icons.location_on_outlined),
            const SizedBox(width: 8),
            Text(
              'Lokasi Saya: ',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            DropdownButton<String>(
              value: _userLocation,
              underline: const SizedBox(),
              items: _continents
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, style: GoogleFonts.poppins()),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _userLocation = val);
                  _gardenService.saveUserLocation(val);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _enterSearchMode,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 12),
                Text(
                  'Cari untuk menambah tanaman...',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSearchBar() {
    return Row(
      key: const ValueKey('active_search'),
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            autofocus: true,
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              hintText: 'Ketik nama tanaman...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade200,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(onPressed: _exitSearchMode, child: const Text('Batal')),
      ],
    );
  }

  Widget _buildContent() {
    if (_currentUserId == null) {
      return Center(
        child: Text(
          'Silakan login untuk menggunakan fitur ini.',
          style: GoogleFonts.poppins(color: Colors.grey.shade700),
        ),
      );
    }
    if (_isSearching) return _buildSearchResults();
    if (_myPlants.isEmpty) return _buildEmptyState();
    return _buildPlantGrid();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.yard_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Taman Anda Masih Kosong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gunakan kotak pencarian di atas untuk mulai menambahkan tanaman ke koleksi Anda.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchController.text.isEmpty) {
      return Center(
        child: Text(
          'Mulai ketik untuk mencari dari katalog...',
          style: GoogleFonts.poppins(color: Colors.grey[600]),
        ),
      );
    }
    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          'Tanaman tidak ditemukan.',
          style: GoogleFonts.poppins(color: Colors.grey[600]),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final plant = _searchResults[index];
        bool isAlreadyAdded = _myPlants.any((p) => p.plantInfo.id == plant.id);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: PlantImage(
                assetPath: plant.gambar,
                imageUrl: plant.gambarUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              plant.namaTanaman,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(plant.asal, style: GoogleFonts.poppins()),
            trailing: isAlreadyAdded
                ? const Icon(Icons.check_circle, color: Colors.green, size: 30)
                : IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: Color(0xFF2C6E49),
                      size: 30,
                    ),
                    tooltip: 'Tambah ke Taman Saya',
                    onPressed: () => _addPlantToGarden(plant),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildPlantGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200.0,
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        childAspectRatio: 0.8,
      ),
      itemCount: _myPlants.length,
      itemBuilder: (context, index) {
        final myPlant = _myPlants[index];
        final difficulty = _calculateDifficulty(myPlant.plantInfo.asal);
        return Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: PlantImage(
                        assetPath: myPlant.plantInfo.gambar,
                        imageUrl: myPlant.plantInfo.gambarUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: Colors.black.withOpacity(0.5),
                      child: Text(
                        myPlant.plantInfo.namaTanaman,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                // Mengurangi padding horizontal agar ada lebih banyak ruang
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    // Bungkus Tooltip dengan Expanded agar ia fleksibel
                    Expanded(
                      child: Tooltip(
                        message: difficultyExplanation[difficulty],
                        preferBelow: false,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: difficultyColor[difficulty]!.withOpacity(
                              0.2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            difficultyDescription[difficulty]!,
                            style: GoogleFonts.poppins(
                              color: difficultyColor[difficulty]!,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            // Jika teksnya panjang, ia akan mengecil atau ellipsis
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    // Tidak perlu Spacer lagi karena sudah pakai Expanded
                    // const Spacer(),
                    IconButton(
                      icon: Icon(
                        myPlant.alarmTime != null
                            ? Icons.alarm_on
                            : Icons.alarm_add,
                        color: myPlant.alarmTime != null
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                      ),
                      tooltip: 'Atur Jadwal Siram',
                      onPressed: () => _showSetAlarmSheet(context, myPlant),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Hapus dari Taman Saya',
                      onPressed: () => _removePlantFromGarden(myPlant),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> _getDayNames(Set<int> days) {
    final dayNames = {
      1: 'Senin',
      2: 'Selasa',
      3: 'Rabu',
      4: 'Kamis',
      5: 'Jumat',
      6: 'Sabtu',
      7: 'Minggu',
    };
    return days.map((d) => dayNames[d] ?? 'Hari $d').toList()..sort();
  }

  void _showSetAlarmSheet(BuildContext context, MyPlant myPlant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SetAlarmSheet(
          myPlant: myPlant,
          onAlarmSet: (newTime, newDays) {
            _onAlarmSet(myPlant, newTime, newDays);
          },
        );
      },
    );
  }
}
