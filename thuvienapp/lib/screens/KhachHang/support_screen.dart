import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/ho_dap.dart';
import '../../models/user.dart';
import '../../providers/api_service.dart';
import 'create_support_screen.dart';
import 'support_chat_screen.dart';

class SupportScreen extends StatefulWidget {
  final User user;
  const SupportScreen({super.key, required this.user});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final ApiService _api = ApiService();
  List<HoiDap> _tickets = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    final tickets = await _api.fetchSupportTickets(widget.user.realId);
    if (mounted) {
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    }
  }

  List<HoiDap> get _filteredTickets {
    return _tickets.where((ticket) {
      final matchesSearch = ticket.tieuDe.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ticket.noiDung.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ticket.loaiHoTro.toLowerCase().contains(_searchQuery.toLowerCase());
      
      if (_selectedFilter == 'Tất cả') {
        return matchesSearch;
      }
      return matchesSearch && ticket.trangThai == _selectedFilter;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Chờ trả lời':
        return const Color(0xFFF59E0B); // Amber
      case 'Đang xử lý':
        return const Color(0xFF2563EB); // Blue
      case 'Đã trả lời':
        return const Color(0xFF10B981); // Emerald
      case 'Đã đóng':
        return const Color(0xFF6B7280); // Gray
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Chờ trả lời':
        return Icons.hourglass_empty_rounded;
      case 'Đang xử lý':
        return Icons.autorenew;
      case 'Đã trả lời':
        return Icons.mark_chat_read_rounded;
      case 'Đã đóng':
        return Icons.cancel_presentation_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Map<String, Color> _getCategoryStyles(String category) {
    final normalized = category.toLowerCase();
    
    if (normalized.contains('đơn hàng') || normalized.contains('don hang') || normalized.contains('sự cố')) {
      return {
        'bgColor': const Color(0xFFEFF6FF), // Light blue (50)
        'textColor': const Color(0xFF1D4ED8), // Dark blue (700)
      };
    } else if (normalized.contains('thanh toán') || normalized.contains('thanh toan')) {
      return {
        'bgColor': const Color(0xFFECFDF5), // Light emerald (50)
        'textColor': const Color(0xFF047857), // Dark emerald (700)
      };
    } else if (normalized.contains('hoàn tiền') || normalized.contains('hoan tien') || normalized.contains('khiếu nại') || normalized.contains('khieu nai') || normalized.contains('góp ý') || normalized.contains('gop y')) {
      return {
        'bgColor': const Color(0xFFFEF2F2), // Light red (50)
        'textColor': const Color(0xFFB91C1C), // Dark red (700)
      };
    } else if (normalized.contains('tài khoản') || normalized.contains('tai khoan') || normalized.contains('tư vấn') || normalized.contains('tu van')) {
      return {
        'bgColor': const Color(0xFFF5F3FF), // Light purple (50)
        'textColor': const Color(0xFF6D28D9), // Dark purple (700)
      };
    } else {
      // Khác / Hỗ trợ khác
      return {
        'bgColor': const Color(0xFFF3F4F6), // Light gray (100)
        'textColor': const Color(0xFF374151), // Dark gray (700)
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Hỏi đáp / Hỗ trợ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Input
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm yêu cầu hỗ trợ...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB)),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Status Filter Badges
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      'Tất cả',
                      'Chờ trả lời',
                      'Đang xử lý',
                      'Đã trả lời',
                      'Đã đóng'
                    ].map((status) {
                      final isSelected = _selectedFilter == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            status,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF2563EB),
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF334155),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() => _selectedFilter = status);
                            }
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300,
                            width: 1,
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Support Ticket List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTickets,
              color: const Color(0xFF2563EB),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                  : _filteredTickets.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTickets.length,
                          itemBuilder: (ctx, i) {
                            final ticket = _filteredTickets[i];
                            return _buildTicketCard(ticket);
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('Tạo hỗ trợ mới', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateSupportScreen(user: widget.user),
            ),
          );
          if (result == true) {
            _loadTickets();
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                size: 80,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Bạn chưa có yêu cầu hỗ trợ nào',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'Tất cả'
                  ? 'Không tìm thấy yêu cầu hỗ trợ nào khớp với bộ lọc.'
                  : 'Hãy bấm nút phía dưới để tạo yêu cầu hỗ trợ mới. Chúng tôi sẽ giải đáp bạn trong thời gian sớm nhất!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isNotEmpty || _selectedFilter != 'Tất cả')
              OutlinedButton.icon(
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Xóa bộ lọc'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedFilter = 'Tất cả';
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(HoiDap ticket) {
    final statusColor = _getStatusColor(ticket.trangThai);
    final statusIcon = _getStatusIcon(ticket.trangThai);
    final formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(ticket.capNhatCuoi);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SupportChatScreen(ticket: ticket, user: widget.user),
              ),
            );
            _loadTickets(); // Reload when returning from chat
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag & Time Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    (() {
                      final styles = _getCategoryStyles(ticket.loaiHoTro);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: styles['bgColor'],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ticket.loaiHoTro,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: styles['textColor'],
                          ),
                        ),
                      );
                    })(),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Title
                Text(
                  ticket.tieuDe,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Last Message Snippet
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ticket.tinNhanCuoi,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 0.8),
                
                // Footer Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          ticket.trangThai,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Trò chuyện ngay',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2563EB).withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: const Color(0xFF2563EB).withOpacity(0.9),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
