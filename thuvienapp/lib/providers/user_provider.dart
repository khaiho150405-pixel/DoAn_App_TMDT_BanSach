import 'package:flutter/material.dart';

import '../models/user.dart';

class UserProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;

  bool get isLoggedIn => _user != null;

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  void updateUser(User user) {
    _user = user;
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }

  bool get isAdmin => _user?.roleId == 1;
  bool get isNhanVienBanHang => _user?.roleId == 2;
  bool get isNhanVienKho => _user?.roleId == 3;
  bool get isKhachHang => _user?.roleId == 4;
}
