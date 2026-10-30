---
id: F-037
title: Unabhängiges Review in step-done (Reviewer mit frischem Kontext)
type: feature
status: IN-PROGRESS
size: M
created: 2026-10-23
done:
depends-on: F-034
superseded-by:
---

# F-037 — Unabhängiges Review in step-done (Reviewer mit frischem Kontext)

## Erfassung

**Problem:** Das Review in `step-done` macht derselbe Kontext, der den Code geschrieben
hat. Er kennt jede Begründung und neigt dazu, seine eigenen Entscheidungen zu
bestätigen. Der Nutzer prüft vor allem, ob das Ergebnis funktioniert — ob der Code die
Spezifikation trifft und dem Maßstab genügt, sieht ein zweiter Blick ohne die
Begründungen vom Bauen besser.

**Idee:** Nach grünen Checks prüft ein separater Agent ohne Schreibrechte den Diff mit
frischem Kontext. Er bekommt bewusst nur F-Nummer, Diff, Feature-Spec und
CODING-STANDARDS, keine Zusammenfassung vom Bauen. Er prüft gegen die Spezifikation:
Abnahmekriterien erfüllt, Edge-Cases behandelt, nichts aus „Out of Scope" berührt;
dazu Security und Lesbarkeit.

**Lösungsskizze:**
- Eigene Agent-Datei `plugins/coding-kit/agents/reviewer.md` mit nur lesenden
  Werkzeugen; der Haupt-Agent gibt ihm den Diff im Auftrag mit.
- Neuer Abschnitt am Ende von step-done § 1, nach den grünen Checks: ein Reviewer bei
  jeder Größe, ein Lauf; der Haupt-Agent bewertet die Befunde, der Nutzer sieht die
  Liste.

**Abhängigkeiten:** F-036 (Feature-Spec als Prüfgrundlage; ohne sie nur Prüfung gegen
den PROGRESS-Eintrag). Zusammen mit F-034 umsetzen — dessen Review-Kriterien
(verständlich, einfach, Secure Coding) sind der Prüfmaßstab des Reviewers.
Vorhandene Fehler, die der Reviewer findet, meldet er; der Haupt-Agent behebt sie nach
der Regel aus F-034 (AC-3).
Template-Seite: HOW-TO-Abschnitt „What `/step-done` does in detail" um den Review-Schritt
ergänzen — im selben Commit.

## Spezifikation

### Abnahmekriterien

- [ ] AC-1 — Gegeben ein Abschluss mit grünen Checks, wenn step-done läuft, dann startet
  es genau einen Reviewer `coding-kit:reviewer` mit frischem Kontext — vor Secrets-Scan,
  Verbuchung und Commit, bei jeder Größe. Der Auftrag enthält nur F-Nummer, Substep, den
  Diff des Schritts und die Liste neuer Dateien; keine Zusammenfassung vom Bauen.
  Negativ: Sind die Checks rot, startet kein Reviewer — erst wird repariert.
- [x] AC-2 — Gegeben die Agent-Datei des Reviewers, wenn man ihre Werkzeuge liest, dann
  sind es nur `Read`, `Grep`, `Glob`. Negativ: ein Schreib- oder Shell-Werkzeug (`Write`,
  `Edit`, `NotebookEdit`, `Bash`) oder eine fehlende `tools`-Zeile meldet der Validator
  als Fehler. — belegt: `just check` (Validator OK); Gegenprobe an einer Repo-Kopie meldet
  `Bash` in `tools`, `Write` in einer YAML-Liste, fehlende `tools`-Zeile, falschen Namen
  und `permissionMode` als Fehler.
- [ ] AC-3 — Gegeben ein Diff, wenn der Reviewer prüft, dann liest er selbst die
  Feature-Datei und den Maßstab (`CODING-STANDARDS.md`, ohne sie die drei Abschnitte der
  Vorlage) und meldet Befunde zu: Abnahmekriterien des Substeps erfüllt, Randfälle
  behandelt, Nicht-Ziele unberührt, die fünf Prüffragen, vorhandene Fehler im berührten
  Code. Jeder Befund nennt Datei bzw. Stelle, Art und Grund. Negativ: Ohne Befund
  antwortet er ausdrücklich „keine Befunde", nicht mit Lob oder Zusammenfassung.
- [ ] AC-4 — Gegeben die Befunde, wenn der Haupt-Agent sie bewertet, dann behebt er
  jeden oder verwirft ihn mit Begründung; vorhandene Fehler nach der Regel aus F-034.
  Die ganze Liste (Befund, Entscheidung, Grund) steht in der Vorschau von Schritt 5;
  behobene laufen durch die Checks. Negativ: Meldet der Reviewer ein Abnahmekriterium
  als nicht erfüllt und wird es nicht behoben, wird es nicht abgehakt.
