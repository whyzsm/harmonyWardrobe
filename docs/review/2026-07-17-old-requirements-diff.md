# 2026-07-17 旧需求差异说明

本文记录当前工作区相对 2026-07-16 和 2026-07-15 提交口径的变化，用来避免继续按旧需求验收。

## 对比基线

- 2026-07-16：`0043d2d feat: 视觉系统升级 — 令牌扩展、组件对齐与 QuickCaptureSheet 重设计`
- 2026-07-15：`3055d88 feat: consolidate runtime navigation and wishlist flow`
- 2026-07-15：`b3093f6 docs: rewrite project readme`
- 2026-07-15：`73e49e3 fix: 级联删除照片清理与搜索索引自增 ID，新增模拟机调试脚本`
- 2026-07-15：`207312d`、`b9dd02b`、`32c5653` 三个 ArkTS / 搜索索引修复提交

历史 `docs/plans` 和旧评审报告保留为归档资料，不再自动代表当前验收口径。当前产品口径以 `docs/background/yibuque-design.md`、`README.md`、本文件和 `scripts/*.mjs` 验证脚本为准。

## 已废弃的旧口径

| 旧口径 | 当前口径 | 影响文件 / 验收 |
| --- | --- | --- |
| `WardrobePage` 内部维护 `衣橱 / 美搭 / 日历` 一级 tab | 衣柜页只保留衣物浏览、搜索、分类和双列瀑布流 | `WardrobePage.ets` 删除 `selectedWardrobeTab`、`WardrobePrimaryTabs`、`visibleOutfits`、`OutfitResultCard` |
| 从搜索 WearLog 跳到衣柜页 `日历` tab | 从搜索 WearLog 跳到底部 `套装` 页，并打开 `WearLogEditPage` | `Index.ets` 使用 `params.wearLogId` + `AppMainTab.Outfit`，`AppRoute.ets` 删除 `wardrobeTab` |
| `CalendarPage` 删除后，日历 UI 内嵌在 `WardrobePage` | 所有日历 UI 都移除，不再维护内嵌月历 | `CalendarPage.ets` 和 `MonthCalendar.ets` 均应不存在 |
| `WearLogRepository` 保留日历专用按日/月查询 | 保留穿着记录 CRUD 和全量搜索索引数据，移除日历 marker 查询 | 删除 `listWearLogsByDate`、`listWearLogDatesForMonth` 和 `SELECT DISTINCT worn_date` |
| 交互脚本验收日历切月、月份 marker | 交互脚本只验收日期选择器、页面转场、卡片 pressed feedback，并反向禁止日历 UI 回流 | `validate-interaction-polish.mjs` 不再读取 `MonthCalendar.ets` |
| README / architecture 把日历回顾列为核心能力 | 当前能力描述为衣物、套装/美搭、穿着记录、逛店、心愿和搜索 | `README.md`、`docs/architecture.md` 已更新 |

## 保留但迁移的能力

- 穿着记录没有删除。`WearLogRepository` 仍负责创建、更新、删除、按 ID 读取、全量读取和搜索索引维护。
- `WearLogEditPage` 仍保留，用于套装页中记录或编辑一次穿着。
- 统一搜索仍支持 WearLog 结果，但入口不再是日历，而是 `OutfitsPage`。
- 底部导航仍是 `衣柜 / 逛店 / 相机 / 套装 / 我的`，中间相机仍打开 `衣柜 / 逛店 / 穿搭` 快捷录入。

## 当前仍禁止的旧方向

- 不恢复底部 `首页`、`日历`、`逛街`、`心愿单` 主入口。
- 不恢复小红书式推荐流、点赞、收藏、评论、关注等社交能力。
- 不恢复旧 Rose VI 粉色背景、粉色主按钮、粉色阴影或粉色边框。
- 不展示远程同步、联网备份、虚构预算统计、虚构商场记录或不存在的用户记录。
- 不把 `build-profile.json5` 中的本机签名配置提交到仓库。

## 提交前检查重点

提交前至少确认：

```bash
rg -n "MonthCalendar|CalendarPage|wardrobeTab|selectedWardrobeTab|initialWardrobeTab|WardrobePrimaryTabs|CalendarTab|visibleOutfits|OutfitResultCard|listWearLogsByDate|listWearLogDatesForMonth|params\\.wardrobeTab" entry/src/main/ets
git diff --check
```

全量脚本验证时，`validate-project-structure.mjs` 可能因为本机 `build-profile.json5` 签名配置失败；该签名差异应继续排除在提交外。
