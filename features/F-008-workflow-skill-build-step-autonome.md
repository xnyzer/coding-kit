---
id: F-008
title: Workflow-Skill build-step + autonome Läufe
type: feature
status: DONE
size:
created: 2026-07-13
done: 2026-07-13
depends-on:
superseded-by:
---

# F-008 — Workflow-Skill build-step + autonome Läufe

## Verlauf

### F-008 — Workflow-Skill build-step + autonome Läufe (2026-07-13)

**Was entstanden ist (Plugin 0.5.0):**

- **build-step** — schließt die Lücke der Implementierungsphase (bisher formloses
  „setze F-xxx um"): prep-step-Plan laden, Substeps mit Verifikation je Schritt
  abarbeiten (Write-then-Verify, just-Checks, Abnahmekriterien einzeln gegen
  Tool-Ausgaben abhaken), je Substep Übergabe an step-done. Leitplanken: Plan-Treue,
  Scope-Schutz (Entdeckungen → add-feature statt still mitbauen), nie pushen, keine
  History-Rewrites, PROGRESS-Pflege nur via step-done.
- **Modus `autonom`:** baut nicht, sondern richtet einen `/goal`-Lauf ein (verifiziert
  gegen die Claude-Code-Doku: /goal hält die Session Turn für Turn am Arbeiten, bis
  ein Prüfmodell die Bedingung als erfüllt bewertet; Skills können /goal nicht selbst
  absetzen). Ablauf: Kontext + Plan laden → Voraussetzungen nennen (Trust-Dialog,
  Hooks, Auto-Modus für unbeaufsichtigte Läufe) → einmalige laufbezogene
  Commit-Freigabe einholen → fertige Goal-Zeile ausgeben (Varianten mit/ohne
  Freigabe, Turn-Limit als Stopp-Klausel, ~5 Turns je Substep) → enden; der Lauf
  startet mit dem Absenden der Goal-Zeile durch den Nutzer.
- **Commit-Granularität entschieden:** step-done + Commit je Substep (prep-step
  zerlegt in einzeln lauffähige Substeps = natürliche Commit-Grenzen; Commits sind
  im autonomen Lauf die Checkpoints gegen Entgleisung).
- **step-done erweitert:** Ausnahme-Regel zur Commit-Frage — bei dokumentierter
  laufbezogener Freigabe committen ohne Nachfrage (nach grünen Checks/Scans, nie
  Push); ohne Freigabe im autonomen Lauf Commit-Vorschlag festhalten und
  weiterarbeiten statt auf Antwort blockieren (schließt die Grauzone, in der ein
  Goal-Lauf sonst raten würde).
- **Vorlagen-Sync:** Halbsatz in `templates/global-CLAUDE.md` und (per
  Übernahme-Regel der Vorlage) in der live `~/.claude/CLAUDE.md`: laufbezogene
  Freigabe zählt als Fragen, Push bleibt tabu.
- README: build-step-Zeile, Zyklus-Satz mit drei Implementierungswegen
  (build-step / teach-step / frei + step-done), neue Anleitung „Autonomer Lauf
  (build-step + /goal)".
