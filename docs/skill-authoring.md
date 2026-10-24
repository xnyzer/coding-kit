# Skill-Authoring-Konvention

Verbindliche Regeln für alle Skills in diesem Plugin. Neue Skills erst gegen diese Liste
prüfen, dann bauen.

## Ablage & Struktur

- Ein Skill = ein Ordner: `plugins/coding-kit/skills/<skill-name>/SKILL.md`.
- `<skill-name>` ist lowercase-kebab und identisch mit dem `name:`-Frontmatter-Feld.
- Plugin-Skills sind immer namespaced sichtbar: `/coding-kit:<skill-name>`.
- Hilfsdateien eines einzelnen Skills (Vorlagen, Scripts) liegen im Skill-Ordner;
  Skripte, die mehrere Skills teilen, unter `plugins/coding-kit/scripts/` (§ Hilfsskripte).
  Scripts referenzieren nur relative Pfade bzw. `${CLAUDE_PLUGIN_ROOT}`.
- **Das Projekt-Template** liegt im Plugin unter `template/` (`MANIFEST.md`, `core/`,
  `modules/`). Skills nennen es immer als `${CLAUDE_PLUGIN_ROOT}/template/…` — nie einen
  Checkout, Klon oder absoluten Pfad. Claude Code ersetzt `${CLAUDE_PLUGIN_ROOT}` beim
  Laden **im Skill-Text**; als Umgebungsvariable in Shell-Befehlen gibt es sie nicht,
  dort den aufgelösten Pfad verwenden. Gemeinsame Auflösung: `/choose-stack` § 0, andere
  Skills verweisen darauf. `just check` prüft, dass jeder genannte
  `${CLAUDE_PLUGIN_ROOT}/…`-Pfad existiert und Formatangaben, Marker und Optional-Blöcke
  zum MANIFEST passen.

## Frontmatter

Pflicht: `name`, `description`. Relevant außerdem:

| Feld | Wann |
|------|------|
| `disable-model-invocation: true` | Skills, die nur der Nutzer bewusst startet (z. B. prep-step, audit-code) — verhindert Auto-Aufruf durch das Modell. |
| `user-invocable: false` | Reine Hintergrund-Skills ohne Slash-Command (bisher keine). |
| `disallowed-tools` | Wenn ein Skill bestimmte Tools nie braucht/nutzen darf. |
| `default-enabled` | Nur setzen, wenn ein Skill opt-in sein soll. |

Ohne `disable-model-invocation: true` darf Claude den Skill selbst starten. Der Skill-Text
darf dem nicht widersprechen: nicht „der Nutzer hat …" oder „vorschlagen, den Skill
aufzurufen" formulieren, wenn Claude ihn direkt starten soll — sonst hält das Modell ihn
für nur manuell startbar.

Die `description` entscheidet, wann das Modell den Skill von sich aus zieht — präzise
formulieren, Trigger-Situationen nennen.

## Sprache

- **Skill-Texte, Doku, README: Deutsch** (das Kit ist primär für den Eigenbedarf).
- **Englisch ist ausschließlich, was in Projekte gelangt oder dort wirkt:** der
  Template-Inhalt (`template/**`, inkl. MANIFEST); Commit-Messages, die der Skill
  vorschlägt; Texte, die der Stop-Hook in beliebigen Projekten ausgibt; Inhalte, die in
  Projektdateien geschrieben werden (dort gilt die Sprache der lebenden Doku des
  Projekts).

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
- **Status-Marker-Konvention:** PROGRESS-Einträge tragen unter der Überschrift eine
  `**Status:**`-Zeile mit sprachinvariantem Token — `BACKLOG` (aufgenommen, setzt
  add-feature) → `PLANNED` (geplant, setzt prep-step; zusätzlich `(PLANNED)` im
  FEATURE-INDEX) → fertig = Done-Tabelle + `(DONE)` im Index (setzt step-done).
  Alt-Einträge ohne Status-Zeile tolerant lesen (Substeps vorhanden ≈ geplant) und
  die Zeile bei der nächsten Berührung nachziehen.
