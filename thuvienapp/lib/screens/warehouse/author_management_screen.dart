import 'package:flutter/material.dart';
import '../../providers/api_service.dart';
import '../../widgets/admin/admin_app_bar_title.dart';

class AuthorManagementScreen extends StatefulWidget {
  const AuthorManagementScreen({super.key});

  @override
  State<AuthorManagementScreen> createState() => _AuthorManagementScreenState();
}

class _AuthorManagementScreenState extends State<AuthorManagementScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _authors = [];
  List<Map<String, dynamic>> _filteredAuthors = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAuthors();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAuthors() async {
    setState(() => _isLoading = true);
    final data = await _api.fetchAuthorsManagement();
    if (mounted) {
      setState(() {
        _authors = data;
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      _filteredAuthors = List.from(_authors);
    } else {
      _filteredAuthors = _authors
          .where((a) =>
              (a['tentg'] ?? '').toString().toLowerCase().contains(q) ||
              (a['quoctich'] ?? '').toString().toLowerCase().contains(q))
          .toList();
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
          icon: Icons.person_search_rounded,
          title: 'Quản lý Tác giả',
          subtitle: 'Thêm, sửa, xóa tác giả',
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAuthorDialog(),
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Thêm tác giả',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc quốc tịch...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (_) => setState(() => _applyFilter()),
            ),
          ),

          // Author list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF2563EB)))
                : _filteredAuthors.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                          Icon(Icons.person_off_rounded,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('Không tìm thấy tác giả nào',
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 15)),
                        ]))
                    : RefreshIndicator(
                        onRefresh: _loadAuthors,
                        color: const Color(0xFF2563EB),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredAuthors.length,
                          itemBuilder: (_, i) =>
                              _authorCard(_filteredAuthors[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _authorCard(Map<String, dynamic> author) {
    final tentg = author['tentg'] ?? '';
    final quoctich = author['quoctich'] ?? '';
    final mota = author['mota'] ?? '';
    final soSach = author['soSach'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              tentg.isNotEmpty ? tentg[0].toUpperCase() : '?',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB)),
            ),
          ),
        ),
        title: Text(tentg,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF1F2937))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (quoctich.isNotEmpty)
              Row(children: [
                const Icon(Icons.flag_rounded,
                    size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Text(quoctich,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
              ]),
            if (mota.isNotEmpty)
              Text(mota,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9CA3AF))),
            Row(children: [
              const Icon(Icons.menu_book_rounded,
                  size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text('$soSach đầu sách',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500)),
            ]),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xFF9CA3AF)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (v) {
            if (v == 'edit') _showAuthorDialog(author: author);
            if (v == 'delete') _confirmDelete(author);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_rounded,
                      size: 18, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Text('Chỉnh sửa'),
                ])),
            const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_rounded,
                      size: 18, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('Xóa', style: TextStyle(color: Colors.redAccent)),
                ])),
          ],
        ),
      ),
    );
  }

  void _showAuthorDialog({Map<String, dynamic>? author}) {
    final isEdit = author != null;
    final nameCtrl =
        TextEditingController(text: isEdit ? author['tentg'] ?? '' : '');
    final countryCtrl =
        TextEditingController(text: isEdit ? author['quoctich'] ?? '' : '');
    final descCtrl =
        TextEditingController(text: isEdit ? author['mota'] ?? '' : '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                        isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
                        color: const Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 12),
                  Text(isEdit ? 'Sửa tác giả' : 'Thêm tác giả mới',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Tên tác giả *',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: countryCtrl,
                  decoration: InputDecoration(
                    labelText: 'Quốc tịch',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.flag_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          isSaving ? null : () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (nameCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Tên tác giả không được để trống!')));
                                return;
                              }
                              setDialogState(() => isSaving = true);

                              final data = {
                                'tenTg': nameCtrl.text.trim(),
                                'quocTich': countryCtrl.text.trim(),
                                'moTa': descCtrl.text.trim(),
                              };

                              final result = isEdit
                                  ? await _api.updateAuthor(
                                      author['matg'], data)
                                  : await _api.addAuthor(data);

                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      result['message'] ?? 'Thành công'),
                                  backgroundColor:
                                      result['success'] == true
                                          ? Colors.green
                                          : Colors.red,
                                ));
                                _loadAuthors();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(isEdit ? 'Cập nhật' : 'Thêm mới'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> author) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444)),
          ),
          const SizedBox(width: 12),
          const Text('Xóa tác giả',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Text(
            'Bạn có chắc muốn xóa tác giả "${author['tentg']}"?\n\nLưu ý: Không thể xóa nếu tác giả đang có sách liên kết.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _api.deleteAuthor(author['matg']);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result['message'] ?? 'Thành công'),
                  backgroundColor:
                      result['success'] == true ? Colors.green : Colors.red,
                ));
                _loadAuthors();
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
