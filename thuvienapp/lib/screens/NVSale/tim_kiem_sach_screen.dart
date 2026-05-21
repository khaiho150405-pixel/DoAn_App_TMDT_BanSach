import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../providers/api_service.dart';
import '../../models/sach.dart';

class TimKiemSachSaleScreen extends StatefulWidget {
  const TimKiemSachSaleScreen({super.key});
  @override
  State<TimKiemSachSaleScreen> createState() => _TimKiemSachSaleScreenState();
}

class _TimKiemSachSaleScreenState extends State<TimKiemSachSaleScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  List<Sach> _allBooks = [];
  List<Sach> _filteredBooks = [];
  bool _isLoading = true;
  String? _selectedTheLoai;
  Set<String> _theLoaiSet = {};

  // Sort & Filter
  String _sortMode = 'none'; // 'none', 'asc', 'desc'
  RangeValues? _priceRange;
  double _minPrice = 0;
  double _maxPrice = 1000000;

  // Publisher Filter
  Set<String> _nhaXuatBanSet = {};
  Set<String> _selectedNhaXuatBans = {};

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    final books = await _api.fetchBooks();
    if (mounted) {
      setState(() {
        _allBooks = books;
        _theLoaiSet = books.map((b) => b.theLoai ?? 'Khác').toSet();
        _nhaXuatBanSet = books.map((b) => b.nhaXuatBan ?? 'Khác').toSet();
        if (books.isNotEmpty) {
          _minPrice =
              books.map((b) => b.giaBanThucTe).reduce((a, b) => a < b ? a : b);
          _maxPrice =
              books.map((b) => b.giaBanThucTe).reduce((a, b) => a > b ? a : b);
          _priceRange = RangeValues(_minPrice, _maxPrice);
        }
        _isLoading = false;
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredBooks = _allBooks.where((b) {
        final nameMatch = b.tenSach.toLowerCase().contains(query);
        final authorMatch = (b.tenTacGia ?? '').toLowerCase().contains(query);
        final categoryMatch = _selectedTheLoai == null ||
            (b.theLoai ?? 'Khác') == _selectedTheLoai;
        final priceMatch = _priceRange == null ||
            (b.giaBanThucTe >= _priceRange!.start &&
                b.giaBanThucTe <= _priceRange!.end);
        final nxbMatch = _selectedNhaXuatBans.isEmpty ||
            _selectedNhaXuatBans.contains(b.nhaXuatBan ?? 'Khác');
        return (nameMatch || authorMatch) &&
            categoryMatch &&
            priceMatch &&
            nxbMatch;
      }).toList();

      // Sort
      if (_sortMode == 'asc') {
        _filteredBooks.sort((a, b) => a.giaBanThucTe.compareTo(b.giaBanThucTe));
      } else if (_sortMode == 'desc') {
        _filteredBooks.sort((a, b) => b.giaBanThucTe.compareTo(a.giaBanThucTe));
      }
    });
  }

  void _showPriceFilterSheet() {
    RangeValues tempRange = _priceRange ?? RangeValues(_minPrice, _maxPrice);
    Set<String> tempSelectedNxb = Set.from(_selectedNhaXuatBans);

    final fmt =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    final minCtrl =
        TextEditingController(text: tempRange.start.round().toString());
    final maxCtrl =
        TextEditingController(text: tempRange.end.round().toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          // Helper to update range and controllers
          void updateRange(RangeValues newRange) {
            setSheetState(() {
              tempRange = RangeValues(
                newRange.start.clamp(_minPrice, _maxPrice),
                newRange.end.clamp(_minPrice, _maxPrice),
              );
              minCtrl.text = tempRange.start.round().toString();
              maxCtrl.text = tempRange.end.round().toString();
            });
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
                24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(children: [
                    Icon(Icons.tune_rounded, color: Color(0xFF2563EB)),
                    SizedBox(width: 10),
                    Text('Bộ lọc tìm kiếm',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B))),
                  ]),
                  const Divider(height: 24),

                  // === SECTION 1: PUBLISHERS ===
                  if (_nhaXuatBanSet.isNotEmpty) ...[
                    const Text('Nhà xuất bản',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B))),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _nhaXuatBanSet.map((nxb) {
                        final isSelected = tempSelectedNxb.contains(nxb);
                        return FilterChip(
                          label: Text(nxb,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF475569))),
                          selected: isSelected,
                          selectedColor: const Color(0xFF2563EB),
                          backgroundColor: Colors.grey.shade100,
                          checkmarkColor: Colors.white,
                          side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : Colors.transparent),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          onSelected: (selected) {
                            setSheetState(() {
                              if (selected) {
                                tempSelectedNxb.add(nxb);
                              } else {
                                tempSelectedNxb.remove(nxb);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // === SECTION 2: PREDEFINED PRICE RANGES ===
                  const Text('Chọn khoảng giá nhanh',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _presetPriceChip('Dưới 100k', RangeValues(0, 100000),
                          tempRange, updateRange),
                      _presetPriceChip('100k - 300k',
                          RangeValues(100000, 300000), tempRange, updateRange),
                      _presetPriceChip('300k - 500k',
                          RangeValues(300000, 500000), tempRange, updateRange),
                      _presetPriceChip(
                          'Trên 500k',
                          RangeValues(500000, _maxPrice),
                          tempRange,
                          updateRange),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // === SECTION 3: MANUAL PRICE INPUT ===
                  const Text('Nhập khoảng giá (đ)',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: minCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          hintText: 'Tối thiểu',
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFF2563EB))),
                        ),
                        onChanged: (val) {
                          final minVal = (double.tryParse(val) ?? 0.0)
                              .clamp(_minPrice, _maxPrice);
                          setSheetState(() {
                            tempRange = RangeValues(
                                minVal, tempRange.end.clamp(minVal, _maxPrice));
                          });
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('—', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: maxCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          hintText: 'Tối đa',
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFF2563EB))),
                        ),
                        onChanged: (val) {
                          final maxVal = (double.tryParse(val) ?? _maxPrice)
                              .clamp(_minPrice, _maxPrice);
                          setSheetState(() {
                            tempRange = RangeValues(
                                tempRange.start.clamp(_minPrice, maxVal),
                                maxVal);
                          });
                        },
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // === SECTION 4: RANGE SLIDER ===
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            fmt.format(
                                tempRange.start.clamp(_minPrice, _maxPrice)),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                                fontSize: 13)),
                        Text(
                            fmt.format(
                                tempRange.end.clamp(_minPrice, _maxPrice)),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                                fontSize: 13)),
                      ]),
                  RangeSlider(
                    values: RangeValues(
                      tempRange.start.clamp(_minPrice, _maxPrice),
                      tempRange.end.clamp(
                          tempRange.start.clamp(_minPrice, _maxPrice),
                          _maxPrice),
                    ),
                    min: _minPrice,
                    max: _maxPrice,
                    divisions: _maxPrice > _minPrice ? 50 : 1,
                    activeColor: const Color(0xFF2563EB),
                    inactiveColor: const Color(0xFF2563EB).withOpacity(0.15),
                    labels: RangeLabels(
                        fmt.format(tempRange.start.clamp(_minPrice, _maxPrice)),
                        fmt.format(tempRange.end.clamp(_minPrice, _maxPrice))),
                    onChanged: (v) {
                      setSheetState(() {
                        tempRange = v;
                        minCtrl.text = v.start.round().toString();
                        maxCtrl.text = v.end.round().toString();
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // === ACTIONS ===
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          setState(() {
                            _priceRange = RangeValues(_minPrice, _maxPrice);
                            _selectedNhaXuatBans.clear();
                          });
                          _applyFilters();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Đặt lại'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          setState(() {
                            _priceRange = tempRange;
                            _selectedNhaXuatBans = tempSelectedNxb;
                          });
                          _applyFilters();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Áp dụng',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _presetPriceChip(String label, RangeValues range,
      RangeValues currentRange, ValueChanged<RangeValues> onSelected) {
    final isSelected = (currentRange.start - range.start).abs() < 1000 &&
        (currentRange.end - range.end).abs() < 1000;
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF475569))),
      selected: isSelected,
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (selected) {
        if (selected) {
          onSelected(range);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Tra cứu Sách',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.05),
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => _applyFilters(),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên sách, tác giả...',
                prefixIcon:
                    const Icon(Icons.search_rounded, color: Color(0xFF2563EB)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _applyFilters();
                        })
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 10),
            // Filter chips
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _filterChip('Tất cả', null),
                  ..._theLoaiSet.map((tl) => _filterChip(tl, tl)),
                ],
              ),
            ),
          ]),
        ),
        // Sort & price filter bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Text('${_filteredBooks.length} kết quả',
                style: TextStyle(
                    color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            const Spacer(),
            // Price range filter
            InkWell(
              onTap: _showPriceFilterSheet,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: ((_priceRange != null &&
                              (_priceRange!.start > _minPrice ||
                                  _priceRange!.end < _maxPrice)) ||
                          _selectedNhaXuatBans.isNotEmpty)
                      ? const Color(0xFF2563EB).withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.tune_rounded,
                      size: 16,
                      color: ((_priceRange != null &&
                                  (_priceRange!.start > _minPrice ||
                                      _priceRange!.end < _maxPrice)) ||
                              _selectedNhaXuatBans.isNotEmpty)
                          ? const Color(0xFF2563EB)
                          : Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('Bộ lọc',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ((_priceRange != null &&
                                      (_priceRange!.start > _minPrice ||
                                          _priceRange!.end < _maxPrice)) ||
                                  _selectedNhaXuatBans.isNotEmpty)
                              ? const Color(0xFF2563EB)
                              : Colors.grey.shade600)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            // Sort button
            InkWell(
              onTap: () {
                setState(() {
                  if (_sortMode == 'none')
                    _sortMode = 'asc';
                  else if (_sortMode == 'asc')
                    _sortMode = 'desc';
                  else
                    _sortMode = 'none';
                });
                _applyFilters();
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _sortMode != 'none'
                      ? const Color(0xFF2563EB).withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    _sortMode == 'asc'
                        ? Icons.arrow_upward_rounded
                        : _sortMode == 'desc'
                            ? Icons.arrow_downward_rounded
                            : Icons.sort_rounded,
                    size: 16,
                    color: _sortMode != 'none'
                        ? const Color(0xFF2563EB)
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _sortMode == 'asc'
                        ? 'Giá ↑'
                        : _sortMode == 'desc'
                            ? 'Giá ↓'
                            : 'Sắp xếp',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _sortMode != 'none'
                            ? const Color(0xFF2563EB)
                            : Colors.grey.shade600),
                  ),
                ]),
              ),
            ),
          ]),
        ),
        // Book list
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2563EB)))
              : _filteredBooks.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.search_off_rounded,
                          size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('Không tìm thấy sách',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 16)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _loadBooks,
                      color: const Color(0xFF2563EB),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _filteredBooks.length,
                        itemBuilder: (ctx, i) => _bookCard(_filteredBooks[i]),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _filterChip(String label, String? value) {
    final isSelected = _selectedTheLoai == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF2D3436))),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedTheLoai = value);
          _applyFilters();
        },
        selectedColor: const Color(0xFF2563EB),
        backgroundColor: Colors.white,
        checkmarkColor: Colors.white,
        side: BorderSide(
            color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _bookCard(Sach book) {
    final hasDiscount = book.phanTramGiam > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          // Book image
          Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                '${ApiService.imageUrl}${book.hinhAnh ?? 'default_book.jpg'}',
                width: 75,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 75,
                  height: 100,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.book_rounded,
                      color: Colors.grey, size: 30),
                ),
              ),
            ),
            if (hasDiscount)
              Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomRight: Radius.circular(8))),
                    child: Text('-${book.phanTramGiam}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  )),
          ]),
          const SizedBox(width: 14),
          // Book info
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(book.tenSach,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF2D3436)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                if (book.tenTacGia != null)
                  Text(book.tenTacGia!,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                if (book.theLoai != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0xFF4A90D9).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(book.theLoai!,
                        style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF4A90D9),
                            fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(height: 8),
                Row(children: [
                  if (hasDiscount) ...[
                    Text(currencyFormat.format(book.giaGoc),
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough)),
                    const SizedBox(width: 6),
                  ],
                  Text(currencyFormat.format(book.giaBanThucTe),
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB))),
                ]),
                if (book.tenSuKienKhuyenMai != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(children: [
                      const Icon(Icons.local_offer_rounded,
                          size: 12, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(book.tenSuKienKhuyenMai!,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                    ]),
                  ),
              ])),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}
