# 🧾 OCR Expense Tracker & Receipt Parser (Flutter & Dart)

[![Flutter](https://img.shields.io/badge/Flutter-3.44.7-blue.svg?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12.2-0175C2.svg?logo=dart)](https://dart.dev)
[![ML Kit](https://img.shields.io/badge/Google_ML_Kit-Text_Recognition-orange.svg?logo=google)](https://developers.google.com/ml-kit)
[![SQLite](https://img.shields.io/badge/SQLite-sqflite-003B57.svg?logo=sqlite)](https://pub.dev/packages/sqflite)
[![CustomPainter](https://img.shields.io/badge/UI_Canvas-CustomPainter_(Zero_3rd_Lib)-green.svg)](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)
[![License](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)

> **Mini-Project 3 (Cross-Platform Mobile App Development - VKU)**  
> Ứng dụng quản lý chi tiêu cá nhân thông minh với trí tuệ nhân tạo On-Device AI xử lý hoàn toàn ngoại tuyến (Zero Cloud Cost).

---

## 🌟 Tính Năng Nổi Bật (Core Functional Specifications)

### 1. 📷 Camera Capture & Framing Crop Overlay
* **Khung ngắm trực tiếp (Live Viewfinder)**: Độ phản hồi cao, tối ưu hóa vòng đời `CameraController` an toàn (tránh rò rỉ RAM).
* **Chạm lấy nét (Tap-to-Focus)**: Tự động điều chỉnh tiêu cự `setFocusPoint` và điểm phơi sáng `setExposurePoint` kèm vòng tròn chỉ thị trực quan.
* **Đèn Flash đa chế độ**: Chuyển đổi nhanh giữa `Tắt (Off)`, `Đèn pin (Torch)` và `Tự động (Auto)`.
* **Khung căn viền hóa đơn (Framing Overlay)**: Vẽ bằng `CustomPainter` với hiệu ứng bán trong suốt và 4 góc định vị emerald giúp căn chuẩn vị trí chụp.

### 2. 🧠 On-Device Text Recognition & Heuristic Regex Engine
* **Trích xuất chữ siêu tốc (<85ms)**: Tích hợp `google_mlkit_text_recognition`, chạy 100% On-Device, không tốn chi phí Cloud API và bảo mật dữ liệu riêng tư tuyệt đối.
* **Bộ Heuristic Regex thông minh cho hóa đơn Việt Nam**:
  * Tự động nhận diện tổng số tiền thanh toán (hỗ trợ `150,000 VND`, `150.000 đ`, `150k`).
  * Trích xuất chính xác ngày giao dịch (`DD/MM/YYYY`, `DD-MM-YYYY`).
  * Trích xuất tên đơn vị/cửa hàng từ tiêu đề hóa đơn.
  * Tự động gợi ý danh mục chi tiêu dựa trên từ khóa nội dung.
* **Màn hình Review Screen**: Cho phép người dùng kiểm tra ảnh thumbnail, chỉnh sửa thủ công số tiền/ngày/cửa hàng trước khi lưu.

### 3. 💾 Local Database & Transaction Lifecycle
* **Lưu trữ SQLite ngoại tuyến**: Tích hợp `sqflite` với cấu trúc bảng tối ưu và cơ chế Singleton.
* **Phân loại 5 danh mục chuẩn**: `Food`, `Study`, `Travel`, `Gear`, `Entertainment`.
* **Lưu trữ & Caching Thumbnail**: Sao chép an toàn ảnh chụp vào `getApplicationDocumentsDirectory()`.
* **Thao tác nhanh**: Hỗ trợ vuốt trượt (`Dismissible`) để xóa giao dịch.

### 4. 📊 Custom Canvas Visualizations with `CustomPainter`
* **Tuyệt đối không dùng thư viện biểu đồ bên thứ 3** (như `fl_chart`).
* **Animated Donut Chart**: Biểu đồ tròn thể hiện cơ cấu chi tiêu 5 danh mục với hoạt ảnh quét góc (`sweep angle animation`) 60 FPS mượt mà.
* **Animated Weekly Bar Chart**: Biểu đồ cột thể hiện mức chi 7 ngày trong tuần với hoạt ảnh tăng chiều cao (`height growth animation`), kèm lưới tọa độ và nhãn ngày.

---

## 🏛️ Kiến Trúc Mã Nguồn (Clean Architecture)

```
expense_ocr_app/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── category_constants.dart      # Phân loại danh mục & bảng màu HSL
│   │   ├── database/
│   │   │   └── database_helper.dart         # SQLite Singleton & CRUD queries
│   │   └── utils/
│   │       ├── currency_formatter.dart      # Chuẩn hóa tiền tệ VNĐ
│   │       └── receipt_parser.dart          # Heuristic Regex & NLP Engine
│   ├── models/
│   │   └── transaction_model.dart           # Entity dữ liệu giao dịch
│   ├── views/
│   │   ├── camera/
│   │   │   ├── camera_screen.dart           # Giao diện Camera Viewfinder
│   │   │   └── widgets/camera_overlay.dart  # CustomPainter khung viền hóa đơn
│   │   ├── review/
│   │   │   └── review_screen.dart           # Màn hình đối soát kết quả OCR
│   │   ├── charts/
│   │   │   ├── animated_donut_chart.dart    # CustomPainter Donut Chart
│   │   │   └── animated_bar_chart.dart      # CustomPainter Bar Chart
│   │   └── dashboard/
│   │       └── dashboard_screen.dart        # Tổng quan thu chi & lịch sử
│   └── main.dart                            # Entry point & Dark Slate theme
├── test/
│   └── widget_test.dart                     # Unit Tests cho Heuristic Parser
├── docs/
│   └── ARCHITECTURE.md                      # Chi tiết kiến trúc hệ thống
└── REPORT.md                                # Báo cáo kỹ thuật chuẩn mẫu VKU
```

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

### Yêu cầu môi trường
* Flutter SDK: `>= 3.12.0` (Đã kiểm thử trên Flutter 3.44.7 / Dart 3.12.2)
* Android Studio / VS Code / Antigravity IDE
* Thiết bị Android thật hoặc Android Emulator (API 21+)

### Các bước thực hiện

1. **Clone repository**:
   ```bash
   git clone https://github.com/NhatPrv/Miniproject3.git
   cd Miniproject3
   ```

2. **Cài đặt các gói phụ thuộc (Dependencies)**:
   ```bash
   flutter pub get
   ```

3. **Chạy kiểm thử đơn vị (Unit Tests)**:
   ```bash
   flutter test
   ```

4. **Kiểm tra chất lượng mã nguồn (Linter)**:
   ```bash
   flutter analyze
   ```

5. **Khởi chạy ứng dụng**:
   ```bash
   flutter run
   ```

6. **Đóng gói file cài đặt (Release APK)**:
   ```bash
   flutter build apk --release
   ```
   *File APK sau khi build nằm tại:* `build/app/outputs/flutter-apk/app-release.apk`.

---

## 📄 Báo Cáo Kỹ Thuật (Technical Report)
Chi tiết báo cáo đồ án nộp bài theo mẫu của môn học xem tại [REPORT.md](REPORT.md) hoặc [Mini-Project-3-Report-Template.md](resource/Mini-Project-3-Report-Template.md).

---
*Phát triển bởi Phan Văn Nhật (NhatPrv) — VKU 2026.*
