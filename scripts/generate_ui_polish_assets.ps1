Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot

function New-UiPath {
    param([string] $RelativePath)
    $path = Join-Path $root $RelativePath
    $dir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
    return $path
}

function New-Color {
    param([int] $A, [int] $R, [int] $G, [int] $B)
    return [System.Drawing.Color]::FromArgb($A, $R, $G, $B)
}

function New-RoundedPath {
    param([float] $X, [float] $Y, [float] $W, [float] $H, [float] $Radius)
    $r = [Math]::Max(0.0, [Math]::Min($Radius, [Math]::Min($W, $H) / 2.0))
    $d = $r * 2.0
    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    if ($r -le 0.0) {
        $path.AddRectangle([System.Drawing.RectangleF]::new($X, $Y, $W, $H))
        return $path
    }
    $path.AddArc($X, $Y, $d, $d, 180, 90)
    $path.AddArc($X + $W - $d, $Y, $d, $d, 270, 90)
    $path.AddArc($X + $W - $d, $Y + $H - $d, $d, $d, 0, 90)
    $path.AddArc($X, $Y + $H - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

function Draw-FrostPanel {
    param(
        [System.Drawing.Graphics] $G,
        [int] $W,
        [int] $H,
        [int] $Radius,
        [System.Drawing.Color] $Top,
        [System.Drawing.Color] $Bottom,
        [System.Drawing.Color] $Border,
        [System.Drawing.Color] $Accent,
        [int] $Seed = 1,
        [bool] $Pressed = $false
    )

    $rect = [System.Drawing.RectangleF]::new(1.5, 1.5, $W - 3.0, $H - 3.0)
    $path = New-RoundedPath $rect.X $rect.Y $rect.Width $rect.Height $Radius
    $brush = [System.Drawing.Drawing2D.LinearGradientBrush]::new($rect, $Top, $Bottom, [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
    $G.FillPath($brush, $path)
    $brush.Dispose()

    $innerPen = [System.Drawing.Pen]::new((New-Color 34 255 255 255), 1.0)
    $innerPath = New-RoundedPath 4.0 4.0 ($W - 8.0) ($H - 8.0) ([Math]::Max(1, $Radius - 3))
    $G.DrawPath($innerPen, $innerPath)
    $innerPath.Dispose()
    $innerPen.Dispose()

    $borderPen = [System.Drawing.Pen]::new($Border, 1.6)
    $G.DrawPath($borderPen, $path)
    $borderPen.Dispose()

    $accentPen = [System.Drawing.Pen]::new($Accent, $(if ($Pressed) { 1.7 } else { 1.2 }))
    $G.DrawLine($accentPen, [float]($Radius + 4), [float]($H - 5), [float]($W - $Radius - 4), [float]($H - 5))
    $G.DrawLine($accentPen, [float]($W - 28), 5.0, [float]($W - 10), [float]($H - 12))
    $accentPen.Dispose()

    $gridPen = [System.Drawing.Pen]::new((New-Color 22 140 172 188), 1.0)
    for ($x = 48; $x -lt $W; $x += 48) {
        $G.DrawLine($gridPen, [float]$x, 8.0, [float]$x, [float]($H - 8))
    }
    for ($y = 34; $y -lt $H; $y += 34) {
        $G.DrawLine($gridPen, 8.0, [float]$y, [float]($W - 8), [float]$y)
    }
    $gridPen.Dispose()

    $rng = [System.Random]::new($Seed)
    $icePen = [System.Drawing.Pen]::new((New-Color 132 230 248 255), 1.0)
    for ($i = 0; $i -lt 26; $i++) {
        $edge = $rng.Next(0, 4)
        $len = $rng.Next(5, 20)
        if ($edge -eq 0) {
            $x = [float]$rng.Next(8, [Math]::Max(9, $W - 8))
            $G.DrawLine($icePen, $x, 1.0, $x + $rng.Next(-5, 6), [float]$rng.Next(3, 9))
        } elseif ($edge -eq 1) {
            $x = [float]$rng.Next(8, [Math]::Max(9, $W - 8))
            $G.DrawLine($icePen, $x, [float]($H - 2), $x + $rng.Next(-5, 6), [float]($H - $rng.Next(4, 11)))
        } elseif ($edge -eq 2) {
            $y = [float]$rng.Next(8, [Math]::Max(9, $H - 8))
            $G.DrawLine($icePen, 1.0, $y, [float]$rng.Next(5, 13), $y + $rng.Next(-4, 5))
        } else {
            $y = [float]$rng.Next(8, [Math]::Max(9, $H - 8))
            $G.DrawLine($icePen, [float]($W - 2), $y, [float]($W - $rng.Next(5, 13)), $y + $rng.Next(-4, 5))
        }
    }
    $icePen.Dispose()

    $crackPen = [System.Drawing.Pen]::new((New-Color 52 210 235 245), 1.0)
    for ($i = 0; $i -lt 3; $i++) {
        $sx = [float]$rng.Next([Math]::Max(10, [int]($W * 0.58)), [Math]::Max(11, $W - 16))
        $sy = [float]$rng.Next(7, [Math]::Max(8, $H - 10))
        $G.DrawLine($crackPen, $sx, $sy, $sx - $rng.Next(14, 45), $sy + $rng.Next(-8, 12))
    }
    $crackPen.Dispose()

    $path.Dispose()
}

function Write-PanelPng {
    param(
        [string] $RelativePath,
        [int] $W,
        [int] $H,
        [int] $Radius,
        [System.Drawing.Color] $Top,
        [System.Drawing.Color] $Bottom,
        [System.Drawing.Color] $Border,
        [System.Drawing.Color] $Accent,
        [int] $Seed = 1,
        [bool] $Pressed = $false
    )

    $bitmap = [System.Drawing.Bitmap]::new($W, $H, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear([System.Drawing.Color]::Transparent)

    Draw-FrostPanel -G $graphics -W $W -H $H -Radius $Radius -Top $Top -Bottom $Bottom -Border $Border -Accent $Accent -Seed $Seed -Pressed:$Pressed

    $path = New-UiPath $RelativePath
    $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
}

function Write-GaugeFill {
    param([string] $RelativePath, [System.Drawing.Color] $Left, [System.Drawing.Color] $Right)
    $w = 104
    $h = 14
    $bitmap = [System.Drawing.Bitmap]::new($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $rect = [System.Drawing.RectangleF]::new(1.0, 1.0, $w - 2.0, $h - 2.0)
    $path = New-RoundedPath $rect.X $rect.Y $rect.Width $rect.Height 5.0
    $brush = [System.Drawing.Drawing2D.LinearGradientBrush]::new($rect, $Left, $Right, [System.Drawing.Drawing2D.LinearGradientMode]::Horizontal)
    $graphics.FillPath($brush, $path)
    $shine = [System.Drawing.Pen]::new((New-Color 92 255 255 255), 1.0)
    $graphics.DrawLine($shine, 7.0, 3.0, [float]($w - 7), 3.0)
    $border = [System.Drawing.Pen]::new((New-Color 80 210 235 245), 1.0)
    $graphics.DrawPath($border, $path)
    $path.Dispose()
    $brush.Dispose()
    $shine.Dispose()
    $border.Dispose()
    $pathOut = New-UiPath $RelativePath
    $bitmap.Save($pathOut, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
}

$panelTop = New-Color 236 22 34 42
$panelBottom = New-Color 242 8 16 23
$panelBorder = New-Color 214 174 216 230
$iceAccent = New-Color 156 119 202 223
$riskAccent = New-Color 184 238 151 88
$dangerAccent = New-Color 190 243 105 78
$lootAccent = New-Color 172 146 219 184
$mutedAccent = New-Color 112 120 138 150

Write-PanelPng "resources/ui/master/hud/hud_header_chip_compact.png" 620 40 10 $panelTop $panelBottom $panelBorder $iceAccent 20
Write-PanelPng "resources/ui/master/hud/hud_gauge_strip_compact.png" 620 34 10 (New-Color 238 16 27 36) (New-Color 244 7 13 20) $panelBorder $iceAccent 21
Write-PanelPng "resources/ui/master/hud/hud_status_pill.png" 196 28 9 (New-Color 238 25 38 46) (New-Color 244 10 17 24) $panelBorder $iceAccent 22
Write-PanelPng "resources/ui/master/hud/hud_icon_button_compact_normal.png" 40 40 10 (New-Color 238 25 38 46) (New-Color 244 8 15 22) $panelBorder $iceAccent 23
Write-PanelPng "resources/ui/master/hud/hud_icon_button_compact_pressed.png" 40 40 10 (New-Color 250 17 29 37) (New-Color 252 4 10 17) (New-Color 232 210 241 250) $riskAccent 24 $true
Write-PanelPng "resources/ui/master/hud/hud_icon_button_compact_disabled.png" 40 40 10 (New-Color 142 24 29 34) (New-Color 154 12 16 21) (New-Color 120 104 125 132) $mutedAccent 25
Write-PanelPng "resources/ui/master/hud/gauge_frame_short_compact.png" 112 20 7 (New-Color 225 15 24 32) (New-Color 236 4 10 16) (New-Color 160 138 178 190) (New-Color 72 180 224 238) 26
Write-GaugeFill "resources/ui/master/hud/gauge_fill_health.png" (New-Color 232 128 216 181) (New-Color 238 76 161 134)
Write-GaugeFill "resources/ui/master/hud/gauge_fill_hunger.png" (New-Color 232 217 174 104) (New-Color 238 152 119 72)
Write-GaugeFill "resources/ui/master/hud/gauge_fill_thirst.png" (New-Color 232 111 198 225) (New-Color 238 74 145 192)
Write-GaugeFill "resources/ui/master/hud/gauge_fill_fatigue.png" (New-Color 232 218 195 104) (New-Color 238 180 128 61)
Write-GaugeFill "resources/ui/master/hud/gauge_fill_cold.png" (New-Color 232 155 223 248) (New-Color 238 86 162 224)

Write-PanelPng "resources/ui/master/indoor/indoor_action_row_compact_idle.png" 620 50 9 (New-Color 238 21 33 42) (New-Color 246 8 15 23) $panelBorder $iceAccent 40
Write-PanelPng "resources/ui/master/indoor/indoor_action_row_compact_pressed.png" 620 50 9 (New-Color 252 18 30 39) (New-Color 255 4 10 18) (New-Color 235 213 244 251) $riskAccent 41 $true
Write-PanelPng "resources/ui/master/indoor/indoor_action_row_risk_idle.png" 620 50 9 (New-Color 240 31 29 27) (New-Color 248 16 13 11) (New-Color 218 234 155 102) $riskAccent 42
Write-PanelPng "resources/ui/master/indoor/indoor_action_row_risk_pressed.png" 620 50 9 (New-Color 255 38 29 22) (New-Color 255 20 11 8) (New-Color 238 255 190 120) $riskAccent 43 $true
Write-PanelPng "resources/ui/master/indoor/indoor_action_row_loot_idle.png" 620 50 9 (New-Color 240 20 39 36) (New-Color 248 8 18 19) (New-Color 210 151 222 193) $lootAccent 44
Write-PanelPng "resources/ui/master/indoor/indoor_action_row_loot_pressed.png" 620 50 9 (New-Color 255 16 48 42) (New-Color 255 5 20 20) (New-Color 232 189 248 216) $lootAccent 45 $true
Write-PanelPng "resources/ui/master/indoor/indoor_action_row_locked_idle.png" 620 50 9 (New-Color 178 20 24 28) (New-Color 190 8 10 13) (New-Color 118 103 118 126) $mutedAccent 46
Write-PanelPng "resources/ui/master/indoor/indoor_location_strip_compact.png" 336 44 9 (New-Color 238 22 35 43) (New-Color 246 7 14 22) $panelBorder $iceAccent 47
Write-PanelPng "resources/ui/master/indoor/indoor_reading_panel_plain.png" 336 168 13 (New-Color 242 20 31 39) (New-Color 250 8 14 20) $panelBorder $iceAccent 48
Write-PanelPng "resources/ui/master/indoor/indoor_minimap_frame.png" 336 184 13 (New-Color 236 19 30 38) (New-Color 246 7 13 20) $panelBorder $iceAccent 49
Write-PanelPng "resources/ui/master/indoor/indoor_section_header_plain_compact.png" 384 40 9 (New-Color 230 24 38 47) (New-Color 240 8 14 22) $panelBorder $iceAccent 50

Write-PanelPng "resources/ui/master/sheet/sheet_bg_compact.png" 648 980 18 (New-Color 246 17 27 35) (New-Color 252 5 10 16) $panelBorder $iceAccent 60
Write-PanelPng "resources/ui/master/sheet/sheet_detail_panel_compact.png" 600 264 16 (New-Color 246 22 34 42) (New-Color 252 7 13 20) $panelBorder $iceAccent 61
Write-PanelPng "resources/ui/master/sheet/sheet_header_strip_compact.png" 604 56 12 (New-Color 242 24 38 47) (New-Color 250 8 15 23) $panelBorder $iceAccent 62
Write-PanelPng "resources/ui/master/sheet/sheet_tab_compact_idle.png" 172 40 10 (New-Color 232 21 32 40) (New-Color 242 8 14 21) (New-Color 156 122 154 165) $mutedAccent 63
Write-PanelPng "resources/ui/master/sheet/sheet_tab_compact_active.png" 172 40 10 (New-Color 248 34 40 39) (New-Color 255 17 18 18) (New-Color 224 241 178 107) $riskAccent 64
Write-PanelPng "resources/ui/master/sheet/inventory_icon_slot.png" 44 44 9 (New-Color 235 26 37 44) (New-Color 246 8 14 20) (New-Color 190 159 196 210) $iceAccent 65
Write-PanelPng "resources/ui/master/sheet/inventory_row_compact_idle.png" 604 66 12 (New-Color 240 21 32 40) (New-Color 248 7 13 20) $panelBorder $iceAccent 66
Write-PanelPng "resources/ui/master/sheet/inventory_row_compact_selected.png" 604 66 12 (New-Color 252 22 42 52) (New-Color 255 8 17 25) (New-Color 235 203 239 250) $iceAccent 67 $true
Write-PanelPng "resources/ui/master/sheet/inventory_row_compact_highlighted.png" 604 66 12 (New-Color 248 32 35 30) (New-Color 255 14 13 10) (New-Color 225 246 192 118) $riskAccent 68
Write-PanelPng "resources/ui/master/sheet/craft_card_attached.png" 604 118 14 (New-Color 246 26 36 42) (New-Color 252 8 14 20) $panelBorder $riskAccent 69
Write-PanelPng "resources/ui/master/sheet/sheet_button_primary_normal.png" 286 56 11 (New-Color 245 31 48 50) (New-Color 252 12 22 25) (New-Color 222 156 224 194) $lootAccent 70
Write-PanelPng "resources/ui/master/sheet/sheet_button_primary_pressed.png" 286 56 11 (New-Color 255 20 58 52) (New-Color 255 5 24 23) (New-Color 235 188 249 218) $lootAccent 71 $true
Write-PanelPng "resources/ui/master/sheet/sheet_button_secondary_normal.png" 286 56 11 (New-Color 240 23 34 42) (New-Color 248 8 14 21) $panelBorder $iceAccent 72
Write-PanelPng "resources/ui/master/sheet/sheet_button_secondary_pressed.png" 286 56 11 (New-Color 255 18 31 40) (New-Color 255 5 10 17) (New-Color 230 210 241 250) $iceAccent 73 $true

$referenceSource = Join-Path $env:USERPROFILE ".codex\generated_images\019de395-7822-7060-91d0-954c6bafd5ff\ig_0d4d4697d80ca4750169f5ac419864819190795fe1724cd061.png"
if (Test-Path -LiteralPath $referenceSource) {
    Copy-Item -LiteralPath $referenceSource -Destination (New-UiPath "resources/ui/master/reference/ui_survival_phone_direction.png") -Force
}

Write-Output "UI polish assets generated."
