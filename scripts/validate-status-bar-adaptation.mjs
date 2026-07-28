import fs from 'node:fs';

const path = 'entry/src/main/ets/entryability/EntryAbility.ets';
const source = fs.readFileSync(path, 'utf8');
const indexPath = 'entry/src/main/ets/pages/Index.ets';
const index = fs.readFileSync(indexPath, 'utf8');

for (const needle of [
  'getMainWindowSync',
  'setWindowLayoutFullScreen(true)',
  'setWindowSystemBarProperties',
  'statusBarColor: YibuqueColor.bgDefault',
  'isStatusBarLightIcon: false',
  'navigationBarColor: YibuqueColor.bgDefault',
  'isNavigationBarLightIcon: false'
]) {
  if (!source.includes(needle)) {
    throw new Error(`${path} missing required status-bar adaptation: ${needle}`);
  }
}

for (const needle of [
  "getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)",
  'window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR',
  'YibuqueSpacing.bottomSafe',
  "AppStorage.setOrCreate('windowTopInsetVp'",
  "AppStorage.setOrCreate('windowBottomInsetVp'"
]) {
  if (!source.includes(needle)) {
    throw new Error(`${path} missing dynamic system inset handling: ${needle}`);
  }
}

for (const needle of [
  "@StorageProp('windowTopInsetVp')",
  "@StorageProp('windowBottomInsetVp')",
  '.padding({ top: this.windowTopInsetVp })',
  'bottomInsetVp: this.windowBottomInsetVp'
]) {
  if (!index.includes(needle)) {
    throw new Error(`${indexPath} missing safe-area padding: ${needle}`);
  }
}

if (!/private async configureWindowStage\(windowStage: window\.WindowStage\)[\s\S]*?windowStage\.loadContent\('pages\/Index'/.test(source)) {
  throw new Error(`${path} must configure the main window before loading the root page`);
}

console.log('PASS');
