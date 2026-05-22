import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

/// Màn hình hiển thị mã QR thanh toán MoMo qua VietQR
/// và giả lập trạng thái xác nhận chuyển khoản cho Demo.
class QrPaymentScreen extends StatefulWidget {
  final double amount;
  final int orderCode;

  const QrPaymentScreen({
    super.key,
    required this.amount,
    required this.orderCode,
  });

  @override
  State<QrPaymentScreen> createState() => _QrPaymentScreenState();
}

class _QrPaymentScreenState extends State<QrPaymentScreen>
    with SingleTickerProviderStateMixin {
  // --- CẤU HÌNH TÀI KHOẢN MOMO NHẬN TIỀN (demo) ---
  static const String _momoPhone = '0901234567';
  static const String _accountName = 'NGUYEN VAN A';
  static const String _bankCode = 'MOMO';

  bool _isPaymentConfirmed = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String get _transferContent => 'DH${widget.orderCode}';

  /// Tạo URL ảnh QR chuẩn VietQR
  String get _qrImageUrl {
    final encodedName = Uri.encodeComponent(_accountName);
    final encodedContent = Uri.encodeComponent(_transferContent);
    return 'https://img.vietqr.io/image/$_bankCode-$_momoPhone-compact.png'
        '?amount=${widget.amount.toInt()}'
        '&addInfo=$encodedContent'
        '&accountName=$encodedName';
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _confirmPayment() {
    setState(() => _isPaymentConfirmed = true);
    _pulseController.stop();

    // Tự động quay về trang chủ sau 3 giây
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isPaymentConfirmed,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black87,
          centerTitle: true,
          title: const Text(
            'Thanh toán chuyển khoản',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          automaticallyImplyLeading: !_isPaymentConfirmed,
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOutCubic,
          child: _isPaymentConfirmed
              ? _buildSuccessView()
              : _buildQrPaymentView(),
        ),
      ),
    );
  }

  // ======================================================
  // GIAO DIỆN CHÍNH: HIỂN THỊ QR + THÔNG TIN CHUYỂN KHOẢN
  // ======================================================
  Widget _buildQrPaymentView() {
    return SingleChildScrollView(
      key: const ValueKey('qr_view'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // --- CARD QR CODE CHÍNH ---
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header MoMo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFAE2070), Color(0xFFD8247B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.account_balance_wallet,
                          color: Colors.white, size: 28),
                      SizedBox(height: 6),
                      Text(
                        'Quét mã để thanh toán MoMo',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

                // QR Image
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFAE2070).withValues(alpha: 0.15),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.network(
                        _qrImageUrl,
                        width: 240,
                        height: 240,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            width: 240,
                            height: 240,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: const Color(0xFFAE2070),
                                strokeWidth: 3,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => SizedBox(
                          width: 240,
                          height: 240,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_2,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'Không tải được mã QR\nVui lòng kiểm tra kết nối',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Số tiền cần thanh toán
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Số tiền: ',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFFAE2070),
                        ),
                      ),
                      Text(
                        '${_formatPrice(widget.amount)} đ',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFAE2070),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Thông tin chuyển khoản chi tiết
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _infoRow('Ví MoMo', _momoPhone, copyable: true),
                      _infoRow('Chủ tài khoản', _accountName),
                      _infoRow('Nội dung CK', _transferContent, copyable: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- TRẠNG THÁI CHỜ THANH TOÁN ---
          ScaleTransition(
            scale: _pulseAnimation,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.orange.shade600,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Đang chờ bạn quét mã và chuyển khoản...',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- NÚT XÁC NHẬN ĐÃ CHUYỂN KHOẢN (Giả lập Demo) ---
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _confirmPayment,
              icon: const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 22),
              label: const Text(
                'Tôi đã chuyển khoản thành công',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                elevation: 2,
                shadowColor: const Color(0xFF16A34A).withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Gợi ý nhỏ
          Text(
            'Lưu ý: Nhập đúng nội dung chuyển khoản để đơn hàng được xử lý nhanh nhất.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ======================================================
  // GIAO DIỆN THÀNH CÔNG: TICK XANH + AUTO REDIRECT
  // ======================================================
  Widget _buildSuccessView() {
    return Center(
      key: const ValueKey('success_view'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tick xanh Animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 80,
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Thanh toán thành công!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Đơn hàng DH${widget.orderCode} đã được xác nhận.\nCảm ơn bạn đã mua sắm!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatPrice(widget.amount)} đ',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF16A34A),
              ),
            ),
            const SizedBox(height: 32),

            // Đếm ngược redirect
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 3, end: 0),
              duration: const Duration(seconds: 3),
              builder: (context, value, child) {
                return Text(
                  'Tự động chuyển hướng về trang chủ sau ${value}s...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Nút về trang chủ ngay
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.home_outlined, size: 20),
              label: const Text(
                'Về trang chủ ngay',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(
                    color: AppColors.primaryBlue, width: 1.5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================================================
  // WIDGET PHỤ: HÀNG THÔNG TIN CHUYỂN KHOẢN
  // ======================================================
  Widget _infoRow(String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã sao chép "$value"'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.black87,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.copy_rounded,
                    size: 16, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }
}
