## Context

The shared quick-entry sheet is presentation-only. `Index` owns application routing and already renders the store editor as a typed route. Clothing and outfit editors are existing page components used by feature pages, so the change should expose them through the same route state instead of adding a second editor implementation.

## Decisions

1. Add `ClothingEditor` and `OutfitEditor` route kinds. This keeps the editor lifecycle explicit and hides the bottom navigation while an editor is active.
2. Reuse `StoreEditor` for the store shortcut.
3. Pass the current local clothing list into `OutfitEditPage`, because outfit creation needs selectable clothing items.
4. On save or cancel, return to the corresponding main tab. Outfit delete uses the existing outfit repository cleanup path.
5. Keep the visible shortcut titles as 衣柜、逛店、穿搭 and make their descriptions create-oriented.

## Risks And Mitigations

- [Clothing list loading fails before outfit creation] -> Still open the outfit editor with an empty list and retain the error message for the editor surface.
- [Old validation accepts list routing] -> Replace the quick-entry route assertion with explicit create-editor callbacks.
- [Existing feature flows regress] -> Preserve `CaptureEditor`, feature-page editors, and store list navigation; run every repository validation script.
