<?php
// === BLOK KODE BARU UNTUK MENGATASI CORS ===
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}
// ============================================

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
$nama_lengkap = $input['nama_lengkap'] ?? '';
$username = $input['username'] ?? '';
$email = $input['email'] ?? '';
$phone_number = $input['phone_number'] ?? '';
$password = $input['password'] ?? '';

if (empty($nama_lengkap) || empty($username) || empty($email) || empty($phone_number) || empty($password)) {
    die(json_encode(['success' => false, 'message' => 'Semua field wajib diisi.']));
}

$hashed_password = password_hash($password, PASSWORD_BCRYPT);

$stmt = $conn->prepare("SELECT id FROM users WHERE username = ? OR email = ? OR phone_number = ?");
$stmt->bind_param("sss", $username, $email, $phone_number);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    die(json_encode(['success' => false, 'message' => 'Username, email, atau nomor telepon sudah terdaftar.']));
}
$stmt->close();

$stmt = $conn->prepare("INSERT INTO users (nama_lengkap, username, email, phone_number, password) VALUES (?, ?, ?, ?, ?)");
$stmt->bind_param("sssss", $nama_lengkap, $username, $email, $phone_number, $hashed_password);

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Registrasi berhasil! Silakan login.']);
} else {
    echo json_encode(['success' => false, 'message' => 'Terjadi kesalahan saat registrasi: ' . $stmt->error]);
}

$stmt->close();
$conn->close();
?>