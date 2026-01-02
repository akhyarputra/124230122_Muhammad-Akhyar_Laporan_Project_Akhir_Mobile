// Lokasi: lib/features/info/screens/plant_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/plant_model.dart';
import '../../../service/currency/currency_service.dart';
import 'package:plantify_app/service/auth/auth_service.dart';
import 'package:plantify_app/features/info/services/bookmark_service.dart';
import 'package:plantify_app/features/info/services/history_service.dart';
import 'package:plantify_app/features/info/widgets/plant_image.dart';

class PlantDetailData {
  final int? userId;
  final bool isBookmarked;
  final String formattedPrice;
  PlantDetailData({
    this.userId,
    required this.isBookmarked,
    required this.formattedPrice,
  });
}

class PlantDetailScreen extends StatefulWidget {
  final Plant plant;
  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  final CurrencyService _currencyService = CurrencyService();
  final AuthService _authService = AuthService();
  final BookmarkService _bookmarkService = BookmarkService();
  final HistoryService _historyService = HistoryService();
  late Future<PlantDetailData> _detailsFuture;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadInitialData();
  }

  Future<PlantDetailData> _loadInitialData() async {
    final userId = await _authService.getCurrentUserId();
    bool isBookmarkedForUser = false;
    if (userId != null) {
      await Future.wait([
        _historyService.addToHistory(widget.plant, userId),
        _bookmarkService.isBookmarked(widget.plant.id, userId).then((value) {
          isBookmarkedForUser = value;
        }),
      ]);
    }
    final String priceString = await _convertAndFormatPrice();
    if (mounted) {
      setState(() {
        _isBookmarked = isBookmarkedForUser;
      });
    }
    return PlantDetailData(
      userId: userId,
      isBookmarked: isBookmarkedForUser,
      formattedPrice: priceString,
    );
  }

  Future<void> _toggleBookmark(int userId) async {
    setState(() => _isBookmarked = !_isBookmarked);
    await _bookmarkService.toggleBookmark(widget.plant, userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBookmarked
                ? '${widget.plant.namaTanaman} ditambahkan ke favorit!'
                : '${widget.plant.namaTanaman} dihapus dari favorit.',
          ),
          backgroundColor: _isBookmarked ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<String> _convertAndFormatPrice() async {
    try {
      final String userCurrency = await _currencyService.getUserCurrency();
      final Map<String, dynamic>? rates = await _currencyService.getRates(
        'IDR',
      );
      if (rates != null) {
        final double rate = rates[userCurrency]?.toDouble() ?? 1.0;
        final double convertedPrice = widget.plant.hargaPerkiraan * rate;
        const currencySymbols = {
          'USD': '\$',
          'EUR': '€',
          'JPY': '¥',
          'IDR': 'Rp ',
        };
        final String symbol = currencySymbols[userCurrency] ?? '\$';
        return NumberFormat.currency(
          locale: userCurrency == 'IDR' ? 'id_ID' : 'en_US',
          symbol: symbol,
          decimalDigits: (userCurrency == 'IDR') ? 0 : 2,
        ).format(convertedPrice);
      }
      return "Harga tidak tersedia";
    } catch (e) {
      print("Error converting price: $e");
      return "Error harga";
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2C6E49);
    const Color backgroundColor = Color(0xFFFAF3E0);
    const Color textColor = Color(0xFF3E3636);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: FutureBuilder<PlantDetailData>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            final data = snapshot.data!;
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 350.0,
                  pinned: true,
                  stretch: true,
                  backgroundColor: primaryColor,
                  iconTheme: const IconThemeData(color: Colors.white),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.4),
                        child: (data.userId == null)
                            ? null
                            : IconButton(
                                icon: Icon(
                                  _isBookmarked
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color: Colors.white,
                                ),
                                tooltip: _isBookmarked
                                    ? 'Hapus dari Favorit'
                                    : 'Tambah ke Favorit',
                                onPressed: () => _toggleBookmark(data.userId!),
                              ),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    titlePadding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 12,
                    ),
                    title: Text(
                      widget.plant.namaTanaman,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    background: Hero(
                      tag: 'plant-image-${widget.plant.id}',
                      child: _buildPlantImage(),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildSectionTitle('Deskripsi', textColor),
                            if (widget.plant.hargaPerkiraan > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  data.formattedPrice,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.plant.deskripsi,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: textColor.withOpacity(0.8),
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildSectionTitle('Manfaat', textColor),
                        const SizedBox(height: 12),

                        // --- PERUBAHAN UTAMA: Bungkus Chip dengan GestureDetector ---
                        GestureDetector(
                          onTap: () => _showFullTextDialog(
                            context,
                            "Manfaat",
                            Icons.healing_outlined,
                            widget.plant.manfaat,
                            primaryColor,
                          ),
                          child: _buildInfoChip(
                            widget.plant.manfaat,
                            Icons.healing_outlined,
                            primaryColor,
                          ),
                        ),

                        const SizedBox(height: 28),
                        _buildSectionTitle('Cara Perawatan', textColor),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 110,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: List.generate(
                              widget.plant.caraPerawatan.length,
                              (index) {
                                final key = widget.plant.caraPerawatan.keys
                                    .elementAt(index);
                                final value = widget.plant.caraPerawatan.values
                                    .elementAt(index);
                                return _buildCareItem(
                                  context,
                                  key,
                                  value,
                                  primaryColor,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildSectionTitle('Detail Lainnya', textColor),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Asal Benua',
                          widget.plant.asal,
                          textColor,
                        ),
                        const Divider(color: Colors.black12, height: 24),
                        _buildDetailRow(
                          'Tingkat Kesulitan',
                          widget.plant.tingkatKesulitan,
                          textColor,
                        ),
                        const Divider(color: Colors.black12, height: 24),
                        _buildDetailRow(
                          'Tinggi Maksimal',
                          widget.plant.tinggiMaksimal,
                          textColor,
                        ),
                        const Divider(color: Colors.black12, height: 24),
                        _buildDetailRow(
                          'Kebutuhan Cahaya',
                          widget.plant.kategoriCahaya,
                          textColor,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return const Center(child: Text("Tidak ada data untuk ditampilkan."));
        },
      ),
    );
  }

  // --- FUNGSI BARU UNTUK MENAMPILKAN POP-UP DETAIL ---
  void _showFullTextDialog(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    Color color,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(description, style: GoogleFonts.poppins(height: 1.6)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Tutup',
                style: GoogleFonts.poppins(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Semua helper widgets lainnya tidak ada perubahan
  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color primaryColor) {
    return Chip(
      avatar: Icon(icon, color: primaryColor, size: 20),
      label: Text(
        text,
        style: GoogleFonts.poppins(
          color: primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: primaryColor.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildDetailRow(String title, String value, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: textColor.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: textColor,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCareItem(
    BuildContext context,
    String key,
    String value,
    Color primaryColor,
  ) {
    final careMap = {
      'penyiraman': Icons.water_drop_outlined,
      'cahaya': Icons.wb_sunny_outlined,
      'suhu': Icons.thermostat_outlined,
      'media_tanam': Icons.eco_outlined,
    };
    final icon = careMap[key] ?? Icons.info_outline;
    final title = key
        .replaceAll('_', ' ')
        .replaceFirst(key[0], key[0].toUpperCase());

    return InkWell(
      onTap: () =>
          _showCareDetailSheet(context, icon, title, value, primaryColor),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Icon(icon, color: primaryColor, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCareDetailSheet(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    Color primaryColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFAF3E0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: Icon(icon, color: primaryColor, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Tutup',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.black12),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: GoogleFonts.poppins(fontSize: 15, height: 1.6),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlantImage() {
    return PlantImage(
      assetPath: widget.plant.gambar,
      imageUrl: widget.plant.gambarUrl,
      fit: BoxFit.cover,
    );
  }
}
