class TinNhanHoTro {
  final int maTinNhan;
  final int maHoiDap;
  final String nguoiGui; // "KhachHang" or "NhanVien"
  final int? maKh;
  final int? maNv;
  final String noiDung;
  final String? hinhAnh;
  final bool daXem;
  final DateTime thoiGian;

  TinNhanHoTro({
    required this.maTinNhan,
    required this.maHoiDap,
    required this.nguoiGui,
    this.maKh,
    this.maNv,
    required this.noiDung,
    this.hinhAnh,
    required this.daXem,
    required this.thoiGian,
  });

  factory TinNhanHoTro.fromJson(Map<String, dynamic> json) {
    return TinNhanHoTro(
      maTinNhan: json['matinnhan'] ?? 0,
      maHoiDap: json['mahoidap'] ?? 0,
      nguoiGui: json['nguoigui'] ?? 'KhachHang',
      maKh: json['makh'],
      maNv: json['manv'],
      noiDung: json['noidung'] ?? '',
      hinhAnh: json['hinhanh'],
      daXem: json['daxem'] ?? false,
      thoiGian: json['thoigian'] != null
          ? DateTime.parse(json['thoigian'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matinnhan': maTinNhan,
      'mahoidap': maHoiDap,
      'nguoigui': nguoiGui,
      'makh': maKh,
      'manv': maNv,
      'noidung': noiDung,
      'hinhanh': hinhAnh,
      'daxem': daXem,
      'thoigian': thoiGian.toIso8601String(),
    };
  }
}
