import fs from 'node:fs';
import zlib from 'node:zlib';

const PNG_SIGNATURE = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
const EXPECTED_LAYER = {
  background: '$media:app_icon_background',
  foreground: '$media:app_icon_foreground'
};

const appConfigPath = 'AppScope/app.json5';
const moduleConfigPath = 'entry/src/main/module.json5';
const appMediaPath = 'AppScope/resources/base/media';
const entryMediaPath = 'entry/src/main/resources/base/media';

function read(file) {
  if (!fs.existsSync(file)) {
    throw new Error(`${file} does not exist`);
  }
  return fs.readFileSync(file);
}

function readJson(file) {
  return JSON.parse(read(file).toString('utf8'));
}

function readPng(file) {
  const data = read(file);
  if (!data.subarray(0, PNG_SIGNATURE.length).equals(PNG_SIGNATURE)) {
    throw new Error(`${file} is not a PNG file`);
  }

  let offset = PNG_SIGNATURE.length;
  let width = 0;
  let height = 0;
  let bitDepth = 0;
  let colorType = 0;
  let interlace = 0;
  const idat = [];

  while (offset < data.length) {
    const length = data.readUInt32BE(offset);
    const type = data.toString('ascii', offset + 4, offset + 8);
    const chunk = data.subarray(offset + 8, offset + 8 + length);
    offset += length + 12;

    if (type === 'IHDR') {
      width = chunk.readUInt32BE(0);
      height = chunk.readUInt32BE(4);
      bitDepth = chunk[8];
      colorType = chunk[9];
      interlace = chunk[12];
    } else if (type === 'IDAT') {
      idat.push(chunk);
    } else if (type === 'IEND') {
      break;
    }
  }

  if (bitDepth !== 8 || interlace !== 0 || ![2, 6].includes(colorType)) {
    throw new Error(`${file} must be a non-interlaced 8-bit RGB or RGBA PNG`);
  }

  const channels = colorType === 6 ? 4 : 3;
  const stride = width * channels;
  const inflated = zlib.inflateSync(Buffer.concat(idat));
  const pixels = Buffer.alloc(stride * height);
  let sourceOffset = 0;

  for (let y = 0; y < height; y += 1) {
    const filter = inflated[sourceOffset];
    sourceOffset += 1;
    const rowOffset = y * stride;

    for (let x = 0; x < stride; x += 1) {
      const raw = inflated[sourceOffset + x];
      const left = x >= channels ? pixels[rowOffset + x - channels] : 0;
      const up = y > 0 ? pixels[rowOffset - stride + x] : 0;
      const upLeft = y > 0 && x >= channels ? pixels[rowOffset - stride + x - channels] : 0;
      let value = raw;

      if (filter === 1) {
        value += left;
      } else if (filter === 2) {
        value += up;
      } else if (filter === 3) {
        value += Math.floor((left + up) / 2);
      } else if (filter === 4) {
        value += paeth(left, up, upLeft);
      } else if (filter !== 0) {
        throw new Error(`${file} uses unsupported PNG filter ${filter}`);
      }

      pixels[rowOffset + x] = value & 0xff;
    }

    sourceOffset += stride;
  }

  return { file, width, height, colorType, channels, pixels };
}

function paeth(left, up, upLeft) {
  const prediction = left + up - upLeft;
  const leftDistance = Math.abs(prediction - left);
  const upDistance = Math.abs(prediction - up);
  const upLeftDistance = Math.abs(prediction - upLeft);
  if (leftDistance <= upDistance && leftDistance <= upLeftDistance) {
    return left;
  }
  return upDistance <= upLeftDistance ? up : upLeft;
}

function pixelAt(image, x, y) {
  const offset = (y * image.width + x) * image.channels;
  return {
    red: image.pixels[offset],
    green: image.pixels[offset + 1],
    blue: image.pixels[offset + 2],
    alpha: image.colorType === 6 ? image.pixels[offset + 3] : 255
  };
}

function assertDimensions(image, width, height) {
  if (image.width !== width || image.height !== height) {
    throw new Error(`${image.file} must be ${width}x${height}, got ${image.width}x${image.height}`);
  }
}

function assertOpaqueFullBleedBackground(image) {
  for (let y = 0; y < image.height; y += 1) {
    for (let x = 0; x < image.width; x += 1) {
      if (pixelAt(image, x, y).alpha !== 255) {
        throw new Error(`${image.file} must be opaque and full-bleed; transparent pixel at ${x},${y}`);
      }
    }
  }
}

