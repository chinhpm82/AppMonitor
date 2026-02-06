class AppTranslations {
  static const Map<String, Map<String, String>> languages = {
    'vi': {
      // General
      'app_name': 'MoniGuard',
      'cancel': 'Hủy',
      'confirm': 'Xác nhận',
      'save_all': 'Lưu tất cả',
      'add': 'Thêm',
      'warning': 'Cảnh báo',
      'error': 'Lỗi',
      'success': 'Thành công',
      'password': 'Mật khẩu',
      'enter_password': 'Nhập mật khẩu',
      'admin_password': 'Mật khẩu quản trị',
      'auth_required': 'Xác thực quyền truy cập',
      'password_incorrect': 'Mật khẩu không đúng!',
      'old_password_incorrect': 'Mật khẩu cũ không đúng!',
      
      // Home
      'monitor_status_on': 'Đang bật Monitor',
      'monitor_status_off': 'Đang tắt Monitor',
      'monitor_desc': 'Ứng dụng đang theo dõi hoạt động Roblox trên máy tính này.',
      'turn_on': 'Bật Monitor',
      'turn_off': 'Tắt Monitor',
      'usage_log': 'Nhật ký sử dụng',
      'view_all': 'Xem tất cả',
      'no_recent_activity': 'Chưa có hoạt động nào gần đây.',
      'playing': 'Chơi',
      
      // Tray
      'tray_monitor_on': 'Bật [ON]',
      'tray_monitor_off': 'Tắt [OFF]',
      'tray_open_window': 'Mở cửa sổ',
      'tray_status_on': 'MONITOR: ON',
      'tray_status_off': 'MONITOR: OFF',

      // Config - Tabs
      'tab_schedule': 'Lịch biểu',
      'tab_monitoring': 'Giám sát',
      'tab_stats': 'Thống kê',
      'tab_notification': 'Thông báo',
      'tab_account': 'Tài khoản',
      'tab_general': 'Chung',
      
      // Config - Schedule
      'schedule_roblox': 'Lịch cho phép chơi Roblox',
      'schedule_other': 'Lịch duyệt Web / Ứng dụng khác',
      
      // Config - Monitoring
      'keywords_title': 'Từ khóa trình duyệt (Browser Keywords)',
      'keywords_subtitle': 'Phát hiện khi tiêu đề cửa sổ chứa các từ này (ví dụ: facebook, tiktok)',
      'keywords_hint': 'Nhập từ khóa...',
      'apps_title': 'Ứng dụng máy tính (.exe)',
      'apps_subtitle': 'Tên file chạy trong Task Manager (ví dụ: RobloxPlayerBeta.exe, discord.exe)',
      'apps_hint': 'Nhập tên file .exe...',
      'time_config_title': 'Cấu hình thời gian (Giây)',
      'delay_warning': 'Cảnh báo sau',
      'delay_overlay': 'Hiện Overlay sau',
      'delay_kill': 'Tắt App sau',
      'overlay_note': '* Overlay giúp chặn tương tác chuột khi vi phạm trên trình duyệt.',
      
      // Config - Stats
      'no_stats_data': 'Chưa có dữ liệu thống kê.',
      
      // Config - Notification
      'tele_config_title': 'Cấu hình Telegram:',
      'tele_desc': 'Nhận thông báo khi phát hiện vi phạm.',
      'bot_token': 'Bot Token',
      'chat_id': 'Chat ID',
      'debounce': 'Giãn cách (phút)',
      'msg_template': 'Mẫu tin nhắn',
      'template_hint': '{reason} tại {time}',
      'template_note': 'Gợi ý: {reason} = Lý do, {time} = Thời gian',
      'send_test': 'Gửi tin nhắn test (Lưu trước khi gửi)',
      'test_sending': 'Đang gửi tin nhắn test...',
      'test_success': '✅ Gửi thành công! Kiểm tra Telegram của bạn.',
      'test_fail': '❌ Gửi thất bại. Kiểm tra Token/ID và mạng.',
      'tele_guide_title': 'Hướng dẫn cấu hình Telegram',
      'guide_step_1': 'Chat với @BotFather trên Telegram, gửi /newbot để tạo bot và lấy Token.',
      'guide_step_2': 'Tìm Bot bạn vừa tạo, bấm Start và gửi tin nhắn bất kỳ cho nó.',
      'guide_step_3': 'Truy cập https://api.telegram.org/bot<TOKEN>/getUpdates để lấy Chat ID.',
      'guide_step_4': 'Nhập Token và Chat ID vào đây, nhấn Lưu và Gửi thử để kiểm tra.',
      'test_msg_content': '🔔 Test Connect from MoniGuard!\nKết nối thành công.',

      // Config - Account
      'change_pass_title': 'Đổi mật khẩu:',
      'current_pass': 'Mật khẩu hiện tại',
      'new_pass': 'Mật khẩu mới',
      'account_note': 'Lưu ý: Bạn chọn các khung giờ ĐƯỢC PHÉP chơi. Các khung giờ không tích sẽ bị chặn hoàn toàn khi Monitor ở trạng thái BẬT.',
      'language': 'Ngôn ngữ (Language)',
      
      // Overlay
      'sites_blocked_title': 'TRANG WEB BỊ CHẶN',
      'sites_blocked_msg': 'Bạn đang truy cập trang web có nội dung bị giới hạn.\nTrình duyệt sẽ bị tắt sau giây lát.',
      
      // Messages
      'msg_roblox_app': 'Chơi Roblox App',
      'msg_restricted_app': 'Ứng dụng giới hạn: {0}',
      'msg_roblox_web': 'Chơi Roblox trên Web ({0})',
      'msg_restricted_web': 'Truy cập nội dung giới hạn trên trình duyệt ({0})',
      'warn_app': 'Ứng dụng \'{0}\' không được phép lúc này!',
      'warn_roblox': 'Không được phép chơi Roblox vào thời gian này!',
      'warn_web_roblox': 'Không được phép xem nội dung Roblox vào lúc này!',
      'warn_web_restricted': 'Không được phép xem nội dung giới hạn vào lúc này!',
    },
    'en': {
      // General
      'app_name': 'MoniGuard',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save_all': 'Save All',
      'add': 'Add',
      'warning': 'Warning',
      'error': 'Error',
      'success': 'Success',
      'password': 'Password',
      'enter_password': 'Enter Password',
      'admin_password': 'Admin Password',
      'auth_required': 'Access Authentication',
      'password_incorrect': 'Incorrect password!',
      'old_password_incorrect': 'Incorrect old password!',

      // Home
      'monitor_status_on': 'Monitor is ON',
      'monitor_status_off': 'Monitor is OFF',
      'monitor_desc': 'Application is monitoring Roblox activity on this computer.',
      'turn_on': 'Turn ON',
      'turn_off': 'Turn OFF',
      'usage_log': 'Usage Log',
      'view_all': 'View All',
      'no_recent_activity': 'No recent activity.',
      'playing': 'Playing',

      // Tray
      'tray_monitor_on': 'Enable [ON]',
      'tray_monitor_off': 'Disable [OFF]',
      'tray_open_window': 'Open Window',
      'tray_status_on': 'MONITOR: ON',
      'tray_status_off': 'MONITOR: OFF',

      // Config - Tabs
      'tab_schedule': 'Schedule',
      'tab_monitoring': 'Monitoring',
      'tab_stats': 'Stats',
      'tab_notification': 'Notify',
      'tab_account': 'Account',
      'tab_general': 'General',

      // Config - Schedule
      'schedule_roblox': 'Roblox Schedule',
      'schedule_other': 'Web / Other Apps Schedule',

      // Config - Monitoring
      'keywords_title': 'Browser Keywords',
      'keywords_subtitle': 'Detects when window title contains these words (e.g., facebook, tiktok)',
      'keywords_hint': 'Enter keyword...',
      'apps_title': 'Desktop Apps (.exe)',
      'apps_subtitle': 'Process name in Task Manager (e.g., RobloxPlayerBeta.exe)',
      'apps_hint': 'Enter .exe name...',
      'time_config_title': 'Time Configuration (Seconds)',
      'delay_warning': 'Warn after',
      'delay_overlay': 'Overlay after',
      'delay_kill': 'Kill App after',
      'overlay_note': '* Overlay blocks mouse interaction on detection.',

      // Config - Stats
      'no_stats_data': 'No statistics data available.',

      // Config - Notification
      'tele_config_title': 'Telegram Configuration:',
      'tele_desc': 'Receive notifications when violation detected.',
      'bot_token': 'Bot Token',
      'chat_id': 'Chat ID',
      'debounce': 'Box Interval (min)',
      'msg_template': 'Message Template',
      'template_hint': '{reason} at {time}',
      'template_note': 'Hint: {reason} = Reason, {time} = Time',
      'send_test': 'Send Test Message (Save first)',
      'test_sending': 'Sending test message...',
      'test_success': '✅ Sent successfully! Check your Telegram.',
      'test_fail': '❌ Send failed. Check Token/ID and network.',
      'tele_guide_title': 'Telegram Setup Guide',
      'guide_step_1': 'Chat with @BotFather on Telegram, send /newbot to create bot & get Token.',
      'guide_step_2': 'Find your new Bot, press Start and send any message to it.',
      'guide_step_3': 'Visit https://api.telegram.org/bot<TOKEN>/getUpdates to get Chat ID.',
      'guide_step_4': 'Enter Token and Chat ID here, press Save then Send Test.',
      'test_msg_content': '🔔 Test Connect from MoniGuard!\nConnection successful.',

      // Config - Account
      'change_pass_title': 'Change Password:',
      'current_pass': 'Current Password',
      'new_pass': 'New Password',
      'account_note': 'Note: Selected slots are ALLOWED. Unchecked slots will be BLOCKED when Monitor is ON.',
      'language': 'Ngôn ngữ (Language)',

      // Overlay
      'sites_blocked_title': 'WEBSITE BLOCKED',
      'sites_blocked_msg': 'You are accessing restricted content.\nThe browser will close shortly.',

      // Messages
      'msg_roblox_app': 'Playing Roblox App',
      'msg_restricted_app': 'Restricted App: {0}',
      'msg_roblox_web': 'Playing Roblox Web ({0})',
      'msg_restricted_web': 'Restricted Browser Content ({0})',
      'warn_app': 'App \'{0}\' is not allowed right now!',
      'warn_roblox': 'Roblox is not allowed at this time!',
      'warn_web_roblox': 'Roblox content is not allowed right now!',
      'warn_web_restricted': 'Restricted content is not allowed right now!',
    },
  };
}
