// Lokasi: lib/features/home/screens/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plantify_app/features/info/widgets/plant_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:plantify_app/features/info/services/history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../service/timezone/timezone_service.dart';
import '../../info/screens/information_screen.dart';
import 'package:plantify_app/features/info/models/plant_model.dart';
import 'package:plantify_app/features/info/screens/plant_detail_screen.dart';
import 'package:plantify_app/features/mygarden/screens/my_garden_screen.dart';
import 'package:plantify_app/features/info/services/my_garden_service.dart';
import 'package:plantify_app/features/info/services/plant_service.dart';
import 'package:plantify_app/features/home/widgets/bottom_nav_bar.dart';
import 'package:plantify_app/features/mygarden/models/my_plant_model.dart';
import 'package:plantify_app/features/home/widgets/reminder_detail_dialog.dart';
import 'package:timezone/timezone.dart' as tz;

// --- PERUBAHAN 1: Tambahkan import untuk AuthService ---
import 'package:plantify_app/service/auth/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final TimezoneService _timezoneService = TimezoneService();
  final HistoryService _historyService = HistoryService();
  final MyGardenService _gardenService = MyGardenService();
  final PlantService _plantService = PlantService();

  int? _currentUserId;
  bool _isLoading = true;

  DateTime? _currentTime;
  Timer? _timer;
  String _timezoneName = "Memuat...";
  String _userGreeting = "Selamat Datang";
  String _userName = "Pengguna";
  String _welcomeMessage = "Semoga harimu menyenangkan!";
  Map<String, List<Plant>> _historyData = {};

  // Inisialisasi Future dengan data kosong untuk menghindari error
  Future<List<MyPlant>> _remindersFuture = Future.value([]);
  List<Plant> _allPlants = [];

  // State lainnya
  int _currentCarouselIndex = 0;
  // bottom nav handled by PlantifyBottomNavBar
  String _selectedContinent = 'Asia';
  final List<String> _continents = [
    'Asia',
    'Australia',
    'Afrika',
    'Amerika',
    'Eropa',
  ];

  final List<Map<String, String>> bannerItems = [
    {
      'image': 'assets/banner1.jpg',
      'title': 'Tips Merawat Old Man Saltbush',
      'subtitle': 'Cara agar sukulen Anda tumbuh subur dan sehat.',
    },
    {
      'image': 'assets/banner2.jpg',
      'title': 'Produk Unggulan: Cendana',
      'subtitle': 'Bunga ikonik yang menjadi favorit banyak orang.',
    },
  ];
  final List<Map<String, dynamic>> categories = [
    {'icon': Icons.local_florist, 'name': 'Bunga Hias'},
    {'icon': Icons.eco, 'name': 'Tanaman Hias Daun'},
    {'icon': Icons.park, 'name': 'Tanaman Buah'},
    {'icon': Icons.spa, 'name': 'Tanaman Herbal'},
    {'icon': Icons.star_outline, 'name': 'Tanaman Langka'},
  ];

  // --- PERUBAHAN 4: Rombak alur inisialisasi ---
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScreen(); // Panggil fungsi inisialisasi utama
  }

  Future<void> _initializeScreen() async {
    setState(() => _isLoading = true);

    // Dapatkan user ID terlebih dahulu
    final userId = await _authService.getCurrentUserId();
    setState(() => _currentUserId = userId);

    final List<Future> tasks = [
      _loadUserData(),
      _setupInitialTime(),
      _loadAllPlants(),
    ];

    // Hanya muat data pengguna jika sudah login
    if (userId != null) {
      tasks.add(_loadHistoryData(userId));
      tasks.add(_loadReminders(userId));
    }

    // Jalankan semua tugas dan tunggu selesai
    await Future.wait(tasks);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // --- PERUBAHAN 5: Modifikasi fungsi data agar menerima userId ---
  Future<void> _loadReminders(int userId) async {
    // Fungsi ini tidak perlu setState karena sudah ditangani oleh FutureBuilder
    _remindersFuture = _gardenService.getPlantsWithAlarms(userId);
  }

  Future<void> _loadAllPlants() async {
    final plants = await _plantService.loadAllPlants();
    if (mounted) {
      setState(() {
        _allPlants = plants;
      });
    }
  }

  Future<void> _loadHistoryData(int userId) async {
    final history = await _historyService.getHistory(userId);
    if (mounted) {
      setState(() {
        _historyData = history;
      });
    }
  }

  // Fungsi _loadUserData tidak berubah karena mengambil data dari sesi SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('namaLengkap') ?? 'Pengguna';
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Panggil kembali alur inisialisasi penuh untuk me-refresh semua data
      _initializeScreen();
    }
  }

  Future<void> _setupInitialTime() async {
    _timer?.cancel();
    String savedTimezoneId = await _timezoneService.getUserTimezone();
    DateTime? initialTime = await _timezoneService.getConvertedTime(
      savedTimezoneId,
    );
    if (mounted) {
      if (initialTime != null) {
        setState(() {
          _currentTime = initialTime;
          _timezoneName = savedTimezoneId.split('/').last.replaceAll('_', ' ');
        });
      } else {
        setState(() {
          _currentTime = DateTime.now();
          _timezoneName = "Waktu Lokal (Offline)";
        });
      }
      if (_currentTime != null) {
        _updateGreeting(_currentTime!);
        _startTimer();
      }
    }
  }

  void _startTimer() {
    /* ... kode asli ... */
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = _currentTime?.add(const Duration(seconds: 1));
          if (_currentTime != null) {
            _updateGreeting(_currentTime!);
          }
        });
      }
    });
  }

  void _updateGreeting(DateTime time) {
    int hour = time.hour;
    if (hour < 4) {
      _userGreeting = "Selamat Malam";
      _welcomeMessage = "Waktunya istirahat dan memulihkan energi.";
    } else if (hour < 11) {
      _userGreeting = "Selamat Pagi";
      _welcomeMessage = "Semoga harimu secerah bunga matahari!";
    } else if (hour < 15) {
      _userGreeting = "Selamat Siang";
      _welcomeMessage = "Jangan lupa siram tanaman kesayanganmu.";
    } else if (hour < 19) {
      _userGreeting = "Selamat Sore";
      _welcomeMessage = "Nikmati tenangnya sore hari di kebunmu.";
    } else {
      _userGreeting = "Selamat Malam";
      _welcomeMessage = "Waktunya istirahat dan memulihkan energi.";
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2C6E49);
    const Color backgroundColor = Color(0xFFFAF3E0);
    const Color textColor = Color(0xFF3E3636);

    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: PlantifyBottomNavBar(
        currentIndex: 0,
        primaryColor: primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(primaryColor),
            _isLoading
                ? const Center(
                    heightFactor: 10,
                    child: CircularProgressIndicator(),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            children: [
                              _buildCarouselSlider(),
                              const SizedBox(height: 10),
                              _buildCarouselIndicator(),
                              const SizedBox(height: 30),
                              _buildCategorySection(textColor, primaryColor),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                        _buildHistorySection(textColor, primaryColor),
                        const SizedBox(height: 30),
                        _buildWateringReminderSection(textColor, primaryColor),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // Widget _buildHeaderSection dan _buildHeader tidak berubah
  Widget _buildHeaderSection(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 20.0),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 25),
            _buildTimeDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.eco, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Plantify',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$_userGreeting, $_userName!',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _welcomeMessage,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
      ],
    );
  }

  // Widget _buildTimeDisplay tidak berubah
  Widget _buildTimeDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _currentTime != null
                ? DateFormat('HH:mm').format(_currentTime!)
                : "--:--",
            style: GoogleFonts.poppins(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentTime != null
                    ? DateFormat('EEEE,', 'id_ID').format(_currentTime!)
                    : "Memuat...",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              Text(
                _currentTime != null
                    ? DateFormat('d MMM yyyy', 'id_ID').format(_currentTime!)
                    : "",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  _timezoneName,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- PERUBAHAN 6: Perbarui logika navigasi untuk refresh semua data pengguna ---
  // Bottom navigation is now provided by the reusable PlantifyBottomNavBar

  // Widget _buildCarouselSlider dan _buildCarouselIndicator tidak berubah
  Widget _buildCarouselSlider() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 180.0,
        autoPlay: true,
        enlargeCenterPage: true,
        aspectRatio: 16 / 9,
        viewportFraction: 1,
        onPageChanged: (index, reason) {
          setState(() {
            _currentCarouselIndex = index;
          });
        },
      ),
      items: bannerItems
          .map(
            (item) => Builder(
              builder: (BuildContext context) => Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: AssetImage(item['image']!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title']!,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['subtitle']!,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () =>
                                  _handleBannerTap(_currentCarouselIndex),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.95),
                                foregroundColor: const Color(0xFF2C6E49),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                'Details',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  void _handleBannerTap(int index) async {
    if (_allPlants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data tanaman belum dimuat. Mohon tunggu...')),
      );
      return;
    }

    String nameKey = index == 0 ? 'old man saltbush' : 'cendana';
    Plant? plant;
    try {
      plant = _allPlants.firstWhere(
        (p) => p.namaTanaman.toLowerCase().contains(nameKey),
      );
    } catch (e) {
      plant = null;
    }
    if (plant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tanaman yang dimaksud tidak ditemukan.')),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlantDetailScreen(plant: plant!)),
    );
    // setelah return dari detail, refresh history jika user logged in
    if (_currentUserId != null) {
      _loadHistoryData(_currentUserId!);
    }
  }

  Widget _buildCarouselIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: bannerItems.asMap().entries.map((entry) {
        return GestureDetector(
          onTap: () {},
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _currentCarouselIndex == entry.key ? 12.0 : 8.0,
            height: 8.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: (const Color(
                0xFF2C6E49,
              )).withOpacity(_currentCarouselIndex == entry.key ? 0.9 : 0.4),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- PERUBAHAN 7: Perbarui _buildCategorySection untuk menyertakan userId ---
  Widget _buildCategorySection(Color textColor, Color primaryColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kategori',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InformationScreen(),
                ),
              ),
              child: Text(
                'Lihat Semua',
                style: GoogleFonts.poppins(color: primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InformationScreen(
                          initialCategoryFilter: category['name'],
                        ),
                      ),
                    ).then((_) {
                      if (_currentUserId != null) {
                        _loadHistoryData(_currentUserId!);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 15),
                    child: Column(
                      children: [
                        Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            category['icon'],
                            color: primaryColor,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- PERUBAHAN 8: Perbarui _buildHistorySection untuk menyertakan userId ---
  Widget _buildHistorySection(Color textColor, Color primaryColor) {
    // Tampilkan prompt login jika tidak ada user
    if (_currentUserId == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Text(
          "Login untuk melihat riwayat.",
          style: GoogleFonts.poppins(),
        ),
      );
    }

    final continentHistory = _historyData[_selectedContinent] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Baru Dilihat',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: primaryColor),
                onPressed: () => _loadHistoryData(_currentUserId!),
                tooltip: 'Muat Ulang Riwayat',
              ),
              const Spacer(),
              _buildContinentDropdown(primaryColor),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: continentHistory.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      'Belum ada riwayat untuk benua $_selectedContinent.',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: continentHistory.length,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemBuilder: (context, index) {
                    final plant = continentHistory[index];
                    return _buildHistoryCard(plant, textColor);
                  },
                ),
        ),
      ],
    );
  }

  // Widget _buildContinentDropdown tidak berubah
  Widget _buildContinentDropdown(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButton<String>(
        value: _selectedContinent,
        underline: const SizedBox(),
        icon: Icon(Icons.keyboard_arrow_down, color: primaryColor),
        style: GoogleFonts.poppins(
          color: primaryColor,
          fontWeight: FontWeight.w600,
        ),
        onChanged: (String? newValue) {
          setState(() {
            _selectedContinent = newValue!;
          });
        },
        items: _continents
            .map<DropdownMenuItem<String>>(
              (String value) =>
                  DropdownMenuItem<String>(value: value, child: Text(value)),
            )
            .toList(),
      ),
    );
  }

  // --- PERUBAHAN 9: Perbarui _buildHistoryCard untuk menyertakan userId ---
  Widget _buildHistoryCard(Plant plant, Color textColor) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlantDetailScreen(plant: plant),
          ),
        );
        if (_currentUserId != null) {
          _loadHistoryData(_currentUserId!);
        }
      },
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'plant-image-${plant.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
                child: PlantImage(
                  assetPath: plant.gambar,
                  imageUrl: plant.gambarUrl,
                  width: 110,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      plant.namaTanaman,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plant.kategori,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PERUBAHAN 10: Perbarui _buildWateringReminderSection untuk menyertakan userId ---
  Widget _buildWateringReminderSection(Color textColor, Color primaryColor) {
    // Tampilkan prompt login jika tidak ada user
    if (_currentUserId == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Text(
          "Login untuk melihat pengingat siram.",
          style: GoogleFonts.poppins(),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pengingat Siram',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: primaryColor),
                onPressed: () => setState(() {
                  _loadReminders(_currentUserId!);
                }),
                tooltip: 'Muat Ulang Pengingat',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: FutureBuilder<List<MyPlant>>(
            future: _remindersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyReminderState(primaryColor);
              }
              final reminders = snapshot.data!;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: reminders.length,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemBuilder: (context, index) {
                  final reminder = reminders[index];
                  return _buildReminderCard(reminder, textColor, primaryColor);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Sisa kode tidak berubah
  Widget _buildEmptyReminderState(Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyGardenScreen()),
          ),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.alarm_add, size: 40, color: primaryColor),
                const SizedBox(height: 12),
                Text(
                  'Belum Ada Pengingat',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Atur alarm di Taman Saya untuk menampilkannya di sini.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: primaryColor.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  tz.TZDateTime? _calculateNextAlarm(MyPlant plant) {
    if (plant.alarmTime == null ||
        plant.alarmDays.isEmpty ||
        plant.alarmTimezoneId == null) {
      return null;
    }
    final tz.Location originalLocation = tz.getLocation(plant.alarmTimezoneId!);
    final TimeOfDay alarmTime = plant.alarmTime!;
    final List<int> sortedDays = plant.alarmDays.toList()..sort();
    final tz.TZDateTime nowInOriginalTz = tz.TZDateTime.now(originalLocation);
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
        if (nextAlarm.isAfter(nowInOriginalTz)) return nextAlarm;
      }
    }
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
    return null;
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return "Waktunya siram!";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    if (days > 0) return "${days}h ${twoDigits(hours)}j";
    if (hours > 0) return "${hours}j ${twoDigits(minutes)}m";
    return "${twoDigits(minutes)}m";
  }

  Widget _buildReminderCard(
    MyPlant reminder,
    Color textColor,
    Color primaryColor,
  ) {
    if (_currentTime == null) return const SizedBox.shrink();
    final nextAlarmTime = _calculateNextAlarm(reminder);
    if (nextAlarmTime == null) return const SizedBox.shrink();
    final timeLeft = nextAlarmTime.difference(_currentTime!);
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return ReminderDetailDialog(
              myPlant: reminder,
              initialCurrentTime: _currentTime!,
              timezoneName: _timezoneName,
            );
          },
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: PlantImage(
                  assetPath: reminder.plantInfo.gambar,
                  imageUrl: reminder.plantInfo.gambarUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        reminder.plantInfo.namaTanaman,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.alarm, size: 16, color: primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('HH:mm').format(nextAlarmTime),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            "Tersisa:",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            _formatDuration(timeLeft),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
