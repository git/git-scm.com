// Generate Git-Icon-*.{svg,png,eps} and Git-Logo-*.{svg,png,eps} using
// Paper.js boolean operations to produce a single closed path from
// design primitives, then rasterize the SVGs to PNG via resvg and
// wrap vector + raster preview into EPS.
//
// Prerequisites:
//   npm install --no-save paper paperjs-offset @resvg/resvg-js node-zopflipng sharp
//
// Source geometry (on a 58x58 grid with origin at 0,0):
//   - Rounded rectangle background: (0,0) 58x58, corner radius 5
//   - Main branch: vertical line x=40.5, y=0..41, stroke-width 5
//   - Topic branch: diagonal (40.5,18) to (17.5,41), stroke-width 5
//   - Three circles at (40.5,18), (40.5,41), (17.5,41), all r=6
//
// The result is placed into a 78x78 viewBox via:
//   transform="translate(10 10) rotate(-45 29 29)"
// Design on 58x58, rotate -45 around the shape center, translate
// to center in 78x78 viewBox.
//
// The Logo files combine the generated icon path scaled by 92/78 times
// with the existing "git" text glyph outlines (g, i, t).

const paper = require('paper');
const { PaperOffset } = require('paperjs-offset');
const { Resvg } = require('@resvg/resvg-js');
const { optimizeZopfliPngSync } = require('node-zopflipng');
const sharp = require('sharp');

const fs = require('fs');
const path = require('path');
const outDir = path.join(__dirname, '../static/images/logos/downloads');

function saveFile(filename, data) {
  const outPath = path.join(outDir, filename);
  fs.writeFileSync(outPath, data);
  console.log(`Wrote ${outPath}`);
}

// Render an SVG string to PNG at 300 DPI via resvg.
// Icons (92pt × 92pt) render to 383x383; Logos (219pt × 92pt) to 913×383.
function renderPng(svgString) {
  const resvg = new Resvg(svgString, { dpi: 300 });
  const png = resvg.render().asPng();
  return optimizeZopfliPngSync(png, {
    // Remove color information from transparent pixels.
    lossyTransparent: true,
    // Do more iterations for better compression.
    more: true,
  });
}

// ============================= EPS generation ==============================

// Convert hex color (#rgb or #rrggbb) to "r g b" PS string (0-1 range).
function hexToPS(hex) {
  const h = hex.replace('#', '');
  const n = h.length === 3
    ? [parseInt(h[0] + h[0], 16), parseInt(h[1] + h[1], 16), parseInt(h[2] + h[2], 16)]
    : [parseInt(h.slice(0, 2), 16), parseInt(h.slice(2, 4), 16), parseInt(h.slice(4, 6), 16)];
  return n.map(v => +(v / 255).toFixed(5)).join(' ');
}

