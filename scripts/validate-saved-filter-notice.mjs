import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

const componentPath = 'entry/src/main/ets/components/SavedFilterNotice.ets';
const component = read(componentPath);

for (const needle of [
  'export struct SavedFilterNotice',
  '@Prop visible: boolean = false',
  "Text('已保存，当前筛选未显示')",
  "Button('查看全部')",
  'YibuqueColor.selectionAccent',
  'this.onViewAll()'
]) {
  if (!component.includes(needle)) {
    throw new Error(`${componentPath} missing ${needle}`);
  }
}

const pages = [
  {
    path: 'entry/src/main/ets/pages/WardrobePage.ets',
    type: 'ClothingItem',
    savedId: 'savedClothingOutsideCurrentFilterId',
    savedItem: 'savedItem',
    filter: 'filterClothingItems',
    isOutside: 'savedClothingIsOutsideCurrentFilter',
    showAll: 'showAllClothingFromSaveNotice',
    allSelection: "this.selectedCategoryLabel = '全部'"
  },
  {
    path: 'entry/src/main/ets/pages/OutfitsPage.ets',
    type: 'OutfitTemplate',
    savedId: 'savedOutfitOutsideCurrentFilterId',
    savedItem: 'savedOutfit',
    filter: 'filterOutfits',
    isOutside: 'savedOutfitIsOutsideCurrentFilter',
    showAll: 'showAllOutfitsFromSaveNotice',
    allSelection: "this.selectedCategoryId = ''"
  },
  {
    path: 'entry/src/main/ets/pages/StoreVisitPage.ets',
    type: 'StoreVisit',
    savedId: 'savedVisitOutsideCurrentFilterId',
    savedItem: 'savedVisit',
    filter: 'filterStoreVisits',
    isOutside: 'savedVisitIsOutsideCurrentFilter',
    showAll: 'showAllVisitsFromSaveNotice',
    allSelection: "this.selectedStatus = 'all'"
  }
];

for (const pageCheck of pages) {
  const page = read(pageCheck.path);
  for (const needle of [
    "import { SavedFilterNotice } from '../components/SavedFilterNotice'",
    pageCheck.savedId,
    pageCheck.isOutside,
    pageCheck.showAll,
    pageCheck.allSelection,
    "this.searchQuery = ''"
  ]) {
    if (!page.includes(needle)) {
      throw new Error(`${pageCheck.path} missing ${needle}`);
    }
  }

  const savedStatePattern = new RegExp(
    `${pageCheck.savedId} = this\\.${pageCheck.filter}\\(\\)\\.some\\(\\(${pageCheck.type === 'StoreVisit' ? 'visit' : pageCheck.type === 'OutfitTemplate' ? 'outfit' : 'item'}: ${pageCheck.type}\\) => ${pageCheck.type === 'StoreVisit' ? 'visit' : pageCheck.type === 'OutfitTemplate' ? 'outfit' : 'item'}\\.id === ${pageCheck.savedItem}\\.id\\)`
  );
  if (!savedStatePattern.test(page)) {
    throw new Error(`${pageCheck.path} must show the notice only when the saved record is outside the active filter`);
  }

  const noticePattern = new RegExp(
    `SavedFilterNotice\\(\\{[\\s\\S]*?visible: this\\.${pageCheck.isOutside}\\(\\)[\\s\\S]*?this\\.${pageCheck.showAll}\\(\\)`
  );
  if (!noticePattern.test(page)) {
    throw new Error(`${pageCheck.path} must provide a view-all action for saved records outside the active filter`);
  }
}

console.log('PASS');
