Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' Lấy đường dẫn thư mục chứa file vbs hiện tại
CurrentDirectory = fso.GetParentFolderName(WScript.ScriptFullName)

' Tạo đường dẫn đầy đủ tới file start.bat
BatPath = CurrentDirectory & "\start.bat"

' Chạy file bat (số 0 nghĩa là ẩn cửa sổ đen, False nghĩa là không đợi chạy xong)
WshShell.Run chr(34) & BatPath & chr(34), 0, False