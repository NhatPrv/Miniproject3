import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _vndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final NumberFormat _compactFormat = NumberFormat.compact(
    locale: 'vi_VN',
  );

  /// Định dạng số tiền sang chuẩn hiển thị: "150.000 ₫"
  static String formatVND(double amount) {
    return _vndFormat.format(amount.round());
  }

  /// Định dạng số tiền rút gọn cho biểu đồ: "150K", "1.5M"
  static String formatCompact(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}Tr';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  /// Phân tích chuỗi số sang double (xử lý dấu . và ,)
  static double parseAmount(String input) {
    if (input.isEmpty) return 0.0;
    // Xóa tất cả ký tự không phải số và dấu chấm/phẩy
    String clean = input.replaceAll(RegExp(r'[^\d.,]'), '').trim();
    if (clean.isEmpty) return 0.0;

    // Xử lý các dạng 150.000 hoặc 150,000 (Việt Nam hay dùng dấu . ngăn cách hàng nghìn)
    if (clean.contains('.') && !clean.contains(',')) {
      // 150.000 -> 150000
      clean = clean.replaceAll('.', '');
    } else if (clean.contains(',') && !clean.contains('.')) {
      // 150,000 -> 150000
      clean = clean.replaceAll(',', '');
    } else if (clean.contains('.') && clean.contains(',')) {
      // 150,000.00 hoặc 150.000,00
      if (clean.lastIndexOf(',') > clean.lastIndexOf('.')) {
        clean = clean.replaceAll('.', '').replaceAll(',', '.');
      } else {
        clean = clean.replaceAll(',', '');
      }
    }

    return double.tryParse(clean) ?? 0.0;
  }
}
