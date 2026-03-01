# JIRA Bug Categorization Standards — Digital Farm Team

> **Effective date:** February 21, 2026
> **Based on:** 27 bugs analyzed from Jan 1, 2026 to Feb 21, 2026 (Digital Farm team only)
> **Scope:** Labels applied to JIRA Bug issues owned by the **Digital Farm** team

---

## 1. Overview

Every JIRA bug in the Digital Farm team **must** receive labels (stored as `categories`) following a structured prefix convention. Categories are applied as JIRA labels and are automatically normalized by the system ([categories_normalizer.rb](app/services/categories_normalizer.rb)).

A bug should have **at minimum**:

1. One **`project:`** label
2. One **`feature:`** label (or **`mfe:`** if frontend micro-frontend specific)
3. Applicable **status markers** (`jira_escalated`, `Failure`, etc.) when relevant

> **Note:** 3 out of 27 bugs (11.1%) had zero categories—this should be avoided going forward.

---

## 2. Category Prefix Reference

| Prefix                   | Purpose                                                                | Required?       | Example                                     |
| ------------------------ | ---------------------------------------------------------------------- | --------------- | ------------------------------------------- |
| `project:`               | Identifies the **project/product** the bug belongs to                  | **Yes**         | `project:cup`                               |
| `feature:`               | Identifies the specific **feature or API** affected                    | **Yes**         | `feature:fields_updates_v2_api`             |
| `mfe:`                   | Identifies the **micro-frontend module** affected (Frontend bugs only) | Conditional     | `mfe:cw_elements_field_edit`                |
| `data_integrity_reason:` | Describes the **root cause** for data integrity issues                 | Conditional     | `data_integrity_reason:duplicated_cropzone` |
| _(no prefix)_            | Status markers and cross-cutting concerns                              | When applicable | `jira_escalated`, `Failure`                 |

---

## 3. `project:` — Project Labels

Identifies which project/product area the bug belongs to. **Every bug must have exactly one.**

| Label                        | Description                                | Usage (historical) |
| ---------------------------- | ------------------------------------------ | ------------------ |
| `project:cw_elements`        | CW Elements micro-frontend library         | 13 bugs (48%)      |
| `project:cup`                | CUP (Cropwise Unified Platform) project    | 4 bugs (15%)       |
| `project:map_integrator`     | Map Integrator integration module          | 3 bugs (11%)       |
| `project:strix`              | Strix project                              | 2 bugs (7%)        |
| `project:cw_farm_settings`   | CW Farm Settings module                    | 1 bug (4%)         |
| `project:integration_core`   | Integration Core messaging/events platform | 0 bugs             |
| `project:weisul_integration` | Weisul report integration                  | 0 bugs             |

### Rules

- Use **underscores** (`_`), not hyphens. ~~`project:cw-elements`~~ → `project:cw_elements`
- Use **lowercase** only. ~~`Strix`~~ → `project:strix`; ~~`cup`~~ → `project:cup`
- Do not create a new project label without team consensus. Propose in the team channel first.

---

## 4. `feature:` — Feature Labels

Identifies the specific feature or API endpoint affected. **Every bug must have at least one.**

### 4.1 Naming Convention

```
feature:<domain>_<action>_<version>_api     # for API endpoints
feature:<domain>_<ui_area>                  # for UI features
```

- Use **snake_case** only
- Include the **API version** when referencing an API endpoint (e.g., `v2_api`, `v3_api`)
- Suffix with `_api` for backend API features

### 4.2 Established Feature Labels by Domain

#### Fields (6 historical usages)

| Label                                  | Description                              |
| -------------------------------------- | ---------------------------------------- |
| `feature:edit_fields`                  | Field editing UI/logic                   |
| `feature:fields_updates_v2_api`        | Fields update API v2                     |
| `feature:fields_create_v2_api`         | Fields creation API v2                   |
| `feature:fields_update_v2_api`         | Single field update API v2               |
| `feature:fields_delta_v2_api`          | Fields delta sync API v2                 |
| `feature:fields_archive_v2_api`        | Fields archival API v2                   |
| `feature:fields_delete_v2_api`         | Fields deletion API v2                   |
| `feature:create_fields`                | Field creation (UI flow)                 |
| `feature:detect_fields`                | Field detection feature                  |
| `feature:delete_field_version`         | Field version deletion                   |
| `feature:season_fields_create_v2_api`  | Season-field association creation API v2 |
| `feature:season_fields_list_v2_api`    | Season-field listing API v2              |
| `feature:season_fields_updates_v2_api` | Season-field updates API v2              |
| `feature:property_fields_list`         | Property fields listing                  |

