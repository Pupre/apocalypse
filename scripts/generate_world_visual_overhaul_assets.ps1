Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$cityRoot = Join-Path $root "resources/world/city"

function New-AssetPath {
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
    $r = [Math]::Max(0.0, [Math]::Min($R, [Math]::Min($W, $H) / 2.0))
    if ($r -le 0.0) {
        $Path.AddRectangle([System.Drawing.RectangleF]::new($X, $Y, $W, $H))
        return
    }
    $d = $r * 2.0
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

function New-Canvas {
    param([int] $W, [int] $H, [bool] $Transparent = $true)
    $bitmap = [System.Drawing.Bitmap]::new($W, $H, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    if ($Transparent) {
        $graphics.Clear([System.Drawing.Color]::Transparent)
    } else {
        $graphics.Clear((New-Color 255 12 20 27))
    }
    return @{ Bitmap = $bitmap; Graphics = $graphics }
}

function Save-Canvas {
    param($Canvas, [string] $RelativePath)
    $path = New-AssetPath $RelativePath
    $Canvas.Bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $Canvas.Graphics.Dispose()
    $Canvas.Bitmap.Dispose()
}

function Draw-Noise {
    param([System.Drawing.Graphics] $G, [int] $W, [int] $H, [int] $Seed, [int] $Count, [System.Drawing.Color] $Color)
    $rng = [System.Random]::new($Seed)
    $brush = New-Brush $Color
    for ($i = 0; $i -lt $Count; $i++) {
        $x = $rng.Next(0, $W)
        $y = $rng.Next(0, $H)
        $s = $rng.Next(1, 3)
        $G.FillRectangle($brush, $x, $y, $s, $s)
    }
    $brush.Dispose()
}

function Draw-SnowClumps {
    param([System.Drawing.Graphics] $G, [int] $W, [int] $H, [int] $Seed, [int] $Count, [System.Drawing.Color] $Color)
    $rng = [System.Random]::new($Seed)
    $brush = New-Brush $Color
    for ($i = 0; $i -lt $Count; $i++) {
        $x = $rng.Next(-8, $W)
        $y = $rng.Next(-8, $H)
        $w = $rng.Next(5, 22)
        $h = $rng.Next(3, 13)
        $G.FillEllipse($brush, $x, $y, $w, $h)
    }
    $brush.Dispose()
}

function Draw-Crack {
    param([System.Drawing.Graphics] $G, [float] $X, [float] $Y, [int] $Seed, [System.Drawing.Color] $Color)
    $rng = [System.Random]::new($Seed)
    $pen = New-Pen $Color 1.0
    $cx = $X
    $cy = $Y
    for ($i = 0; $i -lt $rng.Next(3, 7); $i++) {
        $nx = $cx + $rng.Next(-18, 19)
        $ny = $cy + $rng.Next(-16, 17)
        $G.DrawLine($pen, [float]$cx, [float]$cy, [float]$nx, [float]$ny)
        if ($rng.NextDouble() -gt 0.45) {
            $G.DrawLine($pen, [float]$nx, [float]$ny, [float]($nx + $rng.Next(-12, 13)), [float]($ny + $rng.Next(-10, 11)))
        }
        $cx = $nx
        $cy = $ny
    }
    $pen.Dispose()
}

function Write-Terrain {
    param([string] $Name, [string] $Kind, [int] $Seed)
    $c = New-Canvas 128 128 $false
    $g = $c.Graphics
    $rect = [System.Drawing.RectangleF]::new(0, 0, 128, 128)
    $top = New-Color 255 23 33 40
    $bottom = New-Color 255 11 18 24
    if ($Kind -eq "snow") {
        $top = New-Color 255 188 205 213
        $bottom = New-Color 255 123 151 166
    } elseif ($Kind -eq "sidewalk") {
        $top = New-Color 255 72 84 88
        $bottom = New-Color 255 41 51 57
    } elseif ($Kind -eq "ice") {
        $top = New-Color 255 50 86 103
        $bottom = New-Color 255 18 42 59
    } elseif ($Kind -eq "alley") {
        $top = New-Color 255 12 18 22
        $bottom = New-Color 255 5 9 12
    }
    $brush = [System.Drawing.Drawing2D.LinearGradientBrush]::new($rect, $top, $bottom, [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
    $g.FillRectangle($brush, 0, 0, 128, 128)
    $brush.Dispose()

    Draw-Noise $g 128 128 $Seed 520 (New-Color 44 210 229 236)
    Draw-Noise $g 128 128 ($Seed + 7) 240 (New-Color 34 0 0 0)

    if ($Kind -in @("road", "cracked", "slush", "intersection")) {
        $lane = New-Pen (New-Color 130 198 206 205) 2.0
        if ($Name.EndsWith("_h.png")) {
            $g.DrawLine($lane, 0, 63, 128, 63)
        } elseif ($Name.EndsWith("_v.png")) {
            $g.DrawLine($lane, 63, 0, 63, 128)
        }
        $lane.Dispose()
    }
    if ($Kind -in @("cracked", "intersection", "alley")) {
        for ($i = 0; $i -lt 7; $i++) {
            Draw-Crack $g (18 + (($i * 19) % 96)) (16 + (($i * 31) % 90)) ($Seed + $i) (New-Color 106 130 158 174)
        }
    }
    if ($Kind -in @("slush", "snow", "sidewalk")) {
        Draw-SnowClumps $g 128 128 ($Seed + 31) 32 (New-Color 174 226 238 244)
        Draw-SnowClumps $g 128 128 ($Seed + 41) 14 (New-Color 130 164 190 204)
    }
    if ($Kind -eq "ice") {
        for ($i = 0; $i -lt 10; $i++) {
            Draw-Crack $g (12 + (($i * 23) % 108)) (18 + (($i * 29) % 94)) ($Seed + 80 + $i) (New-Color 170 195 239 255)
        }
    }
    Save-Canvas $c "resources/world/city/terrain/$Name"
}

function Write-Crosswalk {
    param([string] $Name, [bool] $Vertical)
    $c = New-Canvas 128 128 $false
    $g = $c.Graphics
    $road = New-Brush (New-Color 255 19 29 36)
    $g.FillRectangle($road, 0, 0, 128, 128)
    $road.Dispose()
    Draw-Noise $g 128 128 901 420 (New-Color 45 200 220 228)
    $stripe = New-Brush (New-Color 176 210 218 216)
    for ($i = 0; $i -lt 6; $i++) {
        if ($Vertical) {
            $g.FillRectangle($stripe, 18 + ($i * 18), 8, 9, 112)
        } else {
            $g.FillRectangle($stripe, 8, 18 + ($i * 18), 112, 9)
        }
    }
    $stripe.Dispose()
    Draw-SnowClumps $g 128 128 902 12 (New-Color 120 230 240 246)
    Save-Canvas $c "resources/world/city/terrain/$Name"
}

function Write-Curb {
    param([string] $Name, [string] $Side)
    $c = New-Canvas 128 128 $false
    $g = $c.Graphics
    $snow = New-Brush (New-Color 255 138 163 176)
    $sidewalk = New-Brush (New-Color 255 51 64 70)
    $g.FillRectangle($sidewalk, 0, 0, 128, 128)
    if ($Side -eq "top") { $g.FillRectangle($snow, 0, 0, 128, 32) }
    if ($Side -eq "bottom") { $g.FillRectangle($snow, 0, 96, 128, 32) }
    if ($Side -eq "left") { $g.FillRectangle($snow, 0, 0, 32, 128) }
    if ($Side -eq "right") { $g.FillRectangle($snow, 96, 0, 32, 128) }
    $snow.Dispose()
    $sidewalk.Dispose()
    Draw-Noise $g 128 128 (920 + $Name.Length) 360 (New-Color 42 220 235 240)
    Save-Canvas $c "resources/world/city/terrain/$Name"
}

function Write-Decal {
    param([string] $Name, [string] $Kind, [int] $Seed)
    $c = New-Canvas 128 128 $true
    $g = $c.Graphics
    if ($Kind -eq "ice") {
        $brush = New-Brush (New-Color 84 120 205 245)
        $g.FillEllipse($brush, 12, 24, 104, 74)
        $brush.Dispose()
        for ($i = 0; $i -lt 12; $i++) { Draw-Crack $g 64 62 ($Seed + $i) (New-Color 180 230 251 255) }
    } elseif ($Kind -eq "snow") {
        Draw-SnowClumps $g 128 128 $Seed 44 (New-Color 214 232 240 246)
    } elseif ($Kind -eq "wind") {
        $pen = New-Pen (New-Color 128 225 248 255) 2.0
        for ($i = 0; $i -lt 11; $i++) {
            $y = 18 + ($i * 9)
            $g.DrawBezier($pen, 2, $y, 35, $y - 16, 75, $y + 15, 126, $y - 8)
        }
        $pen.Dispose()
    } elseif ($Kind -eq "crack") {
        for ($i = 0; $i -lt 18; $i++) { Draw-Crack $g 64 64 ($Seed + $i) (New-Color 145 205 231 242) }
    } elseif ($Kind -eq "foot_h") {
        $brush = New-Brush (New-Color 120 8 12 16)
        for ($i = 0; $i -lt 7; $i++) {
            $g.FillEllipse($brush, 8 + ($i * 17), 56 + (($i % 2) * 10), 8, 15)
        }
        $brush.Dispose()
    } elseif ($Kind -eq "foot_v") {
        $brush = New-Brush (New-Color 120 8 12 16)
        for ($i = 0; $i -lt 7; $i++) {
            $g.FillEllipse($brush, 54 + (($i % 2) * 11), 8 + ($i * 17), 15, 8)
        }
        $brush.Dispose()
    } elseif ($Kind -eq "warm") {
        $brush = [System.Drawing.Drawing2D.PathGradientBrush]::new([System.Drawing.PointF[]]@(
            [System.Drawing.PointF]::new(64, 18),
            [System.Drawing.PointF]::new(112, 64),
            [System.Drawing.PointF]::new(64, 112),
            [System.Drawing.PointF]::new(16, 64)
        ))
        $brush.CenterColor = New-Color 150 255 180 72
        $brush.SurroundColors = [System.Drawing.Color[]]@(New-Color 0 255 180 72)
        $g.FillEllipse($brush, 12, 12, 104, 104)
        $brush.Dispose()
    } else {
        $brush = New-Brush (New-Color 90 210 230 240)
        $g.FillEllipse($brush, 10, 10, 108, 108)
        $brush.Dispose()
    }
    Save-Canvas $c "resources/world/city/decals/$Name"
}

function Draw-Building {
    param(
        [System.Drawing.Graphics] $G,
        [int] $X,
        [int] $Y,
        [int] $W,
        [int] $H,
        [System.Drawing.Color] $Wall,
        [System.Drawing.Color] $Trim,
        [string] $Kind
    )
    $shadow = New-Brush (New-Color 82 0 0 0)
    $G.FillEllipse($shadow, $X + 8, $Y + $H - 8, $W - 16, 18)
    $shadow.Dispose()

    $dark = New-Brush (New-Color 255 21 29 33)
    $wallBrush = New-Brush $Wall
    $trimBrush = New-Brush $Trim
    $snow = New-Brush (New-Color 235 220 233 239)
    $ice = New-Pen (New-Color 180 223 246 255) 1.2
    $outline = New-Pen (New-Color 230 5 9 12) 2.2

    Fill-RoundedRect $G $X ($Y + 18) $W ($H - 24) 6 $wallBrush
    $G.DrawRectangle($outline, $X, ($Y + 18), $W, ($H - 24))
    $G.FillRectangle($dark, $X + 5, $Y + 22, $W - 10, 18)
    $G.FillRectangle($snow, $X + 2, $Y + 12, $W - 4, 14)
    $G.FillEllipse($snow, $X - 5, $Y + 10, 24, 16)
    $G.FillEllipse($snow, $X + $W - 24, $Y + 9, 28, 17)

    $G.FillRectangle($trimBrush, $X + 6, $Y + 40, $W - 12, 8)
    $doorW = 18
    $doorX = $X + [int]($W * 0.52)
    $doorBrush = New-Brush (New-Color 255 18 37 44)
    $G.FillRectangle($doorBrush, $doorX, $Y + $H - 42, $doorW, 34)
    $G.DrawRectangle($ice, $doorX, $Y + $H - 42, $doorW, 34)
    $doorBrush.Dispose()

    $windowBrush = New-Brush (New-Color 225 36 72 86)
    $glowBrush = New-Brush (New-Color 150 239 169 82)
    $cols = [Math]::Max(2, [int]($W / 38))
    for ($row = 0; $row -lt 2; $row++) {
        for ($col = 0; $col -lt $cols; $col++) {
            $wx = $X + 12 + ($col * 34)
            if ($wx + 18 -gt $X + $W - 10) { continue }
            $wy = $Y + 56 + ($row * 28)
            $G.FillRectangle($windowBrush, $wx, $wy, 18, 13)
            if ((($row + $col + $Kind.Length) % 3) -eq 0) {
                $G.FillRectangle($glowBrush, $wx + 2, $wy + 2, 14, 9)
            }
            $G.DrawRectangle($ice, $wx, $wy, 18, 13)
        }
    }
    $windowBrush.Dispose()
    $glowBrush.Dispose()

    if ($Kind -eq "gas") {
        $canopy = New-Brush (New-Color 255 88 39 31)
        $G.FillRectangle($canopy, $X - 22, $Y + $H - 64, $W + 44, 18)
        $G.FillRectangle($snow, $X - 22, $Y + $H - 70, $W + 44, 7)
        $pump = New-Brush (New-Color 255 115 42 32)
        $G.FillRectangle($pump, $X + 8, $Y + $H - 38, 13, 25)
        $G.FillRectangle($pump, $X + $W - 24, $Y + $H - 38, 13, 25)
        $pump.Dispose()
        $canopy.Dispose()
    } elseif ($Kind -eq "church") {
        $roof = New-Brush (New-Color 255 52 65 70)
        $points = [System.Drawing.Point[]]@(
            [System.Drawing.Point]::new($X + [int]($W * 0.5), $Y),
            [System.Drawing.Point]::new($X + [int]($W * 0.66), $Y + 25),
            [System.Drawing.Point]::new($X + [int]($W * 0.34), $Y + 25)
        )
        $G.FillPolygon($roof, $points)
        $G.FillRectangle($trimBrush, $X + [int]($W * 0.49), $Y + 2, 4, 18)
        $G.FillRectangle($trimBrush, $X + [int]($W * 0.43), $Y + 8, 16, 4)
        $roof.Dispose()
    } elseif ($Kind -eq "school") {
        $flag = New-Brush (New-Color 255 108 58 50)
        $G.FillRectangle($flag, $X + $W - 18, $Y + 5, 13, 8)
        $flag.Dispose()
    } elseif ($Kind -eq "apartment" -or $Kind -eq "hostel" -or $Kind -eq "rowhouse") {
        $rail = New-Pen (New-Color 220 166 184 190) 2
        for ($i = 0; $i -lt 3; $i++) {
            $by = $Y + 52 + ($i * 29)
            $G.DrawLine($rail, $X + 8, $by, $X + $W - 8, $by)
        }
        $rail.Dispose()
    }

    $dark.Dispose()
    $wallBrush.Dispose()
    $trimBrush.Dispose()
    $snow.Dispose()
    $ice.Dispose()
    $outline.Dispose()
}

function Write-Building {
    param([string] $Name, [string] $Kind, [System.Drawing.Color] $Wall, [System.Drawing.Color] $Trim)
    $c = New-Canvas 192 160 $true
    Draw-Building $c.Graphics 24 20 144 124 $Wall $Trim $Kind
    Draw-SnowClumps $c.Graphics 192 160 (1100 + $Name.Length) 12 (New-Color 150 231 240 245)
    Save-Canvas $c "resources/world/city/buildings_cutout/$Name"
}

function Write-Prop {
    param([string] $Name, [string] $Kind, [int] $Seed)
    $c = New-Canvas 128 128 $true
    $g = $c.Graphics
    $shadow = New-Brush (New-Color 72 0 0 0)
    $g.FillEllipse($shadow, 20, 95, 88, 14)
    $shadow.Dispose()
    $outline = New-Pen (New-Color 230 5 8 10) 2.0
    $snow = New-Brush (New-Color 218 227 238 244)
    if ($Kind -eq "car") {
        $body = New-Brush (New-Color 255 63 77 80)
        Fill-RoundedRect $g 24 54 80 34 7 $body
        $g.DrawRectangle($outline, 24, 54, 80, 34)
        $glass = New-Brush (New-Color 230 39 74 86)
        $g.FillRectangle($glass, 45, 42, 34, 18)
        $g.FillEllipse($snow, 30, 44, 68, 18)
        $glass.Dispose()
        $body.Dispose()
    } elseif ($Kind -eq "tree") {
        $trunk = New-Pen (New-Color 255 70 49 34) 5
        $g.DrawLine($trunk, 64, 98, 64, 38)
        for ($i = 0; $i -lt 8; $i++) {
            $g.DrawLine($trunk, 64, 58 + ($i % 3) * 5, 24 + (($i * 17) % 80), 24 + (($i * 23) % 45))
        }
        $trunk.Dispose()
        Draw-SnowClumps $g 128 128 $Seed 12 (New-Color 190 230 240 246)
    } elseif ($Kind -eq "lamp") {
        $metal = New-Pen (New-Color 255 72 80 80) 4
        $g.DrawLine($metal, 62, 100, 62, 28)
        $g.DrawLine($metal, 62, 30, 90, 34)
        $glow = New-Brush (New-Color 190 255 177 69)
        $g.FillEllipse($glow, 85, 31, 14, 14)
        $glow.Dispose()
        $metal.Dispose()
    } elseif ($Kind -eq "barrier") {
        $bar = New-Brush (New-Color 255 126 79 48)
        for ($i = 0; $i -lt 3; $i++) {
            $g.FillRectangle($bar, 28 + ($i * 22), 67 - ($i * 3), 44, 10)
        }
        $bar.Dispose()
    } elseif ($Kind -eq "crate") {
        $crate = New-Brush (New-Color 255 76 89 82)
        Fill-RoundedRect $g 30 54 68 40 4 $crate
        $g.DrawRectangle($outline, 30, 54, 68, 40)
        $crate.Dispose()
    } elseif ($Kind -eq "dumpster") {
        $bin = New-Brush (New-Color 255 44 67 65)
        Fill-RoundedRect $g 25 54 78 38 5 $bin
        $g.DrawRectangle($outline, 25, 54, 78, 38)
        $lid = New-Brush (New-Color 255 28 45 48)
        $g.FillRectangle($lid, 21, 48, 86, 10)
        $lid.Dispose()
        $bin.Dispose()
    } elseif ($Kind -eq "fire") {
        $barrel = New-Brush (New-Color 255 65 77 78)
        Fill-RoundedRect $g 46 62 36 36 5 $barrel
        $flame = New-Brush (New-Color 230 255 143 48)
        $g.FillEllipse($flame, 53, 40, 22, 30)
        $flame.Dispose()
        $barrel.Dispose()
    } elseif ($Kind -eq "cone") {
        $cone = New-Brush (New-Color 255 186 80 45)
        $g.FillPolygon($cone, [System.Drawing.Point[]]@(
            [System.Drawing.Point]::new(64, 44),
            [System.Drawing.Point]::new(82, 92),
            [System.Drawing.Point]::new(46, 92)
        ))
        $cone.Dispose()
    } elseif ($Kind -eq "cart") {
        $cartPen = New-Pen (New-Color 255 150 171 174) 2.2
        $g.DrawRectangle($cartPen, 32, 55, 56, 28)
        $g.DrawLine($cartPen, 24, 50, 32, 55)
        $g.DrawLine($cartPen, 88, 55, 98, 43)
        for ($i = 0; $i -lt 4; $i++) {
            $g.DrawLine($cartPen, 38 + ($i * 11), 57, 38 + ($i * 11), 80)
        }
        $g.DrawEllipse($cartPen, 36, 86, 9, 9)
        $g.DrawEllipse($cartPen, 77, 86, 9, 9)
        $cartPen.Dispose()
    } elseif ($Kind -eq "snow") {
        Draw-SnowClumps $g 128 128 $Seed 58 (New-Color 232 231 242 247)
        Draw-SnowClumps $g 128 128 ($Seed + 19) 18 (New-Color 165 168 195 207)
    } elseif ($Kind -eq "sign") {
        $post = New-Pen (New-Color 255 80 88 88) 4
        $g.DrawLine($post, 64, 100, 64, 42)
        $panel = New-Brush (New-Color 255 42 76 86)
        Fill-RoundedRect $g 42 35 44 22 4 $panel
        $g.DrawRectangle($outline, 42, 35, 44, 22)
        $panel.Dispose()
        $post.Dispose()
    } elseif ($Kind -eq "tires") {
        $tirePen = New-Pen (New-Color 255 9 12 15) 8
        for ($i = 0; $i -lt 4; $i++) {
            $g.DrawEllipse($tirePen, 30 + (($i % 2) * 28), 55 + ([int]($i / 2) * 18), 32, 20)
        }
        $tirePen.Dispose()
    } elseif ($Kind -eq "utility") {
        $box = New-Brush (New-Color 255 58 80 84)
        Fill-RoundedRect $g 42 50 44 46 5 $box
        $g.DrawRectangle($outline, 42, 50, 44, 46)
        $panelPen = New-Pen (New-Color 180 210 236 240) 1.2
        $g.DrawRectangle($panelPen, 50, 60, 28, 14)
        $g.DrawLine($panelPen, 50, 82, 78, 82)
        $panelPen.Dispose()
        $box.Dispose()
    } else {
        $junk = New-Brush (New-Color 255 72 80 84)
        Fill-RoundedRect $g 32 60 64 34 5 $junk
        $junk.Dispose()
    }
    $g.FillEllipse($snow, 34, 48, 58, 14)
    $snow.Dispose()
    $outline.Dispose()
    Save-Canvas $c "resources/world/city/props_cutout/$Name"
}

function Test-ChromaPixel {
    param([System.Drawing.Color] $Color)
    return $Color.R -gt 80 -and $Color.B -gt 80 -and $Color.G -lt 150 -and ($Color.R - $Color.G) -gt 18 -and ($Color.B - $Color.G) -gt 18
}

function Import-BuildingSheet {
    param([string] $SheetPath)
    if (-not (Test-Path -LiteralPath $SheetPath)) {
        return
    }

    $names = @(
        "building_mart.png",
        "building_convenience.png",
        "building_apartment.png",
        "building_clinic.png",
        "building_pharmacy.png",
        "building_office.png",
        "building_warehouse.png",
        "building_gas_station.png",
        "building_cafe.png",
        "building_police.png",
        "building_bookstore.png",
        "building_bakery.png",
        "building_butcher.png",
        "building_church.png",
        "building_school.png",
        "building_row_house.png"
    )

    $sheet = [System.Drawing.Bitmap]::FromFile($SheetPath)
    try {
        $cellW = $sheet.Width / 4.0
        $cellH = $sheet.Height / 4.0
        for ($index = 0; $index -lt $names.Length; $index++) {
            $col = $index % 4
            $row = [int][Math]::Floor($index / 4.0)
            $cell = [System.Drawing.Bitmap]::new([Math]::Ceiling($cellW), [Math]::Ceiling($cellH), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $cellGraphics = [System.Drawing.Graphics]::FromImage($cell)
            $cellGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            $cellGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $src = [System.Drawing.RectangleF]::new($col * $cellW, $row * $cellH, $cellW, $cellH)
            $dst = [System.Drawing.RectangleF]::new(0, 0, $cell.Width, $cell.Height)
            $cellGraphics.DrawImage($sheet, $dst, $src, [System.Drawing.GraphicsUnit]::Pixel)
            $cellGraphics.Dispose()

            $minX = $cell.Width
            $minY = $cell.Height
            $maxX = -1
            $maxY = -1
            $clearPixel = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
            for ($y = 0; $y -lt $cell.Height; $y++) {
                for ($x = 0; $x -lt $cell.Width; $x++) {
                    $px = $cell.GetPixel($x, $y)
                    if (Test-ChromaPixel $px) {
                        $cell.SetPixel($x, $y, $clearPixel)
                        continue
                    }
                    if ($px.A -le 8) {
                        $cell.SetPixel($x, $y, $clearPixel)
                        continue
                    }
                    $minX = [Math]::Min($minX, $x)
                    $minY = [Math]::Min($minY, $y)
                    $maxX = [Math]::Max($maxX, $x)
                    $maxY = [Math]::Max($maxY, $y)
                }
            }

            if ($maxX -lt 0 -or $maxY -lt 0) {
                $cell.Dispose()
                continue
            }

            $trimW = $maxX - $minX + 1
            $trimH = $maxY - $minY + 1
            $canvasW = 192
            $canvasH = 160
            $scale = [Math]::Min(($canvasW - 6) / [double]$trimW, ($canvasH - 4) / [double]$trimH)
            $drawW = [int][Math]::Round($trimW * $scale)
            $drawH = [int][Math]::Round($trimH * $scale)
            $out = [System.Drawing.Bitmap]::new($canvasW, $canvasH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $outGraphics = [System.Drawing.Graphics]::FromImage($out)
            $outGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            $outGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $outGraphics.Clear([System.Drawing.Color]::Transparent)
            $outX = [int][Math]::Round(($canvasW - $drawW) / 2.0)
            $outY = $canvasH - $drawH
            $sourceRect = [System.Drawing.Rectangle]::new($minX, $minY, $trimW, $trimH)
            $destRect = [System.Drawing.Rectangle]::new($outX, $outY, $drawW, $drawH)
            $outGraphics.DrawImage($cell, $destRect, $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
            $outGraphics.Dispose()

            $target = New-AssetPath "resources/world/city/buildings_cutout/$($names[$index])"
            $out.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)
            $out.Dispose()
            $cell.Dispose()
        }
    } finally {
        $sheet.Dispose()
    }
}

function Import-PropSheet {
    param([string] $SheetPath)
    if (-not (Test-Path -LiteralPath $SheetPath)) {
        return
    }

    $names = @(
        "frozen_car.png",
        "barrel_fire.png",
        "barricade_wood.png",
        "bus_stop_sign.png",
        "crate_stack.png",
        "dead_tree.png",
        "dumpster_snow.png",
        "roadblock.png",
        "sandbags.png",
        "shopping_cart.png",
        "snow_drift.png",
        "street_lamp.png",
        "tire_pile.png",
        "traffic_cone.png",
        "utility_box.png",
        "barrel_empty.png"
    )

    $sheet = [System.Drawing.Bitmap]::FromFile($SheetPath)
    try {
        $cellW = $sheet.Width / 4.0
        $cellH = $sheet.Height / 4.0
        for ($index = 0; $index -lt $names.Length; $index++) {
            $col = $index % 4
            $row = [int][Math]::Floor($index / 4.0)
            $cell = [System.Drawing.Bitmap]::new([Math]::Ceiling($cellW), [Math]::Ceiling($cellH), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $cellGraphics = [System.Drawing.Graphics]::FromImage($cell)
            $cellGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            $cellGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $src = [System.Drawing.RectangleF]::new($col * $cellW, $row * $cellH, $cellW, $cellH)
            $dst = [System.Drawing.RectangleF]::new(0, 0, $cell.Width, $cell.Height)
            $cellGraphics.DrawImage($sheet, $dst, $src, [System.Drawing.GraphicsUnit]::Pixel)
            $cellGraphics.Dispose()

            $minX = $cell.Width
            $minY = $cell.Height
            $maxX = -1
            $maxY = -1
            $clearPixel = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
            for ($y = 0; $y -lt $cell.Height; $y++) {
                for ($x = 0; $x -lt $cell.Width; $x++) {
                    $px = $cell.GetPixel($x, $y)
                    if (Test-ChromaPixel $px) {
                        $cell.SetPixel($x, $y, $clearPixel)
                        continue
                    }
                    if ($px.A -le 8) {
                        $cell.SetPixel($x, $y, $clearPixel)
                        continue
                    }
                    $minX = [Math]::Min($minX, $x)
                    $minY = [Math]::Min($minY, $y)
                    $maxX = [Math]::Max($maxX, $x)
                    $maxY = [Math]::Max($maxY, $y)
                }
            }

            if ($maxX -lt 0 -or $maxY -lt 0) {
                $cell.Dispose()
                continue
            }

            $trimW = $maxX - $minX + 1
            $trimH = $maxY - $minY + 1
            $canvasW = 128
            $canvasH = 128
            $scale = [Math]::Min(($canvasW - 4) / [double]$trimW, ($canvasH - 4) / [double]$trimH)
            $drawW = [int][Math]::Round($trimW * $scale)
            $drawH = [int][Math]::Round($trimH * $scale)
            $out = [System.Drawing.Bitmap]::new($canvasW, $canvasH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $outGraphics = [System.Drawing.Graphics]::FromImage($out)
            $outGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            $outGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $outGraphics.Clear([System.Drawing.Color]::Transparent)
            $outX = [int][Math]::Round(($canvasW - $drawW) / 2.0)
            $outY = $canvasH - $drawH
            $sourceRect = [System.Drawing.Rectangle]::new($minX, $minY, $trimW, $trimH)
            $destRect = [System.Drawing.Rectangle]::new($outX, $outY, $drawW, $drawH)
            $outGraphics.DrawImage($cell, $destRect, $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
            $outGraphics.Dispose()

            $target = New-AssetPath "resources/world/city/props_cutout/$($names[$index])"
            $out.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)
            $out.Dispose()
            $cell.Dispose()
        }
    } finally {
        $sheet.Dispose()
    }
}

function Import-TerrainSheet {
    param([string] $SheetPath)
    if (-not (Test-Path -LiteralPath $SheetPath)) {
        return
    }

    $names = @(
        "road_plain.png",
        "road_lane_h.png",
        "road_lane_v.png",
        "road_cracked.png",
        "road_intersection.png",
        "slush_road.png",
        "snow_ground.png",
        "sidewalk_snow.png",
        "alley_dark.png",
        "manhole_road.png",
        "crosswalk_h.png",
        "crosswalk_v.png",
        "curb_top.png",
        "curb_bottom.png",
        "curb_left.png",
        "curb_right.png"
    )

    $sheet = [System.Drawing.Bitmap]::FromFile($SheetPath)
    try {
        $cellW = $sheet.Width / 4.0
        $cellH = $sheet.Height / 4.0
        $inset = 4.0
        for ($index = 0; $index -lt $names.Length; $index++) {
            $col = $index % 4
            $row = [int][Math]::Floor($index / 4.0)
            $out = [System.Drawing.Bitmap]::new(128, 128, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $graphics = [System.Drawing.Graphics]::FromImage($out)
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.Clear([System.Drawing.Color]::Transparent)
            $src = [System.Drawing.RectangleF]::new(($col * $cellW) + $inset, ($row * $cellH) + $inset, $cellW - ($inset * 2.0), $cellH - ($inset * 2.0))
            $dst = [System.Drawing.RectangleF]::new(0, 0, 128, 128)
            $graphics.DrawImage($sheet, $dst, $src, [System.Drawing.GraphicsUnit]::Pixel)
            $graphics.Dispose()
            $target = New-AssetPath "resources/world/city/terrain/$($names[$index])"
            $out.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)
            $out.Dispose()
        }
    } finally {
        $sheet.Dispose()
    }
}

Write-Terrain "road_plain.png" "road" 200
Write-Terrain "road_lane_h.png" "road" 201
Write-Terrain "road_lane_v.png" "road" 202
Write-Terrain "road_cracked.png" "cracked" 203
Write-Terrain "road_intersection.png" "intersection" 204
Write-Terrain "slush_road.png" "slush" 205
Write-Terrain "snow_ground.png" "snow" 206
Write-Terrain "sidewalk_snow.png" "sidewalk" 207
Write-Terrain "alley_dark.png" "alley" 208
Write-Terrain "manhole_road.png" "cracked" 209
Write-Crosswalk "crosswalk_h.png" $false
Write-Crosswalk "crosswalk_v.png" $true
Write-Curb "curb_top.png" "top"
Write-Curb "curb_bottom.png" "bottom"
Write-Curb "curb_left.png" "left"
Write-Curb "curb_right.png" "right"

Write-Decal "ice_patch.png" "ice" 310
Write-Decal "snow_patch.png" "snow" 311
Write-Decal "wind_streak.png" "wind" 312
Write-Decal "crack_overlay.png" "crack" 313
Write-Decal "footprints_h.png" "foot_h" 314
Write-Decal "footprints_v.png" "foot_v" 315
Write-Decal "warm_spill.png" "warm" 316
Write-Decal "frost_corner.png" "ice" 317
Write-Decal "smoke_puff.png" "smoke" 318

Write-Building "building_mart.png" "retail" (New-Color 255 61 75 78) (New-Color 255 120 46 41)
Write-Building "building_convenience.png" "retail" (New-Color 255 54 70 72) (New-Color 255 42 122 116)
Write-Building "building_apartment.png" "apartment" (New-Color 255 67 69 70) (New-Color 255 105 118 121)
Write-Building "building_clinic.png" "medical" (New-Color 255 70 83 84) (New-Color 255 58 129 119)
Write-Building "building_pharmacy.png" "medical" (New-Color 255 54 78 76) (New-Color 255 70 148 128)
Write-Building "building_office.png" "office" (New-Color 255 56 67 75) (New-Color 255 89 101 112)
Write-Building "building_warehouse.png" "industrial" (New-Color 255 59 62 60) (New-Color 255 124 92 56)
Write-Building "building_gas_station.png" "gas" (New-Color 255 56 62 65) (New-Color 255 122 43 36)
Write-Building "building_cafe.png" "food" (New-Color 255 70 58 54) (New-Color 255 133 84 48)
Write-Building "building_police.png" "security" (New-Color 255 50 65 77) (New-Color 255 52 94 137)
Write-Building "building_bookstore.png" "retail" (New-Color 255 64 54 49) (New-Color 255 112 82 48)
Write-Building "building_bakery.png" "food" (New-Color 255 73 59 49) (New-Color 255 154 88 49)
Write-Building "building_deli.png" "food" (New-Color 255 65 55 52) (New-Color 255 137 66 58)
Write-Building "building_butcher.png" "food" (New-Color 255 68 51 51) (New-Color 255 150 58 52)
Write-Building "building_church.png" "church" (New-Color 255 72 76 77) (New-Color 255 142 132 102)
Write-Building "building_school.png" "school" (New-Color 255 73 80 80) (New-Color 255 122 92 58)
Write-Building "building_hostel.png" "hostel" (New-Color 255 68 70 76) (New-Color 255 109 90 70)
Write-Building "building_row_house.png" "rowhouse" (New-Color 255 68 68 65) (New-Color 255 92 107 103)
Write-Building "building_corner_store.png" "retail" (New-Color 255 58 70 64) (New-Color 255 133 74 54)
Write-Building "building_garage.png" "industrial" (New-Color 255 55 60 62) (New-Color 255 118 96 68)
Write-Building "building_storage_depot.png" "industrial" (New-Color 255 51 60 59) (New-Color 255 131 103 66)
Write-Building "building_canteen.png" "food" (New-Color 255 70 64 56) (New-Color 255 148 103 56)
Write-Building "building_tea_shop.png" "food" (New-Color 255 55 71 65) (New-Color 255 102 132 94)

Write-Prop "frozen_car.png" "car" 500
Write-Prop "dead_tree.png" "tree" 501
Write-Prop "street_lamp.png" "lamp" 502
Write-Prop "roadblock.png" "barrier" 503
Write-Prop "barricade_wood.png" "barrier" 504
Write-Prop "sandbags.png" "barrier" 505
Write-Prop "crate_stack.png" "crate" 506
Write-Prop "dumpster_snow.png" "dumpster" 507
Write-Prop "barrel_fire.png" "fire" 508
Write-Prop "barrel_empty.png" "crate" 509
Write-Prop "traffic_cone.png" "cone" 510
Write-Prop "bus_stop_sign.png" "sign" 511
Write-Prop "shopping_cart.png" "cart" 512
Write-Prop "snow_drift.png" "snow" 513
Write-Prop "tire_pile.png" "tires" 514
Write-Prop "utility_box.png" "utility" 515

$latestDirection = Get-ChildItem -Recurse (Join-Path $env:USERPROFILE ".codex/generated_images") -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -eq ".png" } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
if ($latestDirection -ne $null) {
    $referencePath = New-AssetPath "resources/world/city/reference/outdoor_visual_direction_2026-05-02.png"
    if (-not (Test-Path -LiteralPath $referencePath)) {
        Copy-Item -LiteralPath $latestDirection.FullName -Destination $referencePath -Force
    }
    $latestReferencePath = New-AssetPath "resources/world/city/reference/world_visual_overhaul_direction.png"
    if (-not (Test-Path -LiteralPath $latestReferencePath)) {
        Copy-Item -LiteralPath $latestDirection.FullName -Destination $latestReferencePath -Force
    }
}

Import-BuildingSheet (Join-Path $cityRoot "reference/outdoor_building_sheet_2026-05-02.png")
Import-PropSheet (Join-Path $cityRoot "reference/outdoor_prop_sheet_2026-05-02.png")
Import-TerrainSheet (Join-Path $cityRoot "reference/outdoor_terrain_sheet_2026-05-02.png")

Write-Output "World visual overhaul assets generated."
