---
name: add-skill
description: Skill im coding-kit anlegen oder ändern — Plugin-Skill (plugins/coding-kit/skills/) oder repo-lokaler Skill (.claude/skills/). Führt durch die Authoring-Konvention, die leicht vergessenen Begleit-Änderungen (Plugin — plugin.json-Version und -Description, CHANGELOG, README; repo-lokal — kein Bump) und den Abschluss inkl. PROGRESS/ARCHIVE-Pflege. Immer nutzen, wenn in diesem Repo ein Skill entstehen oder sich ändern soll. Claude darf ihn selbst starten; PROGRESS-Einträge entstehen nur nach Freigabe.
disable-model-invocation: false
---

# Skill anlegen oder ändern

Repo-lokaler Pflege-Skill für dieses Repo: standardisiert das Bauen und Ändern von
Skills — **Plugin-Skills** unter `plugins/coding-kit/skills/` und **repo-lokale Skills**
unter `.claude/skills/` (wirken nur bei der Arbeit an diesem Repo). **Quelle der
Wahrheit für alle Konventionen ist `docs/skill-authoring.md`** — dieser Skill hält nur
die Prozedur und die Vollständigkeits-Checkliste, er dupliziert keine Regeln.

Claude darf den Skill selbst starten, z. B. wenn beim Bauen einer Aufgabe ein Skill
entstehen oder sich ändern soll — der Nutzer muss ihn dafür nicht aufrufen.

**Freigabe-Gate:** Jeder neue oder geänderte Eintrag in `PROGRESS.md`,
`PROGRESS-ARCHIVE.md` oder im FEATURE-INDEX wird zuerst als Vorschau gezeigt und erst
nach ausdrücklichem OK des Nutzers geschrieben (ausgenommen: genau der zuvor
freigegebene Text).

## 0. Kontext laden

- `docs/skill-authoring.md` vollständig lesen — immer, auch bei kleinen Änderungen
  (Frontmatter, Sprache und Publishing-Hygiene gelten auch repo-lokal).
- Die Projekt-CLAUDE.md ist im Kontext; relevant: Sync-Invariante, Sprachgrenze,
  Publishing-Hygiene, Freigabe-Regel für die PROGRESS.
- `PROGRESS.md` prüfen: Läuft die Arbeit schon als F-Nummer? Wenn nicht, **vor dem
  Bauen** über `/coding-kit:add-feature` anlegen — Entwurf zeigen, Eintrag erst nach
  Freigabe.

## Kontext-Recovery

Nach Kompaktierung oder Neustart: `PROGRESS.md` (die laufende F-Nummer) neu lesen,
`git status` + `git diff` für den Stand von Skill-Datei und Begleit-Änderungen, dann
bei der ersten offenen Position der Checkliste in Schritt 3 weitermachen.

## 1. Kurz-Interview (M1)

**Eine** Frage pro Antwort, mit empfohlenem Default; überspringen, was aus dem
Auftrag schon klar ist:

1. Neuer Skill oder Änderung an einem bestehenden?
2. **Plugin oder repo-lokal?** Wirkt der Skill in Projekten → Plugin. Betrifft er nur
   die Pflege dieses Repos → repo-lokal (Default für reine Kit-Pflege).
3. Name (lowercase-kebab, identisch mit Ordner- und Frontmatter-Name) und Kategorie
   (Orchestrator / Begleit / Workflow / Pflege / Utility)?
4. Zweck und Trigger-Situationen — daraus entsteht die `description`.
5. Frontmatter-Flags: `disable-model-invocation` (nur bewusster Nutzer-Start)?
   `disallowed-tools` (Tools, die der Skill nie nutzen darf)?
6. Welche Pflicht-Bausteine greifen? (Workflow-Skill → Projektkontext-Schritt + M4;
   Skill braucht Eingaben → M1; Skill schreibt in die PROGRESS → Freigabe-Gate;
   Details in der Authoring-Doku.)

## 2. Bauen bzw. ändern

