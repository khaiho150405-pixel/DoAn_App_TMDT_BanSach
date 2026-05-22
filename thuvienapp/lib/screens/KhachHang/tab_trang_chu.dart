import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/sach.dart';
import '../../providers/api_service.dart';
import 'book_detail_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/recommendation_section.dart';

/// Tab Trang Chủ - Hiển thị danh sách sách nổi bật, sách mới, khuyến mãi
class TabTrangChu extends StatefulWidget {
  final User? user;
  const TabTrangChu({super.key, this.user});

  @override
  State<TabTrangChu> createState() => _TabTrangChuState();
}

class _TabTrangChuState extends State<TabTrangChu> {
  late Future<List<Sach>> _futureBooks;
  late Future<List<Sach>> _futureRecommendations;
  late Future<List<Sach>> _futureTrendingBooks;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  void _loadHomeData() {
    _futureBooks = _apiService.fetchBooks();
    _futureRecommendations = widget.user == null
        ? _apiService.fetchTrendingBooks()
        : _apiService.fetchUserRecommendations(widget.user!.realId);
    _futureTrendingBooks = _apiService.fetchTrendingBooks();
  }

  Future<void> _refreshBooks() async {
    setState(() {
      _loadHomeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshBooks,
      color: AppColors.primaryBlue,
      child: FutureBuilder<List<Sach>>(
        future: _futureBooks,
        builder: (context, snapshot) {
          // Trạng thái: Đang tải
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }
          // Trạng thái: Lỗi
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Lỗi tải dữ liệu',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}',
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _refreshBooks,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white),
                  ),
                ],
              ),
            );
          }
          // Trạng thái: Không có dữ liệu
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Kho sách hiện đang trống!',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          // Trạng thái: Có dữ liệu
          List<Sach> books = snapshot.data!;

          // Lọc sách khuyến mãi
          List<Sach> discountedBooks =
              books.where((s) => s.phanTramGiam > 0).toList();

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- BANNER ---
                _buildBanner(),

                _buildAIChatbotBanner(),

                RecommendationSection(
                  title: 'Có thể bạn thích',
                  icon: Icons.auto_awesome,
                  future: _futureRecommendations,
                  user: widget.user,
                  onRetry: _refreshBooks,
                ),

                RecommendationSection(
                  title: 'Sách đang hot',
                  icon: Icons.local_fire_department,
                  future: _futureTrendingBooks,
                  user: widget.user,
                  onRetry: _refreshBooks,
                ),

                // --- SÁCH KHUYẾN MÃI ---
                if (discountedBooks.isNotEmpty) ...[
                  _buildSectionTitle(
                      '🔥 Khuyến mãi hot', Icons.local_fire_department),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: discountedBooks.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => BookDetailScreen(
                                      sach: discountedBooks[index],
                                      user: widget.user))),
                          child:
                              _BookCardHorizontal(sach: discountedBooks[index]),
                        );
                      },
                    ),
                  ),
                ],

                // --- TẤT CẢ SÁCH ---
                _buildSectionTitle('📚 Tất cả sách', Icons.library_books),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => BookDetailScreen(
                                  sach: books[index], user: widget.user))),
                      child: _BookCardGrid(sach: books[index]),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chào mừng đến\nE-BookStore! 📖',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Khám phá hàng ngàn đầu sách\nvới ưu đãi hấp dẫn',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.auto_stories,
              size: 60, color: AppColors.primaryBlue.withOpacity(0.8)),
        ],
      ),
    );
  }

  Widget _buildAIChatbotBanner() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatbotScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFEFF6FF),
              const Color(0xFFEEF2FF),
              Colors.indigo.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: AppColors.primaryBlue,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Trợ lý ảo AI thông minh',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.auto_awesome, color: Colors.amber, size: 14),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tìm kiếm sách thông minh & nhận gợi ý đọc phù hợp nhất với bạn.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primaryBlue,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  /// Tiêu đề section
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================
// WIDGET CARD SÁCH - CUỘN NGANG (Cho phần khuyến mãi)
// ==============================================================
class _BookCardHorizontal extends StatelessWidget {
  final Sach sach;
  const _BookCardHorizontal({required this.sach});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              spreadRadius: 1),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh sách
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    '${ApiService.imageUrl}${sach.hinhAnh}',
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2));
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child:
                          const Icon(Icons.book, size: 50, color: Colors.grey),
                    ),
                  ),
                  // Nhãn giảm giá
                  if (sach.phanTramGiam > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '-${sach.phanTramGiam}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Thông tin sách
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sach.tenSach,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (sach.phanTramGiam > 0) ...[
                    Text(
                      '${_formatPrice(sach.giaGoc)} đ',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough),
                    ),
                    Text(
                      '${_formatPrice(sach.giaBanThucTe)} đ',
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight: FontWeight.bold),
                    ),
                  ] else ...[
                    Text(
                      '${_formatPrice(sach.giaGoc)} đ',
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold),
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

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}

// ==============================================================
// WIDGET CARD SÁCH - GRID (Cho phần tất cả sách)
// ==============================================================
class _BookCardGrid extends StatelessWidget {
  final Sach sach;
  const _BookCardGrid({required this.sach});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              spreadRadius: 2),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hình ảnh Sách
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    '${ApiService.imageUrl}${sach.hinhAnh}',
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2));
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child:
                          const Icon(Icons.book, size: 50, color: Colors.grey),
                    ),
                  ),
                  // Nhãn giảm giá
                  if (sach.phanTramGiam > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '-${sach.phanTramGiam}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Thông tin Tên sách và Giá tiền
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sach.tenSach,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (sach.phanTramGiam > 0) ...[
                    Text(
                      '${_formatPrice(sach.giaGoc)} đ',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough),
                    ),
                    Text(
                      '${_formatPrice(sach.giaBanThucTe)} đ',
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                          fontWeight: FontWeight.bold),
                    ),
                  ] else ...[
                    Text(
                      '${_formatPrice(sach.giaGoc)} đ',
                      style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold),
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

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}
