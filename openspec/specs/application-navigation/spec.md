# application-navigation Specification

## Purpose
TBD - created by archiving change architecture-convergence-2026-07-15. Update Purpose after archive.
## Requirements
### Requirement: Global navigation uses one typed active route
The application SHALL represent its global main-screen and overlay navigation through a typed route model rather than independent boolean visibility flags.

#### Scenario: Selecting a main tab
- **WHEN** the user selects 衣柜、逛店、穿搭 or 我的
- **THEN** the application activates exactly one corresponding main route and clears incompatible global overlays

#### Scenario: Opening a global overlay
- **WHEN** the user opens the quick capture sheet, capture editor, store editor or wishlist screen
- **THEN** the application activates the corresponding overlay route without creating an invalid combination of global visibility flags

### Requirement: Wishlist screen remains reachable
The application SHALL keep the wishlist screen reachable from the profile flow and unified search result flow after the screen is renamed.

#### Scenario: Opening wishlist from profile
- **WHEN** the user selects 心愿清单 in the profile page
- **THEN** the application opens the wishlist screen and can return to the profile flow

#### Scenario: Opening a wishlist search result
- **WHEN** the user selects a wishlist result in unified search
- **THEN** the application opens the corresponding wishlist item editor

