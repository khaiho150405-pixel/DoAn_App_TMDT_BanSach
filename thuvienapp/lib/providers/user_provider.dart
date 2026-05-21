import 'package:flutter/material.dart';
import '../models/user.dart';

class UserProvider with ChangeNotifier {
  User? _user;

  // Lấy thông tin user hiện tại
  User? get user => _user;

  // Kiểm tra xem đã đăng nhập chưa
  bool get isLoggedIn => _user != null;

  // Gọi hàm này sau khi API Login trả về 200 OK
  void setUser(User user) {
    _user = user;
    notifyListeners(); // Thông báo cho toàn App để update UI (VD: Hiện Avatar)
  }

  // Xóa thông tin khi bấm Đăng xuất
  void logout() {
    _user = null;
    notifyListeners();
  }

  // --- CÁC HÀM TIỆN ÍCH KIỂM TRA QUYỀN (Rất hữu ích để ẩn/hiện nút bấm trên App) ---

  bool get isAdmin => _user?.roleId == 1;
  bool get isNhanVienBanHang => _user?.roleId == 2;
  bool get isNhanVienKho => _user?.roleId == 3;
  bool get isKhachHang => _user?.roleId == 4;
}
