#!/usr/bin/env python3
"""Convert HarmonyOS SVG icons to PNG for PicaComic"""
import os
import re

SRC = r'D:\desktop\HarmonyOS_Icons'
DST = r'F:\Programming\Code\VS_Code\ArkTS\PicaComic-HarmonyOS\ohos\entry\src\main\resources\base\media'

ICONS = {
    'ic_explore': 'ic_public_navigation.svg',
    'ic_explore_selected': 'ic_public_navigation_filled.svg',
    'ic_history': 'ic_public_history.svg',
    'ic_history_selected': 'ic_public_clock_filled.svg',
    'ic_favorites': 'ic_public_favor.svg',
    'ic_favorites_selected': 'ic_public_favor_filled.svg',
    'ic_settings': 'ic_public_settings.svg',
    'ic_settings_selected': 'ic_public_settings_filled.svg',
    'ic_back': 'ic_public_arrow_left.svg',
    'ic_arrow_right': 'ic_public_arrow_right.svg',
    'ic_close': 'ic_public_close.svg',
    'ic_search': 'ic_public_input_search.svg',
    'ic_download': 'ic_public_download.svg',
    'ic_share': 'ic_public_share.svg',
}

# Generate HTML with all icons
html_parts = ['<!DOCTYPE html><html><head><style>']
html_parts.append('body { margin: 0; padding: 0; background: white; }')
html_parts.append('.icon { display: inline-block; width: 96px; height: 96px; margin: 4px; }')
html_parts.append('.icon svg { width: 96px; height: 96px; }')
html_parts.append('</style></head><body>')

count = 0
for name, svg_file in ICONS.items():
    svg_path = os.path.join(SRC, svg_file)
    if not os.path.exists(svg_path):
        print(f'SKIP: {svg_file} not found')
        continue
    with open(svg_path, 'r', encoding='utf-8') as f:
        svg_content = f.read()
    # Force SVG to fill 96x96
    svg_content = re.sub(r'width="[^"]*"', 'width="96"', svg_content)
    svg_content = re.sub(r'height="[^"]*"', 'height="96"', svg_content)
    html_parts.append(f'<div class="icon" data-name="{name}">{svg_content}</div>')
    count += 1

html_parts.append('</body></html>')

html_path = os.path.join(DST, '_convert_icons.html')
with open(html_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(html_parts))
print(f'Created HTML with {count} icons at {html_path}')
