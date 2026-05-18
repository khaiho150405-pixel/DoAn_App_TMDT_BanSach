class User {
  final int maTaiKhoan;   // ID tài khoản dùng để đăng nhập
  final String tenDangNhap;
  final int roleId;       // 1: Admin, 2: Bán hàng, 3: Kho, 4: Khách hàng
  final String? roleName;
  final int realId;       // QUAN TRỌNG: Đây là MaKH (nếu là khách) hoặc MaNV (nếu là nhân viên)
  final String fullName;  // Tên hiển thị trên app
  
  // Các field mới thêm
  final String? email;
  final String? soDienThoai;
  final String? diaChiMacDinh;

  User({
    required this.maTaiKhoan,
    required this.tenDangNhap,
    required this.roleId,
    this.roleName,
    required this.realId,
    required this.fullName,
    this.email,
    this.soDienThoai,
    this.diaChiMacDinh,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      maTaiKhoan: json['maTaiKhoan'] ?? 0,
      tenDangNhap: json['tenDangNhap'] ?? '',
      roleId: json['roleId'] ?? 4,
      roleName: json['roleName'],
      realId: json['realId'] ?? json['maKh'] ?? 0, // Fallback nếu API trả về maKh
      fullName: json['fullName'] ?? json['hoVaTen'] ?? 'Người dùng', // Fallback hoVaTen
      email: json['email'],
      soDienThoai: json['soDienThoai'] ?? json['sdt'], // Support sdt
      diaChiMacDinh: json['diaChiMacDinh'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maTaiKhoan': maTaiKhoan,
      'tenDangNhap': tenDangNhap,
      'roleId': roleId,
      'roleName': roleName,
      'realId': realId,
      'fullName': fullName,
      'email': email,
      'soDienThoai': soDienThoai,
      'diaChiMacDinh': diaChiMacDinh,
    };
  }

  User copyWith({
    int? maTaiKhoan,
    String? tenDangNhap,
    int? roleId,
    String? roleName,
    int? realId,
    String? fullName,
    String? email,
    String? soDienThoai,
    String? diaChiMacDinh,
  }) {
    return User(
      maTaiKhoan: maTaiKhoan ?? this.maTaiKhoan,
      tenDangNhap: tenDangNhap ?? this.tenDangNhap,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      realId: realId ?? this.realId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      soDienThoai: soDienThoai ?? this.soDienThoai,
      diaChiMacDinh: diaChiMacDinh ?? this.diaChiMacDinh,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          maTaiKhoan == other.maTaiKhoan &&
          tenDangNhap == other.tenDangNhap &&
          roleId == other.roleId &&
          roleName == other.roleName &&
          realId == other.realId &&
          fullName == other.fullName &&
          email == other.email &&
          soDienThoai == other.soDienThoai &&
          diaChiMacDinh == other.diaChiMacDinh;

  @override
  int get hashCode =>
      maTaiKhoan.hashCode ^
      tenDangNhap.hashCode ^
      roleId.hashCode ^
      roleName.hashCode ^
      realId.hashCode ^
      fullName.hashCode ^
      email.hashCode ^
      soDienThoai.hashCode ^
      diaChiMacDinh.hashCode;
}