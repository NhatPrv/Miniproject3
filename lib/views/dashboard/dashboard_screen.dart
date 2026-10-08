import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/category_constants.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/transaction_model.dart';
import '../camera/camera_screen.dart';
import '../charts/animated_bar_chart.dart';
import '../charts/animated_donut_chart.dart';
import 'widgets/category_detail_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _totalSpending = 0.0;
  Map<String, double> _categoryDistribution = {};
  Map<String, double> _weeklySpending = {};
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  int _selectedChartTab = 0; // 0: Donut (Danh mục), 1: Bar (Theo tuần)
  String? _selectedCategoryFilter; // null = Tất cả

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final total = await DatabaseHelper.instance.getTotalSpending();
      final distribution = await DatabaseHelper.instance.getCategoryDistribution();
      final weekly = await DatabaseHelper.instance.getWeeklySpending();
      final list = await DatabaseHelper.instance.getAllTransactions();

      if (mounted) {
        setState(() {
          _totalSpending = total;
          _categoryDistribution = distribution;
          _weeklySpending = weekly;
          _transactions = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu Dashboard: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteTransaction(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    _loadDashboardData();
  }

  void _openCategoryDetail(String categoryKey) {
    CategoryDetailSheet.show(context, categoryKey, _loadDashboardData);
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
    // Lọc giao dịch theo danh mục nếu có filter
    final displayedTransactions = _selectedCategoryFilter == null
        ? _transactions
        : _transactions
            .where((t) => t.category.toLowerCase() == _selectedCategoryFilter!.toLowerCase())
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Color(0xFF10B981), size: 24),
            SizedBox(width: 8),
            Text(
              'OCR Expense Tracker',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: const Color(0xFF10B981),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card 1: Tổng chi tiêu
                    _buildTotalBalanceCard(),
                    const SizedBox(height: 16),

                    // Card 2: Trực quan hóa Biểu đồ CustomPainter
                    _buildChartsCard(),
                    const SizedBox(height: 20),

                    // Thanh lọc danh mục chi tiêu (Category Filter Chips)
                    _buildCategoryFilterBar(),
                    const SizedBox(height: 14),

                    // Tiêu đề danh sách giao dịch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedCategoryFilter == null
                              ? 'Lịch Sử Giao Dịch'
                              : 'Hóa Đơn: ${CategoryConstants.getMetadataByKey(_selectedCategoryFilter!).displayName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${displayedTransactions.length} mục',
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Card 3: Danh sách giao dịch
                    if (displayedTransactions.isEmpty)
                      _buildEmptyState()
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayedTransactions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = displayedTransactions[index];
                          return _buildTransactionItem(item);
                        },
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text(
          'Quét Hóa Đơn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CameraScreen()),
          );
          _loadDashboardData();
        },
      ),
    );
  }

  Widget _buildTotalBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng chi tiêu tích lũy',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Icon(Icons.trending_up, color: Color(0xFF10B981), size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatVND(_totalSpending),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Tự động đồng bộ Offline qua SQLite',
              style: TextStyle(color: Color(0xFF34D399), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          // Segment switch giữa Donut và Bar
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedChartTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedChartTab == 0
                          ? const Color(0xFF10B981)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Phân Bổ Danh Mục',
                      style: TextStyle(
                        color: _selectedChartTab == 0 ? Colors.white : Colors.white60,
                        fontWeight: _selectedChartTab == 0 ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedChartTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedChartTab == 1
                          ? const Color(0xFF10B981)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Chi Tiêu Theo Tuần',
                      style: TextStyle(
                        color: _selectedChartTab == 1 ? Colors.white : Colors.white60,
                        fontWeight: _selectedChartTab == 1 ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hiển thị biểu đồ tương ứng
          if (_selectedChartTab == 0)
            AnimatedDonutChart(
              categoryDistribution: _categoryDistribution,
              totalAmount: _totalSpending,
              onCategoryTap: (catKey) => _openCategoryDetail(catKey),
            )
          else
            AnimatedBarChart(
              weeklySpending: _weeklySpending,
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Chip "Tất cả"
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: _selectedCategoryFilter == null,
              label: const Text('Tất cả'),
              selectedColor: const Color(0xFF10B981),
              backgroundColor: const Color(0xFF1E293B),
              labelStyle: TextStyle(
                color: _selectedCategoryFilter == null ? Colors.white : Colors.white70,
                fontWeight: _selectedCategoryFilter == null ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              onSelected: (_) => setState(() => _selectedCategoryFilter = null),
            ),
          ),
          // Các chip danh mục
          ...CategoryConstants.categoryKeys.map((catKey) {
            final isSelected = _selectedCategoryFilter == catKey;
            final meta = CategoryConstants.getMetadataByKey(catKey);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                avatar: Icon(meta.icon, size: 14, color: isSelected ? Colors.white : meta.color),
                label: Text(meta.displayName.split(' ').first),
                selectedColor: meta.color,
                backgroundColor: const Color(0xFF1E293B),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedCategoryFilter = selected ? catKey : null;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel item) {
    final meta = CategoryConstants.getMetadataByKey(item.category);
    final hasImage = item.imagePath != null && File(item.imagePath!).existsSync();

    return Dismissible(
      key: Key(item.id.toString()),
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
      onDismissed: (direction) {
        if (item.id != null) {
          _deleteTransaction(item.id!);
        }
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openCategoryDetail(item.category),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              // Ảnh thumbnail nếu có ảnh hóa đơn chụp thực tế
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
                  backgroundColor: meta.color.withValues(alpha: 0.2),
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
                          '${item.date} • ${meta.displayName.split(' ').first}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        if (hasImage) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.image, size: 14, color: Color(0xFF10B981)),
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.receipt_outlined, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text(
              _selectedCategoryFilter == null
                  ? 'Chưa có giao dịch nào được ghi nhận'
                  : 'Không có giao dịch nào trong danh mục $_selectedCategoryFilter',
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
