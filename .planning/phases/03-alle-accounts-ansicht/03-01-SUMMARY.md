---
phase: 03-alle-accounts-ansicht
plan: 01
subsystem: dashboard
tags: [account-switcher, all-mode, provider-badge, websitecard]
requirements: [FEAT-01]

dependency_graph:
  requires: []
  provides:
    - showAllAccounts state in DashboardView
    - websiteAccountMap: [String: AnalyticsAccount]
    - loadAllAccountsData() in DashboardViewModel
    - providerName badge on WebsiteCard
  affects:
    - InsightFlow/Views/Dashboard/DashboardView.swift
    - InsightFlow/Views/Dashboard/WebsiteCard.swift
    - InsightFlow/Resources/en.lproj/Localizable.strings
    - InsightFlow/Resources/de.lproj/Localizable.strings

tech_stack:
  added: []
  patterns:
    - Manual Menu Buttons with checkmark handling (instead of Picker) for heterogeneous options
    - @ViewBuilder sub-properties to avoid Compiler Type-Check-Timeout in complex Menus
    - WebsiteAccountMap pattern for website-to-account lookup in flat combined view

key_files:
  created: []
  modified:
    - InsightFlow/Views/Dashboard/DashboardView.swift
    - InsightFlow/Views/Dashboard/WebsiteCard.swift
    - InsightFlow/Resources/en.lproj/Localizable.strings
    - InsightFlow/Resources/de.lproj/Localizable.strings

decisions:
  - Manual Buttons in Menu (not Picker) chosen because Picker requires UUID binding, incompatible with the heterogeneous "Alle" option that has no UUID
  - accountSwitcherMenuItems split into separate @ViewBuilder to avoid menu label type complexity
  - In All-mode, onRemoveSite is set to nil on WebsiteCard (removing a site from the combined view is ambiguous; user must switch to individual account first)
  - stats loading in loadAllAccountsData uses sequential per-account approach (not fully concurrent) to avoid credential race conditions between actor-based API clients

metrics:
  duration: ~60 minutes
  completed_date: "2026-03-28"
  tasks_completed: 2
  tasks_deferred: 1
  files_modified: 4
---

# Phase 03 Plan 01: Alle-Accounts-Ansicht Summary

## One-liner

"Alle"-Modus im Account-Switcher mit kombinierter Website-Liste, Provider-Badges (Orange/Blau Capsule) und Auto-Account-Switch bei Website-Tap.

## What Was Built

### Task 2: Provider-Badge auf WebsiteCard (commit: 7fa9bc8)

- New optional parameter `providerName: String? = nil` added to `WebsiteCard`
- New `@ViewBuilder private var providerBadge` renders a colored Capsule label
- Orange for "Umami", blue for "Plausible" — consistent with existing provider color scheme
- Badge appears beneath the domain text in `headerSection`
- Default `nil` = no badge shown (fully backwards-compatible)

### Task 1: Alle-Modus in ViewModel und Account-Switcher Menu (commit: bc501db)

- New `@State private var showAllAccounts = false` in `DashboardView`
- New `@State private var websiteAccountMap: [String: AnalyticsAccount] = [:]` for website-to-account lookup
- New `func loadAllAccountsData(dateRange:accounts:) async -> [String: AnalyticsAccount]` in `DashboardViewModel`:
  - Iterates all accounts, calls `AccountManager.shared.setActiveAccount()` per account to configure credentials
  - Loads websites from each account's API (Umami or Plausible)
  - Loads stats per-account sequentially to avoid credential race conditions
  - Restores original active account at the end
  - Returns account map used for providerName badge and auto-account-switch on tap
- `accountSwitcherMenu` rebuilt using three `@ViewBuilder` sub-properties:
  - `accountSwitcherMenu` — wraps Menu{} + label
  - `accountSwitcherLabel` — `rectangle.stack` in purple when All-mode, provider icon otherwise
  - `accountSwitcherMenuItems` — "Alle" button first, then account buttons with checkmarks, then Divider + Add Account
- Tap on website in All-mode: calls `setActiveAccount()` for the correct account, sets `showAllAccounts = false`, then navigates
- `onReceive(.accountDidChange)` skips reload when All-mode is active
- Localization keys `account.switcher.all` added in EN ("All") and DE ("Alle")

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| Manual Buttons instead of Picker in Menu | Picker requires UUID binding — "Alle" has no UUID, making it incompatible |
| @ViewBuilder sub-properties for Menu | Avoids Compiler Type-Check-Timeout (established pattern from Phase 01) |
| onRemoveSite = nil in All-mode | Removing a site in combined view is ambiguous; user should switch to single account first |
| Sequential per-account stats loading | Avoids actor-based API credential race conditions when loading stats for multiple accounts |

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written.

### Deferred Tasks

**Task 3 (checkpoint:human-verify)** — UI verification was not performed as this plan was executed as a parallel executor agent. Visual verification of the All-mode feature should be performed as part of phase-level review.

## Known Stubs

None — all data flows are wired. The `websiteAccountMap` is populated by `loadAllAccountsData()` and consumed by `WebsiteCard`'s `providerName` and the tap handler's account-switch logic.

## Self-Check: PASSED

- FOUND: .planning/phases/03-alle-accounts-ansicht/03-01-SUMMARY.md
- FOUND: InsightFlow/Views/Dashboard/DashboardView.swift
- FOUND: InsightFlow/Views/Dashboard/WebsiteCard.swift
- FOUND: commit bc501db (All-mode dashboard changes)
- FOUND: commit 7fa9bc8 (WebsiteCard provider badge)
- BUILD SUCCEEDED (iPhone 17 simulator)
