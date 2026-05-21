class User {
  final int maTaiKhoan;
  final String tenDangNhap;
  final int roleId;
  final String? roleName;
  final int realId;
  final String fullName;
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
      realId: json['realId'] ?? json['maKh'] ?? json['maNV'] ?? 0,
      fullName: json['fullName'] ?? json['hoVaTen'] ?? 'Nguoi dung',
      email: json['email'],
      soDienThoai: json['soDienThoai'] ?? json['sdt'],
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
