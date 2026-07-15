## Why

The current quick-entry sheet starts with photo source selection, but the requested product flow starts with the user's destination: wardrobe, store visit, or outfit. The previous category shortcut behavior was intentionally replaced in `db5cba9`; this change restores that behavior without reverting unrelated architecture and data improvements.

## What Changes

- Restore `QuickCaptureSheet` actions for 衣柜、逛店、穿搭.
- Wire each action to the existing typed application routes in `Index.ets`.
- Update active validation rules, design guidance, manual QA, and product-scope checks to match the restored behavior.
- Preserve photo capture and gallery selection inside the existing feature pages.

## Capabilities

### New Capabilities

- `quick-capture-categories`: Category-first quick-entry navigation.

### Modified Capabilities

None.

## Impact

- `entry/src/main/ets/components/QuickCaptureSheet.ets`
- `entry/src/main/ets/pages/Index.ets`
- Related validation scripts and current design/QA documentation.
- No database, permission, dependency, media-storage, or route-registration changes.