// Convert SVG path `d` string to PostScript path commands.
// Handles: M/m, L/l, H/h, V/v, C/c, Z/z (the subset Paper.js emits).
function svgPathToPS(d) {
  const tokens = d.match(/[MmLlHhVvCcZz]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?/g);
  const out = [];
  let cx = 0, cy = 0, mx = 0, my = 0, i = 0;
  const r = v => +v.toFixed(5);
  const num = () => parseFloat(tokens[i++]);
  const isNum = () => i < tokens.length && /^[-+.\d]/.test(tokens[i]);

  while (i < tokens.length) {
    switch (tokens[i++]) {
      case 'M':
        cx = num(); cy = num(); mx = cx; my = cy;
        out.push(`${r(cx)} ${r(cy)} moveto`);
        while (isNum()) { cx = num(); cy = num(); out.push(`${r(cx)} ${r(cy)} lineto`); }
        break;
      case 'm':
        cx += num(); cy += num(); mx = cx; my = cy;
        out.push(`${r(cx)} ${r(cy)} moveto`);
        while (isNum()) { cx += num(); cy += num(); out.push(`${r(cx)} ${r(cy)} lineto`); }
        break;
      case 'L':
        while (isNum()) { cx = num(); cy = num(); out.push(`${r(cx)} ${r(cy)} lineto`); }
        break;
      case 'l':
        while (isNum()) { cx += num(); cy += num(); out.push(`${r(cx)} ${r(cy)} lineto`); }
        break;
      case 'H':
        while (isNum()) { cx = num(); out.push(`${r(cx)} ${r(cy)} lineto`); }
        break;
      case 'h':
        while (isNum()) { cx += num(); out.push(`${r(cx)} ${r(cy)} lineto`); }
        break;
      case 'V':
        while (isNum()) { cy = num(); out.push(`${r(cx)} ${r(cy)} lineto`); }
        break;
      case 'v':
        while (isNum()) { cy += num(); out.push(`${r(cx)} ${r(cy)} lineto`); }
        break;
      case 'C':
        while (isNum()) {
          const x1 = num(), y1 = num(), x2 = num(), y2 = num();
          cx = num(); cy = num();
          out.push(`${r(x1)} ${r(y1)} ${r(x2)} ${r(y2)} ${r(cx)} ${r(cy)} curveto`);
        }
        break;
      case 'c':
        while (isNum()) {
          const x1 = cx + num(), y1 = cy + num(), x2 = cx + num(), y2 = cy + num();
          cx += num(); cy += num();
          out.push(`${r(x1)} ${r(y1)} ${r(x2)} ${r(y2)} ${r(cx)} ${r(cy)} curveto`);
        }
        break;
      case 'Z': case 'z':
        out.push('closepath'); cx = mx; cy = my;
        break;
    }
  }
  return out.join('\n');
}

// Build a DOS EPS Binary file: 30-byte header + PostScript + TIFF preview.
async function buildEPS(psContent, svgString, previewFitTo) {
  // Render TIFF preview at 1:1 (1pt = 1px)
  const resvgOpts = previewFitTo ? { fitTo: previewFitTo } : { dpi: 72 };
  const resvg = new Resvg(svgString, resvgOpts);
  const tiffBuf = await sharp(resvg.render().asPng())
    .tiff({ compression: 'lzw' })
    .toBuffer();

  const psBuf = Buffer.from(psContent, 'latin1');
  const hdrSize = 30;
  const header = Buffer.alloc(hdrSize);
  header.writeUInt32LE(0xC6D3D0C5, 0);      // DOS EPS magic
  header.writeUInt32LE(hdrSize, 4);           // PS offset
  header.writeUInt32LE(psBuf.length, 8);      // PS length
  header.writeUInt32LE(0, 12);                // WMF offset (none)
  header.writeUInt32LE(0, 16);                // WMF length (none)
  header.writeUInt32LE(hdrSize + psBuf.length, 20); // TIFF offset
  header.writeUInt32LE(tiffBuf.length, 24);   // TIFF length
  header.writeUInt16LE(0xFFFF, 28);           // checksum (none)

  return Buffer.concat([header, psBuf, tiffBuf]);
}

// ================================== Icon ===================================

// The path data of the git icon.
const iconGlyph = (() => {
  paper.setup(new paper.Size(78, 78));

  // Background: rounded rectangle
  const bg = new paper.Path.Rectangle({
    point: [0, 0],
    size: [58, 58],
    radius: 5,
  });

  // Branch lines (expand strokes into filled outlines)
  const mainBranch = new paper.Path.Line({ from: [40.5, 0], to: [40.5, 41] });
  const mainExp = PaperOffset.offsetStroke(mainBranch, 2.5, { cap: 'butt' });
  mainBranch.remove();

  const topicBranch = new paper.Path.Line({ from: [40.5, 18], to: [17.5, 41] });
  const topicExp = PaperOffset.offsetStroke(topicBranch, 2.5, { cap: 'butt' });
  topicBranch.remove();

  // Circles
  const branchPoint = new paper.Path.Circle({ center: [40.5, 18], radius: 6 });
  const mainStart   = new paper.Path.Circle({ center: [40.5, 41], radius: 6 });
  const topicStart  = new paper.Path.Circle({ center: [17.5, 41], radius: 6 });

  // Unite all graph elements
  let graph = mainExp.unite(topicExp);
  graph = graph.unite(branchPoint);
  graph = graph.unite(mainStart);
  graph = graph.unite(topicStart);

  // Subtract graph from background
  const icon = bg.subtract(graph);

  return icon.pathData;
})();

