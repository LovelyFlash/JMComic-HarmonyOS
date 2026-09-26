// Playwright script to convert SVG icons to PNG
import { chromium } from 'playwright';
import * as fs from 'fs';
import * as path from 'path';

const SRC = 'D:\\desktop\\HarmonyOS_Icons';
const DST = 'F:\\Programming\\Code\\VS_Code\\ArkTS\\PicaComic-HarmonyOS\\ohos\\entry\\src\\main\\resources\\base\\media';

const ICONS = {
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
};

async function main() {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 96, height: 96 } });
  
  for (const [name, svgFile] of Object.entries(ICONS)) {
    const svgPath = path.join(SRC, svgFile);
    if (!fs.existsSync(svgPath)) {
      console.log(`SKIP: ${svgFile}`);
      continue;
    }
    
    let svgContent = fs.readFileSync(svgPath, 'utf-8');
    // Force size to 96x96
    svgContent = svgContent.replace(/width="[^"]*"/, 'width="96"');
    svgContent = svgContent.replace(/height="[^"]*"/, 'height="96"');
    
    const html = `<!DOCTYPE html><html><body style="margin:0;padding:0;background:transparent;display:flex;align-items:center;justify-content:center;width:96px;height:96px">${svgContent}</body></html>`;
    
    await page.setContent(html);
    const outPath = path.join(DST, name + '.png');
    await page.screenshot({ path: outPath, omitBackground: true });
    console.log(`Created: ${name}.png`);
  }
  
  await browser.close();
  console.log('Done!');
}

main().catch(console.error);
