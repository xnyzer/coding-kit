---
id: F-033
title: Betrieb ohne Graphiti absichern und Auto-Memory ablösen
type: feature
status: IN-PROGRESS
size: L
created: 2026-10-19
done:
depends-on:
superseded-by:
---

# F-033 — Betrieb ohne Graphiti absichern und Auto-Memory ablösen

## Erfassung

**Problem:** Graphiti ist in den Skills bereits weitgehend optional („ohne MCP still
überspringen"), aber nie systematisch geprüft. Zudem geht Wissen, das sonst in den Graph
gegangen wäre (Entscheidungen, gelöste Probleme, Lernprofil), ohne Graphiti ersatzlos
verloren.

**Idee:** Ein Audit stellt sicher, dass jeder Skill, der Installer und die Vorlagen ohne
Graphiti vollständig laufen. Optional bekommt das Kit einen Ersatzweg für das Wissen,
das sonst im Graph landet.

**Lösungsskizze:**
- Alle Graphiti-Stellen (Skills, globale Kit-Regeln, Template-Block, README) auf harte
  Kopplung prüfen — auch impliziten Text wie „erst den Graph fragen".
- Ersatz nur für Wissen ohne eigenen Ort: Entscheidungen, Nicht-Ziele und offene Fragen
  tragen nach F-036 Feature-Dateien und ADRs. Übrig bleiben u. a. Infra-Fakten (das
  Lernprofil von `teach-step` entfällt mit F-040). Ersatz ohne Graphiti ist die getrackte
  `docs/notes.md`, die das Template anlegt und die CLAUDE.md lädt. Die Auto-Memory ist in
  Projekten aus. update-conventions überträgt vorhandene Einträge und setzt auf Wunsch
  die Nutzer-Settings (Auto-Memory aus, Transkripte 365 Tage).
- Der Graphiti-Block der CLAUDE.md-Vorlage im Template (`template/core/CLAUDE.md`) ist
  mitbetroffen — im selben Commit.

**Abhängigkeiten:** F-036 (übernimmt den Großteil des Ersatzwegs). Thematische Nähe zu
F-029/F-030 (Graphiti) und F-032 (gleicher Grundsatz: optionale Infrastruktur wird
ausgewiesen übersprungen).

## Spezifikation

Grundsatz: Projekte sind austauschbar und laufen unabhängig vom Rechner, auf dem sie
entwickelt werden. Wissen, das ein Projekt braucht, liegt deshalb im Graph (von mehreren
Rechnern erreichbar) oder im Repo (reist mit git), nie in rechnerlokalen Ablagen wie der
Auto-Memory von Claude Code.

Bestandsaufnahme vom 2026-10-30: Der Installer kennt Graphiti nicht. Jede Lese- und
Schreibstelle der Skills steht unter „falls verfügbar“, der Template-Block ist optional,
Render-Tests decken Projekte mit und ohne Block ab. Eine harte Kopplung gibt es nicht.
Offen sind drei Lücken: kein Ersatz für Wissen ohne Ort im Repo, stilles Überspringen auch
bei einem Projekt mit Graphiti-Block (ein Wegweiser geht unbemerkt verloren), und
new-project schlägt auch auf Rechnern ohne Graphiti eine group_id vor.

### Abnahmekriterien

- [x] AC-1 — Gegeben die globalen Kit-Regeln (Zone `global-graphiti`), wenn man sie
  liest, dann regeln sie:
  - Die Ablage wählt das Projekt, nicht der Rechner: Projekt mit Graphiti-Block →
    Graphiti wie bisher; Projekt ohne Block → dasselbe Wissen in derselben Form in
    `docs/notes.md`.
  - `docs/notes.md` enthält nur Publizierbares; Privates gehört nach `private/` und
    bleibt bewusst lokal. Überholte Einträge werden ersetzt, nicht angehängt.
  - Ohne Graphiti gibt es keine Wegweiser je Feature; das leistet `features/INDEX.md`.
  - Projekt mit Block, aber Graphiti bei einem Schreibanlass nicht erreichbar → im
    Abschluss ein Satz, dass nicht geschrieben wurde, mit dem Text zum Nachtragen.
  - In Projekten nie die Auto-Memory von Claude Code nutzen.

  Negativ: Für das Schreiben steht kein „still überspringen“ mehr darin, und die
  Auto-Memory ist nirgends als Ablage genannt. — belegt: Zone gelesen (24 Zeilen), grep:
  „still“ nur noch beim Lesen, Auto-Memory nur als Verbot genannt;
  `template-sync.sh render-global` übernimmt die Zone; `just check` (Validator OK, 2181
  Skript-Tests).
- [ ] AC-2 — Gegeben ein frisch gerendertes Projekt, mit und ohne Graphiti, wenn man es
  liest, dann:
  - steht in `.claude/settings.json` `"autoMemoryEnabled": false`;
  - gibt es `docs/notes.md` (seed) mit einem kurzen Kopf: wofür die Datei da ist, was
    nicht hinein gehört;
  - importiert die Zone `claude-startup` der `CLAUDE.md` die Datei per
    `@docs/notes.md`, sodass Claude Code sie bei jedem Start lädt.

  Ein Bestandsprojekt bekommt alle drei per `/coding-kit:update-conventions`. Die
  `.claude/settings.json` des Kit-Repos hat die Zeile auch. Negativ: Das MANIFEST führt
  `docs/notes.md`, `just check` ist grün. Die vorhandene Auto-Memory-Notiz des Kit-Repos
  ist vorher nach Graphiti übertragen (nach OK) und wird nicht ungefragt gelöscht.
- [x] AC-3 — Gegeben ein Projekt mit Graphiti-Block und eine Session ohne Graphiti-MCP,
  wenn step-done ein Feature auf `DONE` setzt, dann ist die Verbuchung vollständig, und
  die Zusammenfassung meldet in einem Satz, dass der Wegweiser nicht geschrieben wurde,
  samt Text. Negativ: In einem Projekt ohne Graphiti-Block gibt es keine Meldung, keinen
  Fehler und keinen Wegweiser in `docs/notes.md`. Die übrigen Schreibstellen
  (new-project, go-public, `DROPPED`/`SUPERSEDED` in add-feature, prep-step,
  refine-requirements) verweisen auf dieselbe Regel; keine sagt fürs Schreiben „still
  überspringen“. — belegt: Headless-Lauf von step-done mit `--plugin-dir` und
  `--strict-mcp-config` in einem Testprojekt mit Graphiti-Block am 2026-11-01. Das
  Feature ging auf `DONE`, die Zusammenfassung meldete den fehlenden Wegweiser mit Text,
  `docs/notes.md` blieb unberührt. grep über die Skills: Jede Schreibstelle schreibt nur
  mit Block und meldet einen Ausfall; „still“ steht nur noch beim Lesen.
- [x] AC-4 — Gegeben eine Session ohne Graphiti-Werkzeuge, wenn new-project nach der
  group_id fragt, dann ist die Vorbelegung „kein Graphiti“, mit dem Hinweis auf
  `docs/notes.md` und darauf, wie sich der Block später nachrüsten lässt. Mit
  Graphiti-Werkzeugen bleibt der Projektname die Vorbelegung. Negativ: Wählt der Nutzer
  trotz fehlender Werkzeuge eine group_id, entsteht der Block, denn ein anderer Rechner
  kann Graphiti haben. — belegt: Trockenlauf von new-project ohne Graphiti-MCP am
  2026-11-01: Vorbelegung „kein Graphiti“ mit Hinweis auf `docs/notes.md` und das
  Nachrüsten. Den Fall mit Werkzeugen und die eigene group_id belegt der Skill-Text
  (§ 2, Frage 6).
- [x] AC-5 — Gegeben Template-Block, HOW-TO, README und die CLAUDE.md des Kits, wenn man
  sie liest, dann beschreiben sie den Weg ohne Graphiti so wie AC-1, und keiner nennt
  „still überspringen“ fürs Schreiben. Negativ: `just check` ist grün, und der
  CHANGELOG-Eintrag hat einen Abschnitt `### Template`. — belegt: Template-Block, HOW-TO
  und Kit-CLAUDE.md (F-033a) sowie der README-Abschnitt „Projektwissen: Graphiti oder
  `docs/notes.md`“ gelesen; grep ohne „still überspringen“ fürs Schreiben; `just check`
  (Validator OK, 2181 Skript-Tests); CHANGELOG 3.2.0 mit `### Template`.
- [ ] AC-6 — Gegeben ein Projekt, dessen Auto-Memory-Ordner auf diesem Rechner Einträge
  hat, wenn `/coding-kit:update-conventions` in diesem Projekt läuft (mit und ohne
  Graphiti-Block), dann findet es nur den Ordner dieses Projekts und zeigt je Eintrag ein
  Ziel:
  - Projektwissen → Graphiti mit der group_id des Projekts bzw. `docs/notes.md` (Ablage
    nach AC-1)
  - Privates → `private/`
  - Projektübergreifendes → Graphiti `main`; ohne Graphiti entscheidet der Nutzer
  - Überholtes oder schon im Repo Stehendes → nur löschen

  Nach Freigabe überträgt es die Einträge in der Form der Konvention und löscht danach
  die übertragenen Dateien. `MEMORY.md` und den Ordner löscht es, sobald er leer ist.
  Negativ: Ohne Freigabe wird nichts gelöscht. Ein Eintrag, dessen Ziel scheitert oder
  den der Nutzer zurückstellt, bleibt liegen und wird gemeldet. Ohne Auto-Memory-Ordner
  läuft der Schritt ohne Ausgabe durch.
- [ ] AC-7 — Gegeben ein Repo-Pfad, wenn das Kit den Auto-Memory-Ordner sucht, dann in
  dieser Reihenfolge:
  1. Der Ordner, den die laufende Session selbst nennt (solange ihre Auto-Memory an ist).
  2. `autoMemoryDirectory` aus den Settings, falls gesetzt.
  3. Der Name nach der Regel „jedes Zeichen außer A–Z, a–z, 0–9 wird zu `-`“, gebildet
     aus dem Hauptpfad des Repos (Worktrees teilen ihn) unter `~/.claude/projects/`.
  4. Sonst der Ordner, dessen Transkripte genau diesen Arbeitspfad nennen.

  Negativ: Findet keine Stufe einen Ordner, meldet der Schritt das und rät nicht. Nennt
  eine Stufe einen Ordner, den sich mehrere Projekte teilen, wird nichts gelöscht.
- [ ] AC-8 — Gegeben `/coding-kit:update-conventions global` (Teil G), wenn es läuft,
  dann bietet es für die Nutzer-Settings (`~/.claude/settings.json`, mit
  `CLAUDE_CONFIG_DIR` dort) zwei Werte an, je mit Grund und einzeln zu bestätigen:
  - `"autoMemoryEnabled": false` — Auto-Memory aus für alle Projekte, auch solche, die
    das Kit nicht pflegt; deren vorhandene Notizen bleiben liegen und werden nicht mehr
    geladen.
  - `"cleanupPeriodDays": 365` — Claude Code hebt die lokalen Transkripte ein Jahr statt
    30 Tage auf; sie sind der Rückweg für verlorene Graphiti-Episoden (F-030) und für
    die Ordnersuche (AC-7).

  Der README-Kasten „Was das Kit mit deinen globalen Claude-Einstellungen macht“ nennt
  beide Werte mit Grund. Negativ: Ohne Bestätigung wird nichts geschrieben, der nächste
  Lauf fragt wieder. Ein vorhandener Wert ab 365 Tagen oder ein schon abgeschaltetes
  Auto-Memory wird nur gemeldet. Alle übrigen Einträge der Settings bleiben unverändert,
  die Datei bleibt gültiges JSON.

### Randfälle

- EC-1 — Graphiti-MCP ist da, aber `add_memory` scheitert (Server aus) → wie ein
  fehlender MCP: ein Satz Meldung mit dem Text.
- EC-2 — Ein Projekt schaltet Graphiti später ein → `docs/notes.md` bleibt und wird
  weiter geladen; Neues geht in den Graph. Keine automatische Übertragung.
- EC-3 — Wissen ist privat (Hostname, IP) in einem Projekt ohne Graphiti → nach
  `private/`, nie nach `docs/notes.md`; der Privacy-Lint fängt Blocklist-Begriffe ab.
- EC-4 — Der Nutzer bittet in einem Projekt ohne Graphiti ausdrücklich, etwas zu
  speichern → `docs/notes.md`, in der Form der Konvention.
- EC-5 — Ein Projekt hat eigene Zeilen in `.claude/settings.json` → update-conventions
  zeigt die neue Zeile wie jede Änderung an einer managed Datei zur Bestätigung.
- EC-6 — `add_memory` meldet nur „queued“ → die Quelldatei wird erst gelöscht, wenn die
  Episode per `get_episodes` in der Gruppe sichtbar ist. Sonst bleibt sie liegen, und
  der nächste Lauf versucht es erneut.
- EC-7 — Pfad mit Umlauten oder anderen Nicht-ASCII-Zeichen, oder unter Windows eine
  andere Pfadform (`C:\…` gegenüber `/c/…`) → Stufe 3 aus AC-7 kann danebenliegen;
  Stufe 4 findet den Ordner über die Transkripte. Gibt es keine Transkripte mehr, meldet
  der Schritt den Fall.
- EC-8 — Die Auto-Memory liegt auf mehreren Rechnern → jeder Rechner hat seinen eigenen
  Ordner; update-conventions überträgt den des Rechners, auf dem es läuft.
- EC-9 — Ein Eintrag steht inhaltlich schon im Graph oder in `docs/notes.md` → nicht
  doppelt schreiben, nur löschen (nach Freigabe).
- EC-10 — Ein Projekt mit Graphiti → `docs/notes.md` gibt es trotzdem und wird geladen;
  sie bleibt meist beim Kopf. So ist ein späterer Wechsel ohne Umbau möglich.
- EC-11 — Die Nutzer-Settings fehlen → nach Bestätigung entsteht die Datei mit den
  bestätigten Werten. Sind sie kein gültiges JSON → melden, nichts schreiben.
- EC-12 — `cleanupPeriodDays` steht auf einem Wert unter 365 → der Wert wird gezeigt und
  nur nach Bestätigung geändert; ein höherer Wert bleibt.
- EC-13 — Jemand will die Auto-Memory global anlassen und lehnt in Teil G ab → in
  Projekten des Kits bleibt sie trotzdem aus, weil Projekt-Settings vor Nutzer-Settings
  gelten. Teil G sagt das beim Angebot; der globale Wert ist ein freiwilliges Extra für
  alles außerhalb der Kit-Projekte.

### Nicht-Ziele

- Kein Ersatz für projektübergreifendes Wissen (heute group `main`) ohne Graphiti.
- Keine Übertragung der Auto-Memory anderer Projekte oder anderer Rechner; jeder Lauf
  behandelt nur den Ordner des aktuellen Projekts auf dem aktuellen Rechner. Die
  Transkripte unter `~/.claude/projects/` werden nur gelesen, nie geändert.
- Keine Übertragung der Auto-Memory von Projekten, die update-conventions nicht pflegt;
  ihre Notizen bleiben auf der Platte und werden nach dem Abschalten nicht mehr geladen.
- Kein Erkennen oder Nachschreiben verlorener Episoden (→ F-030).

### Tests

- AC-1: Check — Zone lesen, grep: kein „still überspringen“ fürs Schreiben, kein
  Auto-Memory-Verweis als Ablage; `template-sync.sh render-global` übernimmt die Zone;
  `just check`.
- AC-2: automatisch — neue Checks in `tests/template-sync/render.sh`: gerendertes
  Projekt mit und ohne Graphiti hat `autoMemoryEnabled` in `.claude/settings.json`,
  `docs/notes.md` und den Import in `CLAUDE.md`; `just check` (MANIFEST-Vertrag, JSON
  gültig). Manuell: in einer Session im gerenderten Projekt zeigt `/context` die Datei
  unter den geladenen Dateien; Kit-Repo-Settings gelesen, Notiz in Graphiti.
- AC-3: manuell — Headless-Lauf `claude -p` mit `--plugin-dir plugins/coding-kit` ohne
  MCP (`--strict-mcp-config`) an einem Testprojekt mit Graphiti-Block: Status `DONE`,
  Meldung in der Ausgabe. Check: grep über die Skills nach `add_memory` und „still“.
- AC-4: manuell — new-project § 2 lesen; Trockenlauf (`dry-run`) in einer Session ohne
  Graphiti-MCP, falls er die Frage ohne Interaktion zeigt.
- AC-5: Check — grep in Template-Block, HOW-TO, README, Kit-CLAUDE.md; `just check`;
  CHANGELOG gelesen.
- AC-6: manuell — update-conventions an einem Testprojekt mit angelegter Auto-Memory (je
  ein Eintrag Projektwissen, Privates, Übergreifendes), mit und ohne Graphiti; danach
  Ordner leer bzw. Zurückgestelltes noch da. Dazu die Notiz des Kit-Repos als erster
  echter Fall.
- AC-7: automatisch — Skript-Tests: Namensregel (Schrägstrich, Leerzeichen, Klammern,
  Punkt, Unterstrich, Windows-Pfad), `autoMemoryDirectory`, Suche über Transkripte, kein
  Ordner. Manuell: Abgleich mit allen Ordnern dieses Rechners (vor der Planung: 29 von 29
  Ordnern mit Transkript passen zur Regel).
- AC-8: manuell — update-conventions global mit `CLAUDE_CONFIG_DIR` auf einem
  Testordner, drei Fälle: Settings fehlen, Wert unter 365, beide Werte schon gesetzt;
  danach Settings gelesen und als JSON geprüft. README-Kasten gelesen.

### Einbettung

- Berührt:
  - Kit-Regeln `plugins/coding-kit/global/coding-kit.md`, Zone `global-graphiti`
  - Template: `core/.claude/settings.json`, neu `core/docs/notes.md` (seed),
    `core/CLAUDE.md` (Zonen `claude-graphiti` und `claude-startup`),
    `core/HOW-TO-CODE-WITH-CLAUDE.md`, MANIFEST (Zeile für `docs/notes.md`)
  - Skills mit Schreibstelle: step-done, new-project, go-public, add-feature,
    prep-step, refine-requirements; new-project zusätzlich die group_id-Frage
  - update-conventions Teil G: Nutzer-Settings `autoMemoryEnabled` und
    `cleanupPeriodDays` (AC-8)
  - update-conventions: neuer Schritt Auto-Memory übertragen (Projektmodus); prüfen,
    ob neue Seed-Dateien schon angeboten werden, sonst legt dieser Schritt
    `docs/notes.md` an
  - `plugins/coding-kit/scripts/template-sync.sh`: Auto-Memory-Ordner des Projekts
    finden (AC-7), mit Tests
  - `docs/skill-authoring.md` (Baustein „Graphiti schreiben“), README
  - Kit-Repo: `.claude/settings.json`, Graphiti-Block der CLAUDE.md (nicht die
    Ziel-Abschnitte). Das Kit nutzt Graphiti und bekommt keine `docs/notes.md`.
  - CHANGELOG und `plugin.json`: neue Version über dem gepushten 3.1.0
- Kommt in Projekten an: Kit-Regeln per `/coding-kit:update-conventions global`,
  Template-Dateien und Zonen per normalem Sync.
- F-029: Die Zone wächst über die 15 Zeilen aus F-029 AC-2 hinaus; F-029 bleibt erfüllt,
  F-033 erweitert die Regel (Entscheidung unten). Die Nachmessung F-029d ändert sich
  nicht, die Zahl der Schreibvorgänge bleibt gleich.
- F-032: gleicher Grundsatz, optionale Infrastruktur wird ausgewiesen übersprungen.
- F-030: Der Teil `cleanupPeriodDays` wandert nach F-033 (AC-8), statt über `install.sh`
  mit F-025. F-030 behält die Erfolgskontrolle der Episoden; Erfassung und empfohlene
  Reihenfolge ziehen nach.
- F-027 (Windows): Die Skripte laufen dort erst mit F-027; die Namensregel deckt
  Windows-Pfade schon ab.
- Kein Widerspruch zu Zielen, Nicht-Zielen oder Rahmenbedingungen.

### Offene Fragen

keine

### Entscheidungen

- 2026-10-30 — Ohne Graphiti geht Wissen ohne Ort im Repo in die getrackte Datei
  `docs/notes.md`. Empfehlung war zuerst die Auto-Memory, dann „kein eigener Speicher“;
  entschieden ist die Notizdatei, weil Projekte rechnerunabhängig sein sollen und das
  Wissen mit git reisen soll. Auto-Memory und `private/` scheiden aus, weil sie nur auf
  einem Rechner liegen.
- 2026-10-30 — Die Auto-Memory von Claude Code ist in Projekten abgeschaltet, per
  `autoMemoryEnabled: false` in der Projekt-Settings-Datei. Grund wie oben; eine Regel
  allein hielte Claude Codes eigene Anweisungen nicht auf.
- 2026-10-30 — Die Auto-Memory per `autoMemoryDirectory` ins Repo umzuleiten ist
  verworfen. Gründe: Der Wert muss ein absoluter oder `~/`-Pfad sein, wäre also je
  Rechner einzutragen. Bei `blockReadsOutsideWorkingDirectories` fällt er still aus. Die
  Auto-Memory speichert auch Persönliches (Rolle, Erfahrung) und brächte es in ein
  publizierbares Repo. Settings gelten fest ab Sessionstart, ein Wechsel je nach
  Erreichbarkeit von Graphiti geht nicht.
- 2026-10-30 — Die Template-CLAUDE.md importiert `docs/notes.md` (Variante B), statt dass
  eine Regel das Lesen zu Sessionbeginn verlangt. Grund: Claude Code lädt die Datei so
  sicher bei jedem Start; das Template legt sie an, deshalb fehlt sie nie.
- 2026-10-30 — Die Ablage wählt das Projekt (Graphiti-Block ja oder nein), nicht der
  Augenblick. So verteilt sich Wissen nicht je nach Rechner auf zwei Ablagen; ein
  Ausfall wird gemeldet statt umgeleitet.
- 2026-10-30 — Schreiben meldet einen Ausfall in einem Satz, Lesen bleibt still. Grund:
  Nur beim Schreiben geht etwas verloren.
- 2026-10-30 — Kein Ersatz für projektübergreifendes Wissen ohne Graphiti.
- 2026-10-30 — Die Auto-Memory ist in jedem Projekt per Projekt-Settings aus, auch wenn
  jemand sie global anhaben will (Wunsch des Nutzers); Projekt-Settings gelten vor
  Nutzer-Settings. Teil G bietet zusätzlich die globale Abschaltung an, als freiwilliges
  Extra für alles außerhalb der Kit-Projekte.
- 2026-10-30 — `cleanupPeriodDays: 365` kommt aus F-030 hierher, weil es derselbe
  Schritt in Teil G ist (Nutzer-Settings, Bestätigung, README-Kasten). Der Nutzer will
  die Änderung transparent: README und eine eigene Bestätigung im Lauf.
- 2026-10-30 — update-conventions überträgt die vorhandene Auto-Memory des aktuellen
  Projekts in die neue Ablage und löscht sie danach (Wunsch des Nutzers). Gelöscht wird
  nur nach Freigabe und erst, wenn das Ziel den Eintrag nachweislich hat.
- 2026-10-30 — Den Ordner findet das Kit selbst (AC-7), weil Claude Code ihn nach dem
  Abschalten nicht mehr nennt. Die Namensregel ist nicht offiziell dokumentiert;
  Fehlerberichte nennen dieselbe Regel für Linux und Windows, aber Abweichungen bei
  Nicht-ASCII-Zeichen und Pfadformen. Deshalb die Suche über die Transkripte als
  Rückfall.

## Plan

**Größe:** L. Aufwand (etwa 18 Dateien) und Reichweite (Kit-Regeln, Template und
Nutzer-Settings wirken auf alle Projekte und Rechner) liegen über M; dazu ist die
Namensregel der Auto-Memory-Ordner nicht offiziell dokumentiert.

**Ansatz:** Die Ablage folgt dem Projekt: Graphiti mit Block, sonst `docs/notes.md`, die
das Template anlegt und die CLAUDE.md per Import lädt. Die Auto-Memory ist in jedem
Projekt per Projekt-Settings aus; Teil G bietet zusätzlich die Nutzer-Settings an
(Auto-Memory aus, Transkripte 365 Tage). Das Mechanische liegt im Skript, mit Tests:
den Auto-Memory-Ordner finden und zwei Schlüssel der Nutzer-Settings lesen und setzen.
Das Urteil liegt im Skill: welcher Eintrag wohin gehört, was gemeldet wird. Gelöscht wird
nur nach Freigabe und erst, wenn das Ziel den Eintrag nachweislich hat.

Verworfen:
- **Auto-Memory per `autoMemoryDirectory` ins Repo umleiten:** nur absolute Pfade, fällt
  bei `blockReadsOutsideWorkingDirectories` still aus, bringt Persönliches ins Repo
  (siehe Entscheidungen).
- **Nutzer-Settings von Claude per Edit-Werkzeug ändern lassen:** Ohne Python oder `jq`,
  die das Kit auf fremden Rechnern nicht voraussetzt, ließe sich die Gültigkeit der
  Datei danach nicht prüfen. Das Skript ändert nur zwei Schlüssel der obersten Ebene und
  bricht bei allem Unerwarteten ab.
- **Den Ordner nur nach der Namensregel bilden:** trifft bei Umlauten und
  Windows-Pfadformen daneben; deshalb die Suche über die Transkripte als Rückfall.

### F-033a — Ablage-Regel, Template und Kit-Repo

- Kit-Regeln, Zone `global-graphiti`:
  - Ablage je Projekt.
  - Form der Einträge in `docs/notes.md`.
  - Privates nach `private/`.
  - Keine Wegweiser ohne Graphiti.
  - Ausfall bei einem Schreibanlass melden.
  - Keine Auto-Memory in Projekten.
- Template:
  - `core/.claude/settings.json` mit `"autoMemoryEnabled": false`.
  - Neu `core/docs/notes.md` (seed) mit kurzem Kopf, dazu eine MANIFEST-Zeile.
  - Zone `claude-startup` mit `@docs/notes.md`.
  - Zone `claude-graphiti`: „melden“ statt „still überspringen“.
  - HOW-TO, Schritt 4 der Einrichtung und Schritt 6 von step-done.
- update-conventions: Eine neue Seed-Datei, die das Projekt nie hatte (keine Seed-Basis),
  wird zum Anlegen angeboten statt nur gemeldet. Den genauen Weg im Skript beim Bau
  prüfen.
- Render-Tests: Settings-Zeile, `docs/notes.md` und Import, je mit und ohne Graphiti.
- Kit-Repo:
  - `.claude/settings.json` mit `"autoMemoryEnabled": false`.
  - Graphiti-Block der CLAUDE.md: „melden“ statt „still überspringen“.
  - Die vorhandene Auto-Memory-Notiz vorher nach Graphiti (`coding-kit`) übertragen, per
    `get_episodes` prüfen und erst dann löschen, nach OK.
- Manuell: In einer Session im gerenderten Projekt zeigt `/context` die Datei
  `docs/notes.md` unter den geladenen Dateien.
- Version 3.2.0 in `plugin.json`, CHANGELOG mit `### Template`.
- Erfüllt AC-1 und AC-2, von AC-5 Template-Block, HOW-TO und die Kit-CLAUDE.md.

### F-033b — Skills melden Ausfälle, new-project fragt nach Verfügbarkeit

- Schreibstellen auf die Regel umstellen: „sonst melden“ statt „still überspringen“.
  Betroffen sind step-done § 6, new-project § 4g, go-public und die Wegweiser bei
  `DROPPED`/`SUPERSEDED` in add-feature, prep-step und refine-requirements. Die
  Lesestellen bleiben still.
- new-project, Frage 6:
  - Die Vorbelegung richtet sich danach, ob die Session Graphiti-Werkzeuge hat.
  - Ohne Graphiti ein Hinweis auf `docs/notes.md` und auf das spätere Nachrüsten über
    `OPTIONAL` in update-conventions. Den Weg beim Bau prüfen.
- `docs/skill-authoring.md`: Baustein „Graphiti schreiben“ um die Meldung ergänzen.
- README: der Weg ohne Graphiti.
- Testlauf: `claude -p` mit `--plugin-dir plugins/coding-kit` und `--strict-mcp-config`
  ohne MCP, an einem Testprojekt mit Graphiti-Block. step-done setzt das Feature auf
  `DONE`; erwartet sind ein vollständiger Abschluss und eine Meldung. Dazu new-project
  im Trockenlauf.
- Erfüllt AC-3 und AC-4, den Rest von AC-5.

### F-033c — Ordnersuche und Nutzer-Settings im Skript, Teil G

- `template-sync.sh`, zwei neue Befehle (Namen beim Bau festlegen):
  - **Ordner finden** (AC-7, Stufen 2–4):
    - Hauptpfad des Repos über `git rev-parse --git-common-dir`.
    - `autoMemoryDirectory` aus Nutzer-, Projekt- und lokalen Settings.
    - Namensregel.
    - Suche nach `"cwd"` in den Transkripten.

    Ausgabe: Ordner und Stufe, oder `none`. Stufe 1 (die Session nennt den Ordner) liegt
    beim Skill.
  - **Nutzer-Settings:** `autoMemoryEnabled` und `cleanupPeriodDays` lesen
    (`missing`, Wert, `invalid`) und setzen. Ändert nur diese beiden Schlüssel der
    obersten Ebene, legt eine fehlende Datei an und bricht bei ungültigem JSON ab.
- Tests unter dash und bash, mit System-awk und mawk:
  - Namensregel: Schrägstrich, Leerzeichen, Klammern, Punkt, Unterstrich, Windows-Pfad.
  - Worktree.
  - `autoMemoryDirectory` mit `~/`.
  - Transkript-Suche, kein Ordner.
  - Settings: fehlen, leer, verschachtelt, Schlüssel schon da, ungültig.
- update-conventions Teil G: neuer Schritt nach dem Abgleich der Regeln. Beide Werte
  einzeln mit Grund anbieten, beim Auto-Memory-Angebot den Hinweis aus EC-13. Gesetzte
  Werte nur melden. Im Modus `status` nur berichten.
- README-Kasten „Was das Kit mit deinen globalen Claude-Einstellungen macht“: beide Werte
  mit Grund.
- Manuell: Teil G mit `global <testordner>`, drei Fälle aus den Tests zu AC-8.
- Erfüllt AC-7 und AC-8.

### F-033d — Auto-Memory übertragen in update-conventions

- Neuer Schritt im Projektmodus, nach dem Abgleich der Dateien:
  - Ordner finden: Stufe 1 aus dem Session-Kontext, sonst das Skript aus F-033c.
  - Einträge lesen und je Eintrag ein Ziel vorschlagen: Graphiti-Gruppe des Projekts,
    `main`, `docs/notes.md`, `private/` oder nur löschen. Dazu erkennen, was schon im
    Graph oder in `docs/notes.md` steht.
  - Eine gemeinsame Freigabe mit Änderungsmöglichkeit je Eintrag.
  - Schreiben in der Form der Konvention.
  - Graphiti-Einträge per `get_episodes` prüfen, erst dann die Quelldatei löschen.
    `MEMORY.md` und den Ordner löschen, sobald er leer ist.
  - Zurückgestelltes und Gescheitertes melden. Bei einem geteilten Ordner nichts
    löschen.
- Testlauf an einem Testprojekt mit angelegter Auto-Memory: je ein Eintrag Projektwissen,
  Privates und Übergreifendes, einmal mit und einmal ohne Graphiti-Block. Danach ist der
  Ordner leer bzw. Zurückgestelltes noch da. Die Testgruppe in Graphiti wird nach OK
  gelöscht.
- Danach Release 3.2.0; der Push erfolgt nur auf Bitte.
- Erfüllt AC-6.

**Erkennung (Schritt 2a):** entfällt. Es kommen keine Frameworks, Dependencies oder
Sprachen dazu; die Skript-Teile bleiben POSIX-Shell und awk. Neue Config, Endpunkte oder
Dependencies gibt es nicht. Gelesen werden `CLAUDE_CONFIG_DIR` und die Settings von
Claude Code.

## Verlauf

### F-033a — fertig 2026-11-01

**Umgesetzt:**

- Kit-Regeln, Zone `global-graphiti`, jetzt „Graphiti Memory und Projektnotizen“:
  - Die Ablage richtet sich nach dem Projekt: mit Graphiti-Block der Graph, sonst
    `docs/notes.md`.
  - Es gibt Form-Regeln für beide Ablagen.
  - Ist der Graph bei einem Schreibanlass nicht erreichbar, meldet Claude das, statt
    still zu überspringen.
  - In Projekten wird keine Auto-Memory genutzt.
- Template:
  - `docs/notes.md` ist neu (seed, Zone `notes-head`).
  - Die Zone `claude-startup` importiert sie per `@docs/notes.md`.
  - `.claude/settings.json` setzt `"autoMemoryEnabled": false`; `.claude/README.md`
    erklärt den Grund.
  - Die Zone `claude-graphiti` und die HOW-TO sind angepasst.
  - Das MANIFEST führt Datei, Zone und den Fall „neue Seed-Datei“.
- `template-sync.sh zones` kennt den Zustand `new-file`: Die Seed-Datei fehlt im
  Projekt, und es gibt keine Seed-Basis. Das Ergebnis ist dann die ganze Datei aus dem
  Render. update-conventions bietet sie zum Anlegen an (Schritt 7, Seed-Basen in
  Schritt 9).
- Tests:
  - Zonen: neue Datei, gelöschte Datei mit Basis, Auswahl per Name, Fragment in einer
    fehlenden Datei.
  - Render mit und ohne Graphiti: Settings-Zeile, Notizdatei und Import.
- Kit-Repo:
  - Die Auto-Memory ist aus, der Graphiti-Block der CLAUDE.md ist angepasst.
  - Die vorhandene Auto-Memory-Notiz liegt jetzt in Graphiti (`main`); ihr Ordner ist
    gelöscht.
- Headless-Test in einem gerenderten Projekt: Die Session kannte ein Testwort aus
  `docs/notes.md`, ohne ein Werkzeug zu nutzen, und hatte keinen Auto-Memory-Abschnitt.
- Version 3.2.0, CHANGELOG mit `### Template`.

**Entscheidungen:**

- `docs/notes.md` hat eine Zone `notes-head`, wie `features/INDEX.md`. So kann das Kit
  den Erklärtext nachziehen, und Bestandsprojekte bekommen die Datei über den
  Zonen-Abgleich.
- `new-file` gilt nur für Zonen in Seed-Dateien. Ein Fragment in einer fehlenden Datei
  bleibt `no-file`: Die Datei ist managed, und der Merge legt sie an.
- Die Regel „fehlt die group_id: im Graph suchen, sonst fragen und eintragen“ entfällt.
  Ohne Block gilt `docs/notes.md`; gefragt wird nur, wenn Datei oder Import fehlen.
- Die Notiz des Kit-Repos ging nach `main`, weil sie für alle Projekte gilt.

**Abweichung vom Plan:**

- Die Zone `notes-head` und der Skript-Zustand `new-file` kamen dazu; der Plan hatte den
  Weg offengelassen.
- Die Notiz ging nach `main` statt nach `coding-kit`.
- Statt `/context` lief eine Headless-Frage an die Session.

**Funde:**

- Die Projekt-Settings schalten die Auto-Memory auch in einem Ordner ab, dem Claude Code
  noch nicht vertraut. Die Rechte-Liste derselben Datei ignoriert es dort.
- Ein älteres Projekt ohne Seed-Basen bekommt eine selbst gelöschte Seed-Datei einmal
  erneut angeboten. Dauerhaft ablehnen geht mit einer `skip`-Zeile.
- Unabhängiges Review: zwei Befunde, beide behoben (Fehlermeldung im Skript, Erklärung in
  `.claude/README.md`).

### F-033b — fertig 2026-11-01

**Umgesetzt:**

- Sechs Skills schreiben nur noch mit Graphiti-Block in den Graph: step-done § 6,
  new-project § 4g, go-public § 5 sowie die Wegweiser bei `DROPPED`/`SUPERSEDED` in
  add-feature, prep-step und refine-requirements. Ist der Graph nicht erreichbar, melden
  sie in einem Satz, was fehlt, mit dem Text zum Nachtragen. Die Kontext-Schritte von
  step-done, go-public und prep-step trennen Lesen (still) und Schreiben (melden).
- new-project, Frage 6: Mit Graphiti-Werkzeugen ist der Projektname vorbelegt, sonst
  „kein Graphiti“. Dazu kommen der Hinweis auf `docs/notes.md` und der Weg zum späteren
  Nachrüsten; eine eigene group_id bleibt erlaubt.
- `docs/skill-authoring.md`: Der Baustein „Graphiti schreiben“ nennt die Meldung, der
  Projektkontext-Schritt nur noch das stille Lesen.
- README: neuer Abschnitt „Projektwissen: Graphiti oder `docs/notes.md`“.
- Testläufe mit `--plugin-dir` und `--strict-mcp-config`: step-done in einem
  Testprojekt mit Graphiti-Block (0,57 US-Dollar) und new-project im Trockenlauf
  (0,45 US-Dollar).

**Entscheidungen:**

- Lesestellen bleiben still (build-step, teach-step, add-feature beim Nachschlagen). Nur
  beim Schreiben geht etwas verloren.
- Nachrüsten von Graphiti läuft über die Antworten in update-conventions (`graphiti` in
  `OPTIONAL`, `GROUP_ID`); ein eigener Weg ist nicht nötig.

**Abweichung vom Plan:**

- In prep-step ist zusätzlich der Kontext-Schritt präzisiert, weil prep-step auch
  schreibt.
- Der Gegenfall von AC-3 (ohne Block keine Meldung) und der Fall von AC-4 mit
  Graphiti-Werkzeugen sind nur am Skill-Text belegt, nicht durch eigene Läufe.

**Funde:**

- Mit `--strict-mcp-config` sieht eine Session auch die Graphiti-Verbindung über
  claude.ai nicht. Damit lässt sich ein Betrieb ohne Graphiti zuverlässig testen.
- Unabhängiges Review: ein Befund (Verweis in go-public), behoben.
