# Alarm Integration Setup

## Android Alarm Intent Configuration

### Fitur
Ketika user mengatur alarm untuk jadwal siram di **My Garden**:
1. Aplikasi membuat **Android Intent** ke system Clock app
2. Alarm **otomatis diatur** dengan:
   - ⏰ **Waktu**: Sesuai yang dipilih user (jam:menit)
   - 🔔 **Label**: "Siram Tanamanmu!"
   - 📅 **Hari**: Hari-hari yang dipilih (dikonversi ke Calendar constants)
   - 📝 **Deskripsi**: "Nama Tanaman - Jam HH:MM"

### Cara Kerja

**Mapping Hari:**
```
App Format (1-7)     → Android Calendar (1-7)
1 (Senin)            → 2 (MONDAY)
2 (Selasa)           → 3 (TUESDAY)
3 (Rabu)             → 4 (WEDNESDAY)
4 (Kamis)            → 5 (THURSDAY)
5 (Jumat)            → 6 (FRIDAY)
6 (Sabtu)            → 7 (SATURDAY)
7 (Minggu)           → 1 (SUNDAY)
```

**Intent Extras:**
```dart
{
  'android.intent.extra.HOUR': 7,           // Jam (0-23)
  'android.intent.extra.MINUTES': 30,       // Menit (0-59)
  'android.intent.extra.MESSAGE': 'Siram Tanamanmu!',
  'android.intent.extra.DESCRIPTION': 'Padi - Jam 07:30',
  'android.intent.extra.DAYS': [2, 4, 6],   // Array hari (Calendar format)
  'android.intent.extra.SKIP_UI': true      // Skip confirmation dialog
}
```

### Lokasi Kode

File: `lib/features/mygarden/screens/my_garden_screen.dart`

**Method:** `_onAlarmSet()`
- Baris: ~195-245
- Melakukan Platform check: `if (Platform.isAndroid)`
- Menggunakan package: `android_intent_plus`

**Dependencies diperlukan:**
```yaml
android_intent_plus: ^4.3.0  # Sudah ada di pubspec.yaml
```

### Flow User

1. User navigasi ke **My Garden** screen
2. Klik tombol alarm (⏰) pada tanaman
3. Atur waktu & hari di `SetAlarmSheet`
4. Klik "Simpan" → Trigger `_onAlarmSet()`
5. Android Intent dikirim → Clock App membuka
6. Alarm tersetel otomatis di device
7. User melihat Snackbar: ✓ "Alarm 'Siram Tanamanmu!' dibuat - [Nama Tanaman]"

### Platform Spesifik

**Android (Fully Automated):**
- ✅ Intent langsung ke Clock app
- ✅ Alarm tersimpan di system alarms
- ✅ Minimal UI (Skip UI jika supported)

**iOS (Manual Instructions):**
- ⚠️ iOS tidak punya API untuk buat alarm programmatically
- User lihat dialog dengan instruksi lengkap:
  - Waktu yang harus diatur
  - Label: "Siram Tanamanmu!"
  - Hari-hari: "Senin, Rabu, Jumat" (format readable)
  - Nama tanaman untuk referensi

### Testing

Untuk test di Android emulator/device:
1. Buka app Plantify
2. Go to **My Garden**
3. Klik alarm icon pada tanaman
4. Set time dan pilih beberapa hari (contoh: Senin, Rabu, Jumat)
5. Tap "Simpan"
6. Verifikasi:
   - Dialog/Snackbar muncul: ✓ "Alarm dibuat"
   - Clock app buka otomatis (atau di background)
   - Alarm bisa dilihat di Clock app dengan label "Siram Tanamanmu!"
   - Days sudah correct

### Troubleshooting

**Jika intent tidak berfungsi:**
1. Pastikan `android_intent_plus` package terinstall: `flutter pub get`
2. Periksa Android SDK version (min API 21 recommended)
3. Verifikasi permissions di `AndroidManifest.xml` (standard intent, no special permissions needed)
4. Test di real device jika emulator tidak support

**Jika alarm tidak tersimpan:**
- Beberapa device manufacturer memodifikasi Clock app
- User mungkin perlu izin untuk create alarms
- Instruksi manual di iOS tetap berguna sebagai fallback
