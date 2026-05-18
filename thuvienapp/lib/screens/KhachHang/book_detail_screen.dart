import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../models/sach.dart';
import '../../models/user.dart';
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
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CheckoutScreen(
        cartItems: [CartItem(sach: widget.sach, soLuong: _soLuongMua)], 
        user: widget.user!
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sach;
    final mockRating = s.danhGiaSao ?? 4.5;
    final mockRatingCount = s.soLuongDanhGia ?? 128;
    final mockSold = s.soLuongDaBan ?? 350;
    final mockStock = s.soLuongTonKho ?? 99;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Nền xám rất nhạt
      appBar: AppBar(
        backgroundColor: backgroundWhite, 
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Chi tiết sách', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          Consumer<CartProvider>(builder: (ctx, cart, _) => Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart_outlined, color: primaryBlue), 
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => GioHangScreen(user: widget.user)));
                }
              ),
              if (cart.itemCount > 0) Positioned(
                right: 8, top: 8, 
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text('${cart.itemCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                )
              ),
            ]
          )),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(children: [
        Expanded(child: SingleChildScrollView(child: Column(children: [
          // === ẢNH SÁCH ===
          _buildImageSection(),
          const SizedBox(height: 8),
          // === GIÁ & TÊN ===
          _buildPriceSection(s, mockRating, mockRatingCount, mockSold),
          const SizedBox(height: 8),
          // === THÔNG TIN CHI TIẾT ===
          _buildInfoSection(s, mockStock),
          const SizedBox(height: 8),
          // === MÔ TẢ ===
          _buildDescriptionSection(s),
          const SizedBox(height: 8),
          // === ĐÁNH GIÁ ===
          _buildRatingSection(mockRating, mockRatingCount),
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
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  errorWidget: (context, url, error) => const Icon(Icons.book, size: 80, color: Colors.grey),
                ),
              ),
            ),
            // Badge giảm giá
            if (widget.sach.phanTramGiam > 0)
              Positioned(top: 16, left: 16, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(20)),
                child: Text('-${widget.sach.phanTramGiam}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
                  margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryBlue.withOpacity(_selectedImageIndex == entry.key ? 0.9 : 0.2)),
                ),
              );
            }).toList(),
          ),
      ])
    );
  }

  // ================ GIÁ & TÊN ================
  Widget _buildPriceSection(Sach s, double rating, int ratingCount, int sold) {
    return Container(
      color: backgroundWhite, 
      padding: const EdgeInsets.all(16), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end, 
            children: [
              Text('${_fmt(s.giaBanThucTe)} đ', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryBlue)),
              if (s.phanTramGiam > 0) ...[
                const SizedBox(width: 12),
                Text('${_fmt(s.giaGoc)} đ', style: const TextStyle(fontSize: 16, color: Colors.grey, decoration: TextDecoration.lineThrough)),
              ],
            ]
          ),
          const SizedBox(height: 12),
          Text(s.tenSach, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3, color: Colors.black87)),
          const SizedBox(height: 12),
          Row(
            children: [
              RatingBarIndicator(
                rating: rating,
                itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                itemCount: 5,
                itemSize: 18.0,
              ),
              const SizedBox(width: 6),
              Text('$rating', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text('($ratingCount)', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4)
                ),
                child: Text('Đã bán $sold', style: TextStyle(fontSize: 13, color: primaryBlue, fontWeight: FontWeight.w500)),
              ),
            ]
          ),
        ]
      )
    );
  }

  // ================ THÔNG TIN CHI TIẾT ================
  Widget _buildInfoSection(Sach s, int stock) {
    return Container(
      color: backgroundWhite, 
      padding: const EdgeInsets.all(16), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: primaryBlue, size: 20),
              const SizedBox(width: 8),
              const Text('Thông tin chi tiết', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow('Tác giả', s.tenTacGia ?? 'Đang cập nhật'),
          _infoRow('Nhà xuất bản', s.nhaXuatBan ?? 'Đang cập nhật'),
          _infoRow('Nhà cung cấp', s.nhaCungCap ?? s.nhaXuatBan ?? 'Đang cập nhật'),
          _infoRow('Thể loại', s.theLoai ?? 'Đang cập nhật'),
          _infoRow('Loại bìa', s.loaiBia ?? 'Bìa mềm'),
          _infoRow('Kho hàng', stock > 0 ? '$stock cuốn' : 'Hết hàng', valueColor: stock > 0 ? Colors.black87 : Colors.red),
        ]
      )
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), 
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600]))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: valueColor ?? Colors.black87))),
        ]
      )
    );
  }

  // ================ MÔ TẢ ================
  Widget _buildDescriptionSection(Sach s) {
    final desc = s.moTa ?? 'Chưa có mô tả cho sản phẩm này.';
    return Container(
      color: backgroundWhite, 
      padding: const EdgeInsets.all(16), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: primaryBlue, size: 20),
              const SizedBox(width: 8),
              const Text('Mô tả sản phẩm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 12),
          Text(desc, 
            maxLines: _moRongMoTa ? null : 4, 
            overflow: _moRongMoTa ? null : TextOverflow.fade,
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6)
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _moRongMoTa = !_moRongMoTa),
              icon: Icon(_moRongMoTa ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: primaryBlue),
              label: Text(_moRongMoTa ? 'Thu gọn' : 'Xem thêm', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
            ),
          ),
        ]
      )
    );
  }

  // ================ ĐÁNH GIÁ ================
  Widget _buildRatingSection(double rating, int count) {
    return Container(
      color: backgroundWhite, 
      padding: const EdgeInsets.all(16), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(
            children: [
              Icon(Icons.star_outline, color: primaryBlue, size: 20),
              const SizedBox(width: 8),
              const Text('Đánh giá sản phẩm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Column(
                children: [
                  Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black87)),
                  RatingBarIndicator(
                    rating: rating,
                    itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                    itemCount: 5,
                    itemSize: 16.0,
                  ),
                  const SizedBox(height: 4),
                  Text('$count đánh giá', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ]
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: List.generate(5, (i) {
                    final star = 5 - i;
                    final pct = star == 5 ? 0.6 : star == 4 ? 0.25 : star == 3 ? 0.1 : star == 2 ? 0.03 : 0.02;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6), 
                      child: Row(
                        children: [
                          Text('$star', style: const TextStyle(fontSize: 13)),
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(value: pct, backgroundColor: Colors.grey[200], color: primaryBlue, minHeight: 6)
                            )
                          ),
                          const SizedBox(width: 8),
                          SizedBox(width: 32, child: Text('${(pct * 100).toInt()}%', style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
                        ]
                      )
                    );
                  })
                )
              ),
            ]
          ),
        ]
      )
    );
  }

  // ================ BOTTOM BAR ================
  Widget _buildBottomBar() {
    final int stock = widget.sach.soLuongTonKho ?? 99;
    final bool outOfStock = stock <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundWhite, 
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ]
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quantity Selector
            if (!outOfStock) Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Text('Số lượng:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
                            child: Icon(Icons.remove, size: 20, color: _soLuongMua > 1 ? primaryBlue : Colors.grey),
                          ),
                        ),
                        Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: Text('$_soLuongMua', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        InkWell(
                          onTap: () {
                            if (_soLuongMua < stock) {
                              setState(() => _soLuongMua++);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vượt quá số lượng tồn kho'), backgroundColor: Colors.red));
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.add, size: 20, color: _soLuongMua < stock ? primaryBlue : Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text('Kho: $stock', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            
            // Action Buttons
            Row(
              children: [
                // Thêm giỏ hàng
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: outOfStock ? null : _themGioHang,
                    icon: Icon(Icons.add_shopping_cart, size: 20, color: outOfStock ? Colors.grey : primaryBlue),
                    label: Text('Thêm giỏ hàng', style: TextStyle(fontWeight: FontWeight.w600, color: outOfStock ? Colors.grey : primaryBlue)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: outOfStock ? Colors.grey : primaryBlue, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  )
                ),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    child: Text(outOfStock ? 'Hết hàng' : 'Mua ngay', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  )
                ),
              ]
            )
          ],
        )
      ),
    );
  }
}
