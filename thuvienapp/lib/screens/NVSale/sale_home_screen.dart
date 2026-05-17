import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../providers/api_service.dart';
import '../login_screen.dart';
import 'quan_ly_don_hang_screen.dart';
import 'tim_kiem_sach_screen.dart';
import 'hoi_dap_screen.dart';
import 'quan_ly_danh_gia_screen.dart';
import 'tao_tai_khoan_khach_screen.dart';

// ============================================================
//  Màu chủ đạo: Trắng - Xanh (Blue)
// ============================================================
const Color kPrimaryBlue = Color(0xFF2563EB);
const Color kLightBlue = Color(0xFF3B82F6);
const Color kBgWhite = Color(0xFFF8FAFC);
const Color kCardWhite = Colors.white;
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF94A3B8);

class SaleHomeScreen extends StatefulWidget {
  const SaleHomeScreen({super.key});
  @override
  State<SaleHomeScreen> createState() => _SaleHomeScreenState();
}

class _SaleHomeScreenState extends State<SaleHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _DashboardTab(),
    QuanLyDonHangScreen(),
    TimKiemSachSaleScreen(),
    HoidapScreen(),
    _CaNhanTab(),
  ];

  void _goToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kCardWhite,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.grid_view_rounded, 'Tổng quan'),
                _navItem(1, Icons.receipt_long_rounded, 'Đơn hàng'),
                _navItem(2, Icons.menu_book_rounded, 'Tìm sách'),
                _navItem(3, Icons.forum_rounded, 'Hỏi đáp'),
                _navItem(4, Icons.person_rounded, 'Cá nhân'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return InkWell(
      onTap: () => _goToTab(index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? kPrimaryBlue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 24, color: isActive ? kPrimaryBlue : kTextGrey),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: isActive ? kPrimaryBlue : kTextGrey)),
        ]),
      ),
    );
  }
}

// ============================================================
//  TAB 1: TỔNG QUAN (Dashboard)
// ============================================================
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();
  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  final ApiService _api = ApiService();
  int _pendingOrders = 0;
  int _pendingQuestions = 0;
  int _totalReviews = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _api.fetchOrdersByStatus('Chờ xác nhận');
      final questions = await _api.fetchPendingQuestions();
      final reviews = await _api.fetchAllReviews();
      if (mounted) {
        setState(() {
          _pendingOrders = orders.length;
          _pendingQuestions = questions.length;
          _totalReviews = reviews.length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    return Scaffold(
      backgroundColor: kBgWhite,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          color: kPrimaryBlue,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              // === TOP BAR: Avatar + Greeting + Bell ===
              Row(children: [
                GestureDetector(
                  onTap: () {
                    // Chuyển sang tab Cá nhân
                    final state = context.findAncestorStateOfType<_SaleHomeScreenState>();
                    state?._goToTab(4);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: kPrimaryBlue, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: kPrimaryBlue.withOpacity(0.1),
                      child: const Icon(Icons.person_rounded, color: kPrimaryBlue, size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Xin chào, ${user?.fullName ?? "Nhân viên"}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
                  const Text('Tổng quan hoạt động BookStore', style: TextStyle(fontSize: 13, color: kTextGrey)),
                ])),
                Stack(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: kPrimaryBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.notifications_rounded, color: kPrimaryBlue, size: 22),
                  ),
                  if (_pendingOrders + _pendingQuestions > 0)
                    Positioned(top: 4, right: 4, child: Container(
                      width: 10, height: 10,
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    )),
                ]),
              ]),

              const SizedBox(height: 24),

              // === STATS GRID (2x2) ===
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.45,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _statCard(
                    icon: Icons.receipt_long_rounded,
                    iconBg: const Color(0xFFDBEAFE),
                    iconColor: kPrimaryBlue,
                    value: _isLoading ? '...' : '$_pendingOrders',
                    label: 'Đơn chờ xác nhận',
                  ),
                  _statCard(
                    icon: Icons.inventory_2_rounded,
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFD97706),
                    value: _isLoading ? '...' : '0',
                    label: 'Đơn đang giao',
                  ),
                  _statCard(
                    icon: Icons.question_answer_rounded,
                    iconBg: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF16A34A),
                    value: _isLoading ? '...' : '$_pendingQuestions',
                    label: 'Hỏi đáp chờ',
                  ),
                  _statCard(
                    icon: Icons.star_half_rounded,
                    iconBg: const Color(0xFFFCE7F3),
                    iconColor: const Color(0xFFDB2777),
                    value: _isLoading ? '...' : '$_totalReviews',
                    label: 'Đánh giá sách',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // === QUICK ACTIONS ===
              const Text('Thao tác nhanh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark)),
              const SizedBox(height: 12),
              _quickAction(
                icon: Icons.person_add_alt_1_rounded,
                iconBg: const Color(0xFFEDE9FE),
                iconColor: const Color(0xFF7C3AED),
                title: 'Tạo tài khoản khách hàng',
                subtitle: 'Mở TK mới cho khách tại quầy',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TaoTaiKhoanKhachScreen())),
              ),
              const SizedBox(height: 10),
              _quickAction(
                icon: Icons.star_rate_rounded,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                title: 'Quản lý đánh giá sách',
                subtitle: 'Duyệt và xóa feedback vi phạm',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuanLyDanhGiaScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({required IconData icon, required Color iconBg, required Color iconColor, required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          Icon(Icons.more_horiz, color: Colors.grey.shade300, size: 20),
        ]),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kTextDark)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: kTextGrey)),
      ]),
    );
  }

  Widget _quickAction({required IconData icon, required Color iconBg, required Color iconColor, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kTextDark)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: kTextGrey)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: kTextGrey),
        ]),
      ),
    );
  }
}

