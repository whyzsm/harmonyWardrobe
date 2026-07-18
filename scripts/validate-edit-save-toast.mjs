import fs from 'node:fs';

const pages = [
  ['entry/src/main/ets/pages/ClothingEditPage.ets', 'saveClothing', '衣物已保存'],
  ['entry/src/main/ets/pages/OutfitEditPage.ets', 'saveOutfit', '穿搭已保存'],
  ['entry/src/main/ets/pages/StoreVisitEditPage.ets', 'saveStoreVisit', '逛店记录已保存'],
  ['entry/src/main/ets/pages/WearLogEditPage.ets', 'saveWearLog', '穿着记录已保存'],
  ['entry/src/main/ets/pages/WishlistEditPage.ets', 'saveWishlistItem', '心愿已保存']
];

for (const [file, methodName, message] of pages) {
  const text = fs.readFileSync(file, 'utf8');
  if (!/private showSaveToast\(message: string\): void[\s\S]*?getUIContext\(\)\.getPromptAction\(\)\.showToast\(\{ message \}\)/.test(text)) {
    throw new Error(`${file} must use UIContext prompt action for save toast`);
  }

  const methodStart = text.indexOf(`private async ${methodName}(): Promise<void> {`);
  if (methodStart < 0) {
    throw new Error(`${file} missing ${methodName}`);
  }
  const nextMethodStart = text.indexOf('\n  private ', methodStart + 1);
  const methodBody = text.slice(methodStart, nextMethodStart < 0 ? text.length : nextMethodStart);
  if (!methodBody.includes(`this.showSaveToast('${message}');`) || !methodBody.includes('this.onSave(')) {
    throw new Error(`${file} must show save toast before invoking onSave`);
  }
}

console.log('PASS');
