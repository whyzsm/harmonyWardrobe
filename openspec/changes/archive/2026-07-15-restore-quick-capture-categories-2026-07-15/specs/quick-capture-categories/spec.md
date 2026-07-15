## ADDED Requirements

### Requirement: Quick entry exposes category destinations
The quick-entry sheet SHALL expose exactly three category actions: 衣柜, 逛店, and 穿搭.

#### Scenario: Open the quick-entry sheet
- **WHEN** the user taps the bottom camera entry
- **THEN** the sheet shows the three category actions and a cancel action

#### Scenario: Choose a category
- **WHEN** the user taps 衣柜、逛店 or 穿搭
- **THEN** the sheet closes and the application activates the corresponding main route

### Requirement: Existing feature capture flows remain available
Restoring category shortcuts SHALL NOT remove photo capture and gallery selection from the existing feature pages.

#### Scenario: Capture from a feature page
- **WHEN** the user starts camera or gallery capture from a wardrobe, store, or outfit feature flow
- **THEN** the existing photo picker, local storage, and capture editor callbacks remain available
