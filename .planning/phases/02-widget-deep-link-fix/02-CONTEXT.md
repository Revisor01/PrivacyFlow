# Phase 2: Widget Deep Link Fix - Context

**Gathered:** 2026-03-28
**Status:** Ready for planning
**Mode:** Bug fix — single-line change

<domain>
## Phase Boundary

Widget-Tap öffnet die Website-Details. Root cause: URL-Schema-Mismatch.

Requirements: BUG-01

</domain>

<decisions>
## Implementation Decisions

### Bug Fix
- WidgetModels.swift Zeile 86: `insightflow://` → `privacyflow://`
- App-seitiger Handler (InsightFlowApp.swift:28) prüft `url.scheme == "privacyflow"` — das ist korrekt
- Kein weiterer Code-Change nötig — der gesamte Deep-Link-Flow funktioniert, nur das Schema war falsch

### Claude's Discretion
Keine — klarer Ein-Zeilen-Bugfix.

</decisions>

<code_context>
## Existing Code Insights

### Bug Location
- `InsightFlowWidget/Models/WidgetModels.swift:86` — `insightflow://` muss `privacyflow://` sein

### Working Flow (nach Fix)
1. Widget generiert URL: `privacyflow://website?id=hmgutmann&provider=umami`
2. `.widgetURL()` in WidgetSizeViews.swift:26
3. InsightFlowApp.swift:28 `.onOpenURL` matched `privacyflow://`
4. QuickActionManager.selectedWebsiteId gesetzt
5. DashboardView:173 `onChange` navigiert zu WebsiteDetailView

</code_context>

<specifics>
## Specific Ideas

Single line fix: `insightflow://` → `privacyflow://`

</specifics>

<deferred>
## Deferred Ideas

None.

</deferred>
