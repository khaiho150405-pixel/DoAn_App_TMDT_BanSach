class AdminUser {
  final int id;
  final String tenDangNhap;
  final String email;
  final int maQuyen;
  final String tenQuyen;
  final String trangThai;
  final String hoVaTen;
  final String chucVu;
  final String sdt;

  const AdminUser({
    required this.id,
    required this.tenDangNhap,
    required this.email,
    required this.maQuyen,
    required this.tenQuyen,
    required this.trangThai,
    required this.hoVaTen,
    required this.chucVu,
    required this.sdt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? 0,
      tenDangNhap: json['tenDangNhap'] ?? '',
      email: json['email'] ?? '',
      maQuyen: json['maQuyen'] ?? 4,
      tenQuyen: json['tenQuyen'] ?? '',
      trangThai: json['trangThai'] ?? 'Hoạt động',
      hoVaTen: json['hoVaTen'] ?? '',
      chucVu: json['chucVu'] ?? '',
      sdt: json['sdt'] ?? '',
    );
  }

  AdminUser copyWith({
    String? trangThai,
  }) {
    return AdminUser(
      id: id,
      tenDangNhap: tenDangNhap,
      email: email,
      maQuyen: maQuyen,
      tenQuyen: tenQuyen,
      trangThai: trangThai ?? this.trangThai,
      hoVaTen: hoVaTen,
      chucVu: chucVu,
      sdt: sdt,
    );
  }
}
