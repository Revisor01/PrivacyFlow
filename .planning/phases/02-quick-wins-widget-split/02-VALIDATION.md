---
phase: 2
slug: quick-wins-widget-split
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-28
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built-in, no tests yet — Phase 5) |
| **Config file** | none |
| **Quick run command** | `xcodebuild build -project InsightFlow.xcodeproj -scheme InsightFlow -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 \| tail -5` |
| **Full suite command** | `xcodebuild build -project InsightFlow.xcodeproj -scheme InsightFlow -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run build command
- **After every plan wave:** Full build verification
- **Before `/gsd:verify-work`:** Full build must succeed
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 2-01-01 | 01 | 1 | STAB-03 | grep | `grep -rn "print(" --include="*.swift" InsightFlow/ \| grep -v "#if DEBUG" \| grep -v "// MARK"` | N/A | ⬜ pending |
| 2-02-01 | 02 | 1 | STRUC-01 | wc | `wc -l InsightFlowWidget/InsightFlowWidget.swift` | N/A | ⬜ pending |
| 2-03-01 | 03 | 2 | STRUC-02 | wc | `wc -l InsightFlow/Views/Detail/WebsiteDetailView.swift InsightFlow/Views/Admin/AdminView.swift InsightFlow/Views/Detail/CompareView.swift` | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No test framework needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Widget displays data correctly after split | STRUC-01 | Requires widget refresh on device | 1. Build and run, 2. Add widget to home screen, 3. Verify all sizes show data |
| Views render correctly after subview extraction | STRUC-02 | Requires visual inspection | 1. Navigate to Detail, Admin, Compare views, 2. Verify layout unchanged |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
