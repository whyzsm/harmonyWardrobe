## Context

`master` already has the intended local-first layering, while `786b754...` contains older demo/debug and orphan page structure. The current implementation concentrates global routing in `pages/Index.ets` and combines database migration, repository wiring, search rebuilding, and platform file APIs in `app/WardrobeRuntime.ets`.

## Goals / Non-Goals

**Goals:**

- Preserve current product behavior and the existing five-entry navigation design.
- Make global route state explicit and mutually exclusive.
- Make runtime bootstrap easier to inspect and avoid duplicate schema work.
- Keep the change compatible with existing ArkUI components, repositories, local SQLite, and media storage.

**Non-Goals:**

- No feature-wide page directory migration.
- No router library, MVVM framework, dependency-injection framework, network service, permission change, or database schema change.
- No visual redesign or user-facing copy expansion.

## Decisions

1. **Use a small typed route module instead of a router framework.** The app has one registered `Index` entry and local nested pages, so an enum plus route parameters is sufficient and avoids introducing lifecycle and serialization complexity.

2. **Keep feature-local nested state inside feature pages.** `WardrobePage`, `OutfitsPage`, `ProfilePage`, and the wishlist page continue to own their editors and detail views. `Index` owns only application-wide route composition and startup state.

3. **Split runtime helpers by responsibility.** `WardrobeRuntime` remains the public dependency container; a factory owns construction, a search-index bootstrap owns rebuild preparation, and a media adapter owns Harmony file-system calls.

4. **Keep migrations as the single schema source.** `MigrationRunner` is authoritative. The duplicate `ensureBaseSchema` path is removed rather than maintained as a second safety mechanism.

5. **Prefer explicit validation over broad refactoring.** Existing repository and media cleanup contracts remain behaviorally unchanged. Validation scripts are updated for the page rename and new route/runtime invariants.

## Risks / Trade-offs

- [Route migration mismatch] → Keep `Index` as the only registered entry page and run all repository validation scripts plus the ArkTS build.
- [Page rename breaks static checks] → Update imports, scripts, docs, and search references in one change.
- [Search rebuild behavior changes] → Preserve a rebuild path for first-run or stale-index cases and verify search for every entity type.
- [Concurrent edits across agents] → Assign disjoint file ownership and have the supervisor review the combined diff before validation.

## Migration Plan

1. Add the OpenSpec artifacts and route/runtime design.
2. Apply runtime and navigation changes in separate file ownership sets.
3. Update validation scripts and architecture documentation.
4. Run OpenSpec validation, all repository scripts, `git diff --check`, and the available Hvigor build.
5. If verification fails, revert only the new change files or restore the previous route/runtime implementation from the change diff; do not touch unrelated user files.

## Open Questions

- Whether conditional search-index rebuild metadata should be added in a later change; this change preserves the existing rebuild behavior unless a safe local marker already exists.
