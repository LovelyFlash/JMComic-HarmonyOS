#!/usr/bin/env python3
"""Create PNG icons for PicaComic tabs using Pillow"""
from PIL import Image, ImageDraw
import os

DST = r'F:\Programming\Code\VS_Code\ArkTS\PicaComic-HarmonyOS\ohos\entry\src\main\resources\base\media'
os.makedirs(DST, exist_ok=True)

SIZE = 96

def create_icon(name, draw_func, color):
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_func(draw, color, SIZE)
    img.save(os.path.join(DST, name + '.png'))

def draw_nav_compass(draw, color, s):
    """Navigation/Explore - compass/arrow icon"""
    cx, cy, r = s//2, s//2, s//3
    draw.ellipse([cx-r, cy-r, cx+r, cy+r], outline=color, width=4)
    # Arrow pointing up-right
    pts = [(cx, cy-r+8), (cx+r-10, cy), (cx, cy+r-8)]
    draw.polygon(pts, fill=color)

def draw_clock(draw, color, s):
    """History - clock icon"""
    cx, cy, r = s//2, s//2, s//3
    draw.ellipse([cx-r, cy-r, cx+r, cy+r], outline=color, width=4)
    draw.line([cx, cy-r+12, cx, cy], fill=color, width=4)
    draw.line([cx, cy, cx+r-14, cy+8], fill=color, width=4)

def draw_heart(draw, color, s):
    """Favorites - heart icon (outline)"""
    # Simplified heart using two arcs
    cx, cy = s//2, s//2 + 4
    draw.ellipse([16, 18, 48, 50], outline=color, width=4)
    draw.ellipse([48, 18, 80, 50], outline=color, width=4)
    draw.polygon([(16, 40), (cx, cy+20), (80, 40)], outline=color, width=4)

def draw_heart_filled(draw, color, s):
    """Favorites filled - heart icon"""
    cx, cy = s//2, s//2 + 4
    draw.ellipse([16, 18, 48, 50], fill=color)
    draw.ellipse([48, 18, 80, 50], fill=color)
    draw.polygon([(16, 40), (cx, cy+20), (80, 40)], fill=color)

def draw_gear(draw, color, s):
    """Settings - gear icon"""
    cx, cy = s//2, s//2
    # Outer circle
    draw.ellipse([20, 20, 76, 76], outline=color, width=4)
    # Inner circle
    draw.ellipse([32, 32, 64, 64], outline=color, width=3)
    # Gear teeth (8 bumps)
    import math
    for i in range(8):
        angle = math.radians(i * 45)
        x1 = cx + int(30 * math.cos(angle))
        y1 = cy + int(30 * math.sin(angle))
        x2 = cx + int(40 * math.cos(angle))
        y2 = cy + int(40 * math.sin(angle))
        draw.line([x1, y1, x2, y2], fill=color, width=5)

def draw_arrow_left(draw, color, s):
    """Back arrow"""
    cy = s // 2
    draw.line([s-20, cy, 20, cy], fill=color, width=4)
    draw.polygon([(20, cy), (36, cy-14), (36, cy+14)], fill=color)

def draw_arrow_right(draw, color, s):
    """Right arrow"""
    cy = s // 2
    draw.line([20, cy, s-20, cy], fill=color, width=4)
    draw.polygon([(s-20, cy), (s-36, cy-14), (s-36, cy+14)], fill=color)

def draw_close(draw, color, s):
    """Close/X icon"""
    draw.line([24, 24, 72, 72], fill=color, width=4)
    draw.line([72, 24, 24, 72], fill=color, width=4)

def draw_search(draw, color, s):
    """Search icon"""
    draw.ellipse([16, 16, 56, 56], outline=color, width=4)
    draw.line([52, 52, 76, 76], fill=color, width=5)

def draw_download(draw, color, s):
    """Download arrow icon"""
    cx = s // 2
    draw.line([cx, 16, cx, 68], fill=color, width=4)
    draw.polygon([(cx, 72), (cx-14, 58), (cx+14, 58)], fill=color)
    draw.line([24, 72, 72, 72], fill=color, width=4)

def draw_share(draw, color, s):
    """Share icon"""
    draw.ellipse([36, 16, 56, 36], outline=color, width=3)
    draw.ellipse([16, 48, 36, 68], outline=color, width=3)
    draw.ellipse([56, 48, 76, 68], outline=color, width=3)
    draw.line([38, 30, 22, 54], fill=color, width=3)
    draw.line([54, 30, 70, 54], fill=color, width=3)

# Colors
GRAY = (142, 142, 147, 255)  # iOS gray
BLUE = (0, 122, 255, 255)    # iOS blue

# Tab icons
create_icon('ic_explore', draw_nav_compass, GRAY)
create_icon('ic_explore_selected', draw_nav_compass, BLUE)
create_icon('ic_history', draw_clock, GRAY)
create_icon('ic_history_selected', draw_clock, BLUE)
create_icon('ic_favorites', draw_heart, GRAY)
create_icon('ic_favorites_selected', draw_heart_filled, BLUE)
create_icon('ic_settings', draw_gear, GRAY)
create_icon('ic_settings_selected', draw_gear, BLUE)

# Utility icons
create_icon('ic_back', draw_arrow_left, GRAY)
create_icon('ic_arrow_right', draw_arrow_right, GRAY)
create_icon('ic_close', draw_close, GRAY)
create_icon('ic_search', draw_search, GRAY)
create_icon('ic_download', draw_download, GRAY)
create_icon('ic_share', draw_share, GRAY)

print(f'Created {14} PNG icons in {DST}')
