import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/api_service.dart';
import '../../providers/user_provider.dart';

class HoidapScreen extends StatefulWidget {
  const HoidapScreen({super.key});
  @override
  State<HoidapScreen> createState() => _HoidapScreenState();
}

class _HoidapScreenState extends State<HoidapScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabCtrl;

  List<Map<String, dynamic>> _pendingQuestions = [];
  List<Map<String, dynamic>> _allQuestions = [];
  bool _isLoadingPending = true;
  bool _isLoadingAll = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    _loadPending();
    _loadAll();
  }

  Future<void> _loadPending() async {
    setState(() => _isLoadingPending = true);
    final data = await _api.fetchPendingQuestions();
    if (mounted)
      setState(() {
        _pendingQuestions = data;
        _isLoadingPending = false;
      });
  }

  Future<void> _loadAll() async {
    setState(() => _isLoadingAll = true);
    final data = await _api.fetchAllQuestions();
    if (mounted)
      setState(() {
        _allQuestions = data;
        _isLoadingAll = false;
      });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Hỗ trợ Khách hàng',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.pending_actions_rounded, size: 18),
              const SizedBox(width: 6),
              const Text('Chờ trả lời'),
              if (_pendingQuestions.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('${_pendingQuestions.length}',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ])),
            const Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.history_rounded, size: 18),
              SizedBox(width: 6),
              Text('Tất cả'),
            ])),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildQuestionList(_pendingQuestions, _isLoadingPending,
              isPending: true),
          _buildQuestionList(_allQuestions, _isLoadingAll),
        ],
      ),
    );
  }

  Widget _buildQuestionList(
      List<Map<String, dynamic>> questions, bool isLoading,
      {bool isPending = false}) {
    if (isLoading)
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)));

    if (questions.isEmpty) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(
            isPending
                ? Icons.check_circle_outline_rounded
                : Icons.forum_outlined,
            size: 80,
            color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(
            isPending
                ? 'Không có câu hỏi nào chờ trả lời'
                : 'Chưa có câu hỏi nào',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
      ]));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF2563EB),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        itemBuilder: (ctx, i) => _questionCard(questions[i], isPending),
      ),
    );
  }

  Widget _questionCard(Map<String, dynamic> q, bool isPending) {
    final tenKH = q['tenKhachHang'] ?? 'Khách hàng';
    final cauHoi = q['cauhoi'] ?? '';
    final traLoi = q['traloi'];
    final trangThai = q['trangthai'] ?? 'Chờ trả lời';
    final thoiGianHoi = q['thoigianhoi'] != null
        ? DateFormat('dd/MM/yyyy HH:mm')
            .format(DateTime.parse(q['thoigianhoi']))
        : '';
    final thoiGianTraLoi = q['thoigiantraloi'] != null
        ? DateFormat('dd/MM/yyyy HH:mm')
            .format(DateTime.parse(q['thoigiantraloi']))
        : '';
    final isAnswered = trangThai == 'Đã trả lời';

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
        border: isPending
            ? Border.all(
                color: const Color(0xFFE8913A).withOpacity(0.3), width: 1)
            : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color:
                (isAnswered ? const Color(0xFF27AE60) : const Color(0xFFE8913A))
                    .withOpacity(0.08),
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF4A90D9).withOpacity(0.15),
              child: Text(tenKH.isNotEmpty ? tenKH[0].toUpperCase() : '?',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A90D9),
                      fontSize: 14)),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(tenKH,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(thoiGianHoi,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isAnswered
                        ? const Color(0xFF27AE60)
                        : const Color(0xFFE8913A))
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(trangThai,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isAnswered
                          ? const Color(0xFF27AE60)
                          : const Color(0xFFE8913A))),
            ),
          ]),
        ),
        // Question
        Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.help_outline_rounded,
                  size: 18, color: const Color(0xFFE8913A).withOpacity(0.7)),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(cauHoi,
                      style: const TextStyle(fontSize: 14, height: 1.4))),
            ]),
            if (traLoi != null && traLoi.toString().isNotEmpty) ...[
              const Divider(height: 20),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 18, color: const Color(0xFF27AE60).withOpacity(0.7)),
                const SizedBox(width: 8),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(traLoi,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF27AE60),
                              height: 1.4)),
                      if (thoiGianTraLoi.isNotEmpty)
                        Text('Trả lời lúc: $thoiGianTraLoi',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                    ])),
              ]),
            ],
            if (isPending) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.reply_rounded, size: 18),
                  label: const Text('Trả lời câu hỏi',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _showReplySheet(q),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  void _showReplySheet(Map<String, dynamic> q) {
    final replyCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Row(children: [
              const Icon(Icons.reply_rounded, color: Color(0xFF2563EB)),
              const SizedBox(width: 10),
              const Expanded(
                  child: Text('Trả lời câu hỏi',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFFE8913A).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12)),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.help_outline,
                    size: 16, color: Color(0xFFE8913A)),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(q['cauhoi'] ?? '',
                        style: const TextStyle(fontSize: 13))),
              ]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: replyCtrl,
              maxLines: 4,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Nhập câu trả lời cho khách hàng...',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Color(0xFF2563EB), width: 2)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send_rounded),
                label: const Text('GỬI TRẢ LỜI',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  if (replyCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Vui lòng nhập câu trả lời')));
                    return;
                  }
                  final user =
                      Provider.of<UserProvider>(context, listen: false).user;
                  Navigator.pop(ctx);
                  final result = await _api.replyQuestion(
                      q['mahoidap'], replyCtrl.text.trim(), user?.realId ?? 0);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(result['message'] ?? 'Đã trả lời'),
                      backgroundColor:
                          result['success'] == true ? Colors.green : Colors.red,
                    ));
                    _loadData();
                  }
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
