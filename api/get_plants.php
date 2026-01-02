<?php
// Izinkan akses dari mana saja dan tangani preflight request
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') { exit(0); }
header('Content-Type: application/json; charset=UTF-8');

/*
 * ======================================================================
 *  API ENDPOINT UNTUK MEMUAT SEMUA DATA TANAMAN DARI FILE JSON
 * ======================================================================
 */

// 1. Tentukan di mana file JSON Anda berada di server
//    Asumsi folder 'data' berada di level yang sama dengan file PHP ini
$data_dir = __DIR__ . '/data/';

// 2. Daftar file JSON yang akan digabungkan
$plant_files = [
    'Asia' => $data_dir . 'tanaman_asia.json',
    'Australia' => $data_dir . 'tanaman_australia.json',
    'Afrika' => $data_dir . 'tanaman_afrika.json',
    'Amerika' => $data_dir . 'tanaman_amerika.json',
    'Eropa' => $data_dir . 'tanaman_eropa.json',
];

$all_plants = [];

// 3. Looping melalui setiap file, baca, dan gabungkan datanya
foreach ($plant_files as $continent => $file_path) {
    if (file_exists($file_path)) {
        $json_content = file_get_contents($file_path);
        $plants_from_file = json_decode($json_content, true);

        // 'Suntikkan' informasi benua ke setiap data tanaman
        foreach ($plants_from_file as &$plant) { // Gunakan '&' untuk referensi
            $plant['asal'] = $continent;
        }

        $all_plants = array_merge($all_plants, $plants_from_file);
    }
}

// 4. Buat respons JSON yang terstruktur
$response = [
    'success' => true,
    'count' => count($all_plants),
    'data' => $all_plants,
];

// 5. Kirimkan hasilnya ke klien (Flutter)
echo json_encode($response);
?>