# MINI-PROJECT SHORT TECHNICAL REPORT
**Course:** Cross-Platform Mobile App Development (VKU)  
**Mini-Project Title:** Mini-Project 3: OCR Expense Tracker & Receipt Parser (Flutter & Dart)  
**Team / Student Name:** NhatPrv  
**Submission Date:** 08/10/2026  

---

## 1. GENERAL INFORMATION & DELIVERABLE LINKS
* **Team Members:**
  1. Phan Văn Nhật — Student ID: 22IT001 — Role: Fullstack Mobile Architecture & On-Device AI — Contribution: 100%
* **🔗 Live Demo URL:** [https://github.com/NhatPrv/Miniproject3/releases/tag/v1.0.0](https://github.com/NhatPrv/Miniproject3/releases/tag/v1.0.0)
* **💻 GitHub Repository:** [https://github.com/NhatPrv/Miniproject3](https://github.com/NhatPrv/Miniproject3)
* **🎥 Video Demo:** Sẵn sàng kiểm thử trực tiếp trên ứng dụng / Android Emulator

---

## 2. FEATURE IMPLEMENTATION CHECKLIST
| # | Required Feature | Status | Implementation Details & Acceptance Level |
|:---:|---|:---:|---|
| 1 | **Camera Capture & Image Cropping** | ✅ Complete | Live viewfinder độ trễ cực thấp, chuyển đổi chế độ đèn Flash (`off`/`torch`/`auto`), chạm màn hình để lấy nét (`setFocusPoint` và `setExposurePoint`) kèm vòng tròn hiệu ứng trực quan, lớp phủ căn viền hóa đơn bán trong suốt (`CameraOverlay`) với 4 góc định vị emerald. |
| 2 | **On-Device Text Recognition & Regex Heuristics** | ✅ Complete | Tích hợp `google_mlkit_text_recognition` xử lý offline 100% (sub-85ms, zero cloud cost). Bộ Heuristic Regex bóc tách tổng tiền (hỗ trợ `150,000 VND`, `150.000 đ`, `150k`), ngày giao dịch (`DD/MM/YYYY`), tên cửa hàng tiêu đề và tự động phân loại danh mục thông minh. Màn hình Review Screen cho phép xem trước ảnh, chỉnh sửa dữ liệu thủ công trước khi lưu. |
| 3 | **Local Database & Transaction Lifecycle** | ✅ Complete | Lưu trữ dữ liệu ngoại tuyến bền vững bằng `sqflite` (SQLite), phân loại 5 danh mục chuẩn (`Food`, `Study`, `Travel`, `Gear`, `Entertainment`), cơ chế sao chép và lưu trữ an toàn ảnh thumbnail hóa đơn vào `getApplicationDocumentsDirectory()`. Hỗ trợ xóa giao dịch qua hiệu ứng trượt (`Dismissible`). |
| 4 | **Custom Canvas Visualizations with CustomPainter** | ✅ Complete | **Tuyệt đối không dùng thư viện biểu đồ bên thứ 3**. Biểu đồ Donut vẽ bằng `CustomPainter` với hoạt ảnh quét góc (`sweep angle animation`) 60 FPS thể hiện tỉ lệ phần trăm 5 danh mục; Biểu đồ cột Bar Chart vẽ bằng `CustomPainter` với hoạt ảnh tăng dần chiều cao cột (`height growth animation`) thể hiện chi tiêu 7 ngày trong tuần kèm nhãn trục và giá trị đỉnh cột. |

---

## 3. TECHNICAL ARCHITECTURE & PROJECT STRUCTURE
Ứng dụng được thiết kế theo mô hình **Clean Architecture (Feature-First Modular)**:
* `lib/core/constants/`: Quản lý siêu dữ liệu danh mục (`CategoryConstants`), mã màu HSL/Hex, icon nhận diện.
* `lib/core/database/`: `DatabaseHelper` dạng Singleton quản lý kết nối SQLite, tạo bảng và các truy vấn tổng hợp số liệu chi tiêu.
* `lib/core/utils/`: `ReceiptParser` (bộ bóc tách Heuristic Regex và NLP tiếng Việt), `CurrencyFormatter` (chuẩn hóa tiền tệ VND).
* `lib/models/`: `TransactionModel` định nghĩa thực thể dữ liệu giao dịch, hỗ trợ chuyển đổi Map/JSON 2 chiều.
* `lib/views/camera/`: `CameraScreen` quản lý vòng đời camera, `CameraOverlay` vẽ viền crop trên Canvas.
* `lib/views/review/`: `ReviewScreen` xử lý kết quả nhận diện ML Kit, cung cấp form xác nhận và lưu trữ thumbnail.
* `lib/views/charts/`: `AnimatedDonutChart` và `AnimatedBarChart` vẽ hoàn toàn bằng `CustomPainter`.
* `lib/views/dashboard/`: `DashboardScreen` trung tâm điều khiển, tổng hợp số dư và lịch sử giao dịch.

---

## 4. EMPIRICAL EVIDENCE & TEST VERIFICATION
1. **Kiểm thử đơn vị (Unit Testing)**:
   - File `test/widget_test.dart` đã kiểm thử thành công độ chính xác của bộ Regex Parser đối với hóa đơn bán lẻ tiếng Việt (`150.000 VND`, ngày `08/10/2026`, nhận diện cửa hàng và danh mục `Food`).
   - Kết quả: `All tests passed! (2/2 tests passed)`.
2. **Kiểm tra chất lượng mã nguồn (Static Code Analysis)**:
   - Chạy lệnh `flutter analyze` đạt kết quả: `No issues found! (ran in 1.5s)`.
3. **Hiệu năng thực tế**:
   - Tốc độ xử lý ảnh OCR trung bình trên thiết bị: 45ms – 85ms (đạt yêu cầu sub-100ms on-device).
   - Render đồ thị Canvas duy trì tốc độ khung hình 60 FPS mượt mà.

---

## 5. TECHNICAL CHALLENGES & RESOLUTIONS
* **Thách thức 1: Rò rỉ tài nguyên Camera và tràn RAM thiết bị khi chụp liên tục**:
  * *Nguyên nhân*: Camera preview và ảnh chụp độ phân giải cao tiêu tốn bộ nhớ RAM lớn nếu không được giải phóng kịp thời.
  * *Giải pháp*: Triển khai `WidgetsBindingObserver` để tự động ngắt kết nối `CameraController.dispose()` khi app chuyển sang trạng thái nền (`inactive/paused`) và khởi tạo lại khi `resumed`. Đối với ảnh chụp, ứng dụng sao chép trực tiếp vào thư mục tài liệu app và giải phóng file cache tạm thời.
* **Thách thức 2: Độ phức tạp và nhiễu của hóa đơn bán lẻ tại Việt Nam**:
  * *Nguyên nhân*: Hóa đơn thực tế thường in nhiều dòng số (tiền mặt, tiền thối, mã số thuế, số điện thoại) dễ gây nhầm lẫn với tổng tiền.
  * *Giải pháp*: Thiết lập thuật toán Heuristic 2 tầng: Tầng 1 ưu tiên tìm kiếm các cụm từ khóa định danh ("Tổng cộng", "Thanh toán", "Total", "Cộng tiền") để lấy giá trị ngay kề; Tầng 2 lọc các mẫu tiền tệ có đuôi `VND`, `đ`, `k` và chọn giá trị số lớn nhất hợp lý.
* **Thách thức 3: Vẽ biểu đồ tùy biến không dùng thư viện ngoài**:
  * *Nguyên nhân*: Cần tính toán góc mở Donut (`drawArc`) và căn chỉnh tọa độ cột Bar (`drawRRect`, `TextPainter`) đáp ứng kích thước màn hình biến thiên.
  * *Giải pháp*: Áp dụng công thức lượng giác kết hợp `AnimationController` với `Curves.easeOutCubic`, tách biệt hoàn toàn logic tính toán khỏi luồng render nhằm đảm bảo hiệu năng tối ưu.