- **Freigabe-Gate (jeder Skill, der in die PROGRESS schreibt):** an der Schreibstelle den
  Standardsatz tragen — sinngemäß gleich in jedem Skill:

  > **Freigabe-Gate:** Jeder neue oder geänderte Eintrag in `PROGRESS.md`,
  > `PROGRESS-ARCHIVE.md` oder im FEATURE-INDEX wird zuerst als Vorschau gezeigt und erst
  > nach ausdrücklichem OK des Nutzers geschrieben (ausgenommen: genau der zuvor
  > freigegebene Text).

  Der Satz steht im Skill selbst, nicht nur hier: diese Doku liegt nicht im Plugin-Cache,
  Skills können sie zur Laufzeit nicht lesen. Fragen bündeln, wo es geht (step-done: eine
  Frage für Verbuchung und Commit). Im autonomen `/goal`-Lauf deckt die beim Start
  erteilte Lauf-Freigabe nur die Verbuchung der geplanten Substeps; neue Einträge werden
  gesammelt und am Ende vorgeschlagen.
- **Nie automatisch committen** — Commits werden vorbereitet und vorgeschlagen, der
  Nutzer entscheidet.

## Hilfsskripte

- **Was deterministisch sein muss, gehört in ein Skript, nicht in den Skill-Text:**
  Rendern, Mergen, Vergleichen — alles, was bei gleicher Eingabe gleich ausgehen muss und
  dessen Fehler (eine vergessene Zeile) niemand sähe. Der Skill zeigt die Ausgabe, berät
  und führt den Dialog; was das Skript kann, baut er nie selbst nach. Vorbild:
  `scripts/template-sync.sh` hinter new-project, update-conventions, choose-stack,
  choose-license und step-done.
- **Aufruf:** im Skill-Text als `${CLAUDE_PLUGIN_ROOT}/scripts/<name>.sh` nennen (der
  Validator prüft, dass es den Pfad gibt); in Shell-Befehlen den aufgelösten Pfad über
  `sh` aufrufen — die Variable gibt es dort nicht, und `sh` braucht kein Ausführungsrecht.
  Ergebnisse in ein frisches Temp-Verzeichnis, nie ungefragt ins Projekt.
- **Form:** POSIX sh mit Standardwerkzeugen (git, awk, sed …), kein Python-Zwang. Der
  Kopfkommentar beschreibt Befehle, Ausgabezeilen (tabulatorgetrennt) und Exit-Codes;
  geschrieben wird nur in die genannten Ordner.
- **Tests:** unter `tests/<name>/`, laufen unter dash und bash in `just check` (der
  Pre-Commit-Hook nur, wenn Skript, Template oder Tests sich ändern). Der Validator prüft
  `sh -n` und das Ausführungsrecht; die Versionsregel zählt `plugins/coding-kit/scripts/`
  zum Plugin-Inhalt.

## Versionierung & Test

- Jede inhaltliche Änderung am Plugin (Skills, Hooks, Skripte, Template): **Version in
  `plugins/coding-kit/.claude-plugin/plugin.json` über den gepushten Stand heben**
  (semver) und einen Eintrag in `plugins/coding-kit/CHANGELOG.md` schreiben; mehrere
  Commits dürfen sich eine unveröffentlichte Version teilen. Ändert sich Template-Inhalt,
  gehört er in den Abschnitt `### Template` des Eintrags. `just version-rule` prüft das
  vor jedem Commit und in der CI.
- Lokal testen: Eine Session im Kit-Repo läuft mit dem **installierten** Plugin. Neue
  Skill-Texte und Template-Inhalte testet man mit `claude --plugin-dir plugins/coding-kit`
  — die Kopie ersetzt das installierte Plugin für diese Session, und Skills wie Template
  kommen aus dem Arbeitsstand; weitere Änderungen holt `/reload-plugins` in die laufende
  Session. `claude plugin details coding-kit@xnyzer` zeigt das
  Komponenten-Inventar; frisch installierte Skills sind ggf. erst nach Session-Neustart
  sichtbar.
- `just check` validiert JSON/YAML-Syntax, Frontmatter-Pflichtfelder, Privacy-Regeln und
  den Vertrag zwischen Skills und Template — muss vor jedem Commit grün sein.
