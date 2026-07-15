# runtime-bootstrap Specification

## Purpose
TBD - created by archiving change architecture-convergence-2026-07-15. Update Purpose after archive.
## Requirements
### Requirement: Database migrations have one initialization source
The application SHALL execute the registered database migrations once during runtime creation and SHALL NOT repeat the same schema creation through a second bootstrap path.

#### Scenario: Creating the runtime
- **WHEN** the application initializes `WardrobeRuntime`
- **THEN** `MigrationRunner` applies pending migrations and no duplicate base-schema pass runs afterward

### Requirement: Runtime assembly has focused responsibilities
The application SHALL keep repository construction, search-index initialization, and Harmony file-system adaptation in focused modules while preserving the existing public runtime dependencies.

#### Scenario: Creating repositories
- **WHEN** runtime construction completes
- **THEN** all existing repositories, photo adapters and photo storage are available through `WardrobeRuntime`

#### Scenario: Initializing search
- **WHEN** the search index is missing, stale or requires a capability-mode rebuild
- **THEN** the bootstrap rebuilds it from SQLite business data

