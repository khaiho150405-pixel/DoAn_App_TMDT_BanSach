import 'package:flutter/material.dart';
import '../../models/sach.dart';
import '../../providers/api_service.dart';
import 'book_detail_screen.dart';
import '../../theme/app_theme.dart';

/// Màn hình Tìm Kiếm Sách
class TimKiemScreen extends StatefulWidget {
  const TimKiemScreen({super.key});

  @override
  State<TimKiemScreen> createState() => _TimKiemScreenState();
}

class _TimKiemScreenState extends State<TimKiemScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Sach> _allBooks = [];
  List<Sach> _filteredBooks = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      final books = await ApiService().fetchBooks();
      if (mounted) {
        setState(() {
          _allBooks = books;
          _filteredBooks = books;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredBooks = _allBooks;
      } else {
        _filteredBooks = _allBooks.where((sach) {
          final name = sach.tenSach.toLowerCase();
          final author = (sach.tenTacGia ?? '').toLowerCase();
          final category = (sach.theLoai ?? '').toLowerCase();
          final q = query.toLowerCase();
          return name.contains(q) || author.contains(q) || category.contains(q);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearch,
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm sách, tác giả...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                _onSearch('');
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : _filteredBooks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Nhập từ khóa để tìm sách'
                            : 'Không tìm thấy kết quả cho "$_searchQuery"',
                        style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filteredBooks.length,
                  itemBuilder: (context, index) {
                    final sach = _filteredBooks[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
                      ),
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => BookDetailScreen(sach: sach))),
                        child: ListTile(
                        contentPadding: const EdgeInsets.all(8),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 50, height: 70,
                            child: Image.network(
                              '${ApiService.imageUrl}${sach.hinhAnh}',
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.book, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        title: Text(sach.tenSach,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (sach.tenTacGia != null)
                              Text(sach.tenTacGia!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            const SizedBox(height: 4),
                            Text('${sach.giaBanThucTe.toStringAsFixed(0)} đ',
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      )),
                    );
                  },
                ),
    );
  }
}
