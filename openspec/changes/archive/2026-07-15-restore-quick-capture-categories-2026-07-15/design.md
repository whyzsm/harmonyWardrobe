## Context

`QuickCaptureSheet` was changed in `db5cba9` from category shortcuts to photo-first actions. The current application already has a typed `AppRoute` model and route helpers, so the restoration can be limited to the sheet's callback contract and its `Index` wiring.

## Goals / Non-Goals

**Goals:**

- Restore the requested category-first quick-entry behavior.
- Reuse `AppMainTab` and existing route helpers.
- Keep the current sheet animation, styling tokens, accessibility labels, and close behavior.

**Non-Goals:**

- Do not revert `db5cba9` wholesale.
- Do not change database schemas, repositories, media storage, permissions, or page registration.
- Do not remove photo capture/gallery flows from feature pages.

## Decisions

1. **Use existing callbacks and routes.** `QuickCaptureSheet` remains presentation-only. It emits `onOpenWardrobe`, `onOpenStoreVisit`, and `onOpenOutfit`; `Index` maps them to `resetMainRoute` or `openStoreVisitList`.

2. **Use 穿搭 as the visible shortcut label.** The destination is the existing outfit page represented by `AppMainTab.Outfit`; internal page terminology such as 穿搭/美搭 remains unchanged.

3. **Update active contracts, not historical reports.** Current design and QA documents must describe the restored behavior. Dated historical review reports remain historical snapshots.

## Risks / Trade-offs

- [Active validation still requires photo-first actions] -> Update the relevant navigation, product-scope, visual-system, and optimization-residue checks together with the implementation.
- [User expects a photo immediately after tapping a category] -> Preserve the existing feature-page camera/gallery entry points and document the category-first flow in manual QA.

## Migration Plan

1. Change the sheet callback contract and labels.
2. Wire callbacks to current typed routes.
3. Update active checks and docs.
4. Run all repository scripts, OpenSpec validation, and `git diff --check`.

## Open Questions

None.
