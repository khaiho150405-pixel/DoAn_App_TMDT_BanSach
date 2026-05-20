class Promotion {
  final int maKM;
  final String tenKM;
  final String moTa;
  final int phanTramGiam;
  final DateTime ngayBatDau;
  final DateTime ngayKetThuc;
  final String trangThai;
  final int soSachApDung;

  const Promotion({
    required this.maKM,
    required this.tenKM,
    required this.moTa,
    required this.phanTramGiam,
    required this.ngayBatDau,
    required this.ngayKetThuc,
    required this.trangThai,
    required this.soSachApDung,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      maKM: json['maKM'] ?? 0,
      tenKM: json['tenKM'] ?? '',
      moTa: json['moTa'] ?? '',
      phanTramGiam: json['phanTramGiam'] ?? 0,
      ngayBatDau: DateTime.tryParse(json['ngayBatDau']?.toString() ?? '') ??
          DateTime.now(),
      ngayKetThuc: DateTime.tryParse(json['ngayKetThuc']?.toString() ?? '') ??
          DateTime.now(),
      trangThai: json['trangThai'] ?? '',
      soSachApDung: json['soSachApDung'] ?? 0,
    );
  }
}
