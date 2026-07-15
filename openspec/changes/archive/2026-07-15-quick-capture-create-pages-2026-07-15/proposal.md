## Why

The restored quick-entry categories currently describe viewing existing content and route to list pages. The product flow requires each shortcut to start the corresponding create task directly.

## What Changes

- Keep the three quick-entry categories as 衣柜、逛店、穿搭.
- Use create-oriented copy: 新增衣物、新增逛店记录、新增穿搭.
- Route each category directly to its corresponding create editor.
- Keep the existing list pages and photo-first feature flows unchanged.
- Update active validation contracts and manual QA wording.

## Capabilities

### Modified Capabilities

- `quick-capture-categories`: category shortcuts open create editors rather than main lists.

## Impact

- `entry/src/main/ets/components/QuickCaptureSheet.ets`
- `entry/src/main/ets/app/AppRoute.ets`
- `entry/src/main/ets/pages/Index.ets`
- Active navigation and optimization validation scripts.
- No database schema, permission, dependency, or media storage changes.