- **Plugin:** `plugins/coding-kit/skills/<name>/SKILL.md` anlegen oder editieren;
  Hilfsdateien in den Skill-Ordner, Scripts nur mit relativen Pfaden bzw.
  `${CLAUDE_PLUGIN_ROOT}`.
- **Repo-lokal:** `.claude/skills/<name>/SKILL.md`; Aufruf ohne Namespace (`/<name>`).
- Liefert der Nutzer einen fertigen Entwurf: gegen die Authoring-Doku prüfen,
  Abweichungen benennen und korrigieren (typisch beim Plugin: Namespacing
  `/coding-kit:<name>` statt `/<name>`, fehlender Leer-Argument-Fallback).
- **Write-then-Verify:** nach jedem Edit re-lesen.

## 3. Begleit-Änderungen (Vollständigkeits-Checkliste — hier wird am meisten vergessen)

**Plugin-Skill:**

- [ ] `plugins/coding-kit/.claude-plugin/plugin.json`: Version bumpen (semver —
      neuer Skill: minor; reine Textkorrektur: patch) **und** die Skill-Aufzählung
      in der `description` aktualisieren.
- [ ] `CHANGELOG.md`: Eintrag unter der neuen Version (Sync-Invariante: gleicher
      Commit wie die Skill-Änderung).
- [ ] `README.md`: Tabellenzeile für `/coding-kit:<name>` anlegen/anpassen **und**
      betroffene Prosa prüfen (z. B. der Zyklus-Satz, die Struktur-Übersicht).
- [ ] Gehört der neue/geänderte Skill zum Projekt-Alltag (Dev-Loop) oder zur
      Projekt-Pflege: die Skill-Übersicht in project-templates
      `core/HOW-TO-CODE-WITH-CLAUDE.md` muss nachziehen. **project-template ist bis
      zur Zusammenlegung (F-039) eingefroren** — den Nachzug daher nicht im Template
      ändern, sondern im F-039-Eintrag der `PROGRESS.md` vermerken (Freigabe-Gate).
      Rein kit-interne Skills (wie add-skill selbst) bleiben draußen.
- [ ] Entstand ein neues, wiederverwendbares Muster: `docs/skill-authoring.md`
      ergänzen.

**Repo-lokaler Skill:**

- [ ] Kein Versions-Bump, kein CHANGELOG-Eintrag, keine Zeile in der README-Skill-
      Tabelle — der Skill ist kein Plugin-Inhalt.
- [ ] `README.md` § Repo-Struktur und `CLAUDE.md` prüfen, ob der Skill dort genannt
      werden muss (wie `/add-skill`).
- [ ] Neues, wiederverwendbares Muster: `docs/skill-authoring.md` ergänzen.

## 4. Verifizieren

- `just check` muss grün sein (validiert JSON/YAML und Privacy-Regeln im ganzen Repo,
  Frontmatter der Plugin-Skills).
- Lokal testen — Plugin: `/reload-plugins` in einer laufenden Session bzw.
  `claude plugin details coding-kit@xnyzer`; frisch installierte Skills sind ggf.
  erst nach Session-Neustart sichtbar. Repo-lokal: Der Skill erscheint in der
  laufenden Session in der Skill-Liste, sonst nach Session-Neustart.

## 5. Abschließen — PROGRESS und ARCHIVE gehören dazu

Auch Skill-Arbeit läuft als F-Nummer und wird verbucht wie jede andere Aufgabe:

- Fehlt die F-Nummer noch: über `/coding-kit:add-feature` anlegen — Entwurf zeigen,
  **erst nach ausdrücklichem OK eintragen**.
- `/coding-kit:step-done` ausführen bzw. empfehlen (interaktiv schließt der Nutzer
  selbst ab) — der zeigt Done-Zeile, Archiv-Eintrag und Commit-Message als Vorschau,
  verbucht nach Freigabe, macht Scans und Graphiti-Update.
- Skill-Datei und **alle** Begleit-Änderungen aus Schritt 3 gehören in denselben
  Commit. Nie automatisch committen.
