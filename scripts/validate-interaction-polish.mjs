import fs from 'node:fs';

function read(file) {
  return fs.readFileSync(file, 'utf8');
}

function mustInclude(source, file, needle) {
  if (!source.includes(needle)) {
    throw new Error(`${file} missing ${needle}`);
  }
}

function mustMatch(source, file, pattern, message) {
  if (!pattern.test(source)) {
    throw new Error(`${file} ${message}`);
  }
}

const capture = read('entry/src/main/ets/pages/CaptureEditPage.ets');
const clothingEdit = read('entry/src/main/ets/pages/ClothingEditPage.ets');
const wearLog = read('entry/src/main/ets/pages/WearLogEditPage.ets');
const index = read('entry/src/main/ets/pages/Index.ets');
const monthCalendar = read('entry/src/main/ets/components/MonthCalendar.ets');
const wardrobe = read('entry/src/main/ets/pages/WardrobePage.ets');
const outfits = read('entry/src/main/ets/pages/OutfitsPage.ets');
const storeVisit = read('entry/src/main/ets/pages/StoreVisitPage.ets');

for (const [file, source, method] of [
  ['CaptureEditPage.ets', capture, 'openPurchaseDatePicker'],
  ['CaptureEditPage.ets', capture, 'openVisitDatePicker'],
  ['ClothingEditPage.ets', clothingEdit, 'openPurchaseDatePicker'],
  ['WearLogEditPage.ets', wearLog, 'openWornDatePicker']
]) {
  mustMatch(source, file, new RegExp(`private ${method}\\(\\): void[\\s\\S]*?showDatePickerDialog`), `${method} must use showDatePickerDialog`);
  mustMatch(source, file, new RegExp(`private ${method}\\(\\): void[\\s\\S]*?end: new Date\\(\\)`), `${method} must reject future dates`);
  mustMatch(source, file, new RegExp(`${method}\\(\\);`), `${method} must be invoked from the date field`);
}

const routeTransitionCount = (index.match(/\.transition\(TransitionEffect\.OPACITY\.animation\(\{ duration: 180, curve: Curve\.EaseOut \}\)\)/g) ?? []).length;
if (routeTransitionCount < 9) {
  throw new Error(`Index.ets must apply route/page transitions to every top-level page branch, found ${routeTransitionCount}`);
}

for (const forbidden of [
  "TextInput({ text: this.purchaseDate",
  "TextInput({ text: this.visitDate"
]) {
  if (capture.includes(forbidden)) {
    throw new Error(`CaptureEditPage.ets must not keep editable date TextInput ${forbidden}`);
  }
}

if (wearLog.includes("TextInput({ text: this.wornDate")) {
  throw new Error('WearLogEditPage.ets must not keep editable wornDate TextInput');
}

for (const needle of [
  'onChangeMonth: (month: string) => void',
  'adjacentMonth(offset: number)',
  "SymbolGlyph($r('sys.symbol.chevron_left'))",
  "SymbolGlyph($r('sys.symbol.chevron_right'))"
]) {
  mustInclude(monthCalendar, 'MonthCalendar.ets', needle);
}

mustMatch(wardrobe, 'WardrobePage.ets', /changeCalendarMonth\(month: string\)[\s\S]*?daysInTargetMonth[\s\S]*?Math\.min\(safeDay, daysInTargetMonth\)[\s\S]*?this\.currentMonth = month[\s\S]*?this\.selectedDate = `\$\{month\}-\$\{`\$\{day\}`\.padStart\(2, '0'\)\}`[\s\S]*?this\.loadCalendar\(\)/, 'must reload calendar when changing month while preserving the selected day');
mustMatch(wardrobe, 'WardrobePage.ets', /MonthCalendar\(\{[\s\S]*?onChangeMonth: \(month: string\) => \{[\s\S]*?this\.changeCalendarMonth\(month\)/, 'must connect MonthCalendar onChangeMonth');

for (const [file, source, stateName] of [
  ['WardrobePage.ets', wardrobe, 'pressedWardrobeItemId'],
  ['OutfitsPage.ets', outfits, 'pressedOutfitCardId'],
  ['StoreVisitPage.ets', storeVisit, 'pressedVisitCardId']
]) {
  mustInclude(source, file, `@State private ${stateName}: string = '';`);
  mustMatch(source, file, new RegExp(`\\.scale\\(\\{ x: this\\.${stateName} === [\\s\\S]*?0\\.98`), 'must scale pressed cards');
  mustMatch(source, file, new RegExp(`\\.onTouch\\(\\(event: TouchEvent\\) => \\{[\\s\\S]*?TouchType\\.Down[\\s\\S]*?${stateName}[\\s\\S]*?TouchType\\.Up[\\s\\S]*?TouchType\\.Cancel`), 'must keep pressed state until touch up or cancel');
}

console.log('PASS');
