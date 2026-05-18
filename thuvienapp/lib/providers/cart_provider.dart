import 'package:flutter/material.dart';
import '../models/sach.dart';

/// Mỗi item trong giỏ hàng
class CartItem {
  final Sach sach;
  int soLuong;
  CartItem({required this.sach, this.soLuong = 1});
}

// BẮT BUỘC PHẢI LÀ TÊN NÀY: CartProvider
class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  /// Tổng số lượng sách trong giỏ (tính cả số lượng mỗi item)
  int get itemCount {
    int count = 0;
    for (var item in _items) {
      count += item.soLuong;
    }
    return count;
  }

  /// Tổng tiền giỏ hàng
  double get totalAmount {
    double total = 0.0;
    for (var item in _items) {
      total += item.sach.giaBanThucTe * item.soLuong;
    }
    return total;
  }

  /// Thêm sách vào giỏ - nếu đã có thì tăng số lượng
  void addItem(Sach sach) {
    var existingIndex =
        _items.indexWhere((item) => item.sach.maSach == sach.maSach);
    if (existingIndex >= 0) {
      _items[existingIndex].soLuong += 1;
    } else {
      _items.add(CartItem(sach: sach, soLuong: 1));
    }
    notifyListeners();
  }

  /// Xóa 1 sách khỏi giỏ hàng
  void removeItem(int maSach) {
    _items.removeWhere((item) => item.sach.maSach == maSach);
    notifyListeners();
  }

  /// Cập nhật số lượng sách trong giỏ
  void updateQuantity(int maSach, int soLuong) {
    if (soLuong <= 0) {
      removeItem(maSach);
      return;
    }
    var index = _items.indexWhere((item) => item.sach.maSach == maSach);
    if (index >= 0) {
      _items[index].soLuong = soLuong;
      notifyListeners();
    }
  }

  /// Giảm 1 đơn vị - nếu còn 1 thì xóa luôn
  void decreaseQuantity(int maSach) {
    var index = _items.indexWhere((item) => item.sach.maSach == maSach);
    if (index >= 0) {
      if (_items[index].soLuong > 1) {
        _items[index].soLuong -= 1;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  /// Xóa toàn bộ giỏ hàng
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  /// Kiểm tra sách đã có trong giỏ chưa
  bool isInCart(int maSach) {
    return _items.any((item) => item.sach.maSach == maSach);
  }
}