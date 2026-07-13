import fs from 'node:fs';

function read(file) {
  if (!fs.existsSync(file)) {
    throw new Error(`${file} does not exist`);
  }
  return fs.readFileSync(file, 'utf8');
}

for (const asset of ['default_fashion_cover.jpg', 'default_store_cover.jpg']) {
  const path = `entry/src/main/resources/base/media/${asset}`;
  if (!fs.existsSync(path)) {
    throw new Error(`Missing default photo asset ${path}`);
  }
}

const expectations = [
  ['entry/src/main/ets/pages/ClothingEditPage.ets', 'app.media.default_fashion_cover'],
  ['entry/src/main/ets/pages/OutfitEditPage.ets', 'app.media.default_fashion_cover'],
  ['entry/src/main/ets/pages/StoreVisitEditPage.ets', 'app.media.default_store_cover'],
  ['entry/src/main/ets/pages/CaptureEditPage.ets', 'app.media.default_fashion_cover'],
  ['entry/src/main/ets/components/PhotoGrid.ets', 'app.media.default_fashion_cover']
];

for (const [file, resource] of expectations) {
  const source = read(file);
  if (!source.includes(resource)) {
    throw new Error(`${file} missing default photo resource ${resource}`);
  }
}

const photoGrid = read('entry/src/main/ets/components/PhotoGrid.ets');
if (!/photoUris\.length === 0[\s\S]*?default_fashion_cover/.test(photoGrid)) {
  throw new Error('PhotoGrid must render a default cover only when no user photo is selected');
}

console.log('PASS');
