// Lokasi: lib/features/cart/cart_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plantify_app/features/info/widgets/plant_image.dart';
import 'package:plantify_app/features/home/widgets/bottom_nav_bar.dart';

// --- IMPORT UNTUK FITUR LBS (dipindahkan dari InformationScreen) ---
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:plantify_app/service/auth/auth_service.dart';

import '../info/services/bookmark_service.dart';
import '../info/models/plant_model.dart';
import '../info/screens/plant_detail_screen.dart';

// --- PERUBAHAN 1: Import InformationScreen ---
// Kita membutuhkannya untuk redirect tombol 'Cari Tanaman'
import '../info/screens/information_screen.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});
  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  final AuthService _authService = AuthService();
  final BookmarkService _bookmarkService = BookmarkService();
  final _searchController = TextEditingController();

  int? _currentUserId;
  List<Plant> _allBookmarks = [];
  List<Plant> _displayedBookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _searchController.addListener(_filterBookmarks);
  }

  Future<void> _initializeScreen() async {
    final userId = await _authService.getCurrentUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });

      if (userId != null) {
        _loadBookmarks(userId);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadBookmarks(int userId) async {
    setState(() {
      _isLoading = true;
    });
    final bookmarks = await _bookmarkService.getBookmarkedPlants(userId);
    if (mounted) {
      setState(() {
        _allBookmarks = bookmarks;
        _displayedBookmarks = bookmarks;
        _isLoading = false;
      });
    }
  }

  void _filterBookmarks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _displayedBookmarks = _allBookmarks.where((plant) {
        return plant.namaTanaman.toLowerCase().contains(query) ||
            plant.namaLatin.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _confirmRemoveBookmark(Plant plant) async {
    if (_currentUserId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Favorit', style: GoogleFonts.poppins()),
        content: Text(
          'Anda yakin ingin menghapus "${plant.namaTanaman}" dari daftar favorit?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _bookmarkService.toggleBookmark(plant, _currentUserId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${plant.namaTanaman} dihapus dari favorit'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _loadBookmarks(_currentUserId!);
    }
  }

  Future<void> _openNearbyPlantStores() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mencari lokasi Anda...'),
        backgroundColor: Colors.blueAccent,
      ),
    );
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Layanan lokasi (GPS) tidak aktif.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied)
          throw 'Izin lokasi ditolak.';
      }
      if (permission == LocationPermission.deniedForever)
        throw 'Izin lokasi ditolak permanen. Buka pengaturan aplikasi.';

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final Uri googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=toko+tanaman+terdekat&ll=${position.latitude},${position.longitude}',
      );

      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Tidak dapat membuka Google Maps. Pastikan aplikasi terinstall.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  // WIDGET UNTUK KARTU LBS (dipindah dari InformationScreen)
  Widget _buildLbsCard(Color primaryColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        elevation: 3,
        shadowColor: primaryColor.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _openNearbyPlantStores,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded, color: primaryColor, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Toko Tanaman Terdekat',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Temukan di sekitar lokasi Anda via Google Maps.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
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
        currentIndex: 1,
        primaryColor: primaryColor,
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            pinned: true,
            floating: true,
            title: Text(
              'Tanaman Favorit',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(180.0),
              child: Column(
                children: [
                  // KARTU LBS DIPINDAH KE SINI (dari InformationScreen)
                  _buildLbsCard(primaryColor, textColor),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.poppins(),
                      decoration: InputDecoration(
                        hintText: 'Cari di favorit...',
                        hintStyle: GoogleFonts.poppins(
                          color: primaryColor.withOpacity(0.7),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: primaryColor,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBodySlivers(primaryColor),
        ],
      ),
    );
  }

  Widget _buildBodySlivers(Color primaryColor) {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_currentUserId == null) {
      return SliverFillRemaining(child: _buildLoginPrompt(primaryColor));
    }
    if (_allBookmarks.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyBookmark(primaryColor));
    }
    if (_displayedBookmarks.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text('Tanaman tidak ditemukan.', style: GoogleFonts.poppins()),
        ),
      );
    }
    return _buildBookmarkList(
      _displayedBookmarks,
      const Color(0xFF3E3636),
      primaryColor,
    );
  }

  Widget _buildLoginPrompt(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login_rounded, size: 100, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'Login Dibutuhkan',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Silakan login untuk melihat tanaman favorit Anda.',
            style: GoogleFonts.poppins(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: Text(
              'Kembali',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBookmark(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 100, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'Belum ada tanaman favorit',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tandai tanaman yang kamu sukai!',
            style: GoogleFonts.poppins(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              // --- PERUBAHAN 2: Redirect ke InformationScreen ---
              // Ini akan membuka halaman katalog sehingga pengguna bisa langsung mencari tanaman.
              // '.then()' akan me-refresh bookmark setelah pengguna kembali.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InformationScreen(),
                ),
              ).then((_) {
                if (_currentUserId != null) {
                  _loadBookmarks(_currentUserId!);
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: Text(
              'Cari Tanaman',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverList _buildBookmarkList(
    List<Plant> items,
    Color textColor,
    Color primaryColor,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = items[index];
        return _buildBookmarkItemCard(item, textColor, primaryColor);
      }, childCount: items.length),
    );
  }

  Widget _buildBookmarkItemCard(
    Plant item,
    Color textColor,
    Color primaryColor,
  ) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      shadowColor: primaryColor.withOpacity(0.1),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlantDetailScreen(plant: item),
            ),
          );
          if (_currentUserId != null) {
            _loadBookmarks(_currentUserId!);
          }
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'plant-image-${item.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: PlantImage(
                    assetPath: item.gambar,
                    imageUrl: item.gambarUrl,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.namaTanaman,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.asal,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.deskripsi,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: textColor.withOpacity(0.7),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_remove, color: Colors.red),
                tooltip: 'Hapus dari Favorit',
                onPressed: () {
                  _confirmRemoveBookmark(item);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
