---
id: F-028
title: Utility-Skill handoff
type: feature
status: DONE
size:
created: 2026-09-16
done: 2026-09-16
depends-on:
superseded-by:
---

# F-028 — Utility-Skill handoff

## Verlauf

### F-028 — Utility-Skill handoff (2026-09-16)

**Aufgabe:** Am Kontextlimit wurde der Handoff an einen frischen Chat jedes Mal per Hand
angefordert („ausführlichen Handover-Prompt zum Kopieren, nur Kontext übergeben, nichts
bauen, nur noch nicht Dokumentiertes"). Das sollte ein projektunabhängiger Skill werden.
Direkt über `/add-skill` gebaut, ohne vorherigen Backlog-Eintrag.

**Was entstanden ist (Plugin 0.19.0):**

- **handoff** (`plugins/coding-kit/skills/handoff/SKILL.md`) — schreibt einen
  kopierfertigen Handoff-Prompt: Grundsatz (übergeben / verweisen / nie übergeben /
  ehrlich bleiben), elfteilige Gliederung in zwei Blöcken — **Orientierung** (Einstieg,
  Ziel, Zuletzt, Stand, Als Nächstes inkl. Reihenfolge-Vorgabe) vor **Hintergrund**
  (Entscheidungen, Fallstricke, Absprachen, Offen, Quellen) —, leere Abschnitte entfallen,
  Richtwert typisch bis ~150 Zeilen, feste Schlussanweisung („Stand bestätigen, auf
  Anweisung warten; steht die Anweisung schon in der Nachricht, loslegen"). Optionales
  Argument = Fokus bzw. geplanter nächster Schritt.
- **Begleit-Änderungen:** `plugin.json` 0.19.0 + Utility-Aufzählung, `CHANGELOG.md`,
  `README.md` (Tabellenzeile; veraltete Struktur-Zeile „Die vier Core-Skills" auf
  „Die Skills (ein Ordner je Skill)" korrigiert).

**Notable decisions:**

- **Maßstab je Zeile statt Themenliste:** „Würde der neue Chat ohne sie etwas falsch
  machen, doppelt tun oder erneut fragen?" — löst den Zielkonflikt „möglichst
  ausführlich, aber nicht überladen" an jeder einzelnen Zeile, nicht über eine Längenvorgabe
  allein. Dokumentiertes (Dateien, Git, CLAUDE.md, Memory, in der Session Geschriebenes)
  nur als Verweis.
- **Richtwert statt Klammer:** der erste Entwurf hatte 30–100 Zeilen. Die Untergrenze
  widersprach „leere Abschnitte weglassen" und hätte nach kurzen Sessions Füllstoff
  erzwungen; 100 Zeilen (grob 2–3 k Tokens) hätten nach langen Sessions ausgerechnet das
  „Warum" gekürzt. Überladen wird ein neuer Chat durch Kopien und vorsorgliches Lesen,
  nicht durch Länge. Ganz ohne Zahl wird es erfahrungsgemäß zu lang — daher „typisch bis
  ~150 Zeilen, nach kurzen Sessions deutlich weniger".
- **Orientierung vor Hintergrund:** im ersten Entwurf standen Stand, ausstehende
  Bestätigungen und nächster Schritt verstreut (Abschnitte 3, 7, 9) — der neue Chat las
  erst Entscheidungen, bevor er erfuhr, wo es weitergeht. Neu ist ausdrücklich
  **Zuletzt** (letzte Aktion und was darauf wartet): genau das steht in keiner Datei und
  nicht im git log.
- **Reihenfolge-Vorgabe generisch erkannt, nicht kopiert:** einige Projekte führen neben
  der Template-Konvention („offene Aufgaben in Ausführungsreihenfolge") eine eigene
  Reihenfolge — in zwei gefundenen Formen: eigene Überschrift mit Pfeilkette der
  F-Nummern bzw. Überschrift über der ganzen offenen Liste. Daher kein fester Wortlaut,
  sondern eine Überschriften-Suche (`reihenfolge|order`, an die Doku-Sprache anpassbar),
  gegen beide Formen und gegen ein Projekt ohne Vorgabe geprüft. Der Handoff nennt
  Fundstelle und nächsten Eintrag, kopiert die Vorgabe aber nicht — sie kann sich im
  neuen Chat ändern (z. B. durch step-done), die Datei bleibt maßgeblich. **Bewusst nicht
  aufgenommen:** die Vorgabe zur Kit-Konvention zu machen, die auch prep-step/build-step
  beachten — hier wirkt sie nur in Chats, die mit einem Handoff starten.
- **Kontextsparsam, weil der Skill genau am Limit läuft:** knapper Skill-Text; leeres
  Argument **ohne Rückfrage** (bewusste Abweichung vom sonst üblichen M1-Fallback wie bei
  refine-prompt — eine Rückfrage kostet den Kontext, der fehlt); höchstens ein
  Shell-Aufruf (Git-Stand plus Überschriften-Suche), keine Datei-Lesevorgänge. Kein
  M4-Block (einschrittig), kein Projektkontext-Schritt (Utility, soll auch außerhalb von
  Kit-Projekten und ohne Git laufen).
- **Hartes Schreibverbot** per `disallowed-tools: Write, Edit, NotebookEdit` (Muster wie
  teach-step) und ausdrücklich **kein Memory-Update**, obwohl die House-Defaults
  Graphiti-Speichern ohne Nachfrage vorsehen: Zusätzliche Aufrufe am Limit gefährden die
  Ausgabe selbst. Dokumentationsbedarf landet im Prompt unter „Offen" und wird im neuen
  Chat auf Anweisung erledigt.
- **„Quellen" statt „Zuerst lesen":** die genannten Dateien liest der neue Chat, sobald
  die Arbeit sie berührt — nicht vorsorglich, sonst startet er wieder überladen.
- **Ausgabe als ein Codeblock mit vier Backticks**, damit innere Code-Schnipsel die
  Kopiervorlage nicht zerbrechen.
- **Name `handoff`** (Nutzerwahl gegenüber `handover`/`context-handover`); nur manuell
  aufrufbar. **Nicht in project-templates HOW-TO** — wie refine-prompt Session-Werkzeug,
  weder Dev-Loop noch Projekt-Pflege.

**Verifikation:** `just check` grün (Frontmatter, JSON, Privacy); Secrets-/Privacy-Scan
des Diffs ohne Befund; Überschriften-Suche gegen zwei Projekte mit unterschiedlicher
Reihenfolge-Form (Treffer) und eines ohne Vorgabe (kein Treffer) geprüft. Ein Praxistest
steht noch aus: das installierte Plugin kommt vom GitHub-Marketplace, der Skill ist erst
nach Push + Plugin-Update (oder in einer Session mit `--plugin-dir plugins/coding-kit`)
aufrufbar.
