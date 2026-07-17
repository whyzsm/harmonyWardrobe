# AGENTS.md

Scope: this file applies to the entire repository.

## Project Context

Harmony Wardrobe is a local-first HarmonyOS Stage wardrobe application. It manages clothing records, outfit templates, wear logs, store visits, shopping wishlist items, and unified search.

The app does not depend on network services. Business data is stored in local SQLite tables. Photos are copied into app-local storage by the media layer and referenced from SQLite by local URI/path only.

The UI design background for the `衣不缺` direction lives in `docs/background/yibuque-design.md`. Read it before changing page layout, design tokens, navigation, visual styling, or user-facing UI copy.

## Reference Repositories

When solving HarmonyOS, OpenHarmony, ArkTS, ArkUI, SQLite, media, or DevEco build issues, use these repositories and collections as reference background before inventing a custom solution:

- OpenHarmony official source: https://gitcode.com/openharmony
- OpenHarmony docs: https://gitcode.com/openharmony/docs
- HarmonyOS Samples: https://gitee.com/harmonyos/samples
- HarmonyOS Samples organization: https://gitee.com/harmonyos_samples
- OpenHarmony app samples: https://gitee.com/openharmony/app_samples
- OpenHarmony Codelabs: https://gitee.com/openharmony/codelabs
- awesome-openharmony: https://github.com/originjs/awesome-openharmony
- awesome-harmony: https://github.com/Wscats/awesome-harmony
- ArkTSCentralRepository: https://gitee.com/ArkTSCentralRepository
- HarmonyOS tutorial: https://github.com/waylau/harmonyos-tutorial
- HarmonyOS NEXT interview handbook project: https://github.com/HarmonyOS-Next/interview-handbook-project
- ArkTS NetEase Cloud Music example: https://github.com/linwu-hi/open_neteasy_cloud
- VSCode ArkTS extension: https://github.com/ohosvscode/arkTS
- JhHarmonyDemo: https://github.com/iotjin/JhHarmonyDemo
- HarmonyNEXT examples: https://github.com/RicardoWesleyli/HarmonyNEXT_Examples

Prefer official OpenHarmony/HarmonyOS docs and samples for platform APIs and lifecycle behavior. Use community repositories for implementation patterns, component ideas, and practical workarounds only after checking whether the approach matches this app's local-first constraints.

## Code Organization

- Core ETS code lives under `entry/src/main/ets`.
- Pages live in `entry/src/main/ets/pages` and own screen composition, navigation state, user input, loading states, empty states, and error presentation.
- Reusable ArkUI components live in `entry/src/main/ets/components` and should stay presentation-focused with typed inputs.
- Domain models and rules live in `entry/src/main/ets/domain` and must not depend on ArkUI widgets, SQLite APIs, or local file APIs.
- Data access, migrations, repositories, and derived search index code live in `entry/src/main/ets/data`.
- Photo picking, app-local media copying, and orphaned media cleanup live in `entry/src/main/ets/media`.
- Small shared helpers live in `entry/src/main/ets/utils`; keep them lightweight and avoid importing pages, components, repositories, or platform-specific adapters unless explicitly isolated.

## Architecture Rules

- UI pages should call domain-facing services or repositories through clear interfaces. Do not write SQL directly in pages.
- SQLite business tables are the source of truth. Search index tables are derived and rebuildable.
- Keep repository operations responsible for keeping business data and search index data consistent.
- Store photo binaries in app-local files only. Do not store image blobs in SQLite.
- Do not add network permissions, backend dependencies, or remote sync unless the task explicitly changes the product scope.
- Keep changes scoped to the current feature or bug. Avoid unrelated refactors and generated metadata churn.

## Validation

Run all repository validation scripts after meaningful code changes:

```bash
for script in scripts/*.mjs; do node "$script"; done
git diff --check
```

For HarmonyOS builds, use the local DevEco command-line-tools `hvigorw`.

Full app build:

```bash
<command-line-tools>/bin/hvigorw assembleApp --no-daemon --no-incremental --no-parallel --stacktrace
```

Entry HAP build:

```bash
<command-line-tools>/bin/hvigorw --mode module -p product=default -p module=entry@default assembleHap --no-daemon --no-incremental --no-parallel --stacktrace
```

Manual QA coverage is documented in `docs/qa/manual-test-script.md`.

## Repository Hygiene

- Do not commit `.hvigor/`, `build/`, `entry/build/`, or other generated build outputs.
- Be careful with existing uncommitted work. Treat unrelated local changes as user-owned and do not revert them.
- Keep documentation aligned with `README.md`, `docs/architecture.md`, and the relevant files under `docs/plans/`.
