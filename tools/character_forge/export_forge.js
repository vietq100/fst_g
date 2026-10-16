// Exports the data of the Pixel Hero Forge (pixel-character.html) for the Godot port.
//   node tools/character_forge/export_forge.js
// Writes
//   actors/hunter/forge/forge_data.json    parts, items, animations, effects, constants (read by ForgeData)
//   tests/fixtures/forge_golden/*.json     reference output of the original engine (read by test_forge.gd)
// The engine is the part of the HTML's <script> before the "STATE + UI" section; it does not use the DOM.
const fs = require('fs');
const path = require('path');

const html = fs.readFileSync(path.join(__dirname, 'pixel-character.html'), 'utf8');
const start = html.indexOf('<script>') + '<script>'.length;
const marker = html.indexOf('STATE + UI');
const end = html.lastIndexOf('/* ===', marker);
const js = html.slice(start, end);
const forge = new Function(js + `; return { W, H, OX, OY, S, UNIT, OCC, RES, BLACK, FIXED, SHADE, HEAD, BODY, SHADOW, UNDER, ITEMS, ANIMS, FX,
  SHOULDER, ARM_LEN, IDLE_HAND, BOW_HAND, FAR_SHOULDER, CAST_X, BOW_X, GROUND, ramp, makePal, bodyPal, fineOf, rasterizeFine,
  GLASS_FINE, local, compose, composeRear, HEAD_REAR, rearHair, hexToRgb, findItem, OPT_CATS };`)();

const { ITEMS, ANIMS, FX, RES, UNIT } = forge;
const out = path.join(__dirname, '..', '..');
const dataDir = path.join(out, 'actors', 'hunter', 'forge');
const goldenDir = path.join(out, 'tests', 'fixtures', 'forge_golden');
fs.mkdirSync(dataDir, { recursive: true });
fs.mkdirSync(goldenDir, { recursive: true });

// ---- parts: plain data only (rows + flags); fine (1.5x) parts come out of fineOf ----
const flags = p => {
  const o = { x: p.x, y: p.y, rows: p.rows };
  for (const k of ['outline', 'inner', 'near', 'keep', 'pattern', 'thick', 'res', 'ox', 'oy']) if (p[k] !== undefined) o[k] = p[k];
  return o;
};
const fineKind = { shirt: RES.shirt, hat: RES.hat };
function exportItem(cat, it) {
  const o = { id: it.id, name: it.name };
  for (const k of ['color', 'accent', 'clip', 'sleeve', 'sleeveColor', 'anim', 'hold', 'tip', 'reach']) if (it[k] !== undefined) o[k] = it[k];
  const conv = p => (fineKind[cat] ? flags(forge.fineOf(p, fineKind[cat])) : flags(p));
  if (it.parts) o.parts = it.parts.map(conv);
  if (it.back) o.back = it.back.map(conv);
  // rear view (game: facing up): hats may list the parts kept (indices) or have their own parts
  if (it.rear) {
    if (typeof it.rear[0] === 'number') o.rear_keep = it.rear;
    else o.rear = it.rear.map(conv);
  }
  if (cat === 'hair' && it.parts) o.rear = forge.rearHair(it).map(flags);
  o.has_shape = !!it.shape;       // weapons are drawn geometrically: they are ported by hand
  return o;
}
const items = {};
for (const cat of Object.keys(ITEMS)) items[cat] = ITEMS[cat].map(it => exportItem(cat, it));

// ---- glasses: rasterised once at 2.5x (the shapes are functions) ----
const glasses = {};
for (const id of Object.keys(forge.GLASS_FINE)) {
  const outlined = id === 'goggle' || id === 'patch';
  const part = forge.rasterizeFine(RES.glasses, 9, 12.5, 7, forge.GLASS_FINE[id](RES.glasses), { outline: outlined });
  glasses[id] = { ...flags(part), res: part.res, ox: part.ox, oy: part.oy };
}

