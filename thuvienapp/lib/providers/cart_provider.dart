import 'package:flutter/material.dart';
import '../models/sach.dart';

class CartItem {
  final Sach sach;
  int soLuong;
  CartItem({required this.sach, this.soLuong = 1});
}

// BẮT BUỘC PHẢI LÀ TÊN NÀY: CartProvider
class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount {
    int count = 0;
    for (var item in _items) {
      count += item.soLuong;
    }
    return count;
  }

  double get totalAmount {
    double total = 0.0;
    for (var item in _items) {
      total += item.sach.giaBanThucTe * item.soLuong;
    }
    return total;
  }

  void addItem(Sach sach) {
    var existingIndex = _items.indexWhere((item) => item.sach.maSach == sach.maSach);
    if (existingIndex >= 0) {
      _items[existingIndex].soLuong += 1;
    } else {
      _items.add(CartItem(sach: sach, soLuong: 1));
    }
    notifyListeners();
  }
}