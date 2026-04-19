Add-Type -AssemblyName System.Drawing

$srcPath = "C:\Users\DELL\-voyage_app\assets\images\onboarding3.jpg"
$dstPath = "C:\Users\DELL\-voyage_app\assets\images\resized_onboarding3.jpg"

$img = [System.Drawing.Image]::FromFile($srcPath)
Write-Host "Original: $($img.Width)x$($img.Height)"

$maxWidth = 1080
if ($img.Width -gt $maxWidth) {
    $ratio = $maxWidth / $img.Width
    $newWidth = [int]($img.Width * $ratio)
    $newHeight = [int]($img.Height * $ratio)
} else {
    $newWidth = $img.Width
    $newHeight = $img.Height
}

$bmp = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
$graphics = [System.Drawing.Graphics]::FromImage($bmp)
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.DrawImage($img, 0, 0, $newWidth, $newHeight)

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 75L)
$bmp.Save($dstPath, $jpegCodec, $encoderParams)

$graphics.Dispose()
$bmp.Dispose()
$img.Dispose()

Remove-Item $srcPath
Rename-Item $dstPath "onboarding3.jpg"

Write-Host "Resized to $newWidth x $newHeight - Done!"
