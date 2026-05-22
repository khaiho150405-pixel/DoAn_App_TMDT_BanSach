class HoiDap {
  final int maHoiDap;
  final int maKh;
  final String tieuDe;
  final String noiDung;
  final String loaiHoTro;
  final String trangThai;
  final DateTime thoiGianTao;
  final DateTime capNhatCuoi;
  final int? maNvPhuTrach;
  final String tinNhanCuoi;

  HoiDap({
    required this.maHoiDap,
    required this.maKh,
    required this.tieuDe,
    required this.noiDung,
    required this.loaiHoTro,
    required this.trangThai,
    required this.thoiGianTao,
    required this.capNhatCuoi,
    this.maNvPhuTrach,
    required this.tinNhanCuoi,
  });

  factory HoiDap.fromJson(Map<String, dynamic> json) {
    return HoiDap(
      maHoiDap: json['mahoidap'] ?? 0,
      maKh: json['makh'] ?? 0,
      tieuDe: json['tieude'] ?? '',
      noiDung: json['noidung'] ?? '',
      loaiHoTro: json['loaihotro'] ?? '',
      trangThai: json['trangthai'] ?? 'Chờ trả lời',
      thoiGianTao: json['thoigiantao'] != null
          ? DateTime.parse(json['thoigiantao'])
          : DateTime.now(),
      capNhatCuoi: json['capnhatcuoi'] != null
          ? DateTime.parse(json['capnhatcuoi'])
          : DateTime.now(),
      maNvPhuTrach: json['manvphutrach'],
      tinNhanCuoi: json['tinNhanCuoi'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mahoidap': maHoiDap,
      'makh': maKh,
      'tieude': tieuDe,
      'noidung': noiDung,
      'loaihotro': loaiHoTro,
      'trangthai': trangThai,
      'thoigiantao': thoiGianTao.toIso8601String(),
      'capnhatcuoi': capNhatCuoi.toIso8601String(),
      'manvphutrach': maNvPhuTrach,
      'tinNhanCuoi': tinNhanCuoi,
    };
  }
}