// Transform which converts the 58×58 square into a diamond (i.e. rotates it by
// 45° and centres it within 78×78 box).
const iconTransform = `translate(10 10) rotate(-45 29 29)`;

// Generates and saves the icon image file.
async function generateIcon(variant, iconFill) {
  const svg =
    `<svg xmlns="http://www.w3.org/2000/svg" width="92pt" height="92pt"` +
    ` viewBox="0 0 78 78"><path fill="${iconFill}"` +
    ` transform="${iconTransform}" d="${iconGlyph}"/></svg>`;
  saveFile(`Git-Icon-${variant}.svg`, svg);
  saveFile(`Git-Icon-${variant}.png`, renderPng(svg));

  const ps = [
    '%!PS-Adobe-3.0 EPSF-3.0',
    '%%BoundingBox: 0 0 92 92',
    '%%EndComments',
    'gsave',
    '0 92 translate 1 -1 scale',
    '1.179487 1.179487 scale 10 10 translate',
    '29 29 translate -45 rotate -29 -29 translate',
    'newpath',
    svgPathToPS(iconGlyph),
    `${hexToPS(iconFill)} setrgbcolor fill`,
    'grestore',
    '%%EOF\n',
  ].join('\n');
  saveFile(`Git-Icon-${variant}.eps`, await buildEPS(ps, svg));
}


// ================================== Logo ===================================

// Text glyph paths extracted from the original Logo SVGs.  These are font
// outlines for the letters "g", "i", and "t" and are carried forward unchanged.
const gGlyph =
  'M130.871 31.836c-4.785 0-8.351 2.352-8.351 8.008 0 4.261 2.347 ' +
  '7.222 8.093 7.222 4.871 0 8.18-2.867 8.18-7.398 0-5.133-2.961-' +
  '7.832-7.922-7.832Zm-9.57 39.95c-1.133 1.39-2.262 2.87-2.262 ' +
  '4.612 0 3.48 4.434 4.524 10.527 4.524 5.051 0 11.926-.352 ' +
  '11.926-5.043 0-2.793-3.308-2.965-7.488-3.227Zm25.761-39.688c1.563 ' +
  '2.004 3.22 4.789 3.22 8.793 0 9.656-7.571 15.316-18.536 ' +
  '15.316-2.789 0-5.312-.348-6.879-.785l-2.87 4.613 8.526.52c15.059.96 ' +
  '23.934 1.398 23.934 12.968 0 10.008-8.789 15.665-23.934 ' +
  '15.665-15.75 0-21.757-4.004-21.757-10.88 0-3.917 1.742-6 ' +
  '4.789-8.878-2.875-1.211-3.828-3.387-3.828-5.739 0-1.914.953-3.656 ' +
  '2.523-5.312 1.566-1.652 3.305-3.305 5.395-5.219-4.262-2.09-7.485-' +
  '6.617-7.485-13.058 0-10.008 6.613-16.88 19.93-16.88 3.742 0 ' +
  '6.004.344 8.008.872h16.972v7.394l-8.007.61';

const iGlyph =
  'M170.379 16.281c-4.961 0-7.832-2.87-7.832-7.836 0-4.957 2.871-' +
  '7.656 7.832-7.656 5.05 0 7.922 2.7 7.922 7.656 0 4.965-2.871 ' +
  '7.836-7.922 7.836Zm-11.227 52.305V61.71l4.438-.606c1.219-.175 ' +
  '1.394-.437 1.394-1.746V33.773c0-.953-.261-1.566-1.132-1.824l-4.7-' +
  '1.656.957-7.047h18.016V59.36c0 1.399.086 1.57 1.395 1.746l4.437' +
  '.606v6.875h-24.805';