const data = {
  w: forge.W, h: forge.H, ox: forge.OX, oy: forge.OY, unit: UNIT, occ: forge.OCC, res: RES, black: forge.BLACK, fixed: forge.FIXED,
  shade: forge.SHADE, head: forge.HEAD, body: { ...forge.BODY, head_rear: [{ x: 4, y: 3, rows: forge.HEAD_REAR }] }, shadow: forge.SHADOW, under: forge.UNDER,
  shoulder: forge.SHOULDER, arm_len: forge.ARM_LEN, idle_hand: forge.IDLE_HAND, bow_hand: forge.BOW_HAND, far_shoulder: forge.FAR_SHOULDER,
  cast_x: forge.CAST_X, bow_x: forge.BOW_X, ground: forge.GROUND,
  items, glasses, anims: ANIMS, fx: FX,
};
const stringify = v => JSON.stringify(v);
fs.writeFileSync(path.join(dataDir, 'forge_data.json'), stringify(data));

// ---- golden fixtures ----
const sel = (k, id) => { const o = forge.findItem(k, id); return { id, color: o.color || '#888888', accent: o.accent || o.color || '#888888' }; };
const coreCfg = () => ({
  skin: '#f4c4a3', eyes: '#3a1a0c', tank: '#ecebe4', shorts: '#3f6db3', black: true,
  hair: { id: 'none', color: '#4a3022', accent: '#e0507a' },
  shirt: sel('shirt', 'none'), pants: sel('pants', 'none'), shoes: sel('shoes', 'none'),
  glasses: sel('glasses', 'none'), hat: sel('hat', 'none'), weapon: sel('weapon', 'none'), fx: 'none', wres: 3,
});
const presetCfg = () => ({
  ...coreCfg(),
  hair: { id: 'short', color: '#47352e', accent: '#e0507a' },
  shirt: sel('shirt', 'armor'), pants: sel('pants', 'armor'), shoes: sel('shoes', 'armor'), weapon: sel('weapon', 'sword'),
});
const ops = g => g.ops.map(o => [o.x, o.y, o.s, Math.round(o.c[0]), Math.round(o.c[1]), Math.round(o.c[2]), +o.a.toFixed(3)]);
const golden = {};
const add = (name, cfg, st) => { golden[name] = { cfg, st: st || {}, ops: ops(forge.compose(cfg, st || {})) }; };

