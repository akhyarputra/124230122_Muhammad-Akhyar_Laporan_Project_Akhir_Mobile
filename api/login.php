<?php
// === BLOK KODE BARU UNTUK MENGATASI CORS ===
// Memberi tahu browser asal mana saja yang boleh mengakses (bintang artinya semua)
header("Access-Control-Allow-Origin: *");
// Memberi tahu browser metode apa saja yang diizinkan (POST, GET, dll)
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
// Memberi tahu browser header kustom apa saja yang boleh dikirim (ini yang paling penting untuk error Anda)
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Jika request yang datang adalah 'surat izin' (preflight OPTIONS),
// cukup kirim header di atas dan hentikan script.
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}
// ============================================

// --- Mulai dari sini, kode lama Anda tidak banyak berubah ---
header('Content-Type: application/json');

$db_host = "localhost";
$db_user = "root";
$db_pass = "";
$db_name = "plantify_db";
$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);

if ($conn->connect_error) {
    die(json_encode(['success' => false, 'message' => 'Koneksi Gagal: ' . $conn->connect_error]));
}

$input = json_decode(file_get_contents('php://input'), true);
$username = $input['username'] ?? '';
$password = $input['password'] ?? '';

if (empty($username) || empty($password)) {
    die(json_encode(['success' => false, 'message' => 'Username dan password wajib diisi.']));
}

$stmt = $conn->prepare("SELECT id, nama_lengkap, username, email, phone_number, password FROM users WHERE username = ? OR email = ?");
$stmt->bind_param("ss", $username, $username);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 1) {
    $user = $result->fetch_assoc();
    
    if (password_verify($password, $user['password'])) {
        $response = [
            'success' => true,
            'message' => 'Login berhasil!',
            'data' => [
                'id' => $user['id'],
                'nama_lengkap' => $user['nama_lengkap'],
                'username' => $user['username'],
                'email' => $user['email'],
                'phone_number' => $user['phone_number']
            ]
        ];
        echo json_encode($response);
    } else {
        echo json_encode(['success' => false, 'message' => 'Username atau password salah.']);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Username atau password salah.']);
}

$stmt->close();
$conn->close();
?>