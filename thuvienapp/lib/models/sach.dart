/// Model Sách - Dùng cho toàn bộ app bán sách
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

  // --- CÁC TRƯỜNG MỚI CHO TRANG CHI TIẾT (nullable, backward compatible) ---
  final String? moTa;           // Mô tả sách
  final String? nhaCungCap;     // Nhà cung cấp
  final String? loaiBia;        // Loại bìa (Bìa mềm, Bìa cứng...)
  final int? soLuongTonKho;     // Số lượng tồn kho
  final double? danhGiaSao;     // Đánh giá sao trung bình (1-5)
  final int? soLuongDanhGia;    // Số lượng đánh giá
  final List<String>? danhSachAnh; // Danh sách ảnh preview

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
  });

  factory Sach.fromJson(Map<String, dynamic> json) {
    // Parse danh sách ảnh nếu có
    List<String>? images;
    if (json['danhSachAnh'] != null) {
      images = List<String>.from(json['danhSachAnh']);
    }

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
      moTa: json['moTa'],
      nhaCungCap: json['nhaCungCap'],
      loaiBia: json['loaiBia'],
      soLuongTonKho: json['soLuongTonKho'],
      danhGiaSao: (json['danhGiaSao'] ?? 0).toDouble(),
      soLuongDanhGia: json['soLuongDanhGia'],
      danhSachAnh: images,
    );
  }

  /// Kiểm tra còn hàng không
  bool get conHang => (soLuongTonKho ?? 0) > 0;

  /// Lấy danh sách tất cả ảnh (ảnh chính + ảnh phụ)
  List<String> get tatCaAnh {
    List<String> result = [];
    if (hinhAnh != null && hinhAnh!.isNotEmpty) {
      result.add(hinhAnh!);
    }
    if (danhSachAnh != null) {
      result.addAll(danhSachAnh!);
    }
    // Nếu không có ảnh nào, trả về ảnh mặc định
    if (result.isEmpty) {
      result.add('default_book.jpg');
    }
    return result;
  }
}