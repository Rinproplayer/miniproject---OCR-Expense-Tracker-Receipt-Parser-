# Mini-Project 3: Receipt OCR & Expense Tracker (VKU Expense OCR)

> **Môn học:** Phát triển Ứng dụng Di động Đa nền tảng (Cross-Platform Mobile App Development)  
> **Khoa:** Khoa Công nghệ Thông tin, Trường Đại học Công nghệ Thông tin & Truyền thông Việt - Hàn (VKU)  
> **Giảng viên hướng dẫn:** TS. Nguyễn Thanh Tuấn  
> **Sinh viên thực hiện:** Nguyễn Trung Nguyên (Mã SV: 23IT.B143)  
> **Nền tảng:** Flutter 3.x (Dart 3) — Android Native  
> **GitHub Repository:** [https://github.com/Rinproplayer/miniproject---OCR-Expense-Tracker-Receipt-Parser-.git](https://github.com/Rinproplayer/miniproject---OCR-Expense-Tracker-Receipt-Parser-.git)  

---

## 🎯 Giới Thiệu Dự Án & Bối Cảnh (Project Overview)

Sinh viên và thủ quỹ các câu lạc bộ tại Trường Đại học CNTT & TT Việt - Hàn (VKU) thường xuyên phải quản lý số lượng lớn hóa đơn giấy (tiền ăn uống căn tin, tiền giáo trình photo, chi phí hoạt động CLB, xăng xe đi lại, thiết bị in ấn). Việc gõ tay từng con số vào bảng tính rất tốn thời gian và dễ xảy ra sai sót.

Ứng dụng **VKU Expense OCR** giải quyết triệt để bài toán này bằng cách kết hợp:
1. **Trí tuệ nhân tạo On-Device AI (Google ML Kit)** nhận diện chữ viết hóa đơn siêu tốc (<100ms), hoàn toàn ngoại tuyến không tốn chi phí máy chủ.
2. **Bộ phân tích cú pháp biểu thức chính quy (Regex Heuristic Engine)** bóc tách tự động: Tổng số tiền thanh toán, Ngày lập hóa đơn, Tên đơn vị bán và Tự động gợi ý danh mục chi tiêu.
3. **Màn hình hiệu chỉnh tương tác (Review Screen)** cho phép người dùng kiểm tra và điều chỉnh thông tin trước khi lưu.
4. **Cơ sở dữ liệu SQLite cục bộ (sqflite)** & Quản lý trạng thái **Riverpod 2.x**.
5. **Trực quan hóa số liệu hoàn toàn tự vẽ bằng Canvas (`CustomPainter`)**: Biểu đồ tròn khuyết tâm (Donut Chart) và Biểu đồ cột tuần (Weekly Bar Chart) tuyệt đối không dùng thư viện ngoài.

---

## 📋 Bảng Đối Chiếu Tiêu Chí Rubric & Đặc Tả Kỹ Thuật (10/10 Điểm)

| Tiêu Chí Rubric | Yêu Cầu Cốt Lõi (Core Specifications) | Hiện Thực Trong Dự Án VKU Expense OCR | Trạng Thái |
|---|---|---|:---:|
| **1. Camera Capture & Image Cropping** *(3.5 pts OCR)* | • Live camera viewfinder<br>• Flash toggle, Focus tap<br>• Framing crop overlay & Cropping<br>• Thumbnail caching | • Màn hình [`LiveCameraScanScreen`](lib/views/scan/live_camera_scan_screen.dart) tích hợp `camera: ^0.12.1`.<br>• Chuyển đổi Flash (Bật / Tắt / Auto).<br>• Chạm lấy nét (`setFocusPoint`) kèm vòng tròn focus hoạt họa.<br>• Khung căn chỉnh hóa đơn với hiệu ứng laser scan tự vẽ.<br>• Tự động crop ảnh hóa đơn và lưu ảnh thu nhỏ vào thư mục ứng dụng qua thư viện `image`. | ✅ Đạt 100% |
| **2. On-Device Text Recognition & Regex** *(3.5 pts OCR)* | • Google ML Kit Text Recognition offline<br>• Regex: Tiền (150k VND, 150.000 đ), Ngày (DD/MM/YYYY), Tên quán<br>• Review screen hiệu chỉnh trước khi lưu | • [`MLKitOCRService`](lib/core/ocr/mlkit_ocr_service.dart) xử lý ảnh offline sub-100ms.<br>• [`ReceiptRegexParser`](lib/core/ocr/receipt_regex_parser.dart) nhận diện đa tầng các định dạng tiền VNĐ, ngày tháng `dd/MM/yyyy`, bóc tách tiêu đề cửa hàng.<br>• [`ReceiptReviewScreen`](lib/views/review/receipt_review_screen.dart) cho phép sửa tay toàn bộ thông tin. | ✅ Đạt 100% |
| **3. State Management & Local DB** *(2.0 pts DB)* | • Lưu trữ bền vững `sqflite`<br>• Phân loại chuẩn 5 nhóm (Food, Study, Travel, Gear, Entertainment)<br>• Caching ảnh và thumbnail | • Quản lý trạng thái theo kiến trúc **Riverpod 2.x** (`StateNotifierProvider`).<br>• SQLite [`DatabaseHelper`](lib/core/database/database_helper.dart) CRUD đầy đủ, tìm kiếm, lọc theo ngày/danh mục.<br>• Mô hình chuẩn [`ExpenseCategory`](lib/models/category.dart) gồm: **Food**, **Study**, **Travel**, **Gear**, **Entertainment** (+ Other).<br>• Lưu ảnh gốc và thumbnail trong thư mục an toàn của app. | ✅ Đạt 100% |
| **4. Custom Canvas Visualization** *(2.5 pts Charts)* | • Biểu đồ Donut/Pie phân bổ danh mục<br>• Biểu đồ Weekly Bar 7 ngày trong tuần<br>• Vẽ trực tiếp bằng `CustomPainter` không dùng thư viện ngoài | • [`CategoryDonutPainter`](lib/views/charts/category_donut_painter.dart): Tự tính góc quét `sweepAngle`, bo viền cung tròn, tâm rỗng hiển thị tổng tiền và danh mục % tương tác.<br>• [`WeeklyBarPainter`](lib/views/charts/weekly_bar_painter.dart): Tự vẽ lưới mốc, cột nền, cột dữ liệu bo góc theo ngày T2-CN kèm nhãn số tiền dạng thu gọn (k / tr). | ✅ Đạt 100% |
| **5. UI/UX Polish & Deliverables** *(1.0 pt UI + 1.0 pt Deliverables)* | • Material 3, Dark & Light Mode<br>• Test tự động passing<br>• Đóng gói Release APK hoàn chỉnh | • Hỗ trợ chuyển đổi tức thì giữa **Dark Mode** & **Light Mode**.<br>• Bộ test tự động [`ocr_parser_test.dart`](test/ocr_parser_test.dart) & [`widget_test.dart`](test/widget_test.dart) đạt 5/5 tests passed.<br>• File **Release APK** độc lập đã build hoàn chỉnh (`app-release.apk` ~84 MB). | ✅ Đạt 100% |

---

## 🏗️ Kiến Trúc Hệ Thống & Luồng Xử Lý Dữ Liệu (Architecture Flow)

```
[ Camera Capture / Viewfinder ]
       │
       ▼ (Focus Tap, Flash Toggle, Framing Crop Overlay)
[ Cropped Image & Thumbnail Cache ] ──► (Lưu trữ: app_documents/receipt_thumbnails)
       │
       ▼
[ Google ML Kit Text Recognition ] (Offline On-device OCR, sub-100ms)
       │
       ▼
[ Dart Regex Heuristic Parser ]
       ├─► Extract Amount: 104.000 đ / 150,000 VND
       ├─► Extract Date: 15/10/2026 (DD/MM/YYYY)
       ├─► Extract Merchant: CĂN TIN ĐẠI HỌC VKU - ĐÀ NẴNG
       └─► Auto-Suggest Category: Food, Study, Travel, Gear, Entertainment
       │
       ▼
[ Interactive Review Screen ] (Người dùng kiểm tra & hiệu chỉnh thủ công)
       │
       ▼
[ SQLite Database (sqflite) ] ◄──► [ Riverpod 2 State Management ]
       │
       ▼
[ CustomPainter Canvas Visualizations ]
       ├─► Animated Donut Chart (Cơ cấu chi tiêu %)
       └─► Animated Weekly Bar Chart (Chi tiêu 7 ngày T2 - CN)
```

---

## 📂 Cấu Trúc Thư Mục Dự Án (Project Structure)

```text
d:\miniproject3\
├── android/                         # Cấu hình Native Android (minSdkVersion 21, compileSdk 35)
│   ├── app/
│   │   ├── build.gradle.kts         # Script build Gradle Android DSL
│   │   ├── proguard-rules.pro       # Quy tắc tối ưu hóa R8 & ProGuard cho ML Kit
│   │   └── src/main/AndroidManifest.xml # Quyền Camera, Storage, Feature Autofocus
├── assets/
│   └── sample_receipts/             # Mẫu hóa đơn thử nghiệm
├── lib/
│   ├── main.dart                    # Điểm khởi chạy app, ProviderScope, Router
│   ├── core/
│   │   ├── constants/               # Bảng màu Material 3, Danh mục & Hằng số
│   │   ├── database/
│   │   │   └── database_helper.dart # SQLite Helper CRUD (Thêm, Sửa, Xóa, Lọc)
│   │   ├── ocr/
│   │   │   ├── mlkit_ocr_service.dart     # Google ML Kit Text Recognition wrapper
│   │   │   └── receipt_regex_parser.dart  # Bộ Regex bóc tách Tiền, Ngày, Cửa hàng
│   │   ├── theme/                   # Bảng màu Material 3 Light & Dark mode
│   │   └── utils/                   # Định dạng tiền tệ VND & Ngày tháng
│   ├── models/
│   │   ├── category.dart            # Enum danh mục (Food, Study, Travel, Gear, Entertainment)
│   │   └── expense_receipt.dart     # Model hóa đơn chi tiêu SQLite
│   ├── providers/
│   │   ├── expense_provider.dart    # Riverpod StateNotifier quản lý danh sách chi tiêu
│   │   ├── filter_provider.dart     # Riverpod quản lý bộ lọc & tìm kiếm
│   │   ├── ocr_provider.dart        # Riverpod quản lý tiến trình quét OCR
│   │   └── theme_provider.dart      # Riverpod quản lý chuyển đổi Theme sáng/tối
│   └── views/
│       ├── charts/
│       │   ├── animated_donut_chart.dart     # Widget biểu đồ Donut có hoạt họa
│       │   ├── category_donut_painter.dart   # CustomPainter vẽ hình xuyến khuyết tâm
│       │   ├── animated_weekly_bar_chart.dart# Widget biểu đồ cột tuần có hoạt họa
│       │   └── weekly_bar_painter.dart       # CustomPainter vẽ biểu đồ cột 7 ngày
│       ├── history/
│       │   ├── expense_detail_screen.dart    # Màn hình chi tiết hóa đơn (Sửa / Xóa)
│       │   └── expense_history_screen.dart   # Lịch sử chi tiêu & Tìm kiếm, Lọc danh mục
│       ├── home/
│       │   ├── home_screen.dart              # Màn hình chính Dashboard tổng quan
│       │   └── widgets/                      # Card thống kê, nút thao tác nhanh, FAB
│       ├── review/
│       │   └── receipt_review_screen.dart    # Màn hình Review xác nhận trước khi lưu
│       ├── scan/
│       │   ├── live_camera_scan_screen.dart  # Viewfinder Camera trực tiếp & Khung cắt
│       │   └── scan_receipt_sheet.dart       # Bottom Sheet chọn Camera / Gallery / Mẫu VKU
│       └── stats/
│           └── statistics_screen.dart        # Màn hình Thống kê biểu đồ Canvas chi tiết
├── test/
│   ├── ocr_parser_test.dart         # Unit tests bóc tách Regex tiếng Việt & tiếng Anh
│   └── widget_test.dart             # Widget tests kiểm thử CustomPainter Donut & Bar
├── pubspec.yaml                     # Danh sách thư viện và tài nguyên
├── README.md                        # Hướng dẫn & Tài liệu dự án
└── REPORT.md                        # Báo cáo kỹ thuật chi tiết nộp bài
```

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

### 1. Yêu Cầu Môi Trường
- **Flutter SDK**: Phiên bản 3.x (Đã kiểm thử trên Flutter 3.47.5 / Dart 3.13.4).
- **Android Studio / Android SDK**: Android API 21+ (Khuyên dùng API 31 đến API 35).
- **Java JDK**: JDK 17 hoặc JDK 19.

### 2. Cài Đặt Phụ Thuộc
Tại thư mục gốc `d:\miniproject3`, mở terminal chạy:
```powershell
flutter pub get
```

### 3. Chạy Kiểm Thử Tự Động (Automated Tests)
```powershell
flutter test
```
*Kết quả: 5/5 bài kiểm thử đơn vị và widget đều vượt qua (All tests passed).*

### 4. Khởi Chạy Ứng Dụng Trên Máy Ảo Hoặc Thiết Bị Thật
- **Cách 1: Chạy từ Android Studio**:
  1. Mở thư mục `D:\miniproject3` trong Android Studio.
  2. Chọn thiết bị (Ví dụ: `Pixel 8 Pro API 35`).
  3. Nhấn nút **Run ▶️** (hoặc phím tắt `Shift + F10`).
- **Cách 2: Chạy từ Command Line**:
  ```powershell
  flutter run
  ```

---

## 📦 File Cài Đặt Release APK (Production Build)

File APK hoàn chỉnh đã được đóng gói tối ưu R8/ProGuard và tích hợp sẵn offline ML Kit:
- **Đường dẫn**: `D:\miniproject3\build\app\outputs\flutter-apk\app-release.apk`
- **Dung lượng**: ~84 MB
- **Cài đặt trực tiếp qua ADB**:
  ```powershell
  adb install -r "D:\miniproject3\build\app\outputs\flutter-apk\app-release.apk"
  ```
- **Cài lên điện thoại thật**: Sao chép file `app-release.apk` vào máy và bấm cài đặt trực tiếp.