// ============================================================
//  TAB 5: CÁ NHÂN (Profile + Logout)
// ============================================================
class _CaNhanTab extends StatelessWidget {
  const _CaNhanTab();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    return Scaffold(
      backgroundColor: kBgWhite,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            // === PROFILE HEADER ===
            Center(child: Column(children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kPrimaryBlue, width: 3),
                ),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: kPrimaryBlue.withOpacity(0.1),
                  child: const Icon(Icons.person_rounded, size: 48, color: kPrimaryBlue),
                ),
              ),
              const SizedBox(height: 14),
              Text(user?.fullName ?? 'Nhân viên', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextDark)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(color: kPrimaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(user?.roleName ?? 'Bán Hàng', style: const TextStyle(color: kPrimaryBlue, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),
              Text('@${user?.tenDangNhap ?? ''}', style: const TextStyle(color: kTextGrey, fontSize: 13)),
            ])),

            const SizedBox(height: 30),

            // === INFO CARD ===
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kCardWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Column(children: [
                _infoRow(Icons.badge_outlined, 'Mã nhân viên', '${user?.realId ?? 'N/A'}'),
                const Divider(height: 24),
                _infoRow(Icons.account_circle_outlined, 'Tên đăng nhập', user?.tenDangNhap ?? 'N/A'),
                const Divider(height: 24),
                _infoRow(Icons.security_outlined, 'Phân quyền', user?.roleName ?? 'Bán Hàng'),
              ]),
            ),

            const SizedBox(height: 16),

            // === MENU ITEMS ===
            _menuItem(context, Icons.star_rate_rounded, 'Quản lý đánh giá', const Color(0xFFF59E0B), onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const QuanLyDanhGiaScreen()));
            }),
            const SizedBox(height: 8),
            _menuItem(context, Icons.person_add_alt_1_rounded, 'Tạo tài khoản khách', const Color(0xFF7C3AED), onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TaoTaiKhoanKhachScreen()));
            }),

            const SizedBox(height: 24),

            // === LOGOUT BUTTON ===
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                label: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _confirmLogout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: kPrimaryBlue, size: 22),
      const SizedBox(width: 14),
      Expanded(child: Text(label, style: const TextStyle(color: kTextGrey, fontSize: 13))),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kTextDark)),
    ]);
  }

  Widget _menuItem(BuildContext context, IconData icon, String title, Color color, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: kCardWhite,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kTextDark))),
          const Icon(Icons.chevron_right_rounded, color: kTextGrey),
        ]),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi hệ thống?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              Provider.of<UserProvider>(context, listen: false).logout();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}