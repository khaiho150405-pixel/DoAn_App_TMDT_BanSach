import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/ho_dap.dart';
import '../../models/tin_nhan_ho_tro.dart';
import '../../models/user.dart';
import '../../providers/api_service.dart';

class SupportChatScreen extends StatefulWidget {
  final HoiDap ticket;
  final User user;
  const SupportChatScreen({super.key, required this.ticket, required this.user});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final ApiService _api = ApiService();
  final List<TinNhanHoTro> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageCtrl = TextEditingController();
  
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages(initial: true);
    // Start periodic polling every 4 seconds to fetch new messages automatically
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) => _loadMessages(initial: false));
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _scrollController.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({required bool initial}) async {
    if (initial) {
      setState(() => _isLoading = true);
    }
    
    final messages = await _api.fetchSupportMessages(widget.ticket.maHoiDap);
    
    if (mounted) {
      bool hasNewMessages = messages.length != _messages.length;
      
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
        _isLoading = false;
      });

      if (hasNewMessages || initial) {
        // Scroll to the bottom when new messages arrive or on initial load
        _scrollToBottom();
      }
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

    _messageCtrl.clear();
    setState(() => _isSending = true);

    final response = await _api.sendSupportMessage(
      widget.ticket.maHoiDap,
      'KhachHang',
      widget.user.realId,
      null,
      text,
    );

    if (mounted) {
      setState(() => _isSending = false);
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
      case 'Đang xử lý':
        return const Color(0xFF2563EB);
      case 'Đã trả lời':
        return const Color(0xFF10B981);
      case 'Đã đóng':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.ticket.trangThai);
    final isClosed = widget.ticket.trangThai == 'Đã đóng';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.ticket.tieuDe,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                Text(
                  '${widget.ticket.loaiHoTro} • ${widget.ticket.trangThai}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                : _messages.isEmpty
                    ? _buildChatEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = _messages[i];
                          final isCustomer = msg.nguoiGui == 'KhachHang';
                          return _buildMessageBubble(msg, isCustomer);
                        },
                      ),
          ),
          
          // Closed Ticket Banner or Input Box
          if (isClosed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade200,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_rounded, color: Colors.grey, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Yêu cầu hỗ trợ này đã được đóng lại.',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            )
          else
            _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildChatEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Chưa có cuộc hội thoại nào.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(TinNhanHoTro msg, bool isCustomer) {
    final bubbleColor = isCustomer ? const Color(0xFF2563EB) : Colors.white;
    final textColor = isCustomer ? Colors.white : const Color(0xFF1E293B);
    final formattedTime = DateFormat('HH:mm').format(msg.thoiGian);

    return Align(
      alignment: isCustomer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isCustomer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender name (only for staff, customer is obvious)
            if (!isCustomer)
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 4),
                child: Text(
                  'Nhân viên hỗ trợ',
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                ),
              ),
            
            // Message Body
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isCustomer ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isCustomer ? Radius.zero : const Radius.circular(16),
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
            
            // Message Time
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
            // Input field
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
                    hintText: 'Nhập tin nhắn hỗ trợ...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF2563EB),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: _sendMessage,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
