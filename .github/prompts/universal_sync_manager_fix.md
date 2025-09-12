---
mode: agent
---

## 🔎 Copilot Task: Definitive Fix Plan for `universal_sync_manager` Integration

**Context**

* We can now create a new **Group**, but **nothing syncs**.
* The project already imports the **`universal_sync_manager`** package correctly via `pubspec.yaml`.
* A **reference copy** of the package code exists at `universal_sync_manager/` (for reading only). **Do not copy code** from there into our app; use the **public package API** only.
* All relevant project code and resources are available locally.

**Goal**

* Perform a **thorough investigation** of why data isn’t syncing.
* Produce a **gap analysis** between the package’s **required integration steps** and our **current implementation**.
* Deliver a **phased implementation plan** to correctly integrate and verify syncing end-to-end, **without modifying the package source**.

---

### ✅ What to Read/Inspect (in this order)

1. **Project config**

   * `pubspec.yaml` (verify `universal_sync_manager` dependency + versions)
   * Any `.env`/config files for API endpoints, auth, organization IDs, collection/table names
2. **App bootstrapping**

   * `main.dart`, dependency injection/initialization, lifecycle hooks (e.g., where the sync manager should be initialized and started)
3. **Data layer**

   * Repositories/services for Groups (create/update/delete/read), local DB adapters, remote API adapters
   * Model definitions (IDs, timestamps, audit flags), mappers/serializers
4. **Sync usage points**

   * Where we **enqueue** or **trigger** sync (e.g., after create/update), background sync tasks, periodic/foreground sync triggers
   * Any Riverpod/Bloc providers that wrap sync state or queues
5. **Local storage**

   * SQLite schema, table names, primary keys, required columns (IDs, audit fields like `is_dirty`, `sync_version`, `last_synced_at`, etc.)
6. **Reference package (read-only)**

   * `universal_sync_manager/` code and docs to extract **required setup**, **expected hooks**, **API contracts**, **queue semantics**, **conflict resolution**, **error handling**

---

### 🧰 Deliverables (create/update these files)

* `docs/sync/gap_analysis.md` → A matrix mapping **package requirements** vs **our implementation**, status ✅/❌, and concrete fixes
* `docs/sync/implementation_plan.md` → A **phased plan** (see structure below)
* `docs/sync/test_matrix.md` → Test cases for push/pull/bi-directional flows, conflict handling, offline, retries
* `docs/sync/observability.md` → Logging/metrics plan (what, where, and sample log lines)


---

### 🧩 Gap Analysis – What to Check Explicitly

Create a table with these rows (expand as needed):

* **Initialization**: Is the sync manager **constructed**, **configured**, and **started** at app boot?
* **Backend config**: Are **endpoint/base URL**, **auth**, **organization/tenant IDs**, **collection/table names** correct?
* **Entity registration**: Are syncable entities (e.g., Group) **registered** with the manager/adapter?
* **ID strategy**: Are we using the **expected primary key format** (e.g., UUID) consistently locally and remotely?
* **Audit columns**: Do we have required fields (`is_dirty`, `sync_version`, `last_synced_at`, `created_at/_by`, `updated_at/_by`, `deleted_at`, `is_deleted`) and are they updated by repository methods?
* **Dirty queue**: After create/update, are records **marked dirty** and **enqueued** for push?
* **Pull scheduling**: Is **pull** scheduled/triggered (app start, interval, manual trigger)?
* **Conflict policy**: Is there a defined **last-write-wins/server-wins/custom** policy and mapping?
* **Serialization**: Are local ↔ remote field names/types mapped correctly?
* **Permissions/auth**: Are tokens/headers applied to sync requests? Do we refresh/validate before sync?
* **Error handling & retries**: Are errors logged; are **retries/backoff** configured?
* **Observers/UI**: Do screens **listen** for sync completion to refresh UI/state?

Populate the matrix with **evidence** (file + line refs) and **fix actions**.

---

### 🧪 Instrumentation & Diagnostics (add if missing)

