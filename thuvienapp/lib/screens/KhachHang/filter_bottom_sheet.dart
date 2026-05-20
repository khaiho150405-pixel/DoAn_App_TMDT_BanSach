import 'package:flutter/material.dart';
import '../../models/filter_model.dart';
import '../../providers/api_service.dart';
import '../../theme/app_theme.dart';

class FilterBottomSheet extends StatefulWidget {
  final BookFilterModel currentFilter;

  const FilterBottomSheet({super.key, required this.currentFilter});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _selectedAuthor;
  String? _selectedPublisher;
  double? _minPrice;
  double? _maxPrice;

  List<String> _authors = [];
  List<String> _publishers = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _priceRanges = [
    {'label': 'Dưới 50.000đ', 'min': 0.0, 'max': 50000.0},
    {'label': '50.000đ - 100.000đ', 'min': 50000.0, 'max': 100000.0},
    {'label': '100.000đ - 200.000đ', 'min': 100000.0, 'max': 200000.0},
    {'label': 'Trên 200.000đ', 'min': 200000.0, 'max': null},
  ];

  @override
  void initState() {
    super.initState();
    _selectedAuthor = widget.currentFilter.author;
    _selectedPublisher = widget.currentFilter.publisher;
    _minPrice = widget.currentFilter.minPrice;
    _maxPrice = widget.currentFilter.maxPrice;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final api = ApiService();
      final authors = await api.fetchAuthors();
      final publishers = await api.fetchPublishers();

      if (mounted) {
        setState(() {
          _authors = authors;
          _publishers = publishers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter() {
    final filter = BookFilterModel(
      author: _selectedAuthor,
      publisher: _selectedPublisher,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
    );
    Navigator.pop(context, filter);
  }

  void _resetFilter() {
    setState(() {
      _selectedAuthor = null;
      _selectedPublisher = null;
      _minPrice = null;
      _maxPrice = null;
    });
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryBlue,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primaryBlue,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Lọc Sách', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const Divider(),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        // Khoảng giá
                        const Text('Mức giá', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 12,
                          children: _priceRanges.map((range) {
                            final isSelected = _minPrice == range['min'] && _maxPrice == range['max'];
                            return _buildChip(
                              range['label'],
                              isSelected,
                              () {
                                setState(() {
                                  if (isSelected) {
                                    _minPrice = null;
                                    _maxPrice = null;
                                  } else {
                                    _minPrice = range['min'];
                                    _maxPrice = range['max'];
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Tác giả
                        const Text('Tác giả', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        if (_authors.isEmpty)
                          const Text('Không có dữ liệu', style: TextStyle(color: Colors.grey))
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 12,
                            children: _authors.map((author) {
                              final isSelected = _selectedAuthor == author;
                              return _buildChip(
                                author,
                                isSelected,
                                () {
                                  setState(() {
                                    _selectedAuthor = isSelected ? null : author;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 24),

                        // Nhà xuất bản
                        const Text('Nhà xuất bản', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        if (_publishers.isEmpty)
                          const Text('Không có dữ liệu', style: TextStyle(color: Colors.grey))
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 12,
                            children: _publishers.map((pub) {
                              final isSelected = _selectedPublisher == pub;
                              return _buildChip(
                                pub,
                                isSelected,
                                () {
                                  setState(() {
                                    _selectedPublisher = isSelected ? null : pub;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          ),

          // Nút hành động
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilter,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: const BorderSide(color: AppColors.primaryBlue),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Đặt lại', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Áp dụng', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
