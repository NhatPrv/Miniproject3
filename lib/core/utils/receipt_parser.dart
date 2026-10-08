import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ParsedReceiptResult {
  final double? totalAmount;
  final String? date;
  final String? merchant;
  final String suggestedCategory;
  final String rawText;
  final int processingTimeMs;

  const ParsedReceiptResult({
    this.totalAmount,
    this.date,
    this.merchant,
    required this.suggestedCategory,
    required this.rawText,
    required this.processingTimeMs,
  });
}

class ReceiptParser {
  /// Phân tích RecognizedText từ Google ML Kit Text Recognition
  static Future<ParsedReceiptResult> parseRecognizedText(
    RecognizedText recognizedText,
  ) async {
    final stopwatch = Stopwatch()..start();
    final rawText = recognizedText.text;

    final lines = <String>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isNotEmpty) {
          lines.add(text);
        }
      }
    }

    final result = _parseLines(lines, rawText, stopwatch);
    return result;
  }

  /// Phân tích từ raw text (dùng cho test hoặc giả lập)
  static ParsedReceiptResult parseRawString(String rawText) {
    final stopwatch = Stopwatch()..start();
    final lines = rawText
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return _parseLines(lines, rawText, stopwatch);
  }

  static ParsedReceiptResult _parseLines(
    List<String> lines,
    String rawText,
    Stopwatch stopwatch,
  ) {
    double? totalAmount = _extractTotalAmount(lines, rawText);
    String? date = _extractDate(lines, rawText);
    String? merchant = _extractMerchant(lines);
    String category = _guessCategory(merchant, rawText);

    stopwatch.stop();

    return ParsedReceiptResult(
      totalAmount: totalAmount,
      date: date,
      merchant: merchant,
      suggestedCategory: category,
      rawText: rawText,
      processingTimeMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// 1. Heuristic trích xuất Tổng số tiền
  static double? _extractTotalAmount(List<String> lines, String rawText) {
    // Các từ khóa chỉ tổng tiền trên hóa đơn Việt Nam
    final totalKeywords = [
      'tổng cộng',
      'tong cong',
      'thanh toán',
      'thanh toan',
      'tổng tiền',
      'tong tien',
      'tiền mặt',
      'tien mat',
      'cộng tiền',
      'cong tien',
      'phải trả',
      'phai tra',
      'total',
      'grand total',
      'amount',
    ];

    // Ưu tiên 1: Tìm dòng chứa từ khóa tổng tiền và bóc tách số ở cùng dòng hoặc dòng ngay sau
    for (int i = 0; i < lines.length; i++) {
      final lineLower = lines[i].toLowerCase();
      for (final kw in totalKeywords) {
        if (lineLower.contains(kw)) {
          // Thử bóc tách số trên cùng dòng
          final amountInLine = _parseAmountFromString(lines[i]);
          if (amountInLine != null && amountInLine > 1000) {
            return amountInLine;
          }
          // Thử kiểm tra dòng kế tiếp
          if (i + 1 < lines.length) {
            final amountNextLine = _parseAmountFromString(lines[i + 1]);
            if (amountNextLine != null && amountNextLine > 1000) {
              return amountNextLine;
            }
          }
        }
      }
    }

    // Ưu tiên 2: Tìm tất cả các số có định dạng tiền tệ (150,000 / 150.000 / 150k / ... VND/đ) và lấy số lớn nhất hợp lý
    final List<double> candidateAmounts = [];
    final currencyPattern = RegExp(
      r'(\d{1,3}(?:[.,]\d{3})+(?:\s*(?:vnđ|vnd|đ|d))?|\d+\s*(?:k|vnđ|vnd|đ))',
      caseSensitive: false,
    );

    for (final line in lines) {
      final matches = currencyPattern.allMatches(line);
      for (final match in matches) {
        final parsed = _parseAmountFromString(match.group(0) ?? '');
        if (parsed != null && parsed >= 1000 && parsed < 1000000000) {
          candidateAmounts.add(parsed);
        }
      }
    }

    if (candidateAmounts.isNotEmpty) {
      // Sắp xếp giảm dần, thường tổng tiền là số lớn nhất trên hóa đơn bán lẻ
      candidateAmounts.sort((a, b) => b.compareTo(a));
      return candidateAmounts.first;
    }

    return null;
  }

  static double? _parseAmountFromString(String text) {
    String clean = text.toLowerCase().trim();

    // Xử lý dạng "150k" -> 150000
    final kMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*k').firstMatch(clean);
    if (kMatch != null) {
      final val = double.tryParse(kMatch.group(1)!.replaceAll(',', '.')) ?? 0;
      return val * 1000;
    }

    // Xóa đơn vị tiền tệ
    clean = clean
        .replaceAll(RegExp(r'(vnđ|vnd|đồng|dong|đ|d|total|amount|cong|tien|:)', caseSensitive: false), '')
        .trim();

    // Bắt số dạng 150,000 hoặc 150.000
    final numMatch = RegExp(r'\d{1,3}(?:[.,]\d{3})+').firstMatch(clean);
    if (numMatch != null) {
      final rawNum = numMatch.group(0)!;
      final digitsOnly = rawNum.replaceAll(RegExp(r'[.,]'), '');
      return double.tryParse(digitsOnly);
    }

    // Bắt số thông thường >= 1000
    final plainNumMatch = RegExp(r'\b\d{4,9}\b').firstMatch(clean);
    if (plainNumMatch != null) {
      return double.tryParse(plainNumMatch.group(0)!);
    }

    return null;
  }

  /// 2. Heuristic trích xuất Ngày giao dịch
  static String? _extractDate(List<String> lines, String rawText) {
    // Regex cho ngày tháng DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY hoặc YYYY-MM-DD
    final dateRegex = RegExp(
      r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})\b|\b(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})\b',
    );

    for (final line in lines) {
      final match = dateRegex.firstMatch(line);
      if (match != null) {
        if (match.group(1) != null) {
          // Định dạng DD/MM/YYYY
          int day = int.tryParse(match.group(1)!) ?? 1;
          int month = int.tryParse(match.group(2)!) ?? 1;
          int year = int.tryParse(match.group(3)!) ?? DateTime.now().year;

          // Chuẩn hóa ngày nếu bị đảo tháng ngày
          if (day > 12 && month <= 12) {
            return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
          } else if (month > 12 && day <= 12) {
            return '${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}/$year';
          }
          return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
        } else if (match.group(4) != null) {
          // Định dạng YYYY-MM-DD
          int year = int.tryParse(match.group(4)!) ?? DateTime.now().year;
          int month = int.tryParse(match.group(5)!) ?? 1;
          int day = int.tryParse(match.group(6)!) ?? 1;
          return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
        }
      }
    }

    // Mặc định trả về ngày hôm nay nếu không trích xuất được
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  /// 3. Heuristic trích xuất Tên Đơn Vị / Cửa Hàng
  static String? _extractMerchant(List<String> lines) {
    final ignoreKeywords = [
      'hóa đơn',
      'hoa don',
      'phiếu thanh toán',
      'phieu thanh toan',
      'phiếu tính tiền',
      'receipt',
      'bill',
      'invoice',
      'tel:',
      'phone',
      'đt:',
      'hotline',
      'địa chỉ',
      'dia chi',
      'address',
      'wifi',
      'pass',
      'bàn:',
      'ban:',
      'khách:',
    ];

    // Duyệt 5 dòng đầu tiên của hóa đơn
    for (int i = 0; i < lines.length && i < 6; i++) {
      final line = lines[i].trim();
      final lineLower = line.toLowerCase();

      // Bỏ qua dòng quá ngắn hoặc chứa từ khóa nhiễu
      if (line.length < 3) continue;
      bool isIgnored = false;
      for (final kw in ignoreKeywords) {
        if (lineLower.contains(kw)) {
          isIgnored = true;
          break;
        }
      }
      if (isIgnored) continue;

      // Nếu chứa tên thương hiệu, công ty hoặc cửa hàng
      return line;
    }

    return lines.isNotEmpty ? lines.first : 'Cửa hàng tiện lợi';
  }

  /// 4. Gợi ý Danh mục dựa trên tên cửa hàng và nội dung hóa đơn
  static String _guessCategory(String? merchant, String rawText) {
    final content = '${merchant ?? ''} $rawText'.toLowerCase();

    // Food
    if (content.contains('coffee') ||
        content.contains('cà phê') ||
        content.contains('quán') ||
        content.contains('cơm') ||
        content.contains('trà sữa') ||
        content.contains('pizza') ||
        content.contains('bánh') ||
        content.contains('nhà hàng') ||
        content.contains('highlands') ||
        content.contains('kfc') ||
        content.contains('lotteria') ||
        content.contains('phúc long') ||
        content.contains('chợ') ||
        content.contains('siêu thị')) {
      return 'Food';
    }

    // Study
    if (content.contains('sách') ||
        content.contains('fahasa') ||
        content.contains('văn phòng phẩm') ||
        content.contains('giáo trình') ||
        content.contains('bút') ||
        content.contains('học phí') ||
        content.contains('in ấn') ||
        content.contains('photocopy')) {
      return 'Study';
    }

    // Travel
    if (content.contains('grab') ||
        content.contains('be ') ||
        content.contains('xăng') ||
        content.contains('petro') ||
        content.contains('vé xe') ||
        content.contains('taxi') ||
        content.contains('gửi xe')) {
      return 'Travel';
    }

    // Gear
    if (content.contains('chuột') ||
        content.contains('bàn phím') ||
        content.contains('tai nghe') ||
        content.contains('gear') ||
        content.contains('laptop') ||
        content.contains('dây sạc') ||
        content.contains('linh kiện') ||
        content.contains('phụ kiện') ||
        content.contains('điện máy')) {
      return 'Gear';
    }

    // Entertainment
    if (content.contains('cgv') ||
        content.contains('cinema') ||
        content.contains('phim') ||
        content.contains('game') ||
        content.contains('karaoke') ||
        content.contains('billiards') ||
        content.contains('vé xem')) {
      return 'Entertainment';
    }

    return 'Food'; // Mặc định là chi tiêu ăn uống
  }
}
