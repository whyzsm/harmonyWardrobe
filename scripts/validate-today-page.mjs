import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/pages/TodayPage.ets', 'utf8');

for (const needle of [
  'WearLogRepository',
  'OutfitRepository',
  'WearLog',
  'OutfitTemplate',
  '首页',
  '推荐',
  '从最近套装里挑一套',
  '最近穿过',
  '记录一次今日搭配',
  'todayIsoDate',
  'todaysWearLog',
  'recentOutfits',
  'recentWearLogs',
  'recordToday',
  'ForEach'
]) {
  if (!text.includes(needle)) {
    throw new Error(`TodayPage missing ${needle}`);
  }
}

console.log('PASS');
