<?php
// Izinkan akses dari mana saja dan tangani preflight request
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') { exit(0); }
header('Content-Type: application/json');

/*
 * ======================================================================
 *  API PROXY UNTUK MENGAMBIL DATA WAKTU DARI TIMEZONEDB.COM
 * ======================================================================
 */

// --- KONFIGURASI PENTING ---
// --- GANTI DENGAN API KEY ANDA DARI TIMEZONEDB.COM ---
$apiKey = "MFSR6CIAZ1X7"; 

// 1. Ambil 'timezone' yang dikirim dari Flutter melalui URL
$timezone = $_GET['timezone'] ?? 'Asia/Jakarta'; 

// Validasi sederhana untuk keamanan
if (!preg_match('/^[A-Za-z]+\/[A-Za-z_]+$/', $timezone)) {
    die(json_encode(['status' => 'FAILED', 'message' => 'Format timezone tidak valid.']));
}

// 2. Siapkan URL untuk memanggil API eksternal TimeZoneDB
// Formatnya: by=zone, zone=Europe/London, format=json, key=...
$externalApiUrl = "http://api.timezonedb.com/v2.1/get-time-zone?key=" . $apiKey . "&format=json&by=zone&zone=" . urlencode($timezone);

// 3. Panggil API eksternal menggunakan cURL
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $externalApiUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
$response_body = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

// 4. Periksa apakah panggilan berhasil dan proses respons
if ($http_code == 200) {
    $data = json_decode($response_body, true);

    // TimeZoneDB mengembalikan 'status' -> 'OK' jika berhasil
    if ($data && $data['status'] == 'OK') {
        // Kita akan membuat format JSON baru yang konsisten agar Flutter tidak perlu diubah
        // Ambil timestamp dari respons, lalu ubah ke format ISO-8601
        $timestamp = $data['timestamp'];
        $datetime = new DateTime("@" . $timestamp);

        // Kirimkan respons yang sama seperti TimeAPI.io sebelumnya
        echo json_encode([
            'timeZone' => $data['zoneName'],
            'dateTime' => $datetime->format('Y-m-d\TH:i:s.uP')
        ]);
    } else {
        // Kirim error jika API TimeZoneDB mengembalikan status FAILED
        http_response_code(502); 
        echo json_encode([
            'success' => false, 
            'message' => 'Gagal mengambil data dari TimeZoneDB: ' . ($data['message'] ?? 'Unknown error')
        ]);
    }
} else {
    // Kirim error jika server TimeZoneDB tidak bisa dihubungi
    http_response_code(502);
    echo json_encode([
        'success' => false, 
        'message' => 'Gagal menghubungi API waktu eksternal. Status: ' . $http_code
    ]);
}
?>