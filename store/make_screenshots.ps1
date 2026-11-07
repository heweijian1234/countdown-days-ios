Add-Type -AssemblyName System.Drawing
$W = 1290; $H = 2796
$OUT = 'E:\AI-Projects\个人成长\10-项目\SaaS项目\countdown-days-ios\store'
if (-not (Test-Path $OUT)) { New-Item -ItemType Directory $OUT | Out-Null }

function New-Bg($w, $h, $c1, $c2, $c3, $c4) {
    $bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, [System.Drawing.Color]::FromArgb($c1,$c2,$c3), [System.Drawing.Color]::FromArgb($c2,$c3,$c4), 60)
    $g.FillRectangle($bg, $rect)
    return @($bmp, $g)
}
function Card($g, $x, $y, $w, $h) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $r = 36
    $path.AddArc($x, $y, $r, $r, 180, 90); $path.AddArc($x+$w-$r, $y, $r, $r, 270, 90)
    $path.AddArc($x+$w-$r, $y+$h-$r, $r, $r, 0, 90); $path.AddArc($x, $y+$h-$r, $r, $r, 90, 90)
    $path.CloseFigure()
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(40, 255, 255, 255))
    $g.FillPath($brush, $path)
}
function CardSolid($g, $x, $y, $w, $h, $a, $r_, $gr, $b) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $r = 44
    $path.AddArc($x, $y, $r, $r, 180, 90); $path.AddArc($x+$w-$r, $y, $r, $r, 270, 90)
    $path.AddArc($x+$w-$r, $y+$h-$r, $r, $r, 0, 90); $path.AddArc($x, $y+$h-$r, $r, $r, 90, 90)
    $path.CloseFigure()
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($a, $r_, $gr, $b))
    $g.FillPath($brush, $path)
}
function Txt($g, $t, $x, $y, $size, $bold, $r, $gr, $b) {
    $style = if ($bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
    $font = New-Object System.Drawing.Font('Segoe UI', $size, $style)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($r, $gr, $b))
    $g.DrawString($t, $font, $brush, $x, $y)
}
function CenterTxt($g, $t, $y, $size, $bold, $r, $gr, $b) {
    $style = if ($bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
    $font = New-Object System.Drawing.Font('Segoe UI', $size, $style)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($r, $gr, $b))
    $m = $g.MeasureString($t, $font)
    $x = ([single]($script:W) - $m.Width) / 2
    $g.DrawString($t, $font, $brush, $x, $y)
}

# ========== shot1 主页（暖粉渐变，顶部 App 名 + 中央大小组件 + 事件卡列表）==========
$c = New-Bg $W $H 46 20 48 84; $bmp = $c[0]; $g = $c[1]
CenterTxt $g 'Countdown Widget - Days' 150 58 $true 255 255 255
CenterTxt $g 'Every event, one glance away' 250 36 $false 255 214 170

# 中央大卡片（模拟桌面小组件 medium：两个事件并排）
CardSolid $g 130 420 1030 460 230 255 255 255
# 左：度假倒数
Txt $g 'Trip to Tokyo' 190 470 38 $true 60 40 90
Txt $g '42' 190 540 150 $true 244 63 94
Txt $g 'days left' 190 700 34 $false 150 130 150
# 右：生日循环
Txt $g 'Emma birthday' 700 470 38 $true 60 40 90
Txt $g '128' 700 540 150 $true 244 63 94
Txt $g 'days · repeats yearly' 700 700 30 $false 150 130 150

Card $g 130 1050 ($W-260) 200
CenterTxt $g 'Birthdays · trips · anniversaries · exams' 1110 40 $false 235 225 240

Card $g 130 1330 ($W-260) 260
Txt $g 'REPEATS YEARLY' 190 1380 38 $true 255 214 170
Txt $g 'Set once, counts down every year' 190 1445 40 $false 255 255 255
Txt $g 'Birthdays and anniversaries never need redoing' 190 1510 30 $false 210 195 220

Card $g 130 1670 ($W-260) 260
Txt $g 'HOME SCREEN WIDGETS' 190 1720 38 $true 255 214 170
Txt $g 'Small, medium and large' 190 1785 40 $false 255 255 255
Txt $g 'Your next event is always one glance away' 190 1850 30 $false 210 195 220