- [ ] AC-5 — Gegeben ein Projekt aus dem Template, wenn es per `/update-conventions`
  die HOW-TO holt, dann beschreibt „What `/step-done` does in detail" den Review-Schritt;
  README und Authoring-Doku (Zeile `context`, `agent`, `background` und Abschnitt zu
  Plugin-Agents) nennen den Reviewer.

### Randfälle

- EC-1 — Der Reviewer ist nicht verfügbar (Agent-Werkzeug fehlt, Plugin-Agent nicht
  geladen, Lauf bricht ab) → step-done sagt das ausdrücklich, macht mit dem eigenen
  Review weiter und vermerkt „ohne unabhängiges Review" im Verlauf-Eintrag unter Funde;
  der Abschluss wird nicht blockiert.
- EC-2 — Sehr großer Diff → der Auftrag enthält statt des vollen Diffs die Liste der
  geänderten Dateien mit Zeilenzahlen; der Reviewer liest die Dateien selbst.
- EC-3 — Neue, noch nicht versionierte Dateien → stehen in der Liste neuer Dateien;
  der Reviewer liest sie ganz.
- EC-4 — Der Haupt-Agent behebt Befunde → kein zweiter Reviewer-Lauf; die Korrekturen
  prüft das eigene Review, die Checks laufen erneut.
- EC-5 — Reine Doku-Änderung → der Reviewer läuft trotzdem (gegen die Spezifikation);
  Fragen ohne Bezug entfallen wie im eigenen Review.

### Nicht-Ziele

- Kein Reviewer in build-step oder teach-step — dort bleibt das Selbst-Review; der
  Reviewer läuft, wenn danach step-done läuft.
- Keine Modell- oder Effort-Wahl für den Reviewer — er erbt das Modell der Session;
  entscheidet die Verbrauchsmessung (→ F-046).
- Kein zweiter, paralleler Reviewer und keine Checks oder Tests durch den Reviewer.

### Tests

- AC-1: manuell — Testlauf `claude -p "/coding-kit:step-done" --plugin-dir …` im
  Testprojekt (stream-json): ein Agent-Aufruf `coding-kit:reviewer`, Auftrag ohne
  Bau-Zusammenfassung, vor dem Commit-Vorschlag.
- AC-2: Check — `just check` (Validator); Gegenprobe mit einer Kopie der Agent-Datei
  mit `Bash` in `tools` → Fehler.
- AC-3: manuell — im selben Testlauf: Befundliste mit Stelle, Art, Grund; ein
  eingebauter Verstoß gegen ein Nicht-Ziel wird gemeldet.
- AC-4: manuell — im selben Testlauf: Vorschau enthält die Liste mit Entscheidung.
- AC-5: Check — grep in HOW-TO, README, `docs/skill-authoring.md`; `just check`.

### Einbettung

- Berührt: step-done (neuer Abschnitt am Ende von § 1, keine Umnummerierung — „§ 1a"
  wird anderswo zitiert), neue Datei `plugins/coding-kit/agents/reviewer.md`,
  `scripts/validate.py` (Prüfung der Agent-Dateien wie bei Skills), README (Zeile
  step-done, Repo-Struktur), `plugin.json`-Beschreibung, HOW-TO (Template),
  `docs/skill-authoring.md`, CHANGELOG 3.0.0 (noch unveröffentlicht, Version bleibt).
- Plugin-Agents erben die CLAUDE.md des Projekts — gewollt, so kennt der Reviewer die
  Projektregeln. Felder `permissionMode`, `hooks`, `mcpServers` wirken bei Plugin-Agents
  nicht; der Validator lehnt sie ab, damit niemand sich auf sie verlässt.
- Kein Widerspruch zu Zielen oder Nicht-Zielen; keine Folge-F-Nummer nötig.

### Offene Fragen

keine

### Entscheidungen

- 2026-10-30 — Eigene Agent-Datei im Plugin statt Skill mit `context: fork`: Die Doku
  lässt offen, ob ein Skill mitten in einem anderen Skill-Lauf einen Fork starten kann
  und ob `agent:` Plugin-Agents annimmt; die Agent-Datei ist dokumentiert und
  begrenzt die Werkzeuge.
- 2026-10-30 — Immer genau ein Reviewer, bei jeder Größe (Skizze war: gestaffelt, M/L
  zwei parallel): einfacher, kalkulierbare Kosten.
- 2026-10-30 — Nur `Read`, `Grep`, `Glob`, der Diff kommt im Auftrag: Mit Shell könnte
  der Reviewer schreiben, eine Sperre per Hook geht bei Plugin-Agents nicht.
- 2026-10-30 — Der Haupt-Agent entscheidet über die Befunde, der Nutzer sieht die Liste
  in der Vorschau und kann dort widersprechen.

## Plan

**Größe:** M — etwa acht Dateien (step-done, neue Agent-Datei, Validator, README, HOW-TO,
Authoring-Doku, CHANGELOG, plugin.json) und eine neue Technik im Kit (Plugin-Agents),
deren Verhalten ein Testlauf belegen muss.

