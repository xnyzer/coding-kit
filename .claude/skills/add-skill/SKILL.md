---
name: add-skill
description: Neuen Plugin-Skill im coding-kit anlegen oder einen bestehenden ändern. Führt durch die Authoring-Konvention, die leicht vergessenen Begleit-Änderungen (plugin.json-Version und -Description, CHANGELOG, README) und den Abschluss inkl. PROGRESS/ARCHIVE-Pflege. Immer nutzen, wenn in diesem Repo ein Skill entstehen oder sich ändern soll.
---

# Plugin-Skill anlegen oder ändern

Repo-lokaler Pflege-Skill für dieses Repo: standardisiert das Bauen und Ändern von
Skills unter `plugins/coding-kit/skills/`. **Quelle der Wahrheit für alle Konventionen
ist `docs/skill-authoring.md`** — dieser Skill hält nur die Prozedur und die
Vollständigkeits-Checkliste, er dupliziert keine Regeln.

## 0. Kontext laden

- `docs/skill-authoring.md` vollständig lesen — immer, auch bei kleinen Änderungen.
- Die Projekt-CLAUDE.md ist im Kontext; relevant: Sync-Invariante, Sprachgrenze,
  Publishing-Hygiene.
- `PROGRESS.md` prüfen: Läuft die Arbeit schon als F-Nummer? (Wenn nicht — siehe
  Schritt 5, sie wird spätestens beim Abschluss vergeben.)

## 1. Kurz-Interview (M1)

**Eine** Frage pro Antwort, mit empfohlenem Default; überspringen, was aus dem
Auftrag schon klar ist:

1. Neuer Skill oder Änderung an einem bestehenden?
2. Name (lowercase-kebab, identisch mit Ordner- und Frontmatter-Name) und Kategorie
   (Orchestrator / Begleit / Workflow / Pflege / Utility)?
3. Zweck und Trigger-Situationen — daraus entsteht die `description`.
4. Frontmatter-Flags: `disable-model-invocation` (nur bewusster Nutzer-Start)?
   `disallowed-tools` (Tools, die der Skill nie nutzen darf)?
5. Welche Pflicht-Bausteine greifen? (Workflow-Skill → Projektkontext-Schritt + M4;
   Skill braucht Eingaben → M1; Details in der Authoring-Doku.)

## 2. Bauen bzw. ändern

- `plugins/coding-kit/skills/<name>/SKILL.md` anlegen oder editieren; Hilfsdateien in
  den Skill-Ordner, Scripts nur mit relativen Pfaden bzw. `${CLAUDE_PLUGIN_ROOT}`.
- Liefert der Nutzer einen fertigen Entwurf: gegen die Authoring-Doku prüfen,
  Abweichungen benennen und korrigieren (typisch: Namespacing
  `/coding-kit:<name>` statt `/<name>`, fehlender Leer-Argument-Fallback).
- **Write-then-Verify:** nach jedem Edit re-lesen.

## 3. Begleit-Änderungen (Vollständigkeits-Checkliste — hier wird am meisten vergessen)

- [ ] `plugins/coding-kit/.claude-plugin/plugin.json`: Version bumpen (semver —
      neuer Skill: minor; reine Textkorrektur: patch) **und** die Skill-Aufzählung
      in der `description` aktualisieren.
- [ ] `CHANGELOG.md`: Eintrag unter der neuen Version (Sync-Invariante: gleicher
      Commit wie die Skill-Änderung).
- [ ] `README.md`: Tabellenzeile für `/coding-kit:<name>` anlegen/anpassen **und**
      betroffene Prosa prüfen (z. B. der Zyklus-Satz, die Struktur-Übersicht).
- [ ] Entstand ein neues, wiederverwendbares Muster: `docs/skill-authoring.md`
      ergänzen.

## 4. Verifizieren

- `just check` muss grün sein (validiert Frontmatter, JSON/YAML, Privacy-Regeln).
- Lokal testen: `/reload-plugins` in einer laufenden Session bzw.
  `claude plugin details coding-kit@xnyzer`; frisch installierte Skills sind ggf.
  erst nach Session-Neustart sichtbar.

## 5. Abschließen — PROGRESS und ARCHIVE gehören dazu

Auch Skill-Arbeit läuft als F-Nummer und wird verbucht wie jede andere Aufgabe:

- Fehlt die F-Nummer noch, jetzt aus dem FEATURE-INDEX (`next-feature:`) vergeben.
- `/coding-kit:step-done` ausführen — der pflegt die Done-Zeile in `PROGRESS.md`,
  den Detail-Eintrag mit Entscheidungen in `PROGRESS-ARCHIVE.md`, macht Scans und
  Graphiti-Update und stellt die Commit-Frage.
- Skill-Datei und **alle** Begleit-Änderungen aus Schritt 3 gehören in denselben
  Commit. Nie automatisch committen.
