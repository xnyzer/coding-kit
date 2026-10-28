---
id: F-006
title: Utility-Skill refine-prompt
type: feature
status: DONE
size:
created: 2026-07-13
done: 2026-07-13
depends-on:
superseded-by:
---

# F-006 — Utility-Skill refine-prompt

## Verlauf

### F-006 — Utility-Skill refine-prompt (2026-07-13)

**Was entstanden ist (Plugin 0.5.0):**

- **refine-prompt** — übergebenen Prompt analysieren (Ziel, Zielgruppe, Ausgabeformat,
  impliziter Kontext), Schwachstellen benennen (Unklarheiten, fehlende Rollen-/
  Kontextangaben, fehlende Erfolgskriterien), nach Prompt-Engineering-Best-Practices
  neu formulieren und den verbesserten Prompt anschließend ausführen. Ausgabe:
  Schwachstellen → verbesserter Prompt (kopierbar) → Ergebnis.
- Nur manuell aufrufbar (`disable-model-invocation: true`); bei leerem `$ARGUMENTS`
  wird nach dem Prompt gefragt (M1). Kein Projektkontext-/M4-Baustein nötig — der
  Skill fasst nichts im Projekt an.
- Erster Skill der neuen Kategorie **Utility-Skills** (Plugin-Description entsprechend
  erweitert); Skill-Text vom Nutzer ausformuliert, bei der Aufnahme gegen
  `docs/skill-authoring.md` geprüft (Korrekturen: Namespacing `/coding-kit:refine-prompt`,
  M1-Fallback ergänzt).