#### Crop Zones (2 historical usages)

| Label                             | Description                        |
| --------------------------------- | ---------------------------------- |
| `feature:cropzones_v3_api`        | Crop zones general API v3          |
| `feature:cropzones_create_v3_api` | Crop zone creation API v3          |
| `feature:cropzones_create_v1_api` | Crop zone creation API v1 (legacy) |
| `feature:cropzones_update_v3_api` | Crop zone update API v3            |
| `feature:cropzones_delete_v3_api` | Crop zone deletion API v3          |
| `feature:cropzones_list_v3_api`   | Crop zone listing API v3           |

#### Map Integrator (3 historical usages)

| Label                                     | Description                |
| ----------------------------------------- | -------------------------- |
| `feature:map_integrator_download_v1_api`  | Map download API v1        |
| `feature:map_integrator_sync_v1_api`      | Map sync API v1            |
| `feature:map_integrator_field_processor`  | Field processing pipeline  |
| `feature:map_integrator_season_processor` | Season processing pipeline |
| `feature:map_integrator_metada_v1_api`    | Metadata API v1            |
| `feature:map_integrator_status_v1_api`    | Status API v1              |

#### Properties (0 historical usages)

| Label                                    | Description                          |
| ---------------------------------------- | ------------------------------------ |
| `feature:property_create`                | Property creation                    |
| `feature:property_edit`                  | Property editing                     |
| `feature:properties_create_v2_api`       | Properties creation API v2           |
| `feature:properties_get_v2_api`          | Properties retrieval API v2          |
| `feature:properties_get_fields_v2_api`   | Properties → fields retrieval API v2 |
| `feature:default_warehouse_for_property` | Default warehouse assignment         |
| `feature:property_total_area`            | Property total area calculation      |
| `feature:property_field_count`           | Property field count                 |

#### CW Farm Settings (1 historical usage)

| Label                                         | Description                         |
| --------------------------------------------- | ----------------------------------- |
| `feature:cw_farm_settings_seasons_page`       | Seasons page in Farm Settings       |
| `feature:cw_farm_settings_fields_back_button` | Fields back button in Farm Settings |
| `feature:cw_farm_settings_side_bar`           | Sidebar in Farm Settings            |

#### Regions (0 historical usages)

| Label                            | Description               |
| -------------------------------- | ------------------------- |
| `feature:delete_region`          | Region deletion           |
| `feature:regions_delta_v2_api`   | Regions delta sync API v2 |
| `feature:regions_create_v2_api`  | Regions creation API v2   |
| `feature:regions_updates_v2_api` | Regions update API v2     |

#### My Cropwise (3 historical usages)

| Label                            | Description                      |
| -------------------------------- | -------------------------------- |
| `feature:my_cropwise_navigation` | My Cropwise navigation/routing   |
| `feature:my_cropwise_favorites`  | Favorites feature in My Cropwise |

#### Topbar (2 historical usages)

| Label                            | Description               |
| -------------------------------- | ------------------------- |
| `feature:topbar_entity_selector` | Entity selector in topbar |
| `feature:topbar`                 | General topbar bugs       |

#### Organizations (0 historical usages)

| Label                        | Description                    |
| ---------------------------- | ------------------------------ |
| `feature:orgs_create_v2_api` | Organization creation API v2   |
| `feature:orgs_delta_v2_api`  | Organization delta sync API v2 |
| `feature:org_edit`           | Organization editing UI        |

#### Upload Tool (4 historical usages)

