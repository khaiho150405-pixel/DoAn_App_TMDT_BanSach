import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/sach.dart';
import '../../models/filter_model.dart';
import '../../providers/api_service.dart';
import 'book_detail_screen.dart';
import 'filter_bottom_sheet.dart';
import '../../theme/app_theme.dart';

/// Tab Danh Mục - Hiển thị sách theo thể loại
class TabDanhMuc extends StatefulWidget {
  final User? user;
  const TabDanhMuc({super.key, this.user});

  @override
  State<TabDanhMuc> createState() => _TabDanhMucState();
}

class _TabDanhMucState extends State<TabDanhMuc> {
  late Future<List<Sach>> _futureBooks;
  String? _selectedCategory;
  BookFilterModel _currentFilter = BookFilterModel();

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  void _loadBooks() {
    setState(() {
      if (_currentFilter.hasFilter) {
        _futureBooks = ApiService().filterBooks(
          author: _currentFilter.author,
          publisher: _currentFilter.publisher,
          minPrice: _currentFilter.minPrice,
          maxPrice: _currentFilter.maxPrice,
        );
      } else {
        _futureBooks = ApiService().fetchBooks();
      }
    });
  }

  void _openFilterSheet() async {
    final result = await showModalBottomSheet<BookFilterModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(currentFilter: _currentFilter),
    );

    if (result != null) {
      _currentFilter = result;
      _loadBooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Sach>>(
      future: _futureBooks,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Chưa có danh mục sách nào'));
        }

        List<Sach> allBooks = snapshot.data!;
        Set<String> categories = {};
        for (var book in allBooks) {
          if (book.theLoai != null && book.theLoai!.isNotEmpty) {
            categories.add(book.theLoai!);
          }
        }
        List<String> categoryList = categories.toList()..sort();

        List<Sach> filteredBooks = _selectedCategory == null
            ? allBooks
            : allBooks.where((s) => s.theLoai == _selectedCategory).toList();

        return Column(
          children: [
            // Thanh lọc thể loại
            Container(
              height: 50,
              color: Colors.white,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                children: [
                  _buildChip('Tất cả', _selectedCategory == null, () {
                    setState(() => _selectedCategory = null);
                  }),
                  ...categoryList.map((c) => _buildChip(c, _selectedCategory == c, () {
                    setState(() => _selectedCategory = _selectedCategory == c ? null : c);
                  })),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(_selectedCategory ?? 'Tất cả sách',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${filteredBooks.length} cuốn',
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _openFilterSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _currentFilter.hasFilter ? AppColors.primaryBlue : Colors.white,
                        border: Border.all(color: AppColors.primaryBlue),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.filter_alt_outlined, size: 16, color: _currentFilter.hasFilter ? Colors.white : AppColors.primaryBlue),
                          const SizedBox(width: 4),
                          Text('Lọc', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _currentFilter.hasFilter ? Colors.white : AppColors.primaryBlue)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: filteredBooks.isEmpty
                  ? const Center(child: Text('Không có sách trong danh mục này'))
                  : RefreshIndicator(
                      color: AppColors.primaryBlue,
                      onRefresh: () async {
                        _loadBooks();
                        await _futureBooks;
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredBooks.length,
                        itemBuilder: (context, index) => GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => BookDetailScreen(sach: filteredBooks[index], user: widget.user))),
                          child: _buildBookTile(filteredBooks[index]),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryBlue,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookTile(Sach sach) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            child: SizedBox(
              width: 90, height: 120,
              child: Image.network(
                '${ApiService.imageUrl}${sach.hinhAnh}',
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.book, size: 40, color: Colors.grey),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sach.tenSach,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (sach.tenTacGia != null) ...[
                    const SizedBox(height: 4),
                    Text(sach.tenTacGia!, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                  const SizedBox(height: 8),
                  if (sach.phanTramGiam > 0) ...[
                    Text('${sach.giaGoc.toStringAsFixed(0)} đ',
                        style: const TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                    Text('${sach.giaBanThucTe.toStringAsFixed(0)} đ',
                        style: const TextStyle(fontSize: 15, color: Colors.red, fontWeight: FontWeight.bold)),
                  ] else
                    Text('${sach.giaGoc.toStringAsFixed(0)} đ',
                        style: const TextStyle(fontSize: 15, color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
