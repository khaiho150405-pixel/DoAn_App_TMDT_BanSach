import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/tin_nhan_ho_tro.dart';
import '../../providers/api_service.dart';
import '../../providers/user_provider.dart';

class SaleSupportChatScreen extends StatefulWidget {
  final Map<String, dynamic> ticket;
  const SaleSupportChatScreen({super.key, required this.ticket});

  @override
  State<SaleSupportChatScreen> createState() => _SaleSupportChatScreenState();
}

class _SaleSupportChatScreenState extends State<SaleSupportChatScreen>
    with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  final List<TinNhanHoTro> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollingTimer;
  String _currentStatus = 'Chờ trả lời';

  int get _maHoiDap => widget.ticket['mahoidap'] ?? 0;
  String get _tenKH => widget.ticket['tenKhachHang'] ?? 'Khách hàng';
  String get _tieuDe =>
      widget.ticket['tieude'] ?? widget.ticket['cauhoi'] ?? 'Hỗ trợ';

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.ticket['trangthai'] ?? 'Chờ trả lời';
    _loadMessages(initial: true);
    _pollingTimer = Timer.periodic(
        const Duration(seconds: 4), (_) => _loadMessages(initial: false));
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _scrollController.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({required bool initial}) async {
    if (initial) setState(() => _isLoading = true);

    final messages = await _api.fetchSupportMessages(_maHoiDap);

    if (mounted) {
      bool hasNew = messages.length != _messages.length;

      // Cập nhật trạng thái dựa trên tin nhắn cuối
      if (messages.isNotEmpty) {
        final lastMsg = messages.last;
        setState(() {
          _currentStatus = lastMsg.nguoiGui == 'KhachHang'
              ? 'Chờ trả lời'
              : 'Đã trả lời';
        });
      }

      setState(() {
        _messages.clear();
        _messages.addAll(messages);
        _isLoading = false;
      });
      if (hasNew || initial) _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    final user = Provider.of<UserProvider>(context, listen: false).user;
    _messageCtrl.clear();
    setState(() => _isSending = true);

    final response = await _api.sendSupportMessage(
      _maHoiDap,
      'NhanVien',
      null,
      user?.realId,
      text,
    );

    if (mounted) {
      setState(() {
        _isSending = false;
        _currentStatus = 'Đã trả lời';
      });
      if (response['success'] == true) {
        _loadMessages(initial: false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi gửi tin nhắn. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Chờ trả lời':
        return const Color(0xFFF59E0B);
      case 'Đã trả lời':
        return const Color(0xFF10B981);
      case 'Đã đóng':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6B7280);
    }
  }

  bool _shouldShowDateSeparator(int index) {
    if (index == 0) return true;
    final current = _messages[index].thoiGian;
    final previous = _messages[index - 1].thoiGian;
    return current.year != previous.year ||
        current.month != previous.month ||
        current.day != previous.day;
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Hôm nay';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Hôm qua';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(_currentStatus);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            // Avatar khách hàng
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                _tenKH.isNotEmpty ? _tenKH[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tenKH,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _currentStatus,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadMessages(initial: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Messages Area
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF2563EB)))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có cuộc hội thoại nào.',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = _messages[i];
                          final isStaff = msg.nguoiGui == 'NhanVien';
                          return Column(
                            children: [
                              if (_shouldShowDateSeparator(i))
                                _buildDateSeparator(msg.thoiGian),
                              _buildMessageBubble(msg, isStaff),
                            ],
                          );
                        },
                      ),
          ),

          // Input Bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatDateSeparator(date),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 0.5)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(TinNhanHoTro msg, bool isStaff) {
    final bubbleColor =
        isStaff ? const Color(0xFF2563EB) : Colors.white;
    final textColor =
        isStaff ? Colors.white : const Color(0xFF1E293B);
    final formattedTime = DateFormat('HH:mm').format(msg.thoiGian);

    return Align(
      alignment: isStaff ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar bên trái cho khách hàng
            if (!isStaff) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF4A90D9).withOpacity(0.15),
                child: Text(
                  _tenKH.isNotEmpty ? _tenKH[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A90D9),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isStaff ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isStaff)
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 4),
                      child: Text(
                        _tenKH,
                        style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft:
                            isStaff ? const Radius.circular(16) : Radius.zero,
                        bottomRight:
                            isStaff ? Radius.zero : const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Text(
                      msg.noiDung,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 6, right: 6),
                    child: Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Avatar bên phải cho nhân viên
            if (isStaff) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF2563EB).withOpacity(0.15),
                child: const Icon(
                  Icons.support_agent,
                  size: 16,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageCtrl,
                  maxLines: null,
                  style: const TextStyle(fontSize: 14.5),
                  decoration: const InputDecoration(
                    hintText: 'Nhập câu trả lời hỗ trợ...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF2563EB),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                      onPressed: _sendMessage,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
