import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  late Future<List<Map<String, dynamic>>> _futureAiPromotions;
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
    _futureAiPromotions = _apiService.fetchAiPromotions();
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

                // --- KHUYẾN MÃI TỪ AI ---
                _buildAiPromotionSection(books),

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

  /// Section khuyến mãi từ AI Mining
  Widget _buildAiPromotionSection(List<Sach> allBooks) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _futureAiPromotions,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final promos = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Ưu đãi HOT', Icons.auto_awesome),
            SizedBox(
              height: 175,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: promos.length,
                itemBuilder: (context, index) {
                  final promo = promos[index];
                  final books = promo['danhSachSach'] as List<dynamic>? ?? [];
                  final discount = promo['phanTramGiam'] ?? 0;
                  final name = (promo['tenKM'] ?? '').toString().replaceFirst('[AI] ', '');
                  final isCombo = books.length > 1;

                  return GestureDetector(
                    onTap: () => _handlePromoTap(promo, allBooks),
                    child: Container(
                      width: 290,
                      margin: const EdgeInsets.only(right: 12, bottom: 8, top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFEEEEEE),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            // Left side: Badges, Title, Call-to-action
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Badges: category + discount
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isCombo
                                              ? const Color(0xFFFFF7ED)
                                              : const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isCombo ? Icons.layers_outlined : Icons.redeem,
                                              color: isCombo
                                                  ? const Color(0xFFEA580C)
                                                  : const Color(0xFF2563EB),
                                              size: 12,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isCombo ? 'COMBO' : 'HOT',
                                              style: TextStyle(
                                                color: isCombo
                                                    ? const Color(0xFFEA580C)
                                                    : const Color(0xFF2563EB),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '-$discount%',
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Promo name
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        color: Color(0xFF1F2937),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // "Xem ngay" button
                                  Row(
                                    children: [
                                      Text(
                                        isCombo ? 'Xem combo' : 'Xem chi tiết',
                                        style: const TextStyle(
                                          color: AppColors.primaryBlue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: AppColors.primaryBlue,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Right side: Book cover(s)
                            SizedBox(
                              width: 90,
                              height: 110,
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.centerRight,
                                children: [
                                  if (isCombo) ...[
                                    // Overlapping stacked book covers
                                    ...List.generate(
                                      books.length.clamp(0, 2),
                                      (idx) {
                                        final reverseIdx = books.length.clamp(0, 2) - 1 - idx;
                                        final displayBook = books[reverseIdx];
                                        final displayImage = displayBook['hinhAnh'] ?? 'default_book.jpg';
                                        
                                        return Positioned(
                                          right: reverseIdx * 18.0,
                                          top: reverseIdx * 8.0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(6),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.08),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(6),
                                              child: CachedNetworkImage(
                                                imageUrl: '${ApiService.imageUrl}$displayImage',
                                                width: 50,
                                                height: 70,
                                                fit: BoxFit.cover,
                                                placeholder: (_, __) => Container(
                                                  width: 50,
                                                  height: 70,
                                                  color: Colors.grey[100],
                                                ),
                                                errorWidget: (_, __, ___) => Container(
                                                  width: 50,
                                                  height: 70,
                                                  color: Colors.grey[200],
                                                  child: const Icon(Icons.book, size: 18, color: Colors.grey),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    if (books.length > 2)
                                      Positioned(
                                        right: 0,
                                        bottom: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF374151),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '+${books.length - 2}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ] else ...[
                                    // Single cover
                                    if (books.isNotEmpty)
                                      Center(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.08),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: CachedNetworkImage(
                                              imageUrl: '${ApiService.imageUrl}${books[0]['hinhAnh'] ?? 'default_book.jpg'}',
                                              width: 65,
                                              height: 90,
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => Container(
                                                width: 65,
                                                height: 90,
                                                color: Colors.grey[100],
                                              ),
                                              errorWidget: (_, __, ___) => Container(
                                                width: 65,
                                                height: 90,
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.book, size: 24, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _handlePromoTap(Map<String, dynamic> promo, List<Sach> allBooks) {
    final books = promo['danhSachSach'] as List<dynamic>? ?? [];
    final discount = promo['phanTramGiam'] ?? 0;

    if (books.isEmpty) return;

    if (books.length == 1) {
      final firstBook = books[0];
      final fullSach = allBooks.firstWhere(
        (s) => s.maSach == firstBook['maSach'],
        orElse: () => Sach(
          maSach: firstBook['maSach'] ?? 0,
          tenSach: firstBook['tenSach'] ?? '',
          hinhAnh: firstBook['hinhAnh'] ?? 'default_book.jpg',
          tenTacGia: firstBook['tenTacGia'] ?? '',
          giaGoc: (firstBook['giaBan'] ?? 0).toDouble(),
          giaBanThucTe: (firstBook['giaBan'] ?? 0).toDouble() * (1 - (discount as num) / 100),
          phanTramGiam: discount.toInt(),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookDetailScreen(sach: fullSach, user: widget.user),
        ),
      );
    } else {
      _showComboDetailsSheet(promo, allBooks);
    }
  }

  void _showComboDetailsSheet(Map<String, dynamic> promo, List<Sach> allBooks) {
    final books = promo['danhSachSach'] as List<dynamic>? ?? [];
    final discount = promo['phanTramGiam'] ?? 0;
    final name = (promo['tenKM'] ?? '').toString().replaceFirst('[AI] ', '');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'COMBO ƯU ĐÃI',
                        style: TextStyle(
                          color: Color(0xFFEA580C),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-$discount%',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Chọn một cuốn sách dưới đây để xem thông tin chi tiết:',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: books.length,
                    separatorBuilder: (_, __) => const Divider(height: 20, color: Color(0xFFEEEEEE)),
                    itemBuilder: (context, idx) {
                      final item = books[idx];
                      final bookId = item['maSach'] ?? 0;
                      final bookTitle = item['tenSach'] ?? '';
                      final bookImage = item['hinhAnh'] ?? 'default_book.jpg';
                      final author = item['tenTacGia'] ?? 'Chưa rõ';
                      final originalPrice = (item['giaBan'] ?? 0).toDouble();
                      final finalPrice = originalPrice * (1 - (discount as num) / 100);

                      final fullSach = allBooks.firstWhere(
                        (s) => s.maSach == bookId,
                        orElse: () => Sach(
                          maSach: bookId,
                          tenSach: bookTitle,
                          hinhAnh: bookImage,
                          tenTacGia: author,
                          giaGoc: originalPrice,
                          giaBanThucTe: finalPrice,
                          phanTramGiam: discount.toInt(),
                        ),
                      );

                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookDetailScreen(sach: fullSach, user: widget.user),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFEEEEEE)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: CachedNetworkImage(
                                    imageUrl: '${ApiService.imageUrl}$bookImage',
                                    width: 46,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(width: 46, height: 60, color: Colors.grey[100]),
                                    errorWidget: (_, __, ___) => Container(
                                      width: 46,
                                      height: 60,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.book, size: 18, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bookTitle,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Tác giả: $author',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          '${_formatPrice(finalPrice)} đ',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${_formatPrice(originalPrice)} đ',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
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
