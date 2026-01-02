<?php
// Izinkan akses lintas domain
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') { exit(0); }

header('Content-Type: application/json');

// --- DATABASE CONNECTION ---
$db_host = "localhost";
$db_user = "root";
$db_pass = "";
$db_name = "plantify_db";

$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);

if ($conn->connect_error) {
    die(json_encode(['success' => false, 'message' => 'Koneksi Database Gagal: ' . $conn->connect_error]));
}

$id = $_POST['id'] ?? '';
if (empty($id)) {
    die(json_encode(['success' => false, 'message' => 'ID User tidak ditemukan di request.']));
}

// Proses Upload
if (isset($_FILES['profile_picture']) && $_FILES['profile_picture']['error'] == 0) {
    $upload_dir = 'uploads/';
    
    // Pastikan folder uploads ada
    if (!is_dir($upload_dir)) { mkdir($upload_dir, 0777, true); }

    $file_tmp_path = $_FILES['profile_picture']['tmp_name'];
    $file_ext = strtolower(pathinfo($_FILES['profile_picture']['name'], PATHINFO_EXTENSION));
    
    // Buat nama unik untuk mencegah duplikat/cache
    $new_file_name = uniqid('profile_' . $id . '_', true) . '.' . $file_ext;
    $dest_path = $upload_dir . $new_file_name;
    
    // Pindahkan file dari temp ke folder tujuan
    if(move_uploaded_file($file_tmp_path, $dest_path)) {
        
        // --- LOGIKA IP DINAMIS (SOLUSI DISINI!) ---
        // 1. Dapatkan IP Server yang sedang aktif dari request
        $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off' || $_SERVER['SERVER_PORT'] == 443) ? "https://" : "http://";
        $server_host = $_SERVER['HTTP_HOST']; // Ini otomatis ambil "10.233.126.217"
        
        // 2. Tentukan folder root script (misal: /api/)
        // Ambil path folder tempat file php ini berada
        $script_path = str_replace(basename($_SERVER['SCRIPT_NAME']), '', $_SERVER['SCRIPT_NAME']);
        
        // 3. Gabungkan semua jadi Full URL yang BENAR
        $base_url = $protocol . $server_host . $script_path; // http://10.233.126.217/api/
        $file_url = $base_url . $dest_path; // Hasil akhir URL gambar yang valid

        // Update database dengan URL baru yang valid ini
        $stmt = $conn->prepare("UPDATE users SET profile_image_url = ? WHERE id = ?");
        $stmt->bind_param("si", $file_url, $id);
        
        if ($stmt->execute()) {
            echo json_encode([
                'success' => true, 
                'message' => 'Foto berhasil diunggah dan disimpan.', 
                'data' => [
                    'profile_image_url' => $file_url // Kembalikan URL valid ke Flutter
                ]
            ]);
        } else {
            echo json_encode(['success' => false, 'message' => 'Database error: Gagal menyimpan URL gambar.']);
        }
        $stmt->close();
    } else {
        echo json_encode(['success' => false, 'message' => 'Server error: Gagal memindahkan file gambar.']);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Upload error: Tidak ada file gambar yang valid diterima.']);
}

$conn->close();
?>