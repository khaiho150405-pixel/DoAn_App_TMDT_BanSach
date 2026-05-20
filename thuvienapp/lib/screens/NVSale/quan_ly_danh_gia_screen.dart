import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../providers/api_service.dart';

class QuanLyDanhGiaScreen extends StatefulWidget {
  const QuanLyDanhGiaScreen({super.key});
  @override
  State<QuanLyDanhGiaScreen> createState() => _QuanLyDanhGiaScreenState();
}

class _QuanLyDanhGiaScreenState extends State<QuanLyDanhGiaScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _filteredReviews = [];
  bool _isLoading = true;
  int? _filterStar; // null = tất cả, 1-5 = lọc theo sao

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    final data = await _api.fetchAllReviews();
    if (mounted) {
      setState(() {
        _reviews = data;
        _filteredReviews = data;
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      if (_filterStar == null) {
        _filteredReviews = _reviews;
      } else {
        _filteredReviews = _reviews.where((r) => r['diem'] == _filterStar).toList();
      }
    });
  }

  double get _avgRating {
    if (_reviews.isEmpty) return 0;
    final total = _reviews.fold<int>(0, (sum, r) => sum + ((r['diem'] ?? 0) as int));
    return total / _reviews.length;
  }

  Map<int, int> get _ratingDistribution {
    final dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var r in _reviews) {
      final d = r['diem'] ?? 0;
      if (d >= 1 && d <= 5) dist[d] = dist[d]! + 1;
    }
    return dist;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Đánh giá sách', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
        : _reviews.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('Chưa có đánh giá nào', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
            ]))
          : RefreshIndicator(
              onRefresh: _loadReviews,
              color: const Color(0xFF2563EB),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // === SUMMARY CARD ===
                  _buildSummaryCard(),
                  const SizedBox(height: 16),

                  // === FILTER CHIPS ===
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _starChip('Tất cả', null, _reviews.length),
                        ...[5, 4, 3, 2, 1].map((s) => _starChip('$s ★', s, _ratingDistribution[s] ?? 0)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // === RESULTS COUNT ===
                  Text('${_filteredReviews.length} đánh giá', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  const SizedBox(height: 8),

                  // === REVIEW LIST ===
                  ..._filteredReviews.map((r) => _reviewCard(r)),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final dist = _ratingDistribution;
    final maxCount = dist.values.fold(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        // Left: Average
        Column(children: [
          Text(_avgRating.toStringAsFixed(1), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          Row(children: List.generate(5, (i) => Icon(
            i < _avgRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 18,
            color: i < _avgRating.round() ? const Color(0xFFF59E0B) : Colors.grey.shade300,
          ))),
          const SizedBox(height: 4),
          Text('${_reviews.length} đánh giá', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ]),
        const SizedBox(width: 24),
        // Right: Distribution bars
        Expanded(child: Column(children: [5, 4, 3, 2, 1].map((star) {
          final count = dist[star] ?? 0;
          final ratio = maxCount > 0 ? count / maxCount : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Text('$star', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              const SizedBox(width: 4),
              const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFF59E0B)),
                  minHeight: 8,
                ),
              )),
              const SizedBox(width: 8),
              SizedBox(width: 24, child: Text('$count', style: TextStyle(fontSize: 12, color: Colors.grey.shade500), textAlign: TextAlign.right)),
            ]),
          );
        }).toList())),
      ]),
    );
  }

  Widget _starChip(String label, int? star, int count) {
    final isSelected = _filterStar == star;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label ($count)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF2D3436))),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _filterStar = star);
          _applyFilter();
        },
        selectedColor: const Color(0xFF2563EB),
        backgroundColor: Colors.white,
        checkmarkColor: Colors.white,
        side: BorderSide(color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> review) {
    final tenSach = review['tenSach'] ?? 'N/A';
    final hinhAnh = review['hinhAnhSach'] ?? 'default_book.jpg';
    final tenKH = review['tenKhachHang'] ?? 'Khách hàng';
    final diem = review['diem'] ?? 0;
    final nhanXet = review['nhanxet'] ?? '';
    final thoiGian = review['thoigian'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(review['thoigian'])) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // User + time
          Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
              child: Text(tenKH.isNotEmpty ? tenKH[0].toUpperCase() : '?', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tenKH, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),
              Text(thoiGian, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ])),
            // Stars inline
            Row(children: List.generate(5, (i) => Icon(
              i < diem ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 16,
              color: i < diem ? const Color(0xFFF59E0B) : Colors.grey.shade300,
            ))),
          ]),

          // Review text
          if (nhanXet.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(nhanXet, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5)),
          ],

          // Book info
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  '${ApiService.imageUrl}$hinhAnh',
                  width: 32, height: 42, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 32, height: 42, color: Colors.grey.shade200, child: const Icon(Icons.book, size: 16, color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(tenSach, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ]),
      ),
    );
  }
}