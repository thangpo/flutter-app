HƯỚNG DẪN CÀI ĐẶT FLUTTER SDK VÀ CHẠY DỰ ÁN TRÊN ANDROID STUDIO (WINDOWS 11)
⚙️ 1. Yêu cầu hệ thống

Trước khi cài đặt, đảm bảo máy bạn đáp ứng:

Hệ điều hành: Windows 10 hoặc 11 (64-bit)

Dung lượng trống: ít nhất 10 GB

RAM: ít nhất 8 GB (khuyến nghị 16 GB nếu chạy Android Emulator)

Quyền: Có quyền Administrator

🧩 2. Cài đặt Flutter SDK
🔹 Bước 1: Tải Flutter SDK

👉 Truy cập trang chính thức:
🔗 https://flutter.dev/docs/get-started/install/windows

Hoặc tải bản stable trực tiếp (ví dụ 2025):
🔗 https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.0-stable.zip

🔹 Bước 2: Giải nén SDK

Giải nén file flutter_windows_x.x.x-stable.zip vào vị trí cố định, ví dụ:

C:\src\flutter


(Không nên để trong thư mục có khoảng trắng như “Program Files”)

🔹 Bước 3: Thêm Flutter vào PATH

Nhấn Start → Gõ “Edit environment variables” → Enter

Trong tab System variables, chọn Path → Edit → New

Dán đường dẫn:

C:\src\flutter\bin


Nhấn OK để lưu lại.

🔹 Bước 4: Kiểm tra cài đặt

Mở Command Prompt (CMD) hoặc PowerShell, nhập:

flutter doctor


Nếu bạn thấy dòng như:

Doctor summary (to see all details, run flutter doctor -v):
[√] Flutter (Channel stable, 3.x.x, on Microsoft Windows [version 11], locale en-US)


là đã cài thành công 🎉

🧰 3. Cài đặt Android Studio (phiên bản mới nhất)
🔹 Bước 1: Tải và cài đặt Android Studio

👉 Link chính thức:
🔗 https://developer.android.com/studio

Tải bản mới nhất (ví dụ: Android Studio Ladybug | 2025).

Chạy file .exe và cài đặt theo hướng dẫn mặc định.

🔹 Bước 2: Cài Flutter Plugin trong Android Studio

Mở Android Studio

Vào File → Settings → Plugins

Gõ “Flutter” trong ô tìm kiếm

Nhấn Install Flutter Plugin (plugin Dart sẽ tự cài kèm)

Khởi động lại Android Studio

📱 4. Cấu hình Android SDK & AVD (Giả lập)
🔹 Bước 1: Cài Android SDK & Platform Tools

Mở Android Studio

Vào More Actions → SDK Manager

Trong tab SDK Platforms, chọn:

Android 13 (Tiramisu) hoặc Android 14

Trong tab SDK Tools, chọn:

Android SDK Build-Tools

Android Emulator

Android SDK Platform-Tools

Google USB Driver

Nhấn Apply → OK để tải.

🔹 Bước 2: Tạo thiết bị ảo (AVD)

Vào More Actions → Device Manager

Nhấn Create Device

Chọn một thiết bị (VD: Pixel 7)

Chọn image hệ điều hành (VD: Android 14)

Nhấn Finish

🚀 5. Chạy dự án Flutter trong Android Studio
🔹 Bước 1: Mở dự án Flutter

Trong Android Studio → Open → Chọn thư mục dự án Flutter

🔹 Bước 2: Cài các package cần thiết

Mở terminal trong Android Studio (hoặc CMD trong thư mục dự án):

flutter pub get

🔹 Bước 3: Kiểm tra thiết bị
flutter devices


Kết quả ví dụ:

1 connected device:
emulator-5554 • Pixel_7_API_34 • android • Android 14 (API 34)

🔹 Bước 4: Chạy ứng dụng
flutter run


Hoặc trong Android Studio → Nhấn nút ▶️ (Run).

🧾 6. Kiểm tra toàn bộ cài đặt

Chạy:

flutter doctor


Nếu có dấu “√” ở tất cả mục:

[√] Flutter
[√] Android toolchain
[√] Android Studio
[√] Connected device


→ Bạn đã sẵn sàng lập trình Flutter 🎉