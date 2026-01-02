// Lokasi: lib/features/info/screens/information_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:plantify_app/features/info/services/bookmark_service.dart';
import 'package:plantify_app/features/info/services/history_service.dart';
import 'package:plantify_app/service/currency/currency_service.dart';
import 'package:plantify_app/features/info/models/plant_model.dart';
import 'package:plantify_app/features/info/services/plant_service.dart';
import 'package:plantify_app/features/info/screens/plant_detail_screen.dart';
import 'package:plantify_app/service/auth/auth_service.dart';
import 'package:plantify_app/features/home/widgets/bottom_nav_bar.dart';
import 'package:plantify_app/features/info/widgets/plant_image.dart';

class InformationScreen extends StatefulWidget {
  final String? initialCategoryFilter;
  const InformationScreen({super.key, this.initialCategoryFilter});
  @override
  State<InformationScreen> createState() => _InformationScreenState();
}

class _InformationScreenState extends State<InformationScreen> {
  // --- STATE & CONTROLLERS ---
  final AuthService _authService = AuthService();
  final PlantService _plantService = PlantService();
  final CurrencyService _currencyService = CurrencyService();
  final BookmarkService _bookmarkService = BookmarkService();
  final HistoryService _historyService = HistoryService();
  final _searchController = TextEditingController();

  List<Plant> _allItems = [];
  List<Plant> _displayedItems = [];
  bool _isLoading = true;

  // State untuk Currency
  String _userCurrency = 'IDR';
  Map<String, dynamic>? _exchangeRates;

  // State untuk User ID & Bookmark
  int? _currentUserId;
  Set<int> _bookmarkedIds = {};