CenterTxt $g 'Free · No account · Works offline' 2030 44 $true 255 214 170
$bmp.Save("$OUT\shot1.png", [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()

# ========== shot2 事件列表页（白底，三张事件卡+emoji 图标）==========
$c = New-Bg $W $H 255 252 250 242; $bmp = $c[0]; $g = $c[1]
Txt $g 'My Events' 80 130 64 $true 60 40 90
Txt $g '3 events · next: Trip to Tokyo' 82 230 36 $false 130 120 140

$evY = 330
# 事件卡：emoji/名称/大数字/单位
foreach ($ev in @(@('✈️', 'Trip to Tokyo', '42', 'days left', 244, 63, 94, 'Jun 12, 2027'),
                  @('🎂', 'Emma birthday', '128', 'days · repeats yearly', 236, 100, 50, 'Mar 15 · every year'),
                  @('💍', 'Anniversary', '301', 'days · repeats yearly', 155, 60, 220, 'Sep 3 · every year'))) {
    CardSolid $g 70 $evY ($W-140) 300 255 255 255 255
    Txt $g $ev[0] 120 ($evY+40) 64 $false 0 0 0
    Txt $g $ev[1] 220 ($evY+55) 40 $false 70 60 90
    Txt $g $ev[2] 220 ($evY+110) 96 $true $ev[4] $ev[5] $ev[6]
    Txt $g $ev[3] 560 ($evY+150) 30 $false 150 140 160
    Txt $g $ev[7] 560 ($evY+95) 28 $false 170 160 180
    $evY += 340
}
CardSolid $g 70 $evY ($W-140) 160 244 63 94 255
CenterTxt $g '+  Add event' ($evY+45) 44 $true 255 255 255
CenterTxt $g 'No account. Everything stays on your device.' 2500 40 $true 60 40 90
$bmp.Save("$OUT\shot2.png", [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()

# ========== shot3 桌面小组件效果（渐变底，模拟手机桌面 4 个小组件）==========
$c = New-Bg $W $H 30 16 40 70; $bmp = $c[0]; $g = $c[1]
CenterTxt $g 'On your Home Screen' 150 58 $true 255 255 255
CenterTxt $g 'Small, medium, large widgets' 250 36 $false 255 214 170

# 模拟桌面图标行（圆角方块）
$ix = 150
foreach ($cc in @(@(244,63,94),@(236,160,50),@(80,170,120),@(70,130,240))) {
    CardSolid $g $ix 400 170 170 255 $cc[0] $cc[1] $cc[2]
    $ix += 230
}
$ix = 150
foreach ($cc in @(@(155,60,220),@(240,120,140),@(90,180,200),@(200,200,210))) {
    CardSolid $g $ix 620 170 170 255 $cc[0] $cc[1] $cc[2]
    $ix += 230
}

# 小组件 small（单事件）
CardSolid $g 130 900 480 480 230 255 255 255
Txt $g '✈️ Tokyo' 170 940 34 $false 70 60 90
Txt $g '42' 170 1000 130 $true 244 63 94
Txt $g 'days' 200 1180 36 $false 150 140 160
# 小组件 small（生日）
CardSolid $g 680 900 480 480 230 255 255 255
Txt $g '🎂 Emma' 720 940 34 $false 70 60 90
Txt $g '128' 720 1000 130 $true 236 100  50
Txt $g 'days' 780 1180 36 $false 150 140 160

# 小组件 medium（前4事件横排）
CardSolid $g 130 1480 1030 420 230 255 255 255
Txt $g 'Next up' 180 1530 38 $true 70 60 90
$wx = 180
foreach ($wd in @(@('✈️','42'), @('🎂','128'), @('💍','301'), @('🎓','89'))) {
    CardSolid $g $wx 1610 220 220 245 242 248 255
    Txt $g $wd[0] ($wx+15) 1620 50 $false 0 0 0
    Txt $g $wd[1] ($wx+15) 1690 60 $true 60 40 90
    $wx += 240
}
CenterTxt $g 'Tap to open · add from the app · all sizes' 2380 44 $true 255 214 170
$bmp.Save("$OUT\shot3.png", [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
Write-Output 'DONE 3 shots (Countdown Widget - Days)'
