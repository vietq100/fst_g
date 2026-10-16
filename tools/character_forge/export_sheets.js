// Renders sprite sheets of the Pixel Hero Forge with the original engine (no Godot needed), to check the
// art and the game's look mapping at a glance (D77).
//   node tools/character_forge/export_sheets.js [out_dir] [scale]
// Writes (default out_dir build/forge_sheets, scale 4 px per character pixel):
//   classes.png   one row per class look (as ForgeLook maps it): idle, breath, blink, rear, rear breath,
//                 then every frame of the class weapon's attack sequence
//   hair.png      the 18 hair styles in the game's order (HunterAppearance.hair_style), front over rear
//   hats.png      every hat, front over rear
//   tops.png      every top, pants and shoes item
//   weapons.png   every weapon at rest, then its attack sequence (fire effects)
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const html = fs.readFileSync(path.join(__dirname, 'pixel-character.html'), 'utf8');
const start = html.indexOf('<script>') + '<script>'.length;
const marker = html.indexOf('STATE + UI');
const end = html.lastIndexOf('/* ===', marker);
const forge = new Function(html.slice(start, end) + `; return { W, H, UNIT, ITEMS, ANIMS, compose, composeRear, findItem };`)();
const { W, H, UNIT, ITEMS, ANIMS } = forge;

const out = path.resolve(process.argv[2] || path.join(__dirname, '..', '..', 'build', 'forge_sheets'));
const SCALE = Math.max(1, parseInt(process.argv[3] || '4', 10));
fs.mkdirSync(out, { recursive: true });

// ---- the game's look mapping (ForgeLook.config, CLASS_LOOKS, HAIR_IDS; first skin and hair colours) ----
const HAIR_IDS = ['short', 'spiky', 'buzz', 'sweep', 'hero', 'bob', 'long', 'pony', 'twin', 'bun',
  'quiff', 'mohawk', 'afro', 'pixie', 'hime', 'wavy', 'braid', 'buns'];
const sel = (cat, id, color) => {
  const it = forge.findItem(cat, id);
  return { id, color: color || it.color || '#888888', accent: it.accent || it.color || '#888888' };
};
const base = (hair = 'short') => ({
  skin: '#fbcbb9', eyes: '#0d0a10', tank: '#ecebe4', shorts: '#c94a4a', black: true,
  hair: { id: hair, color: '#2b2230', accent: '#e0507a' },
  shirt: sel('shirt', 'none'), pants: sel('pants', 'none'), shoes: sel('shoes', 'none'),
  glasses: sel('glasses', 'none'), hat: sel('hat', 'none'), weapon: sel('weapon', 'none'), fx: 'none',
});
const CLASSES = [
  ['core', base(), 'sword'],
  ['warrior', { ...base('spiky'), shirt: sel('shirt', 'armor'), pants: sel('pants', 'armor'), shoes: sel('shoes', 'armor') }, 'sword'],
  ['ranger', { ...base('pony'), shirt: sel('shirt', 'jacket', '#5f8236'), pants: sel('pants', 'cargo'), shoes: sel('shoes', 'boots') }, 'bow'],
  ['rogue', { ...base('hime'), shirt: sel('shirt', 'hoodie', '#52456c'), pants: sel('pants', 'jeans', '#2b2630'), shoes: sel('shoes', 'leather') }, 'dagger'],
  ['guardian', { ...base('buzz'), shirt: sel('shirt', 'knight'), pants: sel('pants', 'armor'), shoes: sel('shoes', 'armor') }, 'hammer'],
];

