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

中文：运行 HarmonyOS 构建时，使用本机 DevEco command-line-tools 的 `hvigorw`。完整 App 构建命令：

English: To run the HarmonyOS build, use `hvigorw` from the local DevEco command-line-tools installation. Full App build command:

```bash
<command-line-tools>/bin/hvigorw assembleApp --no-daemon --no-incremental --no-parallel --stacktrace
```

中文：只构建 entry 模块 HAP 时，使用 module 模式并指定 product、module 和 target：

English: To build only the entry module HAP, use module mode and specify product, module, and target:

```bash
<command-line-tools>/bin/hvigorw --mode module -p product=default -p module=entry@default assembleHap --no-daemon --no-incremental --no-parallel --stacktrace
```

中文：当前调试默认走模拟机调试环境。先在 DevEco Studio 启动 HarmonyOS 模拟器，然后运行：

English: Debugging now defaults to the emulator debug environment. Start the HarmonyOS emulator in DevEco Studio, then run:

```bash
scripts/emulator-debug.sh
```

中文：脚本会构建 `default` debug HAP、通过 `hdc` 安装到当前模拟器、启动 `EntryAbility`，并保存一张模拟器截图。多设备时使用 `HDC_TARGET=<target>` 指定目标；工具路径可通过 `HVIGORW`、`HDC` 或 `DEVECO_COMMAND_LINE_TOOLS` 覆盖。若本机已经有可用 HAP、只想复用现有包安装启动，可运行 `SKIP_BUILD=1 scripts/emulator-debug.sh`。如果模拟器里已有不同签名的同包名应用，脚本会停止并提示；确认可以卸载旧包并保留数据后，再运行 `RESET_APP_ON_SIGN_MISMATCH=1 scripts/emulator-debug.sh`。

English: The script builds the `default` debug HAP, installs it on the current emulator through `hdc`, starts `EntryAbility`, and saves an emulator screenshot. Use `HDC_TARGET=<target>` when multiple devices are connected; override tool paths with `HVIGORW`, `HDC`, or `DEVECO_COMMAND_LINE_TOOLS`. If a usable HAP already exists and you only need to install and launch it, run `SKIP_BUILD=1 scripts/emulator-debug.sh`. If the emulator already has the same bundle name installed with different signing info, the script stops and prompts; when uninstalling the old package while keeping data is acceptable, run `RESET_APP_ON_SIGN_MISMATCH=1 scripts/emulator-debug.sh`.

中文：本仓库提交了 Hvigor 项目配置，但不提交 `.hvigor/`、`build/` 或 `entry/build/` 生成物。

English: This repository commits the Hvigor project configuration, but does not commit generated `.hvigor/`, `build/`, or `entry/build/` outputs.

## 手工 QA / Manual QA

中文：离线手工 QA 脚本位于 `docs/qa/manual-test-script.md`，覆盖 Today、Wardrobe、Outfits、Calendar、Shopping、photo、search 和 offline persistence。

English: The offline manual QA script is in `docs/qa/manual-test-script.md`, covering Today, Wardrobe, Outfits, Calendar, Shopping, photo, search, and offline persistence.

中文：首版交付验证记录位于 `docs/delivery/first-release-verification.md`，其中区分已执行验证、构建结果、未执行真机 QA 的原因，以及替代验证证据。

English: First-release verification notes are in `docs/delivery/first-release-verification.md`, separating executed validations, build result, reasons for skipped device QA, and substitute evidence.

## 约束 / Constraints

中文：不要添加网络权限，不要把照片二进制写入 SQLite，不要提交 `.hvigor/`、`build/` 或 `entry/build/` 生成输出。

English: Do not add network permission, do not store photo binaries in SQLite, and do not commit generated `.hvigor/`, `build/`, or `entry/build/` outputs.
