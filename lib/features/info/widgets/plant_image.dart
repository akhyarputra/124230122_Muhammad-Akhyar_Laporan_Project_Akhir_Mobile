// Lokasi: lib/features/info/widgets/plant_image.dart

import 'package:flutter/material.dart';

class PlantImage extends StatelessWidget {
  final String? assetPath;
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius; // Parameter opsional

  const PlantImage({
    Key? key,
    this.assetPath,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. PEMBERSIHAN DATA (CLEANING)
    String? cleanUrl = imageUrl?.trim().replaceAll(RegExp(r'\s+'), '');
    String? cleanAsset = assetPath?.trim().replaceAll(RegExp(r'\s+'), '');

    Widget imageWidget;

    // --- PRIORITAS 1: INTERNET ---
    // Logika deteksi: Ada string, tidak kosong, dan mengandung http
    if (cleanUrl != null && cleanUrl.isNotEmpty && cleanUrl.contains('http')) {
      // DIAGNOSTIK: Un-comment baris ini jika ingin lihat URL yang dipakai
      // print("load network: $cleanUrl");

      imageWidget = Image.network(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print("❌ [PlantImage] Gagal Net: $error");
          // Fallback ke aset
          return _tryLoadAsset(cleanAsset);
        },
      );
    }
    // --- PRIORITAS 2: ASET LOKAL ---
    else {
      imageWidget = _tryLoadAsset(cleanAsset);
    }

    // 4. PENERAPAN BORDER RADIUS (Solusi Error Anda)
    // Jika borderRadius TIDAK null, baru kita potong (Clip).
    // Jika null, biarkan kotak (lebih aman dan efisien).
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius:
            borderRadius!, // Tambahkan tanda seru (!) untuk menegaskan tidak null
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _tryLoadAsset(String? path) {
    if (path != null && path.isNotEmpty) {
      // Pastikan bukan link http yang nyasar jadi aset
      if (!path.startsWith('http')) {
        return Image.asset(
          path,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (c, e, s) => _placeholder(),
        );
      }
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey, size: 24),
      ),
    );
  }
}