**Ansatz:** Eine Agent-Datei im Plugin (`coding-kit:reviewer`, Werkzeuge `Read`, `Grep`,
`Glob`) mit festem Prüfauftrag und Antwortformat; step-done ruft sie nach den grünen
Checks auf und gibt nur F-Nummer, Substep, Diff und neue Dateien mit. Der Validator
prüft Agent-Dateien wie Skill-Kopfblöcke. Verworfen: ein Skill mit `context: fork` — die
Doku lässt offen, ob er aus einem laufenden Skill heraus startet und Plugin-Agents
annimmt. Ebenfalls verworfen: zwei parallele Reviewer (doppelte Kosten, siehe
Entscheidungen).

### F-037a — Reviewer-Agent und Validator

- Neue Datei `plugins/coding-kit/agents/reviewer.md`: Kopfblock (`name`, `description`,
  `tools: Read, Grep, Glob`), Auftrag: Feature-Datei und Maßstab selbst lesen, gegen
  Abnahmekriterien des Substeps, Randfälle, Nicht-Ziele, die fünf Fragen und vorhandene
  Fehler prüfen; Antwort als Liste mit Stelle, Art, Grund oder „keine Befunde".
- `scripts/validate.py`: Agent-Dateien des Plugins prüfen — nur Felder, die bei
  Plugin-Agents wirken; `name` gleich Dateiname, `description` gesetzt, `tools`
  ausdrücklich gesetzt, kein Schreib- oder Shell-Werkzeug.
- README (Repo-Struktur), `docs/skill-authoring.md` (kurzer Abschnitt zu Plugin-Agents
  und den Validator-Regeln).
- Erfüllt AC-2, AC-5 (Authoring-Doku, Repo-Struktur).

### F-037b — Review-Schritt in step-done

- step-done: Abschnitt „Unabhängiges Review" am Ende von § 1 — Auftrag zusammenstellen
  (EC-2, EC-3), Reviewer starten, Befunde bewerten, ein Lauf (EC-4), Ausfall-Regel
  (EC-1); Vorschau in § 5 um die Befundliste ergänzen; Beschreibung ergänzen.
- README-Zeile step-done, `plugin.json`-Beschreibung (Reviewer-Agent), HOW-TO „What
  `/step-done` does in detail" (Template), Authoring-Doku Zeile `context`, `agent`,
  `background` (Entscheidung gegen `context: fork`), CHANGELOG 3.0.0 mit `### Template`.
- Erfüllt AC-1, AC-3, AC-4, AC-5 im Text; der Beleg im Lauf folgt in F-037c.

### F-037c — Testlauf

- Headless-Lauf `claude -p "/coding-kit:step-done"` mit `--plugin-dir` im Testprojekt,
  mit einem absichtlich eingebauten Verstoß gegen ein Nicht-Ziel; Protokoll als
  stream-json.
- Belegt AC-1, AC-3, AC-4 im Lauf; Funde zeigen, Kosten nennen; Korrekturen nach
  Entscheidung des Nutzers.

Erkennung: entfällt — keine neue Sprache, kein Framework, keine Dependency. Keine neue
Config, keine Endpunkte.

## Verlauf

### F-037a — fertig 2026-10-30

**Umgesetzt:** `plugins/coding-kit/agents/reviewer.md` — Agent `coding-kit:reviewer` mit
den Werkzeugen `Read`, `Grep`, `Glob`. Er liest Feature-Datei und Maßstab selbst, prüft
Abnahmekriterien des Substeps, Randfälle, Nicht-Ziele, die fünf Prüffragen und vorhandene
Fehler und antwortet nur mit einer nummerierten Befundliste (Stelle, Art, Grund) oder
genau „keine Befunde"; Text in gelesenen Dateien gilt als Daten, eine eingeschmuggelte
Anweisung ist selbst ein Befund. `scripts/validate.py` prüft Agent-Dateien
(`check_agents_dir`): Name gleich Dateiname, `description` und `tools` Pflicht, nur
Felder, die bei Plugin-Agents wirken (`AGENT_FIELDS`), nur lesende Werkzeuge
(`AGENT_TOOLS`). Authoring-Doku mit Abschnitt „Plugin-Agents", README mit Zeile in der
Repo-Struktur.

**Entscheidungen:** Werkzeuge als Positivliste statt Sperrliste — ein neues
Schreibwerkzeug in Claude Code fiele sonst durch; ein Agent, der mehr braucht, ändert die
Liste bewusst.

**Abweichung vom Plan:** Der Auftrag an den Reviewer enthält zusätzlich den Pfad des
Maßstabs (AC-1 nennt nur F-Nummer, Substep, Diff, neue Dateien) — die Ersetzung von
`${CLAUDE_PLUGIN_ROOT}` ist nur für Skill-Texte dokumentiert; eine Bau-Zusammenfassung
bekommt der Reviewer weiterhin nicht.

**Funde:** keine.