// ---- painting (like the HTML paint(): rectangles rounded to the output grid, alpha blended) ----
function canvas(cols, rows) {
  const w = cols * W * SCALE, h = rows * H * SCALE;
  return { w, h, px: new Float32Array(w * h * 4) };
}
function paint(cv, g, col, row) {
  const k = SCALE / UNIT, ox = col * W * SCALE, oy = row * H * SCALE;
  for (const o of g.ops) {
    const x0 = Math.round(o.x * k), y0 = Math.round(o.y * k);
    const x1 = Math.round((o.x + o.s) * k), y1 = Math.round((o.y + o.s) * k);
    const c = [(o.c[0] | 0) / 255, (o.c[1] | 0) / 255, (o.c[2] | 0) / 255], a = o.a;
    for (let y = Math.max(0, y0); y < Math.min(H * SCALE, y1); y++) {
      for (let x = Math.max(0, x0); x < Math.min(W * SCALE, x1); x++) {
        const i = ((oy + y) * cv.w + ox + x) * 4, da = cv.px[i + 3], na = a + da * (1 - a);
        for (let j = 0; j < 3; j++) cv.px[i + j] = na ? (c[j] * a + cv.px[i + j] * da * (1 - a)) / na : 0;
        cv.px[i + 3] = na;
      }
    }
  }
}
function png(cv, file) {
  const raw = Buffer.alloc((cv.w * 4 + 1) * cv.h);
  for (let y = 0; y < cv.h; y++) {
    raw[y * (cv.w * 4 + 1)] = 0;
    for (let x = 0; x < cv.w * 4; x++) raw[y * (cv.w * 4 + 1) + 1 + x] = Math.round(cv.px[y * cv.w * 4 + x] * 255);
  }
  const chunk = (type, data) => {
    const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
    const body = Buffer.concat([Buffer.from(type), data]);
    const crc = Buffer.alloc(4); crc.writeUInt32BE(zlib.crc32(body) >>> 0);
    return Buffer.concat([len, body, crc]);
  };
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(cv.w, 0); ihdr.writeUInt32BE(cv.h, 4); ihdr[8] = 8; ihdr[9] = 6;
  fs.writeFileSync(path.join(out, file), Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw, { level: 9 })), chunk('IEND', Buffer.alloc(0))]));
  console.log(path.join(out, file), `${cv.w}×${cv.h}`);
}
const attackFrames = (cfg, weaponId, fx = 'none') => {
  const anim = forge.findItem('weapon', weaponId).anim;
  const frames = ANIMS[anim] || [];
  let t = 0;
  return frames.map((pose, fi) => {
    const st = { pose, frames, fi, p: 0.5, t, seed: 3 };
    t += pose.d;
    return forge.compose({ ...cfg, weapon: sel('weapon', weaponId), fx }, st);
  });
};

// ---- classes.png ----
{
  const rows = CLASSES.map(([name, cfg, weapon]) => {
    const look = { ...cfg, weapon: sel('weapon', weapon) };
    return [forge.compose(look, {}), forge.compose(look, { bob: 1 }), forge.compose(look, { blink: true }),
      forge.composeRear(look, {}), forge.composeRear(look, { bob: 1 }), ...attackFrames(cfg, weapon)];
  });
  const cv = canvas(Math.max(...rows.map(r => r.length)), rows.length);
  rows.forEach((r, j) => r.forEach((g, i) => paint(cv, g, i, j)));
  png(cv, 'classes.png');
}
// ---- hair.png ----
{
  const cv = canvas(HAIR_IDS.length, 2);
  HAIR_IDS.forEach((id, i) => { paint(cv, forge.compose(base(id), {}), i, 0); paint(cv, forge.composeRear(base(id), {}), i, 1); });
  png(cv, 'hair.png');
}
// ---- hats.png ----
{
  const hats = ITEMS.hat.filter(h => h.id !== 'none');
  const cv = canvas(hats.length, 2);
  hats.forEach((h, i) => {
    const cfg = { ...base(), hat: sel('hat', h.id) };
    paint(cv, forge.compose(cfg, {}), i, 0); paint(cv, forge.composeRear(cfg, {}), i, 1);
  });
  png(cv, 'hats.png');
}
// ---- tops.png: tops, then pants, then shoes ----
{
  const rows = ['shirt', 'pants', 'shoes'].map(cat => ITEMS[cat].filter(it => it.id !== 'none')
    .map(it => forge.compose({ ...base(), [cat]: sel(cat, it.id) }, {})));
  const cv = canvas(Math.max(...rows.map(r => r.length)), rows.length);
  rows.forEach((r, j) => r.forEach((g, i) => paint(cv, g, i, j)));
  png(cv, 'tops.png');
}
// ---- weapons.png ----
{
  const rows = ITEMS.weapon.filter(w => w.id !== 'none').map(w =>
    [forge.compose({ ...base(), weapon: sel('weapon', w.id) }, {}), ...attackFrames(base(), w.id, 'fire')]);
  const cv = canvas(Math.max(...rows.map(r => r.length)), rows.length);
  rows.forEach((r, j) => r.forEach((g, i) => paint(cv, g, i, j)));
  png(cv, 'weapons.png');
}
