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
  });

  factory Sach.fromJson(Map<String, dynamic> json) {
    return Sach(
      maSach: json['masach'] ?? 0,
      tenSach: json['tensach'] ?? 'Chưa có tên',
      theLoai: json['tenTheLoai'] ?? json['theloai'],
      hinhAnh: json['hinhanh'] ?? 'default_book.jpg',
      tenTacGia: json['tenTacGia'],
      nhaXuatBan: json['tenNxb'],
      giaGoc: (json['giaGoc'] ?? 0).toDouble(),
      giaBanThucTe: (json['giaBanThucTe'] ?? 0).toDouble(),
      phanTramGiam: json['phanTramGiam'] ?? 0,
      tenSuKienKhuyenMai: json['tenSuKienKhuyenMai'],
    );
  }
}
