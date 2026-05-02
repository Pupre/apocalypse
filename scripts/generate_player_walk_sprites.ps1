Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root "resources/world/city/player"

function New-Color {
    param([int] $A, [int] $R, [int] $G, [int] $B)
    return [System.Drawing.Color]::FromArgb($A, $R, $G, $B)
}

function New-Brush {
    param([System.Drawing.Color] $Color)
    return [System.Drawing.SolidBrush]::new($Color)
}

function New-Pen {
    param([System.Drawing.Color] $Color, [float] $Width = 1.0)
    return [System.Drawing.Pen]::new($Color, $Width)
}

function Add-RoundedRect {
    param([System.Drawing.Drawing2D.GraphicsPath] $Path, [float] $X, [float] $Y, [float] $W, [float] $H, [float] $R)
    $d = $R * 2.0
    $Path.AddArc($X, $Y, $d, $d, 180, 90)
    $Path.AddArc($X + $W - $d, $Y, $d, $d, 270, 90)
    $Path.AddArc($X + $W - $d, $Y + $H - $d, $d, $d, 0, 90)
    $Path.AddArc($X, $Y + $H - $d, $d, $d, 90, 90)
    $Path.CloseFigure()
}

function Fill-RoundedRect {
    param([System.Drawing.Graphics] $G, [float] $X, [float] $Y, [float] $W, [float] $H, [float] $R, [System.Drawing.Brush] $Brush)
    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    Add-RoundedRect $path $X $Y $W $H $R
    $G.FillPath($Brush, $path)
    $path.Dispose()
}

function Draw-Line {
    param([System.Drawing.Graphics] $G, [System.Drawing.Pen] $Pen, [float] $X1, [float] $Y1, [float] $X2, [float] $Y2)
    $G.DrawLine($Pen, $X1, $Y1, $X2, $Y2)
}

