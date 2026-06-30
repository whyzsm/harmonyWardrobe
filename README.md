# Harmony Wardrobe / Harmony Wardrobe

## 项目简介 / Project Overview

中文：Harmony Wardrobe 是一个本地优先的 HarmonyOS Stage 衣橱管理应用，用于记录衣物、穿搭模板、每日穿着、日历回顾、购物心愿和统一搜索。

English: Harmony Wardrobe is a local-first HarmonyOS Stage wardrobe app for clothing records, outfit templates, daily wear logs, calendar recall, shopping wishlist items, and unified search.

中文：应用不依赖网络服务；业务数据保存在本地 SQLite 表中，照片由媒体层复制到应用本地存储后以 URI 引用。

English: The app does not depend on network services; business data is stored in local SQLite tables, and photos are copied by the media layer into app-local storage and referenced by URI.

## 功能范围 / Feature Scope

中文：首版包含 Today、Wardrobe、Outfits、Calendar 和 Shopping 五个主标签页，并支持衣物、穿搭、穿着日志、心愿单的新增、编辑、删除和空态、加载态、错误态展示。

English: The first release includes five main tabs: Today, Wardrobe, Outfits, Calendar, and Shopping, with create, edit, delete, empty, loading, and error states for clothing, outfits, wear logs, and wishlist items.

中文：搜索能力通过可重建的派生索引实现，优先使用 SQLite FTS5；当运行时不支持 FTS5 时，使用普通 n-gram fallback 表。

English: Search is implemented through a rebuildable derived index, preferring SQLite FTS5 and falling back to a normal n-gram table when the runtime does not support FTS5.

## 目录结构 / Directory Structure

中文：核心代码位于 `entry/src/main/ets`，按 `pages`、`components`、`domain`、`data`、`media` 和 `utils` 分层。

English: Core code lives under `entry/src/main/ets`, layered into `pages`, `components`, `domain`, `data`, `media`, and `utils`.

中文：验证脚本位于 `scripts/*.mjs`；架构、计划、QA 和交付说明位于 `docs/`。

English: Validation scripts live in `scripts/*.mjs`; architecture, plans, QA, and delivery notes live under `docs/`.

## 本地验证 / Local Verification

中文：运行全部静态和契约验证：

English: Run all static and contract validations:

```bash
for script in scripts/*.mjs; do node "$script"; done
git diff --check
```

中文：本仓库当前没有提交 `hvigorw` wrapper。执行 HarmonyOS 构建前，需要在本机安装并配置可用的 HarmonyOS/DevEco 构建工具，或补充项目认可的构建入口。

English: This repository currently does not commit an `hvigorw` wrapper. Before running a HarmonyOS build, install and configure the local HarmonyOS/DevEco build toolchain or add the project-approved build entry.

## 手工 QA / Manual QA

中文：离线手工 QA 脚本位于 `docs/qa/manual-test-script.md`，覆盖 Today、Wardrobe、Outfits、Calendar、Shopping、photo、search 和 offline persistence。

English: The offline manual QA script is in `docs/qa/manual-test-script.md`, covering Today, Wardrobe, Outfits, Calendar, Shopping, photo, search, and offline persistence.

中文：首版交付验证记录位于 `docs/delivery/first-release-verification.md`，其中区分已执行验证、未执行构建或真机 QA 的原因，以及替代验证证据。

English: First-release verification notes are in `docs/delivery/first-release-verification.md`, separating executed validations, reasons for skipped build or device QA, and substitute evidence.

## 约束 / Constraints

中文：不要添加网络权限，不要把照片二进制写入 SQLite，不要提交 `.hvigor/outputs/build-logs/build.log`。

English: Do not add network permission, do not store photo binaries in SQLite, and do not commit `.hvigor/outputs/build-logs/build.log`.