| Label                             | Description                     |
| --------------------------------- | ------------------------------- |
| `feature:cw_elements_upload_tool` | Upload tool in CW Elements      |
| `feature:legacy_upload_tool`      | Legacy upload tool              |
| `feature:upload_tool_postman`     | Upload tool (Postman/API tests) |

#### Other Features

| Label                                             | Description                         |
| ------------------------------------------------- | ----------------------------------- |
| `feature:translation`                             | Translation/i18n issues             |
| `feature:backend_event_bus`                       | Backend event bus infrastructure    |
| `feature:integration_core_publish_message_v1_api` | Integration Core message publishing |
| `feature:quota_management`                        | Quota management                    |
| `feature:oauth_client_api`                        | OAuth client API                    |
| `feature:owner_app_id`                            | Owner app ID handling               |
| `feature:ec2_jump_instance`                       | EC2 jump instance (infra)           |
| `feature:map_measure_tool`                        | Map measurement tool                |
| `feature:map_edit_tools`                          | Map editing tools                   |
| `feature:open_farm_mfe`                           | Open Farm MFE                       |
| `feature:mariana_user_bypass`                     | Mariana user bypass                 |
| `feature:weisul_report_page`                      | Weisul report page                  |

---

## 5. `mfe:` — Micro-Frontend Labels

Used **only for Frontend bugs** (`development_type = Frontend`) to indicate the specific micro-frontend module in CW Elements.

| Label                                       | Description                      | Usage |
| ------------------------------------------- | -------------------------------- | ----- |
| `mfe:cw_elements_field_upload_tool`         | Field upload tool MFE            | 5     |
| `mfe:cw_elements_field_edit`                | Field editing MFE                | 3     |
| `mfe:cw_elements_topbar`                    | Topbar MFE                       | 3     |
| `mfe:cw_elements_map`                       | Map MFE                          | 1     |
| `mfe:cw_elements_my_cropwise`               | My Cropwise MFE                  | 1     |
| `mfe:cw_elements_field_edit_detect`         | Field edit detection MFE         | 0     |
| `mfe:cw_elements_property_edit`             | Property editing MFE             | 0     |
| `mfe:cw_elements_org_edit`                  | Organization editing MFE         | 0     |
| `mfe:cw_elements_my_cropwise_global_search` | Global search in My Cropwise MFE | 0     |

### Rules

- All `mfe:` labels start with `mfe:cw_elements_`
- When using an `mfe:` label, also add the corresponding `project:cw_elements`
- Backend bugs should **not** have `mfe:` labels

---

## 6. `data_integrity_reason:` — Data Integrity Labels

Used when the bug is related to a **data integrity issue**. Describes the root cause.

| Label                                                 | Description                                | Usage |
| ----------------------------------------------------- | ------------------------------------------ | ----- |
| `data_integrity_reason:region_tables_migration`       | Migration issues in region tables          | 1     |
| `data_integrity_reason:duplicated_cropzone`           | Duplicated crop zone records               | 0     |
| `data_integrity_reason:parent_name_versioning`        | Parent name versioning inconsistency       | 0     |
| `data_integrity_reason:fields_and_regions_same_level` | Fields and regions at same hierarchy level | 0     |
| `data_integrity_reason:parent_region_versioning`      | Parent region versioning inconsistency     | 0     |
| `data_integrity_reason:deleted_season_property`       | Deleted season-property association        | 0     |
| `data_integrity_reason:duplicated_field_version`      | Duplicated field version records           | 0     |

### Rules

- Always use the full `data_integrity_reason:` prefix. ~~`parent_region_versioning`~~ → `data_integrity_reason:parent_region_versioning`
- ~~`duplicated_season`~~ → `data_integrity_reason:duplicated_season`
- Use snake_case after the prefix

---

## 7. Status Markers (Unprefixed Labels)

These labels indicate **cross-cutting status** information. They do NOT replace `project:` or `feature:` labels.

