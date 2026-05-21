import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';

// Import các model và provider
import '../../models/user.dart';
import '../../providers/api_service.dart';
import '../../providers/cart_provider.dart';

// Import các màn hình
import '../login_screen.dart';
import 'tab_trang_chu.dart';
import 'tab_danh_muc.dart';
import 'tab_ca_nhan.dart';
import 'gio_hang_screen.dart';
import 'tim_kiem_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  final User? user; // Cho phép user null (Khách / Guest mode)
  const HomeScreen({super.key, this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Mặc định chọn tab 0 (Trang chủ) để khách vào thấy nội dung ngay
  int _selectedIndex = 0;
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotificationCount();
  }

  /// Lấy số lượng thông báo mới (sách mới, khuyến mãi...)
  void _fetchNotificationCount() async {
    try {
      var newsList = await ApiService().fetchNewBooksNews();
      if (mounted) {
        setState(() {
          _notificationCount = newsList.length;
        });
      }
    } catch (e) {
      print("Lỗi tải thông báo: $e");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Lấy chữ cái đầu của tên (Nếu là khách trả về icon mặc định sau)
  String _getAvatarLetter(String fullName) {
    if (fullName.isEmpty) return "G"; // G = Guest
    List<String> parts = fullName.trim().split(' ');
    if (parts.isNotEmpty && parts.last.isNotEmpty) {
      return parts.last[0].toUpperCase();
    }
    return fullName[0].toUpperCase();
  }

  /// Hàm chuyển hướng sang trang đăng nhập
  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isGuest = widget.user == null;
    final String avatarLabel =
        isGuest ? "?" : _getAvatarLetter(widget.user!.fullName);

    // Cấu hình danh sách các Tab
    final List<Widget> widgetOptions = [
      // TAB 0: Trang Chủ (Công khai - ai cũng xem được)
      TabTrangChu(user: widget.user),

      // TAB 1: Danh Mục / Sách (Công khai)
      TabDanhMuc(user: widget.user),

      // TAB 2: Cá Nhân (Đã xử lý guest bên trong TabCaNhan)
      TabCaNhan(user: widget.user),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Tắt nút back mặc định
        title: Row(
          children: [
            // --- AVATAR KHÁCH HÀNG ---
            GestureDetector(
              onTap: () {
                _onItemTapped(2); // Chuyển tab sang Tab Cá Nhân
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(0.5), width: 2),
                ),
                child: CircleAvatar(
                  backgroundColor:
                      isGuest ? Colors.grey : AppColors.primaryBlue,
                  child: isGuest
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
                      : Text(
                          avatarLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // --- THANH TÌM KIẾM ---
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TimKiemScreen()),
                  );
                },
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    children: [
                      SizedBox(width: 12),
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Tìm kiếm sách...',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),

            // --- NÚT THÔNG BÁO ---
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_outlined,
                      color: Colors.grey, size: 28),
                  onPressed: () {
                    // Reset số lượng thông báo khi bấm xem
                    setState(() {
                      _notificationCount = 0;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationScreen()),
                    );
                  },
                ),
                if (_notificationCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),

            // --- NÚT GIỎ HÀNG ---
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined,
                      color: Colors.grey, size: 28),
                  onPressed: () {
                    if (isGuest) {
                      // Nếu là khách -> Yêu cầu đăng nhập
                      _navigateToLogin();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                GioHangScreen(user: widget.user!)),
                      );
                    }
                  },
                ),
                // Chỉ hiện số lượng badge nếu KHÔNG phải là khách
                if (!isGuest)
                  Positioned(
                    right: 5,
                    top: 5,
                    child: Consumer<CartProvider>(
                      builder: (context, cart, child) {
                        if (cart.itemCount == 0) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10)),
                          constraints: const BoxConstraints(
                              minWidth: 16, minHeight: 16),
                          child: Text('${cart.itemCount}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10),
                              textAlign: TextAlign.center),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),

      // Hiển thị nội dung Tab được chọn
      body: widgetOptions.elementAt(_selectedIndex),

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book), label: 'Danh mục'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Cá nhân'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// --- WIDGET PHỤ: HIỂN THỊ KHI YÊU CẦU ĐĂNG NHẬP ---
class LoginRequiredView extends StatelessWidget {
  final String title;
  const LoginRequiredView({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              "Bạn cần đăng nhập",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800]),
            ),
            const SizedBox(height: 10),
            const Text(
              "Vui lòng đăng nhập để xem thông tin cá nhân và quản lý đơn hàng.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                backgroundColor: AppColors.primaryBlue,
              ),
              child: const Text("Đăng nhập ngay",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}