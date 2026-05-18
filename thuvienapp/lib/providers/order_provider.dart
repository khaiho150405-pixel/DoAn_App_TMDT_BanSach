import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCustomerOrders(int customerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _orderService.getOrdersByCustomer(customerId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderModel> checkout(Map<String, dynamic> requestBody) async {
    try {
      final order = await _orderService.checkout(requestBody);
      // Cập nhật danh sách đơn hàng sau khi checkout thành công
      _orders.insert(0, order);
      notifyListeners();
      return order;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<OrderModel?> loadOrderDetail(int orderId) async {
    try {
      return await _orderService.getOrderDetail(orderId);
    } catch (e) {
      return null; // Return null if failed, the screen will handle it
    }
  }
}
