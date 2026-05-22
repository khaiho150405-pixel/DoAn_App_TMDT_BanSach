class Sach {
  final int maSach;
  final String tenSach;
  final String? theLoai;
  final String? hinhAnh;
  final String? tenTacGia;
  final String? nhaXuatBan;
  final double giaGoc;
  final double giaBanThucTe;
  final int phanTramGiam;
  final String? tenSuKienKhuyenMai;
  final String? moTa;
  final String? nhaCungCap;
  final String? loaiBia;
  final int? soLuongTonKho;
  final double? danhGiaSao;
  final int? soLuongDanhGia;
  final List<String>? danhSachAnh;
  final double? recommendationScore;
  final String? recommendationReason;

  Sach({
    required this.maSach,
    required this.tenSach,
    this.theLoai,
    this.hinhAnh,
    this.tenTacGia,
    this.nhaXuatBan,
    required this.giaGoc,
    required this.giaBanThucTe,
    required this.phanTramGiam,
    this.tenSuKienKhuyenMai,
    this.moTa,
    this.nhaCungCap,
    this.loaiBia,
    this.soLuongTonKho,
    this.danhGiaSao,
    this.soLuongDanhGia,
    this.danhSachAnh,
    this.recommendationScore,
    this.recommendationReason,
  });

  factory Sach.fromJson(Map<String, dynamic> json) {
    List<String>? images;
    if (json['danhSachAnh'] != null) {
      images = List<String>.from(json['danhSachAnh']);
    }

    return Sach(
      maSach: json['masach'] ?? json['maSach'] ?? 0,
      tenSach: json['tensach'] ?? json['tenSach'] ?? 'Chua co ten',
      theLoai: json['tenTheLoai'] ?? json['theloai'] ?? json['theLoai'],
      hinhAnh: json['hinhanh'] ?? json['hinhAnh'] ?? 'default_book.jpg',
      tenTacGia: json['tenTacGia'],
      nhaXuatBan: json['tenNxb'] ?? json['nhaXuatBan'],
      giaGoc: _toDouble(json['giaGoc']),
      giaBanThucTe: _toDouble(json['giaBanThucTe']),
      phanTramGiam: json['phanTramGiam'] ?? 0,
      tenSuKienKhuyenMai: json['tenSuKienKhuyenMai'],
      moTa: json['moTa'],
      nhaCungCap: json['nhaCungCap'],
      loaiBia: json['loaiBia'],
      soLuongTonKho: json['soLuongTonKho'],
      danhGiaSao: _toDouble(json['danhGiaSao']),
      soLuongDanhGia: json['soLuongDanhGia'],
      danhSachAnh: images,
      recommendationScore: _toDouble(json['recommendationScore']),
      recommendationReason: json['recommendationReason'],
    );
  }

  bool get conHang => (soLuongTonKho ?? 0) > 0;

  List<String> get tatCaAnh {
    final result = <String>[];
    if (hinhAnh != null && hinhAnh!.isNotEmpty) {
      result.add(hinhAnh!);
    }
    if (danhSachAnh != null) {
      result.addAll(danhSachAnh!);
    }
    if (result.isEmpty) {
      result.add('default_book.jpg');
    }
    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'maSach': maSach,
      'tenSach': tenSach,
      'theLoai': theLoai,
      'hinhAnh': hinhAnh,
      'tenTacGia': tenTacGia,
      'nhaXuatBan': nhaXuatBan,
      'giaGoc': giaGoc,
      'giaBanThucTe': giaBanThucTe,
      'phanTramGiam': phanTramGiam,
      'tenSuKienKhuyenMai': tenSuKienKhuyenMai,
      'moTa': moTa,
      'nhaCungCap': nhaCungCap,
      'loaiBia': loaiBia,
      'soLuongTonKho': soLuongTonKho,
      'danhGiaSao': danhGiaSao,
      'soLuongDanhGia': soLuongDanhGia,
      'danhSachAnh': danhSachAnh,
      'recommendationScore': recommendationScore,
      'recommendationReason': recommendationReason,
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
