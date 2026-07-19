## 1. Editor Flow

- [x] 1.1 Add outfit source mode state and segmented source selector to `OutfitEditPage`.
- [x] 1.2 Keep uploaded outfit photos independent from wardrobe item selection changes.
- [x] 1.3 Enable save when either uploaded photos exist or selected wardrobe items have photos.
- [x] 1.4 Improve gallery/camera copy error handling in `OutfitEditPage`.
- [x] 1.5 Persist the selected primary display source on the outfit record.

## 2. Display Flow

- [x] 2.1 Update `OutfitsPage` to compute display photos from uploaded photos first, then wardrobe item photos.
- [x] 2.2 Render one-image cards for a single display photo and stacked cards for two or more photos.
- [x] 2.3 Update `OutfitDetailPage` to prioritize uploaded outfit photos over wardrobe fallback photos.
- [x] 2.4 Make list/detail display follow the saved primary display source with source fallback.

## 3. Verification

- [x] 3.1 Update outfit editor/list/detail validation scripts for the new rules.
- [x] 3.2 Run targeted validation scripts and `git diff --check`.
- [x] 3.3 Run OpenSpec validation for `outfit-create-source-mode`.
- [x] 3.4 Build entry HAP with DevEco `hvigorw`.
- [x] 3.5 Request supervising sub-agent review of the final diff.
- [ ] 3.6 Re-run full validation after the display-source persistence change.
