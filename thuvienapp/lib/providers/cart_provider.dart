import 'package:flutter/material.dart';

import '../models/sach.dart';

class CartItem {
  final Sach sach;
  int soLuong;

  CartItem({required this.sach, this.soLuong = 1});
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount {
    var count = 0;
    for (final item in _items) {
      count += item.soLuong;
    }
    return count;
  }

  double get totalAmount {
    var total = 0.0;
    for (final item in _items) {
      total += item.sach.giaBanThucTe * item.soLuong;
    }
    return total;
  }

  void addItem(Sach sach) {
    final existingIndex =
        _items.indexWhere((item) => item.sach.maSach == sach.maSach);
    if (existingIndex >= 0) {
      _items[existingIndex].soLuong += 1;
    } else {
      _items.add(CartItem(sach: sach));
    }
    notifyListeners();
  }

  void removeItem(int maSach) {
    _items.removeWhere((item) => item.sach.maSach == maSach);
    notifyListeners();
  }

  void updateQuantity(int maSach, int soLuong) {
    if (soLuong <= 0) {
      removeItem(maSach);
      return;
    }

    final index = _items.indexWhere((item) => item.sach.maSach == maSach);
    if (index >= 0) {
      _items[index].soLuong = soLuong;
      notifyListeners();
    }
  }

  void decreaseQuantity(int maSach) {
    final index = _items.indexWhere((item) => item.sach.maSach == maSach);
    if (index < 0) return;

    if (_items[index].soLuong > 1) {
      _items[index].soLuong -= 1;
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  bool isInCart(int maSach) {
    return _items.any((item) => item.sach.maSach == maSach);
  }
}