const tGlyph =
  'M218.371 65.21c-3.742 1.825-9.223 3.481-14.187 3.481-10.356 ' +
  '0-14.27-4.175-14.27-14.015V31.879c0-.524 0-.871-.7-.871h-6.093v-' +
  '7.746c7.664-.871 10.707-4.703 11.664-14.188h8.27v12.36c0 .609 0 ' +
  '.87.695.87h12.27v8.704h-12.965v20.797c0 5.136 1.218 7.136 5.918 ' +
  '7.136 2.437 0 4.96-.609 7.047-1.39l2.351 7.66';

// Transforms which transforms the 78×78 icon glyph into 92×92 to match the
// shape of the letters.
const iconScale = `scale(${+(92 / 78).toFixed(6)})`;

// Generates and saves the logo (icon + text) image file.
async function generateLogo(variant, iconFill, textFill) {
  // If icon and text fills are the same, add a single fill attribute on the SVG
  // element.
  //
  // We’re doing this because we’re using the SVG file on the website via USE
  // element and want to override the FILL for logo and text.  If the PATH
  // element has FILL we cannot USE it and then override FILL.  However, if we
  // put FILL on SVG we can then USE the PATH elements and set FILL to a new
  // value.
  const [ svgFillAttr, iconFillAttr, textFillAttr ] = iconFill == textFill
    ? [ ` fill="${iconFill}"`, '', '' ]
    : [ '', ` fill="${iconFill}"`, ` fill="${textFill}"` ];

  const iconPath =
    `<path id="icon"${iconFillAttr}` +
    ` transform="${iconScale} ${iconTransform}" d="${iconGlyph}"/>`;
  const textPaths =
    `<path id="text"${textFillAttr} d="${gGlyph}${iGlyph}${tGlyph}"/>`;
  const svg =
    `<svg xmlns="http://www.w3.org/2000/svg" width="219pt" height="92pt"` +
    `${svgFillAttr} viewBox="0 0 219 92">${iconPath}${textPaths}</svg>`;
  saveFile(`Git-Logo-${variant}.svg`, svg);

  saveFile(`Git-Logo-${variant}.png`, renderPng(svg));

  const ps = [
    '%!PS-Adobe-3.0 EPSF-3.0',
    '%%BoundingBox: 0 0 219 92',
    '%%EndComments',
    'gsave',
    '0 92 translate 1 -1 scale',
    // Text glyphs (directly in viewBox coordinates)
    `newpath\n${svgPathToPS(gGlyph)}`,
    `${hexToPS(textFill)} setrgbcolor fill`,
    `newpath\n${svgPathToPS(iGlyph)}`,
    `${hexToPS(textFill)} setrgbcolor fill`,
    `newpath\n${svgPathToPS(tGlyph)}`,
    `${hexToPS(textFill)} setrgbcolor fill`,
    // Icon with transform
    'gsave',
    '1.179487 1.179487 scale 10 10 translate',
    '29 29 translate -45 rotate -29 -29 translate',
    `newpath\n${svgPathToPS(iconGlyph)}`,
    `${hexToPS(iconFill)} setrgbcolor fill`,
    'grestore',
    'grestore',
    '%%EOF\n',
  ].join('\n');
  saveFile(`Git-Logo-${variant}.eps`, await buildEPS(ps, svg, { mode: 'height', value: 92 }));
}

// =========================== Variant definitions ===========================

const orange = '#f03c2e';
const brown  = '#362701';
const black  = '#100f0d';
const white  = '#fff';

const iconVariants = {
  '1788C': { icon: orange },
  'Black': { icon: black },
  'White': { icon: white },
};

const logoVariants = {
  '1788C':  { icon: orange, text: orange },
  '2Color': { icon: orange, text: brown },
  'Black':  { icon: black,  text: black },
  'White':  { icon: white,  text: white },
}


// ================================ Generate =================================

async function main() {
  for (const [variant, fill] of Object.entries(iconVariants)) {
    await generateIcon(variant, fill.icon);
  }

  for (const [variant, fill ] of Object.entries(logoVariants)) {
    await generateLogo(variant, fill.icon, fill.text);
  }
}

main();
