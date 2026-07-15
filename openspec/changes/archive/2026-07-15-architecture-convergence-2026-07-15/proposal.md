## Why

The current `master` branch has the more appropriate production-oriented layers than `786b754...`, but global navigation state and runtime bootstrap responsibilities are concentrated in a few files. This makes route combinations difficult to reason about, repeats startup work, and hides cross-layer coupling while the codebase is still small enough to correct safely.

## What Changes

- Remove duplicate schema initialization from the runtime bootstrap.
- Introduce a typed application route model so `Index.ets` does not coordinate multiple independent page visibility flags.
- Separate runtime construction, search-index bootstrap, and Harmony file-system adaptation into focused modules.
- Rename the wishlist screen from `ShoppingPage` to `WishlistPage` and update all references and validation rules.
- Keep feature pages, repositories, domain models, and media storage in their existing layer boundaries; do not perform a broad feature-directory migration.

## Capabilities

### New Capabilities

- `application-navigation`: Typed global route state and reachable main-screen navigation.
- `runtime-bootstrap`: Single-source database initialization and focused runtime assembly.

### Modified Capabilities

None.

## Impact

- Affected ArkTS files under `entry/src/main/ets/app`, `entry/src/main/ets/data/searchIndex`, `entry/src/main/ets/media`, and `entry/src/main/ets/pages`.
- Affected static validation scripts and project architecture documentation.
- No new permissions, network dependencies, database tables, or user-facing visual redesign.
