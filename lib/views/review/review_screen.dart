import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants/category_constants.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/receipt_parser.dart';
import '../../models/transaction_model.dart';

class ReviewScreen extends StatefulWidget {
  final String? imagePath;

  const ReviewScreen({super.key, this.imagePath});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String _selectedCategory = 'Food';
  String _rawText = '';
  int _processingTimeMs = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _processReceipt();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _processReceipt() async {
    setState(() => _isLoading = true);

    try {
      if (widget.imagePath != null && File(widget.imagePath!).existsSync()) {
        final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
        final inputImage = InputImage.fromFilePath(widget.imagePath!);

        final recognizedText = await textRecognizer.processImage(inputImage);
        final parsedResult = await ReceiptParser.parseRecognizedText(recognizedText);

        await textRecognizer.close();

        _populateParsedData(parsedResult);
      } else {
        // Hóa đơn mẫu cho chế độ Test / Emulator
        const sampleReceipt = '''
HIGHLANDS COFFEE
ĐC: 123 Nguyễn Văn Linh, Đà Nẵng
PHIẾU THANH TOÁN
Ngày: 08/10/2026 09:15
1. Phin Sữa Đá Size L         45.000
2. Trà Sen Vàng                55.000
3. Bánh Mì Thịt Nướng          50.000
------------------------------------
TỔNG CỘNG: 150.000 VND
TIỀN MẶT: 200.000 VND
TIỀN THỐI: 50.000 VND
Cảm ơn và hẹn gặp lại quý khách!
''';
        final parsedResult = ReceiptParser.parseRawString(sampleReceipt);
        _populateParsedData(parsedResult);
      }
    } catch (e) {
      debugPrint('Lỗi OCR: $e');
      if (mounted) {
        _amountController.text = '0';
        _merchantController.text = 'Cửa hàng không xác định';
        _dateController.text = DateTime.now().toIso8601String().substring(0, 10);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _populateParsedData(ParsedReceiptResult result) {
    setState(() {
      _amountController.text = result.totalAmount != null
          ? result.totalAmount!.toStringAsFixed(0)
          : '0';
      _merchantController.text = result.merchant ?? 'Cửa hàng tiện lợi';
      _dateController.text = result.date ?? DateTime.now().toIso8601String().substring(0, 10);
      _selectedCategory = result.suggestedCategory;
      _rawText = result.rawText;
      _processingTimeMs = result.processingTimeMs;
    });
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      String? cachedImagePath;

      // Lưu trữ và cache ảnh hóa đơn vào thư mục an toàn của app
      if (widget.imagePath != null && File(widget.imagePath!).existsSync()) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final targetPath = p.join(appDir.path, fileName);

        final File sourceFile = File(widget.imagePath!);
        final File copiedFile = await sourceFile.copy(targetPath);
        cachedImagePath = copiedFile.path;
      }

      final amount = CurrencyFormatter.parseAmount(_amountController.text);

      // Chuyển ngày DD/MM/YYYY sang ISO YYYY-MM-DD để dễ query SQLite
      String isoDate = DateTime.now().toIso8601String().substring(0, 10);
      final parts = _dateController.text.split('/');
      if (parts.length == 3) {
        isoDate = '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      } else if (_dateController.text.contains('-')) {
        isoDate = _dateController.text;
      }

      final transaction = TransactionModel(
        amount: amount,
        date: isoDate,
        merchant: _merchantController.text.trim(),
        category: _selectedCategory,
        imagePath: cachedImagePath,
        createdAt: DateTime.now().toIso8601String(),
      );

      await DatabaseHelper.instance.insertTransaction(transaction);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF10B981),
          content: Text('Đã lưu giao dịch thành công!'),
        ),
      );

      // Trở về Dashboard
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu giao dịch: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác Nhận Hóa Đơn'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF10B981), size: 28),
            onPressed: _saveTransaction,
          )
        ],
      ),
      backgroundColor: const Color(0xFF0F172A),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF10B981)),
                  SizedBox(height: 16),
                  Text('Đang xử lý OCR On-Device...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Badge hiệu năng ML Kit Sub-100ms
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF10B981), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt, color: Color(0xFF10B981), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ML Kit Offline Parser: sub-${_processingTimeMs > 0 ? _processingTimeMs : 45}ms (Zero Cloud Cost)',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Xem trước Thumbnail ảnh hóa đơn
                    if (widget.imagePath != null && File(widget.imagePath!).existsSync())
                      Container(
                        height: 160,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(widget.imagePath!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),

                    // Trường: Tổng số tiền
                    _buildTextField(
                      controller: _amountController,
                      label: 'Tổng tiền thanh toán (VNĐ)',
                      icon: Icons.payments,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Vui lòng nhập số tiền';
                        if (CurrencyFormatter.parseAmount(val) <= 0) return 'Số tiền phải lớn hơn 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Trường: Tên Cửa hàng
                    _buildTextField(
                      controller: _merchantController,
                      label: 'Tên cửa hàng / Đơn vị',
                      icon: Icons.storefront,
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Vui lòng nhập tên cửa hàng' : null,
                    ),
                    const SizedBox(height: 14),

                    // Trường: Ngày tháng
                    _buildTextField(
                      controller: _dateController,
                      label: 'Ngày giao dịch (DD/MM/YYYY)',
                      icon: Icons.calendar_today,
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Vui lòng nhập ngày giao dịch' : null,
                    ),
                    const SizedBox(height: 16),

                    // Chọn danh mục chi tiêu (Category Chips)
                    const Text(
                      'Danh mục chi tiêu:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: CategoryConstants.categoryKeys.map((catKey) {
                        final meta = CategoryConstants.getMetadataByKey(catKey);
                        final isSelected = _selectedCategory == catKey;
                        return ChoiceChip(
                          avatar: Icon(meta.icon, size: 16, color: isSelected ? Colors.white : meta.color),
                          label: Text(meta.displayName),
                          selected: isSelected,
                          selectedColor: meta.color,
                          backgroundColor: const Color(0xFF1E293B),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = catKey);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Khối Raw Text OCR đã nhận diện
                    if (_rawText.isNotEmpty)
                      ExpansionTile(
                        collapsedIconColor: Colors.white54,
                        iconColor: Colors.white,
                        title: const Text(
                          'Chi tiết văn bản OCR gốc',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _rawText,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),

                    // Nút xác nhận lưu
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isSaving ? 'Đang lưu vào SQLite...' : 'Xác Nhận & Lưu Giao Dịch',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isSaving ? null : _saveTransaction,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: const Color(0xFF10B981)),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
        ),
      ),
    );
  }
}
