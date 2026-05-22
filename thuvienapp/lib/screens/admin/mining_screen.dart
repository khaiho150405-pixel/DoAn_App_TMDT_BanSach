import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/api_service.dart';
import '../../widgets/admin/admin_app_bar_title.dart';

/// Màn hình Admin — Phân tích Top-K sản phẩm hữu ích bằng VertTopKDS Mining.
class MiningScreen extends StatefulWidget {
  const MiningScreen({super.key});

  @override
  State<MiningScreen> createState() => _MiningScreenState();
}

class _MiningScreenState extends State<MiningScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _kController = TextEditingController(text: '');
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _isApplying = false;
  String? _errorMessage;
  Map<String, dynamic>? _miningResult;
  List<dynamic>? _appliedPromotions;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _kController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _fmt(double price) => price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  Future<void> _runMining() async {
    final k = int.tryParse(_kController.text.trim());
    if (k == null || k < 1 || k > 100) {
      setState(() => _errorMessage = 'Vui lòng nhập K từ 1 đến 100');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _miningResult = null;
      _appliedPromotions = null;
    });

    try {
      final result = await _apiService.runMiningTopK(k);
      setState(() {
        _miningResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _applyPromotions() async {
    if (_miningResult == null) return;

    final results = _miningResult!['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return;

    setState(() => _isApplying = true);

    try {
      final response = await _apiService.applyMiningPromotions(results);
      setState(() {
        _isApplying = false;
        _appliedPromotions = response['promotions'] as List<dynamic>?;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response['message'] ?? 'Tạo khuyến mãi thành công!'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      setState(() => _isApplying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        titleSpacing: 12,
        title: const AdminAppBarTitle(
          icon: Icons.analytics_outlined,
          title: 'Phân tích',
          subtitle: 'Top-K sản phẩm hữu ích cao',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── INPUT CARD ──────────────────────────────────────
            _buildInputCard(),
            const SizedBox(height: 16),

            // ── LOADING STATE ───────────────────────────────────
            if (_isLoading) _buildLoadingState(),

            // ── ERROR STATE ─────────────────────────────────────
            if (_errorMessage != null) _buildErrorCard(),

            // ── RESULTS ─────────────────────────────────────────
            if (_miningResult != null && !_isLoading) ...[
              _buildStatsRow(),
              const SizedBox(height: 16),
              _buildResultsList(),
              const SizedBox(height: 16),
              _buildApplyButton(),
            ],

            // ── APPLIED PROMOTIONS ──────────────────────────────
            if (_appliedPromotions != null) ...[
              const SizedBox(height: 24),
              _buildAppliedSection(),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // INPUT CARD
  // ════════════════════════════════════════════════════════════════

  Widget _buildInputCard() {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            const Text(
              'Tìm Top-K tập sản phẩm mang lại độ hữu ích cao nhất',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _kController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Giá trị K',
                      labelStyle: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.tag,
                        color: Color(0xFF6B7280),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _runMining,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_arrow_rounded, size: 20),
                    label: Text(
                      _isLoading ? 'Đang chạy...' : 'Phân tích',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // LOADING STATE
  // ════════════════════════════════════════════════════════════════

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.9 + _pulseController.value * 0.1,
                child: child,
              );
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.analytics_outlined,
                size: 40,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Đang phân tích dữ liệu...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mining engine đang quét và tối ưu hóa',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              borderRadius: BorderRadius.circular(4),
              backgroundColor: const Color(0xFFE5E7EB),
              color: const Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // ERROR CARD
  // ════════════════════════════════════════════════════════════════

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // STATS ROW
  // ════════════════════════════════════════════════════════════════

  Widget _buildStatsRow() {
    final totalTxn = _miningResult!['totalTransactions'] ?? 0;
    final totalItems = _miningResult!['totalItems'] ?? 0;
    final results = _miningResult!['results'] as List<dynamic>? ?? [];
    final threshold = (_miningResult!['threshold'] ?? 0).toDouble();

    return Row(
      children: [
        _StatChip(
          icon: Icons.receipt_long,
          label: '$totalTxn đơn hàng',
          color: const Color(0xFF2563EB),
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.menu_book,
          label: '$totalItems sản phẩm',
          color: const Color(0xFF7C3AED),
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.emoji_events,
          label: '${results.length} kết quả',
          color: const Color(0xFFEA580C),
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.trending_up,
          label: 'Min: ${_fmt(threshold)}đ',
          color: const Color(0xFF16A34A),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // RESULTS LIST
  // ════════════════════════════════════════════════════════════════

  Widget _buildResultsList() {
    final results = _miningResult!['results'] as List<dynamic>? ?? [];

    if (results.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Không tìm thấy kết quả.\nCần có dữ liệu đơn hàng để phân tích.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.leaderboard, color: Color(0xFF2563EB), size: 20),
            SizedBox(width: 8),
            Text(
              'Kết quả Top-K',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...results.map((r) => _ResultCard(result: r, fmt: _fmt)),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // APPLY BUTTON
  // ════════════════════════════════════════════════════════════════

  Widget _buildApplyButton() {
    final results = _miningResult!['results'] as List<dynamic>? ?? [];
    if (results.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed:
            _isApplying || _appliedPromotions != null ? null : _applyPromotions,
        icon: _isApplying
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                _appliedPromotions != null
                    ? Icons.check_circle
                    : Icons.auto_fix_high,
                size: 20,
              ),
        label: Text(
          _appliedPromotions != null
              ? 'Đã tạo khuyến mãi thành công!'
              : _isApplying
                  ? 'Đang tạo khuyến mãi...'
                  : 'Tạo khuyến mãi từ kết quả (${results.length} mục)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _appliedPromotions != null
              ? const Color(0xFF16A34A)
              : const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // APPLIED PROMOTIONS SECTION
  // ════════════════════════════════════════════════════════════════

  Widget _buildAppliedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20),
            SizedBox(width: 8),
            Text(
              'Khuyến mãi đã tạo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._appliedPromotions!.map((promo) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD1FAE5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '-${promo['phanTramGiam']}%',
                      style: const TextStyle(
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
                        (promo['tenKM'] ?? '').toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(promo['sachApDung'] as List?)?.length ?? 0} sách áp dụng',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (promo['loai'] ?? '').toString(),
                    style: const TextStyle(
                      color: Color(0xFF16A34A),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// WIDGET: Stat Chip
// ════════════════════════════════════════════════════════════════════

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// WIDGET: Result Card — hiển thị một itemset trong Top-K
// ════════════════════════════════════════════════════════════════════

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  final String Function(double) fmt;

  const _ResultCard({required this.result, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final rank = result['rank'] ?? 0;
    final itemset = result['itemset'] as List<dynamic>? ?? [];
    final itemNames = result['itemNames'] as List<dynamic>? ?? [];
    final itemImages = result['itemImages'] as List<dynamic>? ?? [];
    final utilityScore = (result['utilityScore'] ?? 0).toDouble();
    final promoType = result['promotionType'] ?? 'single';
    final isCombo = promoType == 'combo';

    Color rankColor;
    if (rank == 1) {
      rankColor = const Color(0xFFEAB308);
    } else if (rank == 2) {
      rankColor = const Color(0xFF94A3B8);
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
    } else {
      rankColor = const Color(0xFF6B7280);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rank <= 3
              ? rankColor.withValues(alpha: 0.3)
              : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Rank + Utility + Badge
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: rankColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        color: rankColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
                        '${fmt(utilityScore)} đ',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'Utility Score',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isCombo
                        ? const Color(0xFF7C3AED).withValues(alpha: 0.1)
                        : const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCombo ? Icons.layers : Icons.bookmark,
                        size: 14,
                        color: isCombo
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCombo ? 'Combo -15%' : 'Đơn lẻ -10%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isCombo
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),

            // Book list
            ...List.generate(
              itemset.length,
              (i) {
                final name = i < itemNames.length
                    ? itemNames[i].toString()
                    : 'Sách #${itemset[i]}';
                final image = i < itemImages.length
                    ? itemImages[i].toString()
                    : 'default_book.jpg';

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: i < itemset.length - 1 ? 8.0 : 0,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 36,
                          height: 48,
                          child: CachedNetworkImage(
                            imageUrl: '${ApiService.imageUrl}$image',
                            fit: BoxFit.cover,
                            errorWidget: (c, e, s) => Container(
                              color: const Color(0xFFF3F4F6),
                              child: const Icon(
                                Icons.book,
                                size: 18,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
