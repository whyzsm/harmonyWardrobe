# 2026-07-17 旧需求差异说明

本文记录当前工作区相对 2026-07-16 和 2026-07-15 提交口径的变化，用来避免继续按旧需求验收。

## 对比基线

- 2026-07-16：`0043d2d feat: 视觉系统升级 — 令牌扩展、组件对齐与 QuickCaptureSheet 重设计`
- 2026-07-15：`3055d88 feat: consolidate runtime navigation and wishlist flow`
- 2026-07-15：`b3093f6 docs: rewrite project readme`
- 2026-07-15：`73e49e3 fix: 级联删除照片清理与搜索索引自增 ID，新增模拟机调试脚本`
- 2026-07-15：`207312d`、`b9dd02b`、`32c5653` 三个 ArkTS / 搜索索引修复提交

历史 `docs/plans` 和旧评审报告保留为归档资料，不再自动代表当前验收口径。当前产品口径以 `docs/background/yibuque-design.md`、`README.md`、本文件和 `scripts/*.mjs` 验证脚本为准。

## 本轮审查范围与修改清单

以下清单记录本轮“移除旧日期聚合功能”审查实际查看的文件，以及是否发生修改。

### 运行代码

| 文件 | 审查内容 | 结果 | 本轮修改 |
| --- | --- | --- | --- |
| `entry/src/main/ets/pages/WardrobePage.ets` | 衣柜页面、旧复合子页状态和入口 | 已无旧复合子页结构 | 否 |
| `entry/src/main/ets/pages/Index.ets` | WearLog 搜索结果路由 | 进入 `OutfitsPage` 和 `WearLogEditPage` | 否 |
| `entry/src/main/ets/app/AppRoute.ets` | 路由参数和页面类型 | 无旧衣柜子页参数 | 否 |
| `entry/src/main/ets/pages/OutfitsPage.ets` | 穿着记录编辑入口 | 保留穿着记录编辑流程 | 否 |
| `entry/src/main/ets/pages/WearLogEditPage.ets` | 穿着日期字段和编辑能力 | 保留记录日期，不提供日期聚合页面 | 否 |
| `entry/src/main/ets/data/repositories/WearLogRepository.ets` | CRUD、全量读取、搜索索引和旧日期查询 | 仅保留记录数据能力，旧日期聚合查询已移除 | 否 |

### 当前产品文档

| 文件 | 审查内容 | 结果 | 本轮修改 |
| --- | --- | --- | --- |
| `README.md` | 核心能力和产品边界 | 已是衣物、穿搭/美搭、穿着记录、逛店、心愿和搜索 | 否 |
| `docs/architecture.md` | 架构总览和领域/数据层描述 | 已无旧日期回顾能力描述 | 否 |
| `AGENTS.md` | 项目上下文 | 改为 wear logs、store visits 等当前能力 | 是 |
| `docs/qa/manual-test-script.md` | 当前手工验收口径 | 删除旧入口和旧复合 tab 描述 | 是 |
| `docs/qa/walkthrough-report-2026-07-14.md` | 走查结果和失败项 | 改为当前 WearLog 独立编辑流程 | 是 |

### Review 文档

| 文件 | 本轮处理 |
| --- | --- |
| `docs/review/2026-07-15-fix-checklist.md` | 将旧复合子页任务标记为废弃，更新穿着记录验收 |
| `docs/review/2026-07-15-three-line-review.md` | 删除旧页面、旧子页和旧月份聚合问题，保留有效评审项 |
| `docs/review/2026-07-17-old-requirements-diff.md` | 删除旧日期聚合差异行，并维护本审查清单 |
| `docs/review/2026-07-17-unchanged-items.md` | 更新已删除死代码和当前验收说明 |
| `docs/review/expert-review-2026-07-14-expert.md` | 从死代码清单移除已删除旧页面 |
| `docs/review/expert-review-2026-07-14.md` | 已查看，无需修改 |

### 验证范围

- 执行全部 `scripts/*.mjs`，确认旧页面、旧路由、旧查询均未回流。
- 执行 `openspec validate --all --json`。
- 执行 `git diff --check`。
- 当前产品文档、QA 文档和 Review 文档中不再出现旧日期聚合功能的用户口径。

## 已废弃的旧口径

| 旧口径 | 当前口径 | 影响文件 / 验收 |
| --- | --- | --- |
| `WardrobePage` 内部维护衣橱复合子页 | 衣柜页只保留衣物浏览、搜索、分类和双列瀑布流 | `WardrobePage.ets` 删除旧子页状态和复合 tab 组件 |
| 从搜索 WearLog 进入衣柜复合子页 | 从搜索 WearLog 跳到底部 `穿搭` 页，并打开 `WearLogEditPage` | `Index.ets` 使用 `params.wearLogId` + `AppMainTab.Outfit` |
| 旧交互脚本维护月份标记和专用页面 | 交互脚本只验收日期选择器、页面转场和卡片 pressed feedback | 当前脚本禁止已移除的旧页面与旧导航概念回归 |
| README / architecture 混合旧能力描述 | 当前能力描述为衣物、穿搭/美搭、穿着记录、逛店、心愿和搜索 | `README.md`、`docs/architecture.md` 已同步 |

## 保留但迁移的能力

- 穿着记录没有删除。`WearLogRepository` 仍负责创建、更新、删除、按 ID 读取、全量读取和搜索索引维护。
- `WearLogEditPage` 仍保留，用于穿搭页中记录或编辑一次穿着。
- 统一搜索仍支持 WearLog 结果，入口是 `OutfitsPage`。
- 底部导航仍是 `衣柜 / 逛店 / 相机 / 穿搭 / 我的`，中间相机仍打开 `衣柜 / 逛店 / 穿搭` 快捷录入。

## 当前仍禁止的旧方向

- 不恢复底部 `首页`、`逛街`、`心愿单` 主入口。
- 不恢复小红书式推荐流、点赞、收藏、评论、关注等社交能力。
- 不恢复旧 Rose VI 粉色背景、粉色主按钮、粉色阴影或粉色边框。
- 不展示远程同步、联网备份、虚构预算统计、虚构商场记录或不存在的用户记录。
- 不把 `build-profile.json5` 中的本机签名配置提交到仓库。

## 提交前检查重点

提交前至少确认：

```bash
rg -n "wardrobeTab|selectedWardrobeTab|initialWardrobeTab|WardrobePrimaryTabs|visibleOutfits|OutfitResultCard|params\\.wardrobeTab" entry/src/main/ets
git diff --check
```

全量脚本验证时，`validate-project-structure.mjs` 可能因为本机 `build-profile.json5` 签名配置失败；该签名差异应继续排除在提交外。
