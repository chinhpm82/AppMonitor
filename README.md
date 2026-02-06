# Roblox Monitor

Ứng dụng giám sát và quản lý thời gian chơi Roblox trên Windows.

## ✨ Tính năng chính
- **Giám sát Chặt chẽ**:
  - Phát hiện **Roblox App (Client)** đang chạy.
  - Phát hiện truy cập Roblox hoặc YouTube trên trình duyệt (Chrome, Edge, Firefox...).
- **Lịch biểu Linh hoạt**: Cấu hình khung giờ ĐƯỢC PHÉP chơi cho từng ngày trong tuần.
- **Cảnh báo & Chặn**:
  - Hiển thị cảnh báo toàn màn hình khi vi phạm.
  - Tự động tắt game/trình duyệt nếu cố tình vi phạm.
- **Báo cáo Telegram**: Tự động chụp ảnh màn hình và gửi báo cáo về điện thoại bố mẹ khi phát hiện chơi.
- **Thống kê**: Xem lại lịch sử thời lượng chơi.

---

## 📥 Hướng dẫn Cài đặt

1. **Tải phần mềm**: Tải file cài đặt `RobloxMonitor_Setup.exe` (hoặc bản Portable).
2. **Cài đặt**: Chạy file cài đặt, nhấn Next để hoàn tất.
3. **Chạy lần đầu**:
   - Mở `RobloxMonitor` từ Desktop hoặc Start Menu.
   - *Lưu ý*: Nếu Windows hiện cảnh báo **SmartScreen** (do app chưa có chứng chỉ số), vui lòng chọn **More info** -> **Run anyway**.

---

## ⚙️ Hướng dẫn Cấu hình

Khi mở ứng dụng từ System Tray (khay hệ thống) hoặc lần đầu chạy, bạn cần đăng nhập.
🔑 **Mật khẩu mặc định:** `admin`

### 1. Cấu hình Lịch biểu (Schedule)
- Chọn tab **Lịch biểu**.
- Có 2 bảng cấu hình:
  - **Lịch cho phép chơi Roblox**: Áp dụng cho Game Client.
  - **Lịch cho phép xem YouTube**: Áp dụng cho Trình duyệt.
- **Cách chọn giờ**:
  - Các ô được **TÍCH MÀU XANH** là thời gian **ĐƯỢC PHÉP** sử dụng.
  - Các ô **TRỐNG (MÀU ĐEN)** là thời gian **BỊ CẤM**.
- Bấm **Lưu tất cả** để áp dụng.

### 2. Cấu hình Telegram (Nhận thông báo từ xa)
Để nhận tin nhắn và ảnh chụp màn hình khi con chơi game, bạn cần tạo một Telegram Bot:

#### Bước 1: Tạo Bot và lấy Token
1. Mở app Telegram, tìm và chat với **@BotFather**.
2. Gửi lệnh `/newbot`.
3. Đặt **Tên hiển thị** và **Username** cho bot theo hướng dẫn của BotFather.
4. Copy **HTTP API Token** được cấp.
   - *Ví dụ:* `8502976200:AAG6u...` (nằm sau dòng "Use this token to access the HTTP API").

#### Bước 2: Lấy Chat ID
1. Tìm Bot bạn vừa tạo trên Telegram và bấm **Start**.
2. Gửi một tin nhắn bất kỳ cho Bot (ví dụ: `hello`).
3. Mở trình duyệt web, truy cập link sau (thay Token của bạn vào):
   `https://api.telegram.org/bot<TOKEN_CUA_BAN>/getUpdates`
4. Tìm dòng `"chat":{"id":123456789...`. Số `123456789` chính là **Chat ID**.

#### Bước 3: Nhập vào App
1. Quay lại Roblox Monitor, chọn tab **Thông báo**.
2. Nhập **Bot Token** và **Chat ID**.
3. Bấm **Gửi tin nhắn test** để kiểm tra kêt nối.
4. Bấm **Lưu tất cả**.

### 3. Đổi mật khẩu
- Để tránh trẻ tự vào thay đổi cài đặt, hãy vào tab **Tài khoản**.
- Nhập mật khẩu cũ (`admin`) và thiết lập mật khẩu mới.

---

## 📖 Hướng dẫn Sử dụng & Vận hành

- **Chế độ chạy ngầm**: Khi bạn đóng cửa sổ cấu hình (nút X hoặc Hủy), ứng dụng **KHÔNG TẮT** mà sẽ thu nhỏ xuống **System Tray** (góc dưới bên phải, cạnh đồng hồ/loa).
- **Icon**: Biểu tượng hình chiếc khiên màu xanh (hoặc logo Roblox Monitor).
- **Mở lại cấu hình**: Double-click vào icon ở khay hệ thống, nhập mật khẩu để mở lại bảng điều khiển.
- **Thoát hoàn toàn**: Vào task manager, tìm process Roblox Monitor và kill nó.
---

## 🛠 Yêu cầu hệ thống
- Hệ điều hành: **Windows 10 / 11** (64-bit).
- Môi trường: .NET Framework (mặc định có sẵn trên Win 10/11) để hỗ trợ các chức năng hệ thống.