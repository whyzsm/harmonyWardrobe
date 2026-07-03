import fs from 'node:fs';

const index = fs.readFileSync('entry/src/main/ets/pages/Index.ets', 'utf8');

for (const forbidden of [
  'HomeRecommendation',
  'showRecommendationDetail',
  '点赞',
  '收藏',
  '评论',
  '关注',
  'TodayPage({'
]) {
  if (index.includes(forbidden)) {
    throw new Error(`Index must not expose old home feed concept ${forbidden}`);
  }
}

console.log('PASS');
