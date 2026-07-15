## 1. Baseline And Runtime

- [x] 1.1 Remove the duplicate `ensureBaseSchema` execution while preserving registered migrations.
- [x] 1.2 Extract the Harmony file-system adapter from `WardrobeRuntime` without changing `PhotoFileSystem` behavior.
- [x] 1.3 Extract search-index rebuild preparation into a focused bootstrap module and preserve existing entity coverage.

## 2. Navigation And Naming

- [x] 2.1 Add the typed application route model and reduce `Index.ets` global route state to one active route plus parameters.
- [x] 2.2 Preserve quick capture, store editor, wishlist, search-result, and bottom-navigation flows.
- [x] 2.3 Rename `ShoppingPage` to `WishlistPage` and update imports, scripts, docs, and references.

## 3. Repository And Documentation Hygiene

- [x] 3.1 Verify repositories still receive the shared photo storage and preserve delete/search-index cleanup behavior.
- [x] 3.2 Update architecture documentation and mark stale review claims as historical where necessary.
- [x] 3.3 Add or update static checks for route exclusivity, page naming, duplicate migration removal, and forbidden demo pages/data.

## 4. Verification

- [x] 4.1 Run `openspec validate architecture-convergence-2026-07-15 --json`.
- [x] 4.2 Run every script under `scripts/*.mjs` and `git diff --check`.
- [x] 4.3 Report the exact environment limitation: this checkout has no `hvigorw` or `arktsc`, so the Hvigor/ArkTS build could not run.
- [x] 4.4 Supervisor reviews the final diff for layer violations, route reachability, and unrelated changes.