* Add **scoped, verbose logs** around:

  * Manager initialization, configuration values (mask secrets)
  * Queue enqueue/dequeue for entities (IDs, operation type)
  * Outbound/inbound requests (method, path, status)
  * Conflict resolution decisions
  * Local DB writes with row counts
* Add a **temporary “Force Sync” action** in a developer menu or debug shortcut to trigger push/pull and dump a **sync report** to logs (counts of queued, pushed, pulled, failed).
* Ensure repository methods **emit** state changes so UI can refresh after sync.

---

### 🚦 Acceptance Criteria (must all pass)

1. **Create → Push:** Creating a Group locally enqueues it, pushes to remote, clears `is_dirty`, sets/updates `sync_version` & `last_synced_at`. Remote record exists.
2. **Remote → Pull:** Modifying the same Group remotely is **pulled** and applied locally with correct field mapping.
3. **Update → Push:** Local updates re-enqueue and sync correctly without duplicates.
4. **Soft delete:** Deleting locally marks `is_deleted`/`deleted_at` and syncs; pulling remote deletes applies locally.
5. **Conflict handling:** Defined policy is executed and observable in logs.
6. **Offline resilience:** With no network, records remain queued; on reconnect, sync completes automatically.
7. **No package source edits:** All changes confined to **our app**, using only the package’s **public API**.

---

## 📐 Phased Implementation Plan (use this structure in `docs/sync/implementation_plan.md`)

### Phase 0 — Baseline & Evidence

* Map current imports/usage of `universal_sync_manager` (files + symbols).
* Record current config values (endpoints, collections, auth).
* Run app, create a Group, **collect logs**, and note where the flow stops (enqueue? HTTP? DB write?).

**Output:** Baseline log snippet + short narrative of current failure point.

---

### Phase 1 — Configuration & Initialization

* Ensure **single, early** initialization of the sync manager with correct config.
* Register the **Group** entity/collection with the manager/adapter.
* Verify DI/lifecycle so the manager persists through app lifetime.

**Output:** Code refs/diffs, and logs confirming init + entity registration.

---

### Phase 2 — Data Layer Contracts

* Ensure repository methods **set audit fields** (created/updated/deleted), **mark dirty**, and **enqueue** changes.
* Verify **ID generation** and **serialization mapping** between local and remote schemas.
* Patch any mismatched columns/field names.

**Output:** Repository updates + sample logs showing enqueue after create/update.

---

### Phase 3 — Triggers, Scheduling, Pull

* Add/verify **push triggers** (after mutations) and **pull triggers** (on app start, interval, manual).
* Implement a **developer “Force Sync”** action for manual testing.
* Add robust **retry/backoff** and **error logging**.

**Output:** Logs showing scheduled/manual pull/push cycles with counts.

---

### Phase 4 — Conflict Handling & Edge Cases

* Implement or configure **conflict policy**; add logging for decisions.
* Handle **soft deletes**, **duplicate prevention**, and **idempotency**.
* Validate **auth refresh** flow if tokens expire.

**Output:** Tests/logs demonstrating conflicts resolved and soft deletes synced.

---

### Phase 5 — Verification, Docs, and Cleanup

* Fill `docs/sync/test_matrix.md` with test cases and results.
* Write `docs/sync/observability.md` with log keys, where to find them, and sample snippets.
* Update `CHANGELOG.md` and `CommitMessage.md` (Conventional Commit w/ emojis).
* Remove temporary debug UI if not needed.

**Output:** All docs updated; acceptance criteria met in a final test pass.

---

### 🧭 Guardrails

* **Do not** copy or modify code from `universal_sync_manager/` folder; treat it as **reference docs**.
* Use only the **public API** from the imported package.
* Keep changes **localized** to our app’s configuration, data layer, and integration points.

---

### Tools
Use sqlite, pocketbase and dart mcp server to help you investigate this issue

### 📣 Final Request

Proceed now: generate the **gap analysis**, then the **phased implementation plan**, and propose **specific file-level changes** (diff-style where helpful). Include paths and line anchors so edits are straightforward.
