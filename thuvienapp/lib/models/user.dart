class User {
  final int maTaiKhoan;   // ID tài khoản dùng để đăng nhập
  final String tenDangNhap;
  final int roleId;       // 1: Admin, 2: Bán hàng, 3: Kho, 4: Khách hàng
  final String? roleName;
  final int realId;       // QUAN TRỌNG: Đây là MaKH (nếu là khách) hoặc MaNV (nếu là nhân viên)
  final String fullName;  // Tên hiển thị trên app

  User({
    required this.maTaiKhoan,
    required this.tenDangNhap,
    required this.roleId,
    this.roleName,
    required this.realId,
    required this.fullName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      maTaiKhoan: json['maTaiKhoan'] ?? 0,
      tenDangNhap: json['tenDangNhap'] ?? '',
      roleId: json['roleId'] ?? 4,
      roleName: json['roleName'],
      realId: json['realId'] ?? 0,
      fullName: json['fullName'] ?? 'Người dùng',
    );
  }
}