function Draw-BodyFrontBack {
    param([System.Drawing.Graphics] $G, [string] $Facing, [int] $Frame)

    $step = @(0, 3, 5, 3, 0, -3, -5, -3)[$Frame]
    $bob = @(0, -1, -2, -1, 0, -1, -2, -1)[$Frame]
    $idle = $Frame -lt 0
    if ($idle) { $step = 0; $bob = 0 }

    $shadowBrush = New-Brush (New-Color 72 0 0 0)
    $G.FillEllipse($shadowBrush, 21, 54, 22, 5)
    $shadowBrush.Dispose()

    $outline = New-Pen (New-Color 215 8 14 17) 3.2
    $legPen = New-Pen (New-Color 255 24 35 38) 5.0
    $bootPen = New-Pen (New-Color 255 9 13 14) 5.2
    $armPen = New-Pen (New-Color 255 19 31 32) 5.0
    $glovePen = New-Pen (New-Color 255 83 111 82) 5.0

    $leftFootX = 26 - $step
    $rightFootX = 38 + $step
    $leftFootY = 55 + [Math]::Max(0, $step) * 0.28
    $rightFootY = 55 + [Math]::Max(0, -$step) * 0.28
    if ($Facing -eq "up") {
        $leftFootY = 54 + [Math]::Max(0, -$step) * 0.2
        $rightFootY = 54 + [Math]::Max(0, $step) * 0.2
    }

    Draw-Line $G $outline 29 (40 + $bob) $leftFootX $leftFootY
    Draw-Line $G $outline 35 (40 + $bob) $rightFootX $rightFootY
    Draw-Line $G $legPen 29 (40 + $bob) $leftFootX $leftFootY
    Draw-Line $G $legPen 35 (40 + $bob) $rightFootX $rightFootY
    Draw-Line $G $bootPen ($leftFootX - 2) $leftFootY ($leftFootX + 3) $leftFootY
    Draw-Line $G $bootPen ($rightFootX - 3) $rightFootY ($rightFootX + 2) $rightFootY

    $armSwing = if ($idle) { 0 } else { -$step * 0.55 }
    Draw-Line $G $outline 23 (25 + $bob) (19 + $armSwing) (43 + $bob)
    Draw-Line $G $outline 41 (25 + $bob) (45 + $armSwing) (43 + $bob)
    Draw-Line $G $armPen 23 (25 + $bob) (19 + $armSwing) (43 + $bob)
    Draw-Line $G $armPen 41 (25 + $bob) (45 + $armSwing) (43 + $bob)
    Draw-Line $G $glovePen (19 + $armSwing) (43 + $bob) (17 + $armSwing) (46 + $bob)
    Draw-Line $G $glovePen (45 + $armSwing) (43 + $bob) (47 + $armSwing) (46 + $bob)

    $coatBrush = New-Brush (New-Color 255 38 51 55)
    $coatLight = New-Brush (New-Color 255 67 86 91)
    Fill-RoundedRect $G 21 (18 + $bob) 22 28 7 $coatBrush
    $G.FillRectangle($coatLight, 31, (21 + $bob), 2, 23)
    $coatLight.Dispose()
    $coatBrush.Dispose()

    if ($Facing -eq "up") {
        $packBrush = New-Brush (New-Color 255 135 103 62)
        Fill-RoundedRect $G 23 (22 + $bob) 18 20 4 $packBrush
        $packBrush.Dispose()
    } else {
        $zipPen = New-Pen (New-Color 190 188 216 220) 1.4
        Draw-Line $G $zipPen 32 (21 + $bob) 32 (44 + $bob)
        $zipPen.Dispose()
        $scarfPen = New-Pen (New-Color 255 92 121 78) 2.5
        Draw-Line $G $scarfPen 24 (20 + $bob) 40 (20 + $bob)
        $scarfPen.Dispose()
    }

    $hoodBrush = New-Brush (New-Color 255 20 29 34)
    $furBrush = New-Brush (New-Color 235 210 222 217)
    $faceBrush = New-Brush (New-Color 255 238 198 151)
    Fill-RoundedRect $G 22 (8 + $bob) 20 15 6 $hoodBrush
    if ($Facing -eq "down") {
        $G.FillEllipse($faceBrush, 26, (11 + $bob), 12, 8)
    }
    $furPen = New-Pen (New-Color 230 209 225 222) 2.0
    Draw-Line $G $furPen 24 (10 + $bob) 40 (10 + $bob)
    $furPen.Dispose()
    $faceBrush.Dispose()
    $furBrush.Dispose()
    $hoodBrush.Dispose()
    $outline.Dispose()
    $legPen.Dispose()
    $bootPen.Dispose()
    $armPen.Dispose()
    $glovePen.Dispose()
}

