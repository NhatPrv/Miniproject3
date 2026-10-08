import 'package:flutter_test/flutter_test.dart';
import 'package:expense_ocr_app/core/utils/receipt_parser.dart';
import 'package:expense_ocr_app/core/utils/currency_formatter.dart';

void main() {
  group('ReceiptParser & CurrencyFormatter Unit Tests', () {
    test('Heuristic regex parses total amount with VND symbol', () {
      const mockReceipt = '''
HIGHLANDS COFFEE
Ngay: 08/10/2026
1. Ca phe sua da: 45.000d
Tong cong: 150.000 VND
Cam on quy khach!
''';
      final result = ReceiptParser.parseRawString(mockReceipt);
      expect(result.totalAmount, equals(150000.0));
      expect(result.date, equals('08/10/2026'));
      expect(result.merchant, contains('HIGHLANDS'));
      expect(result.suggestedCategory, equals('Food'));
    });

    test('CurrencyFormatter parses and formats correctly', () {
      expect(CurrencyFormatter.parseAmount('150.000'), equals(150000.0));
      expect(CurrencyFormatter.parseAmount('150,000 VND'), equals(150000.0));
      expect(CurrencyFormatter.formatCompact(150000.0), equals('150K'));
      expect(CurrencyFormatter.formatCompact(1500000.0), equals('1.5Tr'));
    });
  });
}
