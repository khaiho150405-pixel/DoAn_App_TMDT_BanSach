import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/api_service.dart';
import '../../providers/warehouse_provider.dart';
import '../../widgets/admin/admin_app_bar_title.dart';
import 'book_form_screen.dart';

class WarehouseInventoryScreen extends StatefulWidget {
  const WarehouseInventoryScreen({super.key});

  @override
  State<WarehouseInventoryScreen> createState() =>
      _WarehouseInventoryScreenState();
}

class _WarehouseInventoryScreenState extends State<WarehouseInventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WarehouseProvider>();
      provider.loadInventory();
      provider.loadLookupData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    final provider = context.read<WarehouseProvider>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String? selectedCategory = provider.filterCategory;
        String? selectedStatus = provider.filterStatus;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bộ lọc',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          provider.clearFilters();
                          _searchController.clear();
                          Navigator.pop(context);
                        },
                        child: const Text('Xoá bộ lọc'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Thể loại',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    hint: const Text('Tất cả thể loại'),
                    items: provider.categoryNames
                        .map((name) => DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setSheetState(() => selectedCategory = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Trạng thái',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    hint: const Text('Tất cả trạng thái'),
                    items: const [
                      DropdownMenuItem(
                          value: 'Có sẵn', child: Text('Có sẵn')),
                      DropdownMenuItem(
                          value: 'Đã hết', child: Text('Đã hết')),
                    ],
                    onChanged: (v) {
                      setSheetState(() => selectedStatus = v);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        provider.setFilterCategory(selectedCategory);
                        provider.setFilterStatus(selectedStatus);
                        Navigator.pop(context);
                      },
                      child: const Text('Áp dụng'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Map<String, dynamic> book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline,
                  color: Color(0xFFEF4444)),
            ),
            const SizedBox(width: 12),
            const Text('Xác nhận xoá',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Ngừng kinh doanh sách "${book['tensach']}"?\n'
          'Trạng thái sẽ chuyển về "Đã hết" và tồn kho về 0.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final result =
                  await ApiService().deleteBook(book['masach'] as int);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Đã xoá sách'),
                  backgroundColor: result['success'] == true
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              );
              context.read<WarehouseProvider>().loadInventory();
            },
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        titleSpacing: 12,
        title: const AdminAppBarTitle(
          icon: Icons.inventory_2_rounded,
          title: 'Quản lý tồn kho',
          subtitle: 'Danh sách sách & CRUD',
        ),
        actions: [
          IconButton(
            tooltip: 'Bộ lọc',
            icon: const Icon(Icons.filter_list, color: Color(0xFF2563EB)),
            onPressed: _showFilterSheet,
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BookFormScreen()),
          );
          if (!mounted) return;
          context.read<WarehouseProvider>().loadInventory();
        },
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm sách'),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên sách...',
                prefixIcon:
                    const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Color(0xFF9CA3AF)),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<WarehouseProvider>()
                              .searchInventory('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) {
                context.read<WarehouseProvider>().searchInventory(v);
                setState(() {}); // update clear icon
              },
            ),
          ),

          // List
          Expanded(
            child: Consumer<WarehouseProvider>(
              builder: (context, provider, child) {
                if (provider.isInventoryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.inventoryError != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(provider.inventoryError!,
                            style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: provider.loadInventory,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                final items = provider.filteredInventory;

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          provider.searchQuery.isNotEmpty
                              ? 'Không tìm thấy sách phù hợp'
                              : 'Chưa có sách nào trong kho',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: const Color(0xFF2563EB),
                  onRefresh: provider.loadInventory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final book = items[index];
                      final stock = book['soluongton'] ?? 0;
                      final status = book['trangthai'] ?? '';
                      final isOutOfStock = status == 'Đã hết';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Book Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 60,
                                  height: 80,
                                  color: const Color(0xFFF3F4F6),
                                  child: Image.network(
                                    '${ApiService.imageUrl}${book['hinhanh'] ?? 'default_book.jpg'}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.menu_book,
                                            color: Color(0xFF9CA3AF)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      book['tensach'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${book['tenTheLoai'] ?? ''} • ${book['tenTacGia'] ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          currencyFormat.format(
                                              book['giaban'] ?? 0),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isOutOfStock
                                                ? const Color(0xFFFEE2E2)
                                                : const Color(0xFFD1FAE5),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            isOutOfStock
                                                ? 'Hết hàng'
                                                : 'Tồn: $stock',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isOutOfStock
                                                  ? const Color(0xFFEF4444)
                                                  : const Color(0xFF10B981),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Actions
                              Column(
                                children: [
                                  InkWell(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              BookFormScreen(book: book),
                                        ),
                                      );
                                      if (!mounted) return;
                                      context
                                          .read<WarehouseProvider>()
                                          .loadInventory();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.edit_outlined,
                                          size: 18,
                                          color: Color(0xFF2563EB)),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    onTap: () => _confirmDelete(book),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Color(0xFFEF4444)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
