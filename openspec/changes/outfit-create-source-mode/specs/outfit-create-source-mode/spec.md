## ADDED Requirements

### Requirement: Outfit editor exposes source mode choices
The system SHALL let users choose whether a new outfit starts from uploaded photos or from wardrobe items.

#### Scenario: Create outfit from uploaded photos
- **WHEN** the user chooses `上传照片`
- **THEN** the editor shows photo capture/gallery selection as the primary section and treats wardrobe item selection as optional association

#### Scenario: Create outfit from wardrobe items
- **WHEN** the user chooses `选衣柜单品`
- **THEN** the editor shows wardrobe item selection as the primary section and treats uploaded outfit photos as optional supplement

### Requirement: Outfit photo state remains independent
The system SHALL store only user-uploaded outfit photos in `outfit.photoUris` and SHALL NOT overwrite them when wardrobe item selections change.

#### Scenario: Toggle wardrobe items after uploading photos
- **WHEN** the user uploads outfit photos and then selects or unselects wardrobe items
- **THEN** the uploaded outfit photos remain selected and are saved with the outfit

#### Scenario: Edit existing outfit with uploaded photos
- **WHEN** an existing outfit has uploaded photos and associated wardrobe items
- **THEN** opening the editor restores the uploaded photos instead of replacing them with wardrobe item photos

### Requirement: Outfit save accepts either source
The system SHALL allow saving an outfit from either source and SHALL validate the required source according to the selected editor mode.

#### Scenario: Save uploaded-photo outfit
- **WHEN** the user has selected one or more uploaded outfit photos
- **THEN** the save action is enabled even if no wardrobe item is selected

#### Scenario: Save wardrobe-item outfit
- **WHEN** the user has selected one or more wardrobe items with photos
- **THEN** the save action is enabled even if no uploaded outfit photo exists

#### Scenario: Uploaded-photo mode without uploaded photo
- **WHEN** the user chooses `上传照片` and only selects optional wardrobe items
- **THEN** the save action remains disabled until an uploaded outfit photo exists

#### Scenario: Wardrobe-item mode without wardrobe item photo
- **WHEN** the user chooses `选衣柜单品` and only uploads supplemental outfit photos
- **THEN** the save action remains disabled until a selected wardrobe item has a usable photo

### Requirement: Outfit display adapts to photo count
The system SHALL render outfit cards using one full image for a single display photo and the stacked two-image layout only when at least two display photos exist.

#### Scenario: One display photo
- **WHEN** an outfit has exactly one display photo
- **THEN** the list card shows that one photo without a second placeholder

#### Scenario: Two or more display photos
- **WHEN** an outfit has two or more display photos
- **THEN** the list card uses the existing stacked layout with the first two photos

### Requirement: Outfit display prioritizes uploaded photos
The system SHALL display uploaded outfit photos before associated wardrobe item photos.

#### Scenario: Outfit has uploaded photos and wardrobe items
- **WHEN** the outfit appears in the list or detail page
- **THEN** uploaded outfit photos are used for the visual display

#### Scenario: Outfit has no uploaded photos
- **WHEN** the outfit has associated wardrobe items with photos but no uploaded photos
- **THEN** wardrobe item photos are used as display fallback
