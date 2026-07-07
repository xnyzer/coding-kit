# Skill-Authoring-Konvention

Verbindliche Regeln für alle Skills in diesem Plugin. Neue Skills erst gegen diese Liste
prüfen, dann bauen.

## Ablage & Struktur

- Ein Skill = ein Ordner: `plugins/coding-kit/skills/<skill-name>/SKILL.md`.
- `<skill-name>` ist lowercase-kebab und identisch mit dem `name:`-Frontmatter-Feld.
- Plugin-Skills sind immer namespaced sichtbar: `/coding-kit:<skill-name>`.
- Hilfsdateien (Templates, Scripts) liegen im Skill-Ordner; Scripts referenzieren nur
  relative Pfade bzw. `${CLAUDE_PLUGIN_ROOT}`.

## Frontmatter

Pflicht: `name`, `description`. Relevant außerdem:

| Feld | Wann |
|------|------|
| `disable-model-invocation: true` | Skills, die nur der Nutzer bewusst startet (z. B. prep-step, audit-code) — verhindert Auto-Aufruf durch das Modell. |
| `user-invocable: false` | Reine Hintergrund-Skills ohne Slash-Command (bisher keine). |
| `disallowed-tools` | Wenn ein Skill bestimmte Tools nie braucht/nutzen darf. |
| `default-enabled` | Nur setzen, wenn ein Skill opt-in sein soll. |

Die `description` entscheidet, wann das Modell den Skill von sich aus zieht — präzise
formulieren, Trigger-Situationen nennen.

## Sprache

- **Skill-Texte, Doku, README: Deutsch** (das Kit ist primär für den Eigenbedarf).
- **Englisch ist ausschließlich, was in Projekte gelangt oder dort wirkt:** Commit-
  Messages, die der Skill vorschlägt; Texte, die der Stop-Hook in beliebigen Projekten
  ausgibt; Inhalte, die in Projektdateien geschrieben werden (dort gilt die Sprache der
  lebenden Doku des Projekts).

## Harte Verbote (Publishing-Hygiene — das Repo ist public)

- **Keine Personendaten:** keine Klarnamen, privaten E-Mail-Adressen, Kundennamen.
- **Keine absoluten lokalen Pfade** (`/Users/…`, `/home/…`) und keine privaten
  IPs/Hostnames.
- **Keine hartkodierte Identität:** GitHub-Login/Noreply-E-Mail immer zur Laufzeit
  ermitteln (`git config`, `gh api user`); nicht Ermittelbares kommt aus der
  Personal-Config `~/.claude/coding-kit.env` (per Installer angelegt, nie committed).
- **Keine statischen Versionsstände** in Skill-Texten („aktuelles LTS" statt Zahl);
  aktuelle Stände zur Laufzeit per Websuche verifizieren.
- **Kein hartkodierter Projektzustand:** Skills dürfen nichts über ein konkretes Projekt
  wissen (Stack, Reifegrad, Feature-Stand). Alles Projektspezifische kommt zur Laufzeit
  aus der Projekt-CLAUDE.md, dem justfile und der PROGRESS.md.

## Pflicht-Bausteine

- **Projektkontext-Schritt (alle Workflow-Skills):** Projekt-CLAUDE.md lesen —
  Graphiti-group_id (Graphiti optional, ohne MCP still überspringen), Sprache der
  lebenden Doku, Scope, Sicherheits-Postur.
- **Stack-Agnostik:** Checks nur über die just-Standardrezepte (`just check` / `test` /
  `lint` / `format`); ohne justfile die projektüblichen Checks aus CLAUDE.md/README
  ermitteln — nie einen Stack raten.
- **M1 — Interview-Muster:** wenn ein Skill Eingaben braucht: **eine** Frage pro Antwort,
  immer mit empfohlenem Default; erst relevante Dateien lesen, dann fragen.
- **M4 — Kontext-Recovery-Block** in jedem Skill, der über mehrere Schritte arbeitet:
  Spec/PROGRESS re-lesen, `git status` + `git diff`, weitermachen ohne Doppelarbeit.
- **F-Nummern-Toleranz:** Alt-Formate (F-9, F9, „1.2") lesen, Neues ausschließlich als
  F-NNN (dreistellig, Substeps F-006a) schreiben; `next-feature:` aus dem
  FEATURE-INDEX-Block.
- **Nie automatisch committen** — Commits werden vorbereitet und vorgeschlagen, der
  Nutzer entscheidet.

## Versionierung & Test

- Jede inhaltliche Änderung am Plugin (Skills, Hooks): **Version in
  `plugins/coding-kit/.claude-plugin/plugin.json` bumpen** (semver) und einen Eintrag in
  `CHANGELOG.md` schreiben — im selben Commit.
- Lokal testen: `/reload-plugins` in einer laufenden Session bzw.
  `claude plugin details coding-kit@xnyzer` für das Komponenten-Inventar; frisch
  installierte Skills sind ggf. erst nach Session-Neustart sichtbar.
- `just check` validiert JSON/YAML-Syntax, Frontmatter-Pflichtfelder und Privacy-Regeln —
  muss vor jedem Commit grün sein.
