class DanhGia {
  final int maDanhGia;
  final int maSach;
  final int maKhachHang;
  final String tenKhachHang;
  final String? tenSach;
  final String? hinhAnhSach;
  final int diem;
  final String nhanXet;
  final DateTime thoiGian;

  DanhGia({
    required this.maDanhGia,
    required this.maSach,
    required this.maKhachHang,
    required this.tenKhachHang,
    this.tenSach,
    this.hinhAnhSach,
    required this.diem,
    required this.nhanXet,
    required this.thoiGian,
  });

  factory DanhGia.fromJson(Map<String, dynamic> json) {
    return DanhGia(
      maDanhGia: json['madanhgia'] ?? json['maDanhGia'] ?? 0,
      maSach: json['masach'] ?? json['maSach'] ?? 0,
      maKhachHang: json['makh'] ?? json['maKh'] ?? 0,
      tenKhachHang: json['tenKhachHang'] ?? 'Người dùng',
      tenSach: json['tenSach'] ?? json['tensach'],
      hinhAnhSach: json['hinhAnhSach'] ?? json['hinhAnhSach'] ?? json['hinhanhSach'] ?? json['hinhanh'],
      diem: json['diem'] ?? 0,
      nhanXet: json['nhanxet'] ?? json['nhanXet'] ?? '',
      thoiGian: json['thoigian'] != null
          ? DateTime.tryParse(json['thoigian']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'madanhgia': maDanhGia,
      'masach': maSach,
      'makh': maKhachHang,
      'tenKhachHang': tenKhachHang,
      'tenSach': tenSach,
      'hinhAnhSach': hinhAnhSach,
      'diem': diem,
      'nhanxet': nhanXet,
      'thoigian': thoiGian.toIso8601String(),
    };
  }
}
