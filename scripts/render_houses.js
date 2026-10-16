// Rend brand/houses/*.svg en assets/houses/*.jpg (1200x900) avec Chromium (playwright-core).
const { chromium } = require('playwright-core');
const fs = require('fs'), path = require('path');
const src = path.join(__dirname, '..', 'brand', 'houses'), dst = path.join(__dirname, '..', 'assets', 'houses');
(async () => {
  const b = await chromium.launch({ executablePath: process.env.CHROMIUM || '/opt/pw-browsers/chromium', args: ['--no-sandbox'] });
  const p = await b.newPage({ viewport: { width: 1200, height: 900 } });
  for (const f of fs.readdirSync(src).filter(f => f.endsWith('.svg'))) {
    await p.setContent(`<body style="margin:0">${fs.readFileSync(path.join(src, f), 'utf8')}</body>`);
    await p.screenshot({ path: path.join(dst, f.replace('.svg', '.jpg')), type: 'jpeg', quality: 86 });
  }
  await b.close();
})();
