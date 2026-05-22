import 'package:flutter/material.dart';
import '../../providers/api_service.dart';
import '../../widgets/admin/admin_app_bar_title.dart';

class PublisherManagementScreen extends StatefulWidget {
  const PublisherManagementScreen({super.key});

  @override
  State<PublisherManagementScreen> createState() =>
      _PublisherManagementScreenState();
}

class _PublisherManagementScreenState extends State<PublisherManagementScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _publishers = [];
  List<Map<String, dynamic>> _filteredPublishers = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPublishers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPublishers() async {
    setState(() => _isLoading = true);
    final data = await _api.fetchPublishersManagement();
    if (mounted) {
      setState(() {
        _publishers = data;
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      _filteredPublishers = List.from(_publishers);
    } else {
      _filteredPublishers = _publishers
          .where((p) =>
              (p['tennxb'] ?? '').toString().toLowerCase().contains(q) ||
              (p['diachi'] ?? '').toString().toLowerCase().contains(q))
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
          icon: Icons.business_rounded,
          title: 'Quản lý Nhà xuất bản',
          subtitle: 'Thêm, sửa, xóa NXB',
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPublisherDialog(),
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Thêm NXB',
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
                hintText: 'Tìm theo tên hoặc địa chỉ...',
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

          // Publisher list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF2563EB)))
                : _filteredPublishers.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                          Icon(Icons.business_outlined,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('Không tìm thấy NXB nào',
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 15)),
                        ]))
                    : RefreshIndicator(
                        onRefresh: _loadPublishers,
                        color: const Color(0xFF2563EB),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredPublishers.length,
                          itemBuilder: (_, i) =>
                              _publisherCard(_filteredPublishers[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _publisherCard(Map<String, dynamic> pub) {
    final tennxb = pub['tennxb'] ?? '';
    final diachi = pub['diachi'] ?? '';
    final sdt = pub['sdt'] ?? '';
    final soSach = pub['soSach'] ?? 0;

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
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.business_rounded,
                color: Color(0xFF16A34A), size: 24),
          ),
        ),
        title: Text(tennxb,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF1F2937))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (diachi.isNotEmpty)
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(diachi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
                ),
              ]),
            if (sdt.isNotEmpty)
              Row(children: [
                const Icon(Icons.phone_outlined,
                    size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Text(sdt,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
              ]),
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
            if (v == 'edit') _showPublisherDialog(publisher: pub);
            if (v == 'delete') _confirmDelete(pub);
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

  void _showPublisherDialog({Map<String, dynamic>? publisher}) {
    final isEdit = publisher != null;
    final nameCtrl = TextEditingController(
        text: isEdit ? publisher['tennxb'] ?? '' : '');
    final addressCtrl = TextEditingController(
        text: isEdit ? publisher['diachi'] ?? '' : '');
    final phoneCtrl = TextEditingController(
        text: isEdit ? publisher['sdt'] ?? '' : '');
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
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                        isEdit
                            ? Icons.edit_rounded
                            : Icons.add_business_rounded,
                        color: const Color(0xFF16A34A)),
                  ),
                  const SizedBox(width: 12),
                  Text(isEdit ? 'Sửa nhà xuất bản' : 'Thêm NXB mới',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Tên nhà xuất bản *',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.business_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.phone_outlined),
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
                                            'Tên NXB không được để trống!')));
                                return;
                              }
                              setDialogState(() => isSaving = true);

                              final data = {
                                'tenNxb': nameCtrl.text.trim(),
                                'diaChi': addressCtrl.text.trim(),
                                'sdt': phoneCtrl.text.trim(),
                              };

                              final result = isEdit
                                  ? await _api.updatePublisher(
                                      publisher['manxb'], data)
                                  : await _api.addPublisher(data);

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
                                _loadPublishers();
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

  void _confirmDelete(Map<String, dynamic> pub) {
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
          const Text('Xóa nhà xuất bản',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Text(
            'Bạn có chắc muốn xóa NXB "${pub['tennxb']}"?\n\nLưu ý: Không thể xóa nếu NXB đang có sách liên kết.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _api.deletePublisher(pub['manxb']);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result['message'] ?? 'Thành công'),
                  backgroundColor:
                      result['success'] == true ? Colors.green : Colors.red,
                ));
                _loadPublishers();
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
