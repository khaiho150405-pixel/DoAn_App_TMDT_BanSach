import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import '../../models/sach.dart';
import '../../models/user.dart';
import '../../models/danh_gia.dart';
import '../../providers/api_service.dart';
import '../../providers/cart_provider.dart';
import '../login_screen.dart';
import 'checkout_screen.dart';
import '../../theme/app_theme.dart';
import 'gio_hang_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final Sach sach;
  final User? user; // Guest có thể là null
  const BookDetailScreen({super.key, required this.sach, this.user});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  int _selectedImageIndex = 0;
  int _soLuongMua = 1;
  bool _moRongMoTa = false;

  List<String> get _images => widget.sach.tatCaAnh;

  // Màu chủ đạo trắng, xanh dương
  final Color primaryBlue = AppColors.primaryBlue;
  final Color backgroundWhite = AppColors.backgroundWhite;

  List<DanhGia> _reviews = [];
  bool _isReviewsLoading = true;
  DanhGia? _myExistingReview;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isReviewsLoading = true);
    final data = await _apiService.fetchReviewsByBook(widget.sach.maSach);
    
    // Tìm đánh giá của người dùng hiện tại (nếu đã đăng nhập)
    DanhGia? myRev;
    if (widget.user != null) {
      final myId = widget.user!.realId;
      for (var r in data) {
        if (r.maKhachHang == myId) {
          myRev = r;
          break;
        }
      }
    }

    if (mounted) {
      setState(() {
        _reviews = data;
        _myExistingReview = myRev;
        _isReviewsLoading = false;
      });
    }
  }

  Color _getAvatarColor(String name) {
    final hash = name.hashCode;
    final index = hash.abs() % 5;
    final List<Color> colors = [
      const Color(0xFFEFF6FF), // Blue
      const Color(0xFFECFDF5), // Green
      const Color(0xFFFEF3C7), // Amber
      const Color(0xFFFDF2F8), // Pink
      const Color(0xFFF5F3FF), // Purple
    ];
    return colors[index];
  }

  Color _getAvatarTextColor(String name) {
    final hash = name.hashCode;
    final index = hash.abs() % 5;
    final List<Color> colors = [
      const Color(0xFF2563EB),
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFFDB2777),
      const Color(0xFF7C3AED),
    ];
    return colors[index];
  }

  Map<int, int> get _ratingDistribution {
    final dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var r in _reviews) {
      if (r.diem >= 1 && r.diem <= 5) {
        dist[r.diem] = dist[r.diem]! + 1;
      }
    }
    return dist;
  }

  String _fmt(double p) => p.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  void _themGioHang() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    for (int i = 0; i < _soLuongMua; i++) {
      cart.addItem(widget.sach);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Đã thêm ${widget.sach.tenSach} vào giỏ hàng'),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(10),
    ));
  }

  void _muaNgay() {
    // Bắt buộc đăng nhập khi mua ngay
    if (widget.user == null) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CheckoutScreen(
              cartItems: [CartItem(sach: widget.sach, soLuong: _soLuongMua)],
              user: widget.user!),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sach;
    
    // TÍNH TOÁN RATING THỰC TẾ TỪ DATABASE
    final double rating = _reviews.isEmpty
        ? 0.0
        : _reviews.fold<int>(0, (sum, r) => sum + r.diem) / _reviews.length;
    final int ratingCount = _reviews.length;
    
    final mockStock = s.soLuongTonKho ?? 99;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Nền xám rất nhạt
      appBar: AppBar(
        backgroundColor: backgroundWhite,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Chi tiết sách',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          Consumer<CartProvider>(
              builder: (ctx, cart, _) =>
                  Stack(alignment: Alignment.center, children: [
                    IconButton(
                        icon: Icon(Icons.shopping_cart_outlined,
                            color: primaryBlue),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      GioHangScreen(user: widget.user)));
                        }),
                    if (cart.itemCount > 0)
                      Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                color: primaryBlue, shape: BoxShape.circle),
                            constraints: const BoxConstraints(
                                minWidth: 18, minHeight: 18),
                            child: Text('${cart.itemCount}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center),
                          )),
                  ])),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(children: [
        Expanded(
            child: SingleChildScrollView(
                child: Column(children: [
          // === ẢNH SÁCH ===
          _buildImageSection(),
          const SizedBox(height: 8),
          // === GIÁ & TÊN ===
          _buildPriceSection(s, rating, ratingCount),
          const SizedBox(height: 8),
          // === THÔNG TIN CHI TIẾT ===
          _buildInfoSection(s, mockStock),
          const SizedBox(height: 8),
          // === MÔ TẢ ===
          _buildDescriptionSection(s),
          const SizedBox(height: 8),
          // === ĐÁNH GIÁ ===
          _buildRatingSection(rating, ratingCount),
          const SizedBox(height: 80),
        ]))),
        // === BOTTOM BAR ===
        _buildBottomBar(),
      ]),
    );
  }

  // ================ ẢNH SÁCH ================
  Widget _buildImageSection() {
    return Container(
        color: backgroundWhite,
        child: Column(children: [
          Stack(
            children: [
              CarouselSlider.builder(
                itemCount: _images.length,
                options: CarouselOptions(
                  height: 320,
                  viewportFraction: 1.0,
                  onPageChanged: (index, reason) {
                    setState(() => _selectedImageIndex = index);
                  },
                ),
                itemBuilder: (ctx, i, realIdx) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CachedNetworkImage(
                    imageUrl: '${ApiService.imageUrl}${_images[i]}',
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.book, size: 80, color: Colors.grey),
                  ),
                ),
              ),
              // Badge giảm giá
              if (widget.sach.phanTramGiam > 0)
                Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('-${widget.sach.phanTramGiam}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    )),
            ],
          ),
          // Thumbnail Indicators
          if (_images.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _images.asMap().entries.map((entry) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedImageIndex = entry.key),
                  child: Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 4.0),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryBlue.withOpacity(
                            _selectedImageIndex == entry.key ? 0.9 : 0.2)),
                  ),
                );
              }).toList(),
            ),
        ]));
  }

  // ================ GIÁ & TÊN ================
  Widget _buildPriceSection(Sach s, double rating, int ratingCount) {
    return Container(
        color: backgroundWhite,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${_fmt(s.giaBanThucTe)} đ',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue)),
            if (s.phanTramGiam > 0) ...[
              const SizedBox(width: 12),
              Text('${_fmt(s.giaGoc)} đ',
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough)),
            ],
          ]),
          const SizedBox(height: 12),
          Text(s.tenSach,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: Colors.black87)),
          const SizedBox(height: 12),
          Row(children: [
            RatingBarIndicator(
              rating: rating,
              itemBuilder: (context, index) =>
                  const Icon(Icons.star, color: Colors.amber),
              itemCount: 5,
              itemSize: 18.0,
            ),
            const SizedBox(width: 6),
            Text('$rating',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Text('($ratingCount)',
                style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ]),
        ]));
  }

  // ================ THÔNG TIN CHI TIẾT ================
  Widget _buildInfoSection(Sach s, int stock) {
    return Container(
        color: backgroundWhite,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: primaryBlue, size: 20),
              const SizedBox(width: 8),
              const Text('Thông tin chi tiết',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow('Tác giả', s.tenTacGia ?? 'Đang cập nhật'),
          _infoRow('Nhà xuất bản', s.nhaXuatBan ?? 'Đang cập nhật'),
          _infoRow(
              'Nhà cung cấp', s.nhaCungCap ?? s.nhaXuatBan ?? 'Đang cập nhật'),
          _infoRow('Thể loại', s.theLoai ?? 'Đang cập nhật'),
          _infoRow('Loại bìa', s.loaiBia ?? 'Bìa mềm'),
          _infoRow('Kho hàng', stock > 0 ? '$stock cuốn' : 'Hết hàng',
              valueColor: stock > 0 ? Colors.black87 : Colors.red),
        ]));
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          SizedBox(
              width: 120,
              child: Text(label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: valueColor ?? Colors.black87))),
        ]));
  }

  // ================ MÔ TẢ ================
  Widget _buildDescriptionSection(Sach s) {
    final desc = s.moTa ?? 'Chưa có mô tả cho sản phẩm này.';
    return Container(
        color: backgroundWhite,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: primaryBlue, size: 20),
              const SizedBox(width: 8),
              const Text('Mô tả sản phẩm',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 12),
          Text(desc,
              maxLines: _moRongMoTa ? null : 4,
              overflow: _moRongMoTa ? null : TextOverflow.fade,
              style: const TextStyle(
                  fontSize: 14, color: Colors.black87, height: 1.6)),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _moRongMoTa = !_moRongMoTa),
              icon: Icon(
                  _moRongMoTa
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: primaryBlue),
              label: Text(_moRongMoTa ? 'Thu gọn' : 'Xem thêm',
                  style: TextStyle(
                      color: primaryBlue, fontWeight: FontWeight.w600)),
            ),
          ),
        ]));
  }

  // ================ ĐÁNH GIÁ ================
  Widget _buildRatingSection(double rating, int count) {
    final dist = _ratingDistribution;

    return Container(
        color: backgroundWhite,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Icon(Icons.star_outline, color: primaryBlue, size: 20),
              const SizedBox(width: 8),
              const Text('Đánh giá sản phẩm',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 16),
          Row(children: [
            Column(children: [
              Text(rating.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              RatingBarIndicator(
                rating: rating,
                itemBuilder: (context, index) =>
                    const Icon(Icons.star, color: Colors.amber),
                itemCount: 5,
                itemSize: 16.0,
              ),
              const SizedBox(height: 4),
              Text('$count đánh giá',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ]),
            const SizedBox(width: 24),
            Expanded(
                child: Column(
                    children: List.generate(5, (i) {
              final star = 5 - i;
              final countStar = dist[star] ?? 0;
              final pct = count > 0 ? countStar / count : 0.0;
              return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Text('$star', style: const TextStyle(fontSize: 13)),
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor: Colors.grey[200],
                                color: primaryBlue,
                                minHeight: 6))),
                    const SizedBox(width: 8),
                    SizedBox(
                        width: 32,
                        child: Text('${(pct * 100).toInt()}%',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]))),
                  ]));
            }))),
          ]),
          
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nhận xét từ khách hàng ($count)',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _hienThiFormDanhGia,
                icon: Icon(
                  _myExistingReview != null ? Icons.edit_note : Icons.rate_review_outlined,
                  size: 18,
                  color: primaryBlue,
                ),
                label: Text(
                  _myExistingReview != null ? 'Sửa đánh giá' : 'Viết đánh giá',
                  style: TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryBlue, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_isReviewsLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 2),
              ),
            )
          else if (_reviews.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[350]),
                  const SizedBox(height: 12),
                  const Text(
                    'Chưa có đánh giá nào cho cuốn sách này',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hãy là người đầu tiên mua và chia sẻ nhận xét của bạn!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              children: _reviews.map((r) => _buildReviewItem(r)).toList(),
            ),
        ]));
  }

  Widget _buildReviewItem(DanhGia review) {
    final avatarColor = _getAvatarColor(review.tenKhachHang);
    final avatarTextColor = _getAvatarTextColor(review.tenKhachHang);
    final firstLetter = review.tenKhachHang.isNotEmpty ? review.tenKhachHang[0].toUpperCase() : '?';
    final formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(review.thoiGian);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[100]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: avatarColor,
                child: Text(
                  firstLetter,
                  style: TextStyle(
                    color: avatarTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.tenKhachHang,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: review.diem.toDouble(),
                          itemBuilder: (context, index) => const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 14.0,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formattedTime,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.nhanXet.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(
                review.nhanXet,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _hienThiFormDanhGia() {
    if (widget.user == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: primaryBlue),
              const SizedBox(width: 8),
              const Text('Yêu cầu đăng nhập'),
            ],
          ),
          content: const Text(
            'Chỉ khách hàng đã đăng nhập mới được phép đánh giá sách. Bạn có muốn đăng nhập ngay?',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Đăng nhập', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    double diemSo = _myExistingReview?.diem.toDouble() ?? 5.0;
    final textController = TextEditingController(text: _myExistingReview?.nhanXet ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: backgroundWhite,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _myExistingReview != null ? 'Chỉnh sửa đánh giá' : 'Viết đánh giá sách',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.sach.tenSach,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: RatingBar.builder(
                        initialRating: diemSo,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: false,
                        itemCount: 5,
                        itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                        itemBuilder: (context, _) => const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                        ),
                        onRatingUpdate: (rating) {
                          setSheetState(() {
                            diemSo = rating;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        diemSo == 5
                            ? 'Cực kỳ hài lòng'
                            : diemSo == 4
                                ? 'Rất hài lòng'
                                : diemSo == 3
                                    ? 'Hài lòng'
                                    : diemSo == 2
                                        ? 'Chưa hài lòng'
                                        : 'Rất không hài lòng',
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: textController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'Hãy chia sẻ cảm nhận của bạn về cuốn sách này nhé...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryBlue, width: 1.5),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final comment = textController.text.trim();
                              if (comment.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Vui lòng điền nội dung nhận xét!'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              setSheetState(() {
                                isSaving = true;
                              });

                              final result = await _apiService.saveReview(
                                maSach: widget.sach.maSach,
                                maKh: widget.user!.realId,
                                diem: diemSo.toInt(),
                                nhanXet: comment,
                              );

                              if (result['success'] == true) {
                                Navigator.pop(ctx);
                                _loadReviews();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message'] ?? 'Gửi đánh giá thành công!'),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                setSheetState(() {
                                  isSaving = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message'] ?? 'Gửi đánh giá thất bại!'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(
                              _myExistingReview != null ? 'Cập nhật đánh giá' : 'Gửi đánh giá',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  // ================ BOTTOM BAR ================
  Widget _buildBottomBar() {
    final int stock = widget.sach.soLuongTonKho ?? 99;
    final bool outOfStock = stock <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: backgroundWhite, boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5)),
      ]),
      child: SafeArea(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quantity Selector
          if (!outOfStock)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Text('Số lượng:',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderLight),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            if (_soLuongMua > 1) {
                              setState(() => _soLuongMua--);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.remove,
                                size: 20,
                                color: _soLuongMua > 1
                                    ? primaryBlue
                                    : Colors.grey),
                          ),
                        ),
                        Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: Text('$_soLuongMua',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        InkWell(
                          onTap: () {
                            if (_soLuongMua < stock) {
                              setState(() => _soLuongMua++);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Vượt quá số lượng tồn kho'),
                                      backgroundColor: Colors.red));
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.add,
                                size: 20,
                                color: _soLuongMua < stock
                                    ? primaryBlue
                                    : Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text('Kho: $stock',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),

          // Action Buttons
          Row(children: [
            // Thêm giỏ hàng
            Expanded(
                child: OutlinedButton.icon(
              onPressed: outOfStock ? null : _themGioHang,
              icon: Icon(Icons.add_shopping_cart,
                  size: 20, color: outOfStock ? Colors.grey : primaryBlue),
              label: Text('Thêm giỏ hàng',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: outOfStock ? Colors.grey : primaryBlue)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: outOfStock ? Colors.grey : primaryBlue, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            )),
            const SizedBox(width: 12),
            // Mua ngay
            Expanded(
                child: ElevatedButton(
              onPressed: outOfStock ? null : _muaNgay,
              style: ElevatedButton.styleFrom(
                  backgroundColor: outOfStock ? Colors.grey : primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              child: Text(outOfStock ? 'Hết hàng' : 'Mua ngay',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            )),
          ])
        ],
      )),
    );
  }
}
