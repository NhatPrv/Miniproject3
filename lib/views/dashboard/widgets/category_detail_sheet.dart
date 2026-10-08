import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/category_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/transaction_model.dart';

class CategoryDetailSheet extends StatefulWidget {
  final String categoryKey;
  final VoidCallback onDataChanged;

  const CategoryDetailSheet({
    super.key,
    required this.categoryKey,
    required this.onDataChanged,
  });

  static void show(BuildContext context, String categoryKey, VoidCallback onDataChanged) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryDetailSheet(
        categoryKey: categoryKey,
        onDataChanged: onDataChanged,
      ),
    );
  }

  @override
  State<CategoryDetailSheet> createState() => _CategoryDetailSheetState();
}

class _CategoryDetailSheetState extends State<CategoryDetailSheet> {
  List<TransactionModel> _items = [];
  bool _isLoading = true;
  double _categoryTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCategoryTransactions();
  }

  Future<void> _loadCategoryTransactions() async {
    setState(() => _isLoading = true);
    final list = await DatabaseHelper.instance.getTransactionsByCategory(widget.categoryKey);
    double total = 0.0;
    for (final item in list) {
      total += item.amount;
    }

    if (mounted) {
      setState(() {
        _items = list;
        _categoryTotal = total;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    widget.onDataChanged();
    await _loadCategoryTransactions();
  }

  void _showReceiptImageModal(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = CategoryConstants.getMetadataByKey(widget.categoryKey);

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: meta.color.withValues(alpha: 0.2),
                  child: Icon(meta.icon, color: meta.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meta.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_items.length} hóa đơn trong danh mục',
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Tổng tiền danh mục
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng chi danh mục:',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  CurrencyFormatter.formatVND(_categoryTotal),
                  style: TextStyle(
                    color: meta.color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 20),

          // Danh sách các hóa đơn trong danh mục
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(meta.icon, size: 48, color: Colors.white24),
                            const SizedBox(height: 12),
                            Text(
                              'Không có hóa đơn nào thuộc danh mục ${meta.key}',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final hasImage = item.imagePath != null &&
                              File(item.imagePath!).existsSync();

                          return Dismissible(
                            key: Key('cat_${item.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) {
                              if (item.id != null) {
                                _deleteItem(item.id!);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Row(
                                children: [
                                  // Ảnh thumbnail nếu có
                                  if (hasImage)
                                    GestureDetector(
                                      onTap: () => _showReceiptImageModal(item.imagePath!),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(item.imagePath!),
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  else
                                    CircleAvatar(
                                      backgroundColor: meta.color.withValues(alpha: 0.15),
                                      child: Icon(meta.icon, color: meta.color, size: 20),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.merchant,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              item.date,
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (hasImage) ...[
                                              const SizedBox(width: 6),
                                              const Icon(
                                                Icons.image,
                                                size: 14,
                                                color: Color(0xFF10B981),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.formatVND(item.amount),
                                    style: const TextStyle(
                                      color: Color(0xFF34D399),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
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
