// Lokasi: lib/features/info/models/plant_model.dart

class Plant {
  final int id;
  final String namaTanaman;
  final String namaLatin;
  final String kategori;
  final String deskripsi;
  final String manfaat;
  final Map<String, String> caraPerawatan;
  final String asal;
  final String tinggiMaksimal;
  final String tingkatKesulitan;

  // KITA UBAH DISINI: CUMA PAKE SATU SUMBER (GAMBAR URL)
  final String?
  gambar; // Kita tetap pake nama variabel ini biar ga ngerombak UI
  final String? gambarUrl; // Cadangan

  final String kategoriCahaya;
  final int hargaPerkiraan;

  Plant({
    required this.id,
    required this.namaTanaman,
    required this.namaLatin,
    required this.kategori,
    required this.deskripsi,
    required this.manfaat,
    required this.caraPerawatan,
    required this.asal,
    required this.tinggiMaksimal,
    required this.tingkatKesulitan,
    this.gambar,
    this.gambarUrl,
    required this.kategoriCahaya,
    required this.hargaPerkiraan,
  });

  factory Plant.fromJson(Map<String, dynamic> json, String originContinent) {
    // --- LOGIKA "PAKSA URL" ---
    // Kita cek semua kemungkinan kolom yang mungkin berisi link https

    String? potentialUrl;

    // Cek kolom 'gambar_url' dulu
    if (json['gambar_url'] != null &&
        json['gambar_url'].toString().contains('http')) {
      potentialUrl = json['gambar_url'];
    }
    // Cek kolom 'gambar'
    else if (json['gambar'] != null &&
        json['gambar'].toString().contains('http')) {
      potentialUrl = json['gambar'];
    }
    // Jika kolom 'gambar' isinya masih "assets/...", ABAIKAN/BUANG SAJA!
    // Kita set null biar Widget menampilkan placeholder daripada error aset.

    return Plant(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      namaTanaman: json['nama_tanaman'] ?? 'Tanaman',
      namaLatin: json['nama_latin'] ?? '-',
      kategori: json['kategori'] ?? '-',
      deskripsi: json['deskripsi'] ?? 'Tidak ada deskripsi.',
      manfaat: json['manfaat'] ?? '-',

      caraPerawatan: json['cara_perawatan'] is Map
          ? Map<String, String>.from(json['cara_perawatan'])
          : {},

      asal: originContinent.isNotEmpty
          ? originContinent
          : (json['asal'] ?? 'Unknown'),

      tinggiMaksimal: json['tinggi_maksimal'] ?? '-',
      tingkatKesulitan: json['tingkat_kesulitan'] ?? '-',

      // DISINI MAGIC-NYA: Kita masukkan URL yang valid ke variabel 'gambar'
      // Widget UI (Image) akan otomatis merender NetworkImage karena ada http
      // Kalau null (karena data masih "assets/..."), dia jadi placeholder rapi.
      gambar: null, // Kita matikan field aset, karena request "pure URL"
      gambarUrl: potentialUrl, // Hanya ini yang kita isi jika ada link valid

      kategoriCahaya: json['kategori_cahaya'] ?? '-',
      hargaPerkiraan: json['harga_perkiraan'] is int
          ? json['harga_perkiraan']
          : int.tryParse(json['harga_perkiraan'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_tanaman': namaTanaman,
      'nama_latin': namaLatin,
      'kategori': kategori,
      'deskripsi': deskripsi,
      'manfaat': manfaat,
      'cara_perawatan': caraPerawatan,
      'asal': asal,
      'tinggi_maksimal': tinggiMaksimal,
      'tingkat_kesulitan': tingkatKesulitan,
      'gambar_url': gambarUrl,

      'kategori_cahaya': kategoriCahaya,
      'harga_perkiraan': hargaPerkiraan,
    };
  }
}
