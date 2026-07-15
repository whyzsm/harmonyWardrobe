# quick-capture-categories Specification

## Purpose
TBD - created by archiving change restore-quick-capture-categories-2026-07-15. Update Purpose after archive.
## Requirements
### Requirement: Quick entry exposes category destinations
The quick-entry sheet SHALL expose exactly three category actions: 衣柜, 逛店, and 穿搭. Their descriptions SHALL communicate the create actions 新增衣物、新增逛店记录、新增穿搭.

#### Scenario: Open the quick-entry sheet
- **WHEN** the user taps the bottom camera entry
- **THEN** the sheet shows the three category actions, create-oriented descriptions, and a cancel action

#### Scenario: Choose a category
- **WHEN** the user taps 衣柜、逛店 or 穿搭
- **THEN** the sheet closes and the application opens the corresponding blank create editor; the outfit editor receives the current local clothing items for selection

### Requirement: Existing feature capture flows remain available
The create-page shortcuts SHALL NOT remove photo capture and gallery selection from the existing feature pages.

#### Scenario: Capture from a feature page
- **WHEN** the user starts camera or gallery capture from a wardrobe, store, or outfit feature flow
- **THEN** the existing photo picker, local storage, and capture editor callbacks remain available

