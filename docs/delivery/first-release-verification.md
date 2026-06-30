# 首版交付验证 / First Release Verification

## 范围 / Scope

中文：本记录覆盖 Harmony Wardrobe 首版实现，从设计与计划提交到 Task 34 完成后的验证基线。

English: This record covers the Harmony Wardrobe first-release implementation, from the design and plan commits through the verification baseline after Task 34.

中文：验证基线 commit 为 `a071c39`（`docs: mark Harmony Wardrobe task 34 complete`）。Task 35 的 README 与交付说明更新会在该基线之后追加提交。

English: The verification baseline commit is `a071c39` (`docs: mark Harmony Wardrobe task 34 complete`). The Task 35 README and delivery-note updates are committed after that baseline.

## Commit 范围 / Commit Range

中文：首版实现范围从 `6e9abaf`（`docs: add Harmony Wardrobe app design`）开始，到 `a071c39`（Task 34 完成）结束。

English: The first-release implementation range starts at `6e9abaf` (`docs: add Harmony Wardrobe app design`) and ends at `a071c39` (Task 34 complete).

中文：主要功能提交包含 HarmonyOS Stage 项目骨架、领域模型、SQLite 迁移、搜索索引、照片存储与选择、仓储、五个主页面、编辑流、清理服务、UI 状态、主题 token 和离线 QA fixture。

English: Major feature commits include the HarmonyOS Stage project skeleton, domain models, SQLite migrations, search index, photo storage and picker, repositories, five main pages, edit flows, cleanup service, UI states, theme tokens, and offline QA fixture.

## 已执行验证 / Executed Verification

中文：已执行全部本地验证脚本：

English: All local validation scripts were executed:

```bash
for script in scripts/*.mjs; do node "$script"; done
```

中文：结果：通过。当前 `scripts/` 下 33 个 `.mjs` 验证脚本均输出 `PASS` 或以 0 退出。

English: Result: passed. All 33 `.mjs` validation scripts under `scripts/` printed `PASS` or exited with status 0.

中文：已执行空白和补丁格式检查：

English: Whitespace and patch-format validation was executed:

```bash
git diff --check
```

中文：结果：通过，没有尾随空白或补丁格式问题。

English: Result: passed, with no trailing whitespace or patch-format issues.

## 构建结果 / Build Result

中文：未执行 HarmonyOS HAP 构建。原因：仓库根目录没有 `hvigorw` wrapper，本机 `PATH` 中也没有可用的 `hvigor` 命令。

English: HarmonyOS HAP build was not executed. Reason: the repository root does not contain an `hvigorw` wrapper, and no usable `hvigor` command is available on the local `PATH`.

中文：替代验证：执行了全部 Node 静态/契约验证脚本，并确认项目结构、权限、数据层、媒体层、搜索索引和页面静态约束通过。

English: Substitute verification: all Node static and contract validation scripts were executed, covering project structure, permissions, data layer, media layer, search index, and page-level static constraints.

## 手工 QA 结果 / Manual QA Result

中文：未在真机或模拟器上执行手工 QA。原因：当前环境没有已连接并可操作的 HarmonyOS 设备或模拟器会话。

English: Manual QA was not executed on a device or emulator. Reason: the current environment does not have an attached and operable HarmonyOS device or emulator session.

中文：替代验证：已新增离线手工 QA 脚本 `docs/qa/manual-test-script.md`，覆盖 Today、Wardrobe、Outfits、Calendar、Shopping、photo、search 和 offline persistence；`scripts/validate-qa-fixture.mjs` 已验证 QA 脚本和 seed fixture 存在。

English: Substitute verification: the offline manual QA script `docs/qa/manual-test-script.md` was added, covering Today, Wardrobe, Outfits, Calendar, Shopping, photo, search, and offline persistence; `scripts/validate-qa-fixture.mjs` verifies the QA script and seed fixture exist.

## FTS5 与 fallback / FTS5 And Fallback

中文：代码实现了运行时 FTS5 探测：`detectSearchCapability` 先用临时 `temp.search_fts_probe` 验证 `CREATE VIRTUAL TABLE ... USING fts5`，成功时创建 FTS5 索引，失败时创建普通 n-gram fallback 表。

English: Runtime FTS5 detection is implemented: `detectSearchCapability` first probes `CREATE VIRTUAL TABLE ... USING fts5` through temporary `temp.search_fts_probe`, creates the FTS5 index on success, and creates the normal n-gram fallback table on failure.

中文：本地未执行真实 HarmonyOS SQLite runtime 探测。替代验证：`scripts/validate-search-schema.mjs` 和 `scripts/validate-search-repository.mjs` 已验证 FTS5 schema、fallback schema、安全 MATCH 查询、fallback n-gram 查询和 `rebuildSearchIndex`。

English: Real HarmonyOS SQLite runtime probing was not executed locally. Substitute verification: `scripts/validate-search-schema.mjs` and `scripts/validate-search-repository.mjs` validate the FTS5 schema, fallback schema, safe MATCH query construction, fallback n-gram query, and `rebuildSearchIndex`.

## 交付门禁 / Delivery Gates

中文：网络权限检查：`entry/src/main/module.json5` 没有声明 `ohos.permission.INTERNET`。

English: Network permission check: `entry/src/main/module.json5` does not declare `ohos.permission.INTERNET`.

中文：网络 API 检查：`entry/src/main/ets` 未发现 `@ohos.net`、NetworkKit、`fetch`、Axios 或 XMLHttpRequest 用法。

English: Network API check: `entry/src/main/ets` does not contain `@ohos.net`, NetworkKit, `fetch`, Axios, or XMLHttpRequest usage.

中文：照片存储检查：业务 SQLite schema 未使用 BLOB 存储照片；照片以本地 URI 写入照片关联表，复制逻辑位于媒体层。

English: Photo storage check: the business SQLite schema does not store photos as BLOBs; photos are referenced by local URI rows, with copy logic isolated in the media layer.

中文：搜索索引检查：搜索索引是派生数据，仓储写操作会更新索引，`SearchRepository.rebuildSearchIndex` 可从传入文档重建索引。

English: Search index check: the search index is derived data, repository writes update it, and `SearchRepository.rebuildSearchIndex` can rebuild the index from provided documents.

## 已知限制 / Known Limitations

中文：首版没有完成真实设备上的 HAP 构建、安装验证和交互式手工 QA，需要在配置好 HarmonyOS/DevEco 工具链和设备后补跑。

English: The first release has not completed real-device HAP build, installation verification, or interactive manual QA; these must be rerun after the HarmonyOS/DevEco toolchain and device are available.

中文：搜索不包含拼音搜索或高级中文分词；首版使用短文本 n-gram 召回。

English: Search does not include pinyin search or advanced Chinese segmentation; the first release uses short-text n-gram recall.

中文：Debug seed 使用 `debug://photos/...` URI，只用于离线 QA fixture，不代表真实相册或相机返回的 URI。

English: The debug seed uses `debug://photos/...` URIs for offline QA fixture purposes only; they do not represent real gallery or camera returned URIs.
