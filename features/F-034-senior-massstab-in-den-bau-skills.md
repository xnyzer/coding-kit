---
id: F-034
title: Senior-Maßstab in den Bau-Skills
type: feature
status: BACKLOG
size:
created: 2026-10-20
done:
depends-on:
superseded-by:
---

# F-034 — Senior-Maßstab in den Bau-Skills

## Erfassung

**Problem:** Der inhaltliche Maßstab steht in der `CODING-STANDARDS.md` des Templates,
die Bau-Skills wenden ihn aber nicht aktiv an: `build-step` liest die Datei nur
(„falls vorhanden"). Qualität wird erst nachträglich in `step-done` geprüft, ohne
CODING-STANDARDS gibt es gar keine Messlatte, und im autonomen `/goal`-Lauf fehlt eine
Regel für den Fall, dass die saubere Lösung nicht im Plan liegt.

**Idee:** Die Bau-Skills arbeiten durchgängig wie ein Senior-Entwickler. Sie wählen die
einfachste tragfähige Lösung, schreiben Code, den der Nächste beim Ändern versteht
(keine verschachtelten Schleifen oder cleveren Ketten) und den ein Senior-Entwickler im
Diff prüfen kann — immer menschenlesbar, nie minifiziert —, bauen keine Workarounds und
sichern jeden Substep auch auf Secure Coding ab. Die Skills regeln den Prozess, den
Inhalt regelt die `CODING-STANDARDS.md`.

**Lösungsskizze:**
- `build-step`: aktive Qualitäts-Leitplanke. Selbst-Review je Substep, bevor er als
  fertig gemeldet wird: verständlich, einfach, sicher. Workaround-Stopp: Ist die saubere
  Lösung im Plan nicht machbar, anhalten und melden statt Hack (autonom: Lauf stoppen).
- **Menschenlesbarer Code:** Was die Skills schreiben, ist lesbarer Quelltext — nie
  minifiziert, komprimiert oder auf eine Zeile gepresst, auch nicht JSON, CSS oder
  Konfiguration —, damit ein Senior-Entwickler jede Änderung prüfen kann. Minifiziertes
  entsteht nur als Build-Ausgabe des Build-Werkzeugs und wird nie von Hand geschrieben
  oder bearbeitet. `build-step` prüft das im Selbst-Review, `step-done` im Review.
- Knapper Ersatz-Maßstab für Projekte ohne `CODING-STANDARDS.md` (Kernprinzipien,
  kein Duplikat der Vorlage).
- `teach-step`, `prep-step` (einfachstes Design planen; Security-Punkte je Substep
  deckt mit F-036 der Sicherheits-Blick der Spezifikation ab) und `step-done`
  (Review-Kriterien Verständlichkeit und Secure Coding) konsistent nachziehen.
- Inhaltliche Lücken der Vorlage (Lesbarkeit vor Cleverness, Secure Coding über Secrets
  hinaus) sind mit TPL-021 (project-template 0.14.0) bereits im Template;
  Bestandsprojekte erhalten sie über `/update-conventions`. Neu dazu: eine Regel in der
  `CODING-STANDARDS.md` der Vorlage (bei „Readable over clever", § 6): Quelltext ist
  menschenlesbar und nie minifiziert, Minifiziertes nur als Build-Ausgabe. Das ist
  Template-Inhalt und braucht deshalb einen CHANGELOG-Abschnitt `### Template`.

**Abhängigkeiten:** F-036 — schreibt prep-step und step-done grundlegend um, deshalb
erst danach (sonst doppelte Arbeit); zusammen mit F-037 umsetzen. Gegenstück:
TPL-021 (Inhalte der CODING-STANDARDS-Vorlage, erledigt) — die Skill-Kriterien darauf
abstimmen.
