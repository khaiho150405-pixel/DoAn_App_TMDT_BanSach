import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sach.dart';
import '../providers/api_service.dart';
import '../providers/cart_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Sach>> _futureBooks;

  @override
  void initState() {
    super.initState();
    // Gọi API lấy dữ liệu ngay khi màn hình vừa khởi tạo
    _futureBooks = ApiService().fetchBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Màu nền hơi xám cho nổi bật thẻ trắng
      appBar: AppBar(
        title: const Text('E-BookStore', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Icon Giỏ hàng có huy hiệu (Badge) số lượng
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      // TODO: Điều hướng sang trang Chi tiết Giỏ Hàng
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng Giỏ hàng đang xây dựng!')),
                      );
                    },
                  ),
                  // Chỉ hiện vòng đỏ nếu có đồ trong giỏ
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),

      // Xử lý luồng đợi dữ liệu từ API bằng FutureBuilder
      body: FutureBuilder<List<Sach>>(
        future: _futureBooks,
        builder: (context, snapshot) {
          // Trạng thái 1: Đang chờ mạng (Hiện vòng xoay)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
          }
          // Trạng thái 2: Lỗi mạng hoặc lỗi server
          else if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          // Trạng thái 3: Call API thành công nhưng CSDL chưa có sách nào
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Kho sách hiện đang trống!', style: TextStyle(fontSize: 16)));
          }

          // Trạng thái 4: Có dữ liệu -> Hiển thị danh sách
          List<Sach> books = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,       // 2 cột sách
              childAspectRatio: 0.65,  // Chỉnh tỷ lệ để không bị lẹm chữ (cao/rộng)
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              return BookCard(sach: books[index]);
            },
          );
        },
      ),
    );
  }
}

// ==============================================================
// WIDGET CARD HIỂN THỊ 1 CUỐN SÁCH (Có nhãn giảm giá)
// ==============================================================
class BookCard extends StatelessWidget {
  final Sach sach;

  const BookCard({super.key, required this.sach});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, spreadRadius: 2),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hình ảnh Sách (Bọc trong Stack để gắn nhãn Giảm giá đè lên trên)
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    '${ApiService.imageUrl}${sach.hinhAnh}',
                    fit: BoxFit.cover,
                    // Hiển thị vòng xoay lúc ảnh đang tải
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                    },
                    // Hiển thị icon xám nếu ảnh bị lỗi (không tìm thấy trong wwwroot)
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.grey[300], child: const Icon(Icons.book, size: 50, color: Colors.grey)),
                  ),

                  // Nhãn giảm giá màu đỏ góc trên bên trái
                  if (sach.phanTramGiam > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '-${sach.phanTramGiam}%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 2. Thông tin Tên sách và Giá tiền
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sach.tenSach,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis, // Quá dài sẽ biến thành "..."
                  ),
                  const SizedBox(height: 6),

                  // Logic hiển thị giá
                  if (sach.phanTramGiam > 0) ...[
                    // Giá gốc gạch ngang
                    Text(
                      '${sach.giaGoc.toStringAsFixed(0)} đ',
                      style: const TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.lineThrough),
                    ),
                    // Giá sale màu đỏ
                    Text(
                      '${sach.giaBanThucTe.toStringAsFixed(0)} đ',
                      style: const TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ] else ...[
                    // Không sale thì hiện giá đen bình thường
                    Text(
                      '${sach.giaGoc.toStringAsFixed(0)} đ',
                      style: const TextStyle(fontSize: 16, color: Colors.deepOrange, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}