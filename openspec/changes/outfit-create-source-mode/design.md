## Context

`OutfitTemplate` already stores uploaded photos in `photoUris` and associated wardrobe items in `clothingItemIds`. The current editor derives photos from selected wardrobe items and writes them into `photoUris`, which mixes two different concepts and creates accidental overwrites. The editor also needs to remember whether uploaded photos or wardrobe item photos are the primary display source.

## Goals / Non-Goals

**Goals:**
- Make source selection explicit in the outfit editor.
- Preserve uploaded outfit photos when wardrobe item selections change.
- Support creating outfits from only uploaded photos or only wardrobe item photos.
- Persist the primary display source so edit, list, and detail views stay consistent.
- Keep list/detail visual rendering source-aware and count-aware.

**Non-Goals:**
- No photo-table migration; one additive migration adds `outfit_templates.display_source`.
- No new media picker API.
- No network sync or remote image handling.

## Decisions

- Keep `photoUris` as uploaded outfit photos only. This avoids storing wardrobe item photo references in `outfit_photos`, which could interact badly with orphan-photo cleanup when an outfit is deleted.
- Persist `display_source` as the primary display source. Compute `displayPhotoUris()` from that source first, then fall back to the other available source.
- Validate save readiness by the active source mode: uploaded-photo mode requires at least one uploaded outfit photo, while wardrobe-item mode requires at least one selected wardrobe item with a usable photo. Optional sections stay optional and do not satisfy the opposite mode by themselves.
- Use a lightweight segmented control inside `OutfitEditPage` instead of adding a new route. The user remains in one editor and can switch modes before saving.
- Reuse existing `PhotoStorage` and `PhotoPickerAdapter` flows. The change only improves state ownership and error handling.

## Risks / Trade-offs

- Existing outfits default to the previous uploaded-photo preference. Users can switch the display source while editing.
- Wardrobe-item-only outfits require selected items to have at least one photo. The save message must make this clear when selected items are photo-less.
- List cards need access to clothing items to compute fallback display photos; `OutfitsPage` already loads `clothingItems`, so no repository change is required.

## Migration Plan

- Implement UI/state changes and the additive display-source migration.
- Existing records continue to load normally.
- Rollback is limited to the affected page changes and validation scripts.
