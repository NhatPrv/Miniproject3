# Kiến Trúc Hệ Thống (System Architecture)
## Mini-Project 3: OCR Expense Tracker & Receipt Parser

Dự án được xây dựng theo mô hình **Clean Architecture (Feature-First Modular)** kết hợp quản lý trạng thái phản ứng (Reactive State Management) nhằm tối ưu hiệu năng on-device AI và giao diện vẽ đồ họa tùy biến trên Flutter 3.x.

---

### 1. Sơ Đồ Phân Tầng Kiến Trúc (Architectural Layers)

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                       │
│  - Camera Screen (Viewfinder, Tap-to-Focus, Flash Toggle)   │
│  - Camera Overlay (Framing Crop Bounds)                     │
│  - Review Screen (OCR Result Form, Validation & Manual Edit)│
│  - Dashboard Screen (Summary, Recent Transactions)          │
│  - Custom Canvas Visualizations (CustomPainter Donut & Bar) │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                       DOMAIN LAYER                          │
│  - Transaction Model (Entity, JSON serialization)           │
│  - Category Enums (Food, Study, Travel, Gear, Entertainment)│
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    DATA & HARDWARE LAYER                    │
│  - On-Device OCR Pipeline (google_mlkit_text_recognition)   │
│  - Heuristic Regex Parser Engine (VND, Date, Merchant)      │
│  - SQLite Database Helper (sqflite Local Persistence)       │
│  - Local Thumbnail Caching (path_provider)                  │
└─────────────────────────────────────────────────────────────┘
```

---

### 2. Luồng Xử Lý Dữ Liệu (End-to-End Data Flow)

1. **Thu nhận ảnh (Image Capture)**:
   - Người dùng sử dụng camera độ trễ thấp với khung căn chỉnh hóa đơn (`CameraOverlay`).
   - Lấy nét (`setFocusPoint`) và kích hoạt chụp ảnh lưu tạm vào bộ đệm cache.
2. **Trích xuất chữ ngoại tuyến (Offline Text Extraction)**:
   - Ảnh chụp được đưa trực tiếp vào `google_mlkit_text_recognition` qua luồng xử lý On-Device.
   - Trích xuất toàn bộ text blocks trong thời gian mục tiêu `< 100ms`, hoàn toàn không phụ thuộc Internet hoặc Cloud API.
3. **Phân tích Heuristic Regex (NLP Heuristics)**:
   - `ReceiptParser` chuẩn hóa văn bản tiếng Việt.
   - Trích xuất số tiền lớn nhất hoặc theo từ khóa (Tổng cộng, Thanh toán, Total, VND, đ).
   - Bóc tách ngày giao dịch định dạng `DD/MM/YYYY`.
   - Bóc tách tên cửa hàng/đơn vị từ các dòng tiêu đề.
4. **Xác nhận & Cân chỉnh thủ công (Review & Validation)**:
   - Màn hình `ReviewScreen` cho phép người dùng kiểm tra lại thông tin, phân loại danh mục (Food, Study, Travel, Gear, Entertainment) trước khi ghi dữ liệu.
5. **Lưu trữ cục bộ & Caching (Persistence)**:
   - Bản ghi được lưu vào SQLite thông qua `DatabaseHelper`.
   - Ảnh hóa đơn được lưu vào thư mục tài liệu an toàn của ứng dụng (`getApplicationDocumentsDirectory`).
6. **Trực quan hóa đồ họa (Custom Canvas Charts)**:
   - Tính toán phân phối danh mục và vẽ biểu đồ Donut có hoạt ảnh mở góc (`sweep angle`) bằng `CustomPainter`.
   - Tính toán chi tiêu 7 ngày trong tuần và vẽ biểu đồ Bar có hoạt ảnh tăng dần chiều cao bằng `CustomPainter`.
   - Tuyệt đối không dùng thư viện biểu đồ ngoài, đảm bảo tốc độ render 60–120 FPS.