| Label            | When to use                                                        | Usage   |
| ---------------- | ------------------------------------------------------------------ | ------- |
| `jira_escalated` | Bug was escalated via JIRA escalation process                      | 6 (22%) |
| `Failure`        | Bug resulted in a production failure/outage                        | 0 (0%)  |
| `cup-migration`  | Bug is related to CUP migration effort                             | 0 (0%)  |
| `cropwise-help`  | Bug originated from Cropwise Help/support channel                  | 0       |
| `delayed`        | Bug resolution was delayed beyond SLA                              | 0       |
| `translation`    | Bug is related to translations/i18n (prefer `feature:translation`) | 0       |

### Rules

- `jira_escalated` and `Failure` are the only high-frequency status markers — use them consistently
- Prefer `feature:translation` over unprefixed `translation`
- `cup-migration` is project-specific; always pair it with `project:cup`
- `user_tracking` → should use `feature:user_tracking` going forward

---

## 8. Automatic Normalization Rules

The system applies automatic normalization via `CategoriesNormalizer`. Be aware of these transformations:

| Input                            | Output                           | Rule                                        |
| -------------------------------- | -------------------------------- | ------------------------------------------- |
| `cw_elements_*`                  | `mfe:cw_elements_*`              | Auto-prefixed with `mfe:`                   |
| `*_api` (no prefix)              | `feature:*_api`                  | Auto-prefixed with `feature:`               |
| `data_integrity_*`               | `data_integrity_reason:*`        | Auto-prefixed with `data_integrity_reason:` |
| `map_integrator*` (no prefix)    | `feature:map_integrator*`        | Auto-prefixed with `feature:`               |
| `cw_farm_settings*` (no prefix)  | `feature:cw_farm_settings*`      | Auto-prefixed with `feature:`               |
| `Strix`                          | `project:strix`                  | Replaced with project label                 |
| `cup`                            | `project:cup`                    | Replaced with project label                 |
| `project:cw-elements`            | `project:cw_elements`            | Hyphen fixed to underscore                  |
| Any `cw_elements*` label present | `project:cw_elements` added      | Auto-derived project                        |
| Any `cw_farm_settings*` present  | `project:cw_farm_settings` added | Auto-derived project                        |
| Any `map_integrator*` present    | `project:map_integrator` added   | Auto-derived project                        |
| `feature:feature:*`              | `feature:*`                      | Duplicate prefix fix                        |

> Even though normalization exists, **always write labels in their correct final form** to avoid noise in changelogs.

---

## 9. Complete Labeling Examples

### Backend API Bug

```
project:cup
feature:fields_updates_v2_api
jira_escalated
Failure
```

### Frontend MFE Bug

```
project:cw_elements
feature:edit_fields
mfe:cw_elements_field_edit
```

### Data Integrity Bug

```
project:cup
feature:cropzones_v3_api
data_integrity_reason:duplicated_cropzone
jira_escalated
Failure
```

### Map Integrator Bug

```
project:map_integrator
feature:map_integrator_sync_v1_api
jira_escalated
Failure
```

### CUP Migration Bug

```
project:cup
feature:fields_create_v2_api
cup-migration
jira_escalated
```

---

## 10. Checklist Before Submitting a Bug

- [ ] **`project:`** label assigned (exactly one)
- [ ] **`feature:`** label assigned (at least one, matching the affected feature/API)
- [ ] **`mfe:`** label assigned if this is a Frontend bug in CW Elements
- [ ] **`data_integrity_reason:`** label assigned if this is a data integrity issue
- [ ] **`jira_escalated`** added if the bug was escalated
- [ ] **`Failure`** added if the bug caused a production failure
- [ ] **`cup-migration`** added if related to CUP migration
- [ ] All labels use **snake_case** and correct prefixes
- [ ] No unprefixed labels that should have a prefix (e.g., use `feature:translation`, not `translation`)

---

## 11. Adding New Categories

When a new feature or project is introduced:

1. **Check if an existing label fits** — review the tables above before creating a new one
2. **Follow the naming pattern**: `<prefix>:<domain>_<specifics>_<version>_api`
3. **Propose new `project:` labels** in the team channel before use
4. **New `feature:` labels** can be created freely but must follow snake_case and include API version if applicable
5. **Update this document** when a new label is established

---

_Document generated from analysis of 27 Digital Farm bugs (Jan 2026 – Feb 2026)._
