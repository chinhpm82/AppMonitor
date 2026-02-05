$pngPath = "d:\IT\GitHub\RobloxMonitor\assets\app_icon.png"
$icoPath = "d:\IT\GitHub\RobloxMonitor\windows\runner\resources\app_icon.ico"
$icoAssetsPath = "d:\IT\GitHub\RobloxMonitor\assets\app_icon.ico"

# Load PNG and resize to 256x256 just in case
Add-Type -AssemblyName System.Drawing
$bmp = [System.Drawing.Bitmap]::FromFile($pngPath)
$resized = New-Object System.Drawing.Bitmap(256, 256)
$g = [System.Drawing.Graphics]::FromImage($resized)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($bmp, 0, 0, 256, 256)
$g.Dispose()

# Save resized as temporary PNG to get the bytes
$ms = New-Object System.IO.MemoryStream
$resized.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
$pngBytes = $ms.ToArray()
$ms.Dispose()
$resized.Dispose()
$bmp.Dispose()

# Manual ICO Construction (PNG-in-ICO format)
$size = $pngBytes.Length
$icoBytes = New-Object byte[] (22 + $size)

# ICONDIR header
$icoBytes[0] = 0; $icoBytes[1] = 0  # Reserved
$icoBytes[2] = 1; $icoBytes[3] = 0  # Type (1 = Icon)
$icoBytes[4] = 1; $icoBytes[5] = 0  # Count (1 image)

# ICONDIRENTRY
$icoBytes[6] = 0    # Width (0 = 256)
$icoBytes[7] = 0    # Height (0 = 256)
$icoBytes[8] = 0    # Colors
$icoBytes[9] = 0    # Reserved
$icoBytes[10] = 1; $icoBytes[11] = 0 # Planes
$icoBytes[12] = 32; $icoBytes[13] = 0 # BPP (32 bit)

# Size of PNG data (4 bytes, little-endian)
$icoBytes[14] = $size -band 0xff
$icoBytes[15] = ($size -shr 8) -band 0xff
$icoBytes[16] = ($size -shr 16) -band 0xff
$icoBytes[17] = ($size -shr 24) -band 0xff

# Offset of PNG data (4 bytes, little-endian, always 22)
$icoBytes[18] = 22
$icoBytes[19] = 0
$icoBytes[20] = 0
$icoBytes[21] = 0

# Copy PNG data
[System.Buffer]::BlockCopy($pngBytes, 0, $icoBytes, 22, $size)

# Write to both locations
[System.IO.File]::WriteAllBytes($icoPath, $icoBytes)
[System.IO.File]::WriteAllBytes($icoAssetsPath, $icoBytes)