add('core', coreCfg());
add('core_blink', coreCfg(), { blink: true });
add('preset', presetCfg());
add('preset_bob', presetCfg(), { bob: 0.5 });
const withCfg = (patch) => ({ ...presetCfg(), ...patch });
for (const w of ITEMS.weapon) {
  if (w.id === 'none') continue;
  add('weapon_' + w.id, withCfg({ weapon: sel('weapon', w.id) }));
  if (w.anim && ANIMS[w.anim]) {
    const frames = ANIMS[w.anim];
    const fi = Math.min(frames.length - 1, 2);
    add('attack_' + w.id, withCfg({ weapon: sel('weapon', w.id), fx: w.anim === 'cast' ? 'fire' : 'none' }),
      { pose: frames[fi], frames, fi, p: 0.5, t: 100, seed: 3 });
  }
}
// every attack frame without its effects (PHASE_13 step 4: poses are drawn, effects come in step 6)
const FX_KEYS = ['arc', 'hit', 'shock', 'circle', 'charge', 'strike', 'proj', 'lines', 'mark', 'shake', 'fade'];
for (const w of ITEMS.weapon) {
  if (!w.anim || !ANIMS[w.anim]) continue;
  ANIMS[w.anim].forEach((frame, i) => {
    if (i !== 0 && i !== 2) return;   // wind-up (behind / drawn arrow) and the swing
    const pose = Object.fromEntries(Object.entries(frame).filter(([k]) => !FX_KEYS.includes(k)));
    // frames / fi only feed the effects: one "hit" frame for the impact point, fi before it (no particles)
    add(`pose_${w.id}_${i}`, withCfg({ weapon: sel('weapon', w.id) }), { pose, frames: [{ ...pose, hit: true }], fi: -1 });
  });
}
// every element: a sword hit (burst + particles + aura), the staff's strike (spell column) and the rest aura
for (const el of Object.keys(FX)) {
  const slash = ANIMS.slash, hi = slash.findIndex(f => f.hit);
  add(`fx_${el}_slash`, withCfg({ weapon: sel('weapon', 'sword'), fx: el }), { pose: slash[hi], frames: slash, fi: hi, p: 0.3, t: 240, seed: 5 });
  const cast = ANIMS.cast;
  add(`fx_${el}_strike`, withCfg({ weapon: sel('weapon', 'staff'), fx: el }), { pose: cast[3], frames: cast, fi: 3, p: 0.6, t: 380, seed: 9 });
  add(`fx_${el}_rest`, withCfg({ weapon: sel('weapon', 'axe'), fx: el }), { t: 200 });
}
// rear view (facing up): a few looks, with and without weapons, one breathing
const addRear = (name, cfg, st) => { golden[name] = { cfg, st: { ...(st || {}), back: true }, ops: ops(forge.composeRear(cfg, st || {})) }; };
addRear('rear_core', coreCfg());
addRear('rear_preset', presetCfg());
addRear('rear_preset_bob', presetCfg(), { bob: 1 });
addRear('rear_bow_hood', withCfg({ weapon: sel('weapon', 'bow'), hat: sel('hat', 'hood'), hair: { id: 'long', color: '#c0472f', accent: '#e0507a' } }));
addRear('rear_helm_pony', withCfg({ weapon: sel('weapon', 'hammer'), hat: sel('hat', 'helm'), hair: { id: 'pony', color: '#d9a441', accent: '#e0507a' } }));
addRear('rear_hoodie_twin', withCfg({ shirt: sel('shirt', 'hoodie'), weapon: sel('weapon', 'none'), hair: { id: 'twin', color: '#e070a8', accent: '#e0507a' } }));
for (const [cat, id] of [['hat', 'helm'], ['hat', 'hood'], ['hair', 'long'], ['hair', 'spiky'], ['hat', 'wizard'], ['hat', 'viking'], ['glasses', 'round'], ['glasses', 'goggle'],
    ['shirt', 'hoodie'], ['pants', 'jeans'], ['shoes', 'boots']]) {
  if (!ITEMS[cat].some(o => o.id === id)) continue;
  add(`${cat}_${id}`, withCfg({ [cat]: sel(cat, id) }));
}
fs.writeFileSync(path.join(goldenDir, 'compose.json'), stringify(golden));

// palette golden: ramp of a few colours
const rampSamples = {};
for (const hex of ['#47352e', '#f4c4a3', '#d24a43', '#3f6db3', '#ecebe4', '#2b2630', '#f1e3b3', '#6b5ac9']) {
  const r = forge.ramp(hex);
  rampSamples[hex] = Object.fromEntries(Object.entries(r).map(([k, v]) => [k, v.map(c => +c.toFixed(3))]));
}
fs.writeFileSync(path.join(goldenDir, 'ramp.json'), stringify(rampSamples));

// weapon rows at 7 angles (rest pose position of each weapon)
const angles = [-90, -60, 0, 45, 90, 135, 180];
const weaponRows = {};
for (const w of ITEMS.weapon) {
  if (!w.shape) continue;
  const G = w.hold.slice(0, 2);
  weaponRows[w.id] = {};
  for (const ang of angles) {
    const wst = { K: RES.weapon, pull: 0, arrow: false };
    const part = forge.rasterizeFine(RES.weapon, G[0], G[1], w.reach, forge.local(G[0], G[1], ang, (u, v) => w.shape(u, v, wst)));
    weaponRows[w.id][ang] = { ox: part.ox, oy: part.oy, res: part.res, rows: part.rows };
  }
}
fs.writeFileSync(path.join(goldenDir, 'weapons.json'), stringify(weaponRows));

const size = f => (fs.statSync(f).size / 1024).toFixed(0) + ' KB';
console.log('forge_data.json', size(path.join(dataDir, 'forge_data.json')));
for (const f of fs.readdirSync(goldenDir)) console.log('golden/' + f, size(path.join(goldenDir, f)));
console.log('golden configs:', Object.keys(golden).length, '· weapons:', Object.keys(weaponRows).join(' '));