function alphaBounds(image) {
  let minX = image.width;
  let minY = image.height;
  let maxX = -1;
  let maxY = -1;

  for (let y = 0; y < image.height; y += 1) {
    for (let x = 0; x < image.width; x += 1) {
      if (pixelAt(image, x, y).alpha === 0) {
        continue;
      }
      minX = Math.min(minX, x);
      minY = Math.min(minY, y);
      maxX = Math.max(maxX, x);
      maxY = Math.max(maxY, y);
    }
  }

  if (maxX < 0) {
    throw new Error(`${image.file} has no visible foreground pixels`);
  }
  return { minX, minY, maxX, maxY };
}

function assertForeground(image) {
  if (image.colorType !== 6) {
    throw new Error(`${image.file} must preserve an alpha channel`);
  }

  for (const [x, y] of [[0, 0], [image.width - 1, 0], [0, image.height - 1], [image.width - 1, image.height - 1]]) {
    if (pixelAt(image, x, y).alpha !== 0) {
      throw new Error(`${image.file} must not bake a rounded app-icon background into the foreground`);
    }
  }

  const bounds = alphaBounds(image);
  if (bounds.maxX - bounds.minX < image.width * 0.625 ||
    bounds.maxY - bounds.minY < image.height * 0.7) {
    throw new Error(`${image.file} foreground artwork is too small or padded: ${JSON.stringify(bounds)}`);
  }

  const requiredColors = [
    { red: 0, green: 113, blue: 227, found: false },
    { red: 29, green: 29, blue: 31, found: false },
    { red: 147, green: 197, blue: 253, found: false }
  ];
  for (let y = 0; y < image.height && requiredColors.some((color) => !color.found); y += 1) {
    for (let x = 0; x < image.width && requiredColors.some((color) => !color.found); x += 1) {
      const pixel = pixelAt(image, x, y);
      if (pixel.alpha < 250) {
        continue;
      }
      for (const color of requiredColors) {
        if (Math.abs(pixel.red - color.red) <= 2 &&
          Math.abs(pixel.green - color.green) <= 2 &&
          Math.abs(pixel.blue - color.blue) <= 2) {
          color.found = true;
        }
      }
    }
  }
  const missingColors = requiredColors.filter((color) => !color.found);
  if (missingColors.length > 0) {
    throw new Error(`${image.file} is missing brand colors: ${missingColors
      .map((color) => `${color.red},${color.green},${color.blue}`).join('; ')}`);
  }
}

function assertLayeredResource(mediaPath) {
  const file = `${mediaPath}/app_icon.json`;
  const layeredImage = readJson(file)['layered-image'];
  if (!layeredImage || layeredImage.background !== EXPECTED_LAYER.background ||
    layeredImage.foreground !== EXPECTED_LAYER.foreground) {
    throw new Error(`${file} must reference the app icon foreground and background layers`);
  }

  const background = readPng(`${mediaPath}/app_icon_background.png`);
  const foreground = readPng(`${mediaPath}/app_icon_foreground.png`);
  assertDimensions(background, 1024, 1024);
  assertDimensions(foreground, 1024, 1024);
  assertOpaqueFullBleedBackground(background);
  assertForeground(foreground);
  return { background, foreground };
}

const appConfig = readJson(appConfigPath);
const moduleConfig = readJson(moduleConfigPath);
const mainAbility = moduleConfig.module.abilities.find((ability) => ability.name === moduleConfig.module.mainElement);

if (appConfig.app.icon !== '$media:app_icon') {
  throw new Error(`${appConfigPath} must reference $media:app_icon`);
}
if (!mainAbility || mainAbility.icon !== '$media:app_icon') {
  throw new Error(`${moduleConfigPath} main ability must reference $media:app_icon`);
}
if (mainAbility.startWindowIcon !== '$media:app_icon_start') {
  throw new Error(`${moduleConfigPath} must use the dedicated start-window icon`);
}

const appIcon = assertLayeredResource(appMediaPath);
const entryIcon = assertLayeredResource(entryMediaPath);
for (const layer of ['background', 'foreground']) {
  if (!read(appIcon[layer].file).equals(read(entryIcon[layer].file))) {
    throw new Error(`AppScope and Entry ${layer} layers must be identical`);
  }
}

const startIcon = readPng(`${entryMediaPath}/app_icon_start.png`);
assertDimensions(startIcon, 256, 256);
assertForeground(startIcon);

if (fs.existsSync(`${entryMediaPath}/app_icon.svg`)) {
  throw new Error('legacy single-layer app_icon.svg must be removed');
}

console.log('PASS');
