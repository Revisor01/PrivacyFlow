# Requirements: StatFlow (formerly PrivacyFlow/InsightFlow)

**Defined:** 2026-03-28
**Core Value:** Nutzer können ihre Website-Analytics sicher und übersichtlich vom iPhone aus überwachen

## v2.4 Requirements

Komplettes Rebranding von PrivacyFlow/InsightFlow zu StatFlow.

### Rename

- [ ] **RENAME-01**: App-Name überall auf "StatFlow" — Display Name, alle Lokalisierungsstrings, Kommentare, About-Texte
- [ ] **RENAME-02**: Bundle IDs ändern — de.godsapp.PrivacyFlow → de.godsapp.statflow (App, Widget Extension, App Group)
- [ ] **RENAME-03**: URL Scheme + Deep Links — privacyflow:// → statflow:// (Info.plist, Widget-Links)
- [ ] **RENAME-04**: StoreKit Product IDs — de.godsapp.insightflow.support.* → de.godsapp.statflow.support.*

## Out of Scope

| Feature | Reason |
|---------|--------|
| Xcode Projekt umbenennen (InsightFlow.xcodeproj) | Funktioniert auch mit altem Projektnamen, riskanter Rename |
| GitHub Repo umbenennen | Separater Schritt, nicht in der App |
| App Store Connect Eintrag | Manuell durch User |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| RENAME-01 | Phase 12 | Pending |
| RENAME-02 | Phase 12 | Pending |
| RENAME-03 | Phase 12 | Pending |
| RENAME-04 | Phase 12 | Pending |

**Coverage:**
- v2.4 requirements: 4 total
- Mapped to phases: 4
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-28*
