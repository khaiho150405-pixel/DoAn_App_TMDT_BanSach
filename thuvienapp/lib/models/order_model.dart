class OrderDetail {
  final int maSach;
  final String tenSach;
  final String hinhAnh;
  final int soLuong;
  final double donGia;
  final double thanhTien;

  OrderDetail({
    required this.maSach,
    required this.tenSach,
    required this.hinhAnh,
    required this.soLuong,
    required this.donGia,
    required this.thanhTien,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      maSach: json['maSach'],
      tenSach: json['tenSach'],
      hinhAnh: json['hinhAnh'],
      soLuong: json['soLuong'],
      donGia: (json['donGia'] as num).toDouble(),
      thanhTien: (json['thanhTien'] as num).toDouble(),
    );
  }
}

class OrderModel {
  final int maDH;
  final DateTime ngayDat;
  final double tongTien;
  final String tenNguoiNhan;
  final String sdtNhan;
  final String diaChiGiao;
  final String phuongThucThanhToan;
  final String trangThaiThanhToan;
  final String trangThaiDonHang;
  final int soLuongSanPham;
  final List<OrderDetail> chiTiet;

  OrderModel({
    required this.maDH,
    required this.ngayDat,
    required this.tongTien,
    required this.tenNguoiNhan,
    required this.sdtNhan,
    required this.diaChiGiao,
    required this.phuongThucThanhToan,
    required this.trangThaiThanhToan,
    required this.trangThaiDonHang,
    required this.soLuongSanPham,
    required this.chiTiet,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var list = json['chiTiet'] as List? ?? [];
    List<OrderDetail> detailList = list.map((i) => OrderDetail.fromJson(i)).toList();

    return OrderModel(
      maDH: json['maDH'],
      ngayDat: DateTime.parse(json['ngayDat']),
      tongTien: (json['tongTien'] as num).toDouble(),
      tenNguoiNhan: json['tenNguoiNhan'],
      sdtNhan: json['sdtNhan'],
      diaChiGiao: json['diaChiGiao'],
      phuongThucThanhToan: json['phuongThucThanhToan'],
      trangThaiThanhToan: json['trangThaiThanhToan'],
      trangThaiDonHang: json['trangThaiDonHang'],
      soLuongSanPham: json['soLuongSanPham'] ?? detailList.fold(0, (sum, item) => sum + item.soLuong),
      chiTiet: detailList,
    );
  }
}
