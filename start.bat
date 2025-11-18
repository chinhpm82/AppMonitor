@echo off

:: Dòng này đảm bảo script luôn chạy từ thư mục chứa nó
:: (Để nó có thể tìm thấy file .jar)
cd /d %~dp0

:: 'javaw' dùng để chạy mà không hiện cửa sổ console đen
:: 'java' sẽ hiện cửa sổ console
"C:\Program Files\Java\jdk-17\bin\javaw.exe" -jar AppMonitor-1.0-all.jar > NUL 2>&1