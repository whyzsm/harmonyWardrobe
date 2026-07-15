## 1. Implementation

- [x] 1.1 Restore the three category actions and icons in `QuickCaptureSheet`.
- [x] 1.2 Wire the three actions to the existing typed routes in `Index.ets`.

## 2. Contracts And Documentation

- [x] 2.1 Update active validation scripts for category-first quick entry.
- [x] 2.2 Update current design guidance and manual QA while preserving historical review snapshots.

## 3. Verification

- [x] 3.1 Run `openspec validate restore-quick-capture-categories-2026-07-15 --json`.
- [x] 3.2 Run all `scripts/*.mjs` and `git diff --check`.
- [x] 3.3 Report the exact environment limitation: this checkout has no `hvigorw` or `arktsc`, so the Hvigor/ArkTS build could not run.
