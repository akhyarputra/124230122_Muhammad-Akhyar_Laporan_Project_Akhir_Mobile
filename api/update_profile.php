<?php
// Izinkan akses dari mana saja (CORS) dan handle preflight request
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') { exit(0); }
header('Content-Type: application/json');

// --- GANTI DENGAN KREDENSIAL DATABASE ANDA ---
$db_host = "localhost";
$db_user = "root";
$db_pass = "";
$db_name = "plantify_db";
$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);

if ($conn->connect_error) { die(json_encode(['success' => false, 'message' => 'Koneksi Gagal: ' . $conn->connect_error])); }

$input = json_decode(file_get_contents('php://input'), true);
$id = $input['id'] ?? '';
$nama_lengkap = $input['nama_lengkap'] ?? '';
$username = $input['username'] ?? '';
$email = $input['email'] ?? '';
$phone_number = $input['phone_number'] ?? '';

if (empty($id) || empty($nama_lengkap) || empty($username) || empty($email) || empty($phone_number)) { die(json_encode(['success' => false, 'message' => 'Semua field wajib diisi.'])); }

$stmt = $conn->prepare("SELECT id FROM users WHERE (username = ? OR email = ? OR phone_number = ?) AND id != ?");
$stmt->bind_param("sssi", $username, $email, $phone_number, $id);
$stmt->execute();
if ($stmt->get_result()->num_rows > 0) { die(json_encode(['success' => false, 'message' => 'Username, email, atau no. telepon sudah digunakan oleh akun lain.'])); }
$stmt->close();

$stmt = $conn->prepare("UPDATE users SET nama_lengkap = ?, username = ?, email = ?, phone_number = ? WHERE id = ?");
$stmt->bind_param("ssssi", $nama_lengkap, $username, $email, $phone_number, $id);
if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Profil berhasil diperbarui!', 'data' => ['nama_lengkap' => $nama_lengkap, 'username' => $username, 'email' => $email, 'phone_number' => $phone_number]]);
} else {
    echo json_encode(['success' => false, 'message' => 'Gagal memperbarui profil: ' . $stmt->error]);
}

$stmt->close();
$conn->close();
?>