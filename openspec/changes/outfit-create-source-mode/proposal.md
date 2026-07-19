## Why

Creating an outfit currently conflates uploaded outfit photos with photos derived from selected wardrobe items. This makes the create/edit flow confusing and can cause selected gallery photos to be overwritten when the user changes wardrobe selections.

## What Changes

- Add an outfit source mode selector in the outfit editor: `上传照片` and `选衣柜单品`.
- Keep user-uploaded outfit photos independent from associated wardrobe item IDs.
- Persist the selected primary display source so editing, list cards, and detail pages agree.
- Allow saving when either uploaded outfit photos exist or selected wardrobe items provide photos.
- Render outfit cards as a single image when only one display photo exists; use the existing stacked layout only when two or more display photos exist.
- Follow the saved display source in outfit detail and list display, falling back to the other source only when the selected source has no usable photos.

## Capabilities

### New Capabilities
- `outfit-create-source-mode`: Covers outfit creation source modes, independent photo state, and count-aware outfit display.

### Modified Capabilities
- None.

## Impact

- Affected pages: `OutfitEditPage.ets`, `OutfitsPage.ets`, `OutfitDetailPage.ets`.
- Affected validation scripts: outfit editor, outfit list, and outfit detail checks.
- Additive SQLite migration only: `outfit_templates.display_source`; existing `outfit_photos` and `outfit_items` remain the source of truth for images and relationships.