  // State untuk filter
  RangeValues _currentRangeValues = const RangeValues(0, 1000000);
  double _minPrice = 0;
  double _maxPrice = 1000000;
  final Set<String> _selectedCategories = {};
  final Set<String> _selectedContinents = {};
  List<String> _plantCategories = [];
  final List<String> _continents = ['Asia', 'Australia', 'Afrika', 'Amerika'];
  final Map<String, String> _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'JPY': '¥',
    'IDR': 'Rp ',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryFilter != null) {
      _selectedCategories.add(widget.initialCategoryFilter!);
    }
    _initializeScreen();
    _searchController.addListener(_applyFilters);
  }

  Future<void> _initializeScreen() async {
    final userId = await _authService.getCurrentUserId();
    setState(() {
      _currentUserId = userId;
    });

    final List<Future> tasks = [
      _fetchDataAndSetupFilters(),
      _loadCurrencyData(),
    ];

    if (userId != null) {
      tasks.add(_loadBookmarks(userId));
    }

    await Future.wait(tasks);

    if (mounted) {
      _applyFilters();
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDataAndSetupFilters() async {
    final plants = await _plantService.loadAllPlants();
    if (!mounted) return;

    if (plants.isNotEmpty) {
      final allCategories = plants.map((p) => p.kategori).toSet().toList()
        ..sort();
      _plantCategories = allCategories;

      final prices = plants.map((p) => p.hargaPerkiraan).toList();
      _minPrice = prices.reduce((a, b) => a < b ? a : b).toDouble();
      _maxPrice = prices.reduce((a, b) => a > b ? a : b).toDouble();
      _currentRangeValues = RangeValues(_minPrice, _maxPrice);
    }

    plants.shuffle();
    _allItems = plants;
    _displayedItems = plants;
  }

  Future<void> _loadCurrencyData() async {
    final currency = await _currencyService.getUserCurrency();
    final rates = await _currencyService.getRates('IDR');
    if (mounted) {
      setState(() {
        _userCurrency = currency;
        _exchangeRates = rates;
      });
    }
  }

  Future<void> _loadBookmarks(int userId) async {
    final bookmarks = await _bookmarkService.getBookmarkedPlants(userId);
    if (mounted) {
      setState(() {
        _bookmarkedIds = bookmarks.map((p) => p.id).toSet();
      });
    }
  }

  void _applyFilters() {
    List<Plant> filteredList = List.from(_allItems);
    final String query = _searchController.text.toLowerCase();

    if (query.isNotEmpty) {
      filteredList = filteredList
          .where(
            (plant) =>
                plant.namaTanaman.toLowerCase().contains(query) ||
                plant.namaLatin.toLowerCase().contains(query),
          )
          .toList();
    }
    if (_selectedCategories.isNotEmpty) {
      filteredList = filteredList
          .where((p) => _selectedCategories.contains(p.kategori))
          .toList();
    }
    if (_selectedContinents.isNotEmpty) {
      filteredList = filteredList
          .where((p) => _selectedContinents.contains(p.asal))
          .toList();
    }
    filteredList = filteredList
        .where(
          (p) =>
              p.hargaPerkiraan >= _currentRangeValues.start &&
              p.hargaPerkiraan <= _currentRangeValues.end,
        )
        .toList();

    setState(() {
      _displayedItems = filteredList;
    });
  }

  String _formatPrice(double idrPrice) {
    if (_exchangeRates == null) return "Rp ...";
    final rate = _exchangeRates![_userCurrency] ?? 1.0;
    final convertedPrice = idrPrice * rate;
    return NumberFormat.compactCurrency(
      symbol: _currencySymbols[_userCurrency],
      locale: _userCurrency == 'IDR' ? 'id_ID' : 'en_US',
    ).format(convertedPrice);
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        currentIndex: 3,
        primaryColor: primaryColor,
      ),
      body: CustomScrollView(
        slivers: [
          // --- HEADER HIJAU BARU ---
          SliverAppBar(
            backgroundColor: primaryColor, // Latar belakang Hijau
            foregroundColor: Colors.white, // Ikon & Teks Putih
            floating: true,
            pinned: true,
            elevation: 4, // Sedikit bayangan
            // Bentuk rounded di bawah agar terlihat seperti kontainer
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),

            // Tidak perlu expandedHeight berlebih, cukup ruang untuk Title + Search
            expandedHeight: 0,
            toolbarHeight: 60, // Tinggi baris judul
            // Judul
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                Text(
                  "Katalog Tanaman",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Search Bar & Filter Button diletakkan di bagian Bottom
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(
                90.0,
              ), // Beri ruang vertikal yang cukup
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: 20.0,
                ), // Jarak dari bawah container hijau
                child: _buildSearchAndFilterHeader(primaryColor, textColor),
              ),
            ),
          ),

          _isLoading
              ? SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                )
              : _displayedItems.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Text(
                      "Tanaman tidak ditemukan.",
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                )
              : SliverPadding(
                  // Tambahkan padding atas agar konten tidak mepet dengan header
                  padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 16.0),
                  sliver: _buildPlantGrid(),
                ),
        ],
      ),
    );
  }

  // Widget Search & Filter yang disesuaikan untuk di dalam Header Hijau
  Widget _buildSearchAndFilterHeader(Color primaryColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ), // Padding horizontal kiri-kanan
      // Latar belakang transparan karena sudah berada di atas warna hijau primaryColor
      child: Row(
        children: [
          Expanded(
            child: Container(
              // Dekorasi bayangan agar search bar menonjol
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(
                  color: textColor,
                ), // Teks input tetap gelap
                decoration: InputDecoration(
                  hintText: 'Cari nama tanaman...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey, // Hint text abu-abu
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white, // Search bar berwarna Putih
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Tombol Filter (Putih dengan Icon Hijau) agar kontras di latar Hijau
          Material(
            color: Colors.white,
            elevation: 2,
            borderRadius: BorderRadius.circular(50),
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: () => _showFilterBottomSheet(context),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.tune, color: Color(0xFF2C6E49), size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantGrid() {
    return SliverMasonryGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childCount: _displayedItems.length,
      itemBuilder: (context, index) {
        final plant = _displayedItems[index];
        return GestureDetector(
          onTap: () async {
            if (_currentUserId != null) {
              await _historyService.addToHistory(plant, _currentUserId!);
            }
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlantDetailScreen(plant: plant),
              ),
            );
            if (_currentUserId != null) {
              _loadBookmarks(_currentUserId!);
            }
          },
          child: _buildPlantCard(plant),
        );
      },
    );
  }

  Widget _buildPlantCard(Plant plant) {
    bool isBookmarked = _bookmarkedIds.contains(plant.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 3,
      shadowColor: const Color(0xFF2C6E49).withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Hero(
                tag: 'plant-image-${plant.id}',
                child: PlantImage(
                  assetPath: plant.gambar,
                  imageUrl: plant.gambarUrl,
                  fit: BoxFit.cover,
                ),
              ),
              if (_currentUserId != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.black.withOpacity(0.4),
                    child: IconButton(
                      iconSize: 20,
                      tooltip: isBookmarked
                          ? 'Hapus dari Favorit'
                          : 'Tambahkan ke Favorit',
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        await _bookmarkService.toggleBookmark(
                          plant,
                          _currentUserId!,
                        );
                        _loadBookmarks(_currentUserId!);
                      },
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.kategori.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  plant.namaTanaman,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3E3636),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    const Color primaryColor = Color(0xFF2C6E49);
    const Color textColor = Color(0xFF3E3636);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAF3E0),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(25.0),
                        ),
                      ),
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(24.0),
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Filter Tanaman',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Jenis Tanaman',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Wrap(
                            spacing: 8.0,
                            children: _plantCategories.map((category) {
                              bool isSelected = _selectedCategories.contains(
                                category,
                              );
                              return FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (selected) => setModalState(() {
                                  if (selected) {
                                    _selectedCategories.add(category);
                                  } else {
                                    _selectedCategories.remove(category);
                                  }
                                }),
                                backgroundColor: Colors.white,
                                selectedColor: primaryColor,
                                checkmarkColor: Colors.white,
                                labelStyle: GoogleFonts.poppins(
                                  color: isSelected ? Colors.white : textColor,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Benua',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Wrap(
                            spacing: 8.0,
                            children: _continents.map((continent) {
                              bool isSelected = _selectedContinents.contains(
                                continent,
                              );
                              return FilterChip(
                                label: Text(continent),
                                selected: isSelected,
                                onSelected: (selected) => setModalState(() {
                                  if (selected) {
                                    _selectedContinents.add(continent);
                                  } else {
                                    _selectedContinents.remove(continent);
                                  }
                                }),
                                backgroundColor: Colors.white,
                                selectedColor: primaryColor,
                                checkmarkColor: Colors.white,
                                labelStyle: GoogleFonts.poppins(
                                  color: isSelected ? Colors.white : textColor,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Rentang Harga ($_userCurrency)',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          if (_maxPrice > _minPrice)
                            Column(
                              children: [
                                RangeSlider(
                                  values: RangeValues(
                                    _currentRangeValues.start *
                                        (_exchangeRates?[_userCurrency] ?? 1.0),
                                    _currentRangeValues.end *
                                        (_exchangeRates?[_userCurrency] ?? 1.0),
                                  ),
                                  min:
                                      _minPrice *
                                      (_exchangeRates?[_userCurrency] ?? 1.0),
                                  max:
                                      _maxPrice *
                                      (_exchangeRates?[_userCurrency] ?? 1.0),
                                  divisions: 20,
                                  activeColor: primaryColor,
                                  labels: RangeLabels(
                                    _formatPrice(_currentRangeValues.start),
                                    _formatPrice(_currentRangeValues.end),
                                  ),
                                  onChanged: (values) {
                                    final rate =
                                        _exchangeRates?[_userCurrency] ?? 1.0;
                                    if (rate > 0) {
                                      setModalState(
                                        () => _currentRangeValues = RangeValues(
                                          values.start / rate,
                                          values.end / rate,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatPrice(_currentRangeValues.start),
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        _formatPrice(_currentRangeValues.end),
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 30),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => setModalState(() {
                                  _selectedCategories.clear();
                                  _selectedContinents.clear();
                                  _currentRangeValues = RangeValues(
                                    _minPrice,
                                    _maxPrice,
                                  );
                                }),
                                child: Text(
                                  'Reset',
                                  style: GoogleFonts.poppins(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    _applyFilters();
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: Text(
                                    'Terapkan Filter',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
            );
          },
        );
      },
    );
  }
}
