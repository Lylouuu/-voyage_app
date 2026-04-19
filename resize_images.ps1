Add-Type -AssemblyName System.Drawing

$basePath = "C:\Users\DELL\-voyage_app\assets\images"
$files = @("onboarding1.jpg","onboarding2.jpg","onboarding3.jpg")

foreach ($f in $files) {
    $srcPath = Join-Path $basePath $f
    $dstPath = Join-Path $basePath ("resized_" + $f)
    
    $img = [System.Drawing.Image]::FromFile($srcPath)
    Write-Host "$f : $($img.Width)x$($img.Height)"
    
    # Resize to max 1080px wide (phone screen width)
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
    
    # Save with JPEG quality 75
    $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
    $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 75L)
    $bmp.Save($dstPath, $jpegCodec, $encoderParams)
    
    $graphics.Dispose()
    $bmp.Dispose()
    $img.Dispose()
    
    Write-Host "Resized $f -> $newWidth x $newHeight"
}

# Replace originals with resized versions
foreach ($f in $files) {
    $srcPath = Join-Path $basePath $f
    $dstPath = Join-Path $basePath ("resized_" + $f)
    Remove-Item $srcPath
    Rename-Item $dstPath $f
}

Write-Host "Done!"