function Draw-BodySide {
    param([System.Drawing.Graphics] $G, [string] $Facing, [int] $Frame)

    $sign = if ($Facing -eq "right") { 1 } else { -1 }
    $step = @(0, 4, 7, 4, 0, -4, -7, -4)[$Frame]
    $bob = @(0, -1, -2, -1, 0, -1, -2, -1)[$Frame]
    $idle = $Frame -lt 0
    if ($idle) { $step = 0; $bob = 0 }

    $shadowBrush = New-Brush (New-Color 72 0 0 0)
    $G.FillEllipse($shadowBrush, 21, 54, 22, 5)
    $shadowBrush.Dispose()

    $outline = New-Pen (New-Color 215 8 14 17) 3.2
    $legPen = New-Pen (New-Color 255 24 35 38) 5.0
    $bootPen = New-Pen (New-Color 255 9 13 14) 5.2
    $armPen = New-Pen (New-Color 255 19 31 32) 5.0
    $glovePen = New-Pen (New-Color 255 83 111 82) 5.0

    $frontFootX = 32 + ($sign * (4 + [Math]::Max(0, $step)))
    $backFootX = 32 - ($sign * (4 + [Math]::Max(0, -$step)))
    $frontFootY = 55
    $backFootY = 54
    Draw-Line $G $outline 32 (41 + $bob) $backFootX $backFootY
    Draw-Line $G $outline 33 (41 + $bob) $frontFootX $frontFootY
    Draw-Line $G $legPen 32 (41 + $bob) $backFootX $backFootY
    Draw-Line $G $legPen 33 (41 + $bob) $frontFootX $frontFootY
    Draw-Line $G $bootPen ($backFootX - 2 * $sign) $backFootY ($backFootX + 3 * $sign) $backFootY
    Draw-Line $G $bootPen ($frontFootX - 2 * $sign) $frontFootY ($frontFootX + 4 * $sign) $frontFootY

    $armSwing = if ($idle) { 0 } else { $step * 0.35 }
    Draw-Line $G $outline 31 (25 + $bob) (28 - $sign * $armSwing) (43 + $bob)
    Draw-Line $G $outline 36 (25 + $bob) (39 + $sign * $armSwing) (43 + $bob)
    Draw-Line $G $armPen 31 (25 + $bob) (28 - $sign * $armSwing) (43 + $bob)
    Draw-Line $G $armPen 36 (25 + $bob) (39 + $sign * $armSwing) (43 + $bob)
    Draw-Line $G $glovePen (28 - $sign * $armSwing) (43 + $bob) (26 - $sign * $armSwing) (46 + $bob)
    Draw-Line $G $glovePen (39 + $sign * $armSwing) (43 + $bob) (41 + $sign * $armSwing) (46 + $bob)

    $coatBrush = New-Brush (New-Color 255 38 51 55)
    Fill-RoundedRect $G 23 (18 + $bob) 19 28 7 $coatBrush
    $coatBrush.Dispose()

    $packBrush = New-Brush (New-Color 255 126 94 56)
    if ($sign -eq 1) {
        Fill-RoundedRect $G 21 (24 + $bob) 8 16 3 $packBrush
    } else {
        Fill-RoundedRect $G 35 (24 + $bob) 8 16 3 $packBrush
    }
    $packBrush.Dispose()

    $hoodBrush = New-Brush (New-Color 255 20 29 34)
    $faceBrush = New-Brush (New-Color 255 238 198 151)
    Fill-RoundedRect $G 22 (8 + $bob) 20 15 6 $hoodBrush
    if ($sign -eq 1) {
        $G.FillEllipse($faceBrush, 34, (12 + $bob), 7, 7)
    } else {
        $G.FillEllipse($faceBrush, 23, (12 + $bob), 7, 7)
    }
    $furPen = New-Pen (New-Color 230 209 225 222) 2.0
    Draw-Line $G $furPen 24 (10 + $bob) 40 (10 + $bob)
    $scarfPen = New-Pen (New-Color 255 92 121 78) 2.4
    Draw-Line $G $scarfPen 25 (20 + $bob) 39 (20 + $bob)
    $scarfPen.Dispose()
    $furPen.Dispose()
    $hoodBrush.Dispose()
    $faceBrush.Dispose()
    $outline.Dispose()
    $legPen.Dispose()
    $bootPen.Dispose()
    $armPen.Dispose()
    $glovePen.Dispose()
}

function Write-Frame {
    param([string] $Facing, [int] $Frame)
    $name = if ($Frame -lt 0) { "${Facing}_idle.png" } else { "${Facing}_walk$($Frame + 1).png" }
    $bitmap = [System.Drawing.Bitmap]::new(64, 64, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear([System.Drawing.Color]::Transparent)
    if ($Facing -in @("left", "right")) {
        Draw-BodySide $graphics $Facing $Frame
    } else {
        Draw-BodyFrontBack $graphics $Facing $Frame
    }
    $path = Join-Path $outDir $name
    $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
}

foreach ($facing in @("down", "up", "left", "right")) {
    Write-Frame $facing -1
    for ($frame = 0; $frame -lt 8; $frame++) {
        Write-Frame $facing $frame
    }
}

Write-Output "Player walk sprites generated."
