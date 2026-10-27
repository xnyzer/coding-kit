# Changelog

Eine Version für Plugin und Template, seit 1.0.0
(`plugins/coding-kit/.claude-plugin/plugin.json`, semver). Jede inhaltliche Änderung an
Skills, Hooks, Skripten oder Template bumpt die Version und bekommt hier einen Eintrag;
`scripts/version-rule.py` prüft das vor jedem Commit und in der CI.

- **`### Template`:** Ändert ein Release Template-Inhalt (`template/`), beschreibt dieser
  Abschnitt, was in Projekten ankommt — `/update-conventions` zeigt ihn als
  Update-Fenster. Fehlt er, betrifft das Release Projekte nicht.
- **Eingefrorene Abschnitte** unten stammen aus der Zeit getrennter Repos und werden nicht
  mehr geändert. Stempel unter 1.0.0 (`.claude/template-version`) gehören zur alten
  Template-Reihe und lesen nur „project-template bis 0.16.0"; Aufgaben-Nummern des
  Templates heißen dort `TPL-NNN`.

## 1.7.0 — unveröffentlicht

Neue Zonen erreichen bestehende Projekte und Rechner (F-049, in Arbeit).

- **`scripts/template-sync.sh zones`** unterscheidet über eine Basis, ob eine fehlende
  Zone neu ist oder abgewählt wurde. Neue Zustände: `new` auch für Zonen (weder in der
  Datei noch in der Basis — etwa eine neue Kit-Zone oder `claude-graphiti`, nachdem
  Graphiti eingeschaltet wurde), `unconfirmed` (die Datei hat noch keine Basis) und
  `removed` (die Zone steht in Datei und Basis, das Template hat sie entfernt; mit
  Override-Zeile bleibt sie `local`). `opted-out` heißt jetzt: Die Basis kennt die Zone.
  Eine neue Zone setzt das Skript hinter ihren nächsten Vorgänger aus dem Render, ohne
  Vorgänger vor den nächsten Nachfolger, ohne beide ans Dateiende; eine entfernte löscht
  es samt Inhalt. Ohne Namen wendet es `differs`, `new` und `removed` an, `opted-out` und
  `unconfirmed` nur per Name — so lässt sich eine abgewählte Zone zurückholen. Die
  Zählung bei geschützten Blöcken gilt jetzt auch für Zonen.
- **`snapshot --seeds`** setzt die Basis von seed-Dateien als `<Ziel>.seed`; `status`,
  `merge` und `changed` lesen sie nicht. `zones` liest `.base`, sonst `.seed`.
- **`update-conventions`** bietet die neuen Zustände an: eine neue Zone **einsetzen**
  oder **nicht einsetzen** (dann gilt sie als abgewählt — ein „diesmal nicht" gibt es
  dafür nicht), eine gestrichene **entfernen** oder **behalten**, eine Zone ohne Basis
  einmal erfragen, eine abgewählte auf Wunsch zurückholen (Lauf mit dem Namen); bei
  geschützten Zonen zeigt er die Template-Änderung seit dem letzten Sync zur Info.
  Schritt 9 setzt die Seed-Basen in jedem Lauf, auch wenn Zonen abgelehnt wurden. Für
  die globalen Kit-Regeln (Teil G) gilt dasselbe; ihre Basis im Datenordner gibt es
  schon.
- **`new-project`** setzt die Seed-Basen beim Anlegen mit.
- **Text ohne Marker (`bare`, Fund aus dem ersten Testlauf):** Wer eine Zone abwählt,
  löscht ihr Markerpaar und behält meist den Text. Steht der Inhalt einer fehlenden Zone
  wörtlich außerhalb aller Zonen in der Datei und kennt die Basis sie nicht, meldet
  `zones` sie als `bare`; per Name legt das Skript nur die Marker um den Text, statt die
  Zone ein zweites Mal einzusetzen — ebenso beim Zurückholen einer abgewählten Zone.
  Fehlen einer Datei alle Marker, gilt eine Zone, die die Basis kennt, als `opted-out`
  statt `unmarked`. update-conventions bietet `bare` als **Marker setzen** / **so
  lassen** an; die Marker-Migration von Hand (A3) bleibt für Text, der sich geändert
  hat.
- **Kit:** Tests für neue, abgewählte, entfernte und umbenannte Zonen, Dateien ohne
  Basis, alle Einsetz-Stellen, die Auswahl per Name, `snapshot --seeds`, Graphiti nach
  dem Einschalten und eine neue Zone in den globalen Regeln.

### Template

- MANIFEST § Base snapshot: seed-Dateien mit Zonen bekommen eine eigene Basis
  (`<Ziel>.seed` unter `.claude/template-base/`), die nur der Zonen-Abgleich liest.
- MANIFEST § Seed sections: neue, abgewählte und entfernte Zonen und wo eine neue Zone
  eingesetzt wird. Projekte ohne diese Basis werden einmal je fehlender Zone gefragt;
  steht der Text einer Zone noch ohne Marker da, bekommt er auf Wunsch nur seine Marker
  zurück.

## 1.6.0 — 2026-10-27

Globale Kit-Regeln mit dem Plugin ausliefern und abgleichen, Erklär-Niveau (F-040);
Frontmatter-Pflichtfelder für alle Skills (F-048).

**Nach dem Update:** Wer die frühere Kit-Vorlage in `~/.claude/CLAUDE.md` hat, bekommt
beim nächsten Session-Start einen Hinweis. `/coding-kit:update-conventions global`
richtet dann die Kit-Regeln in `~/.claude/rules/coding-kit.md` ein und nimmt — nach
Bestätigung und mit Diff — den Kit-Teil aus der CLAUDE.md; persönliche Zeilen bleiben.
Bis dahin bleibt alles wie bisher. Eine selbst angelegte CLAUDE.md fasst das Kit nicht
an, und wer die Kit-Regeln nicht einrichtet, merkt vom Update nichts.

- **`global/coding-kit.md` (neu):** die globalen Regeln des Kits. Bisher lagen sie als
  Vorlage `templates/global-CLAUDE.md` im Repo-Root, die nur `install.sh` einmal nach
  `~/.claude/CLAUDE.md` kopierte. Jetzt kommen sie mit dem Plugin auf den Rechner und
  werden nach `~/.claude/rules/coding-kit.md` gerendert, das Claude Code in jeder Session
  lädt; `~/.claude/CLAUDE.md` bleibt allein dem Nutzer. Die Abschnitte sind
  `section:`-Zonen (`global-head` mit dem Kommentar für Menschen und dem Titel,
  `global-language`, `global-explain`, `global-git`, `global-graphiti`,
  `global-workflow`). Inhalt wie die Vorlage plus die Regel, nichts ohne ausdrückliche
  Erlaubnis als Artifact zu veröffentlichen; neu ist der Abschnitt Erklär-Niveau mit den
  Stufen `einsteiger`, `junior`, `fortgeschritten` und `senior` und einer freien Notiz.
  Antwortsprache, Stufe und Notiz kommen aus der Personal-Config
  (`CODING_KIT_REPLY_LANGUAGE`, `CODING_KIT_EXPLAIN_LEVEL`, `CODING_KIT_EXPLAIN_NOTE`);
  ohne Wert entfällt die Zeile.
- **`/coding-kit:update-conventions global` (Teil G):** richtet die Kit-Regeln auf dem
  Rechner ein und gleicht sie je Abschnitt über `zones` ab, auch außerhalb eines Projekts;
  jeder andere Lauf prüft sie einmal mit, sobald sie eingerichtet sind. Fehlen Werte,
  startet er `explain-level`; die env-Datei selbst gibt er nicht aus. Eine alte Kit-Kopie
  in `~/.claude/CLAUDE.md` (erkannt an der Kopfzeile der früheren Vorlage) migriert er in
  einem Schritt mit der Einrichtung: Die Kit-Abschnitte gehen hinaus, Persönliches bleibt,
  unklare Zeilen legt er einzeln vor.
  Eine selbst angelegte CLAUDE.md schreibt er nie, er meldet nur Widersprüche zu den
  Kit-Regeln. Der Stand des letzten Abgleichs liegt als Basis im Datenordner des Plugins
  (`snapshot --snapshot`); `global <ordner>` arbeitet mit einem Stellvertreter-Ordner.
  Eine Datei `rules/coding-kit.md` ohne Kennung des Kits fasst er nicht an.
- **Session-Hinweis (neu, `hooks/session-start.sh`):** Beim Start einer Session meldet
  er in einer Zeile eine alte Kit-Kopie in der CLAUDE.md, seit dem letzten Abgleich
  geänderte Kit-Regeln oder Werte (Render gegen die Basis im Datenordner) oder eine
  Personal-Config, die sich nicht lesen lässt. Er schreibt nichts, endet immer ohne
  Fehler und schweigt ohne eingerichtete Kit-Regeln, bei einer fremden Regeldatei und
  bei abgelehnten Änderungen.
- **`install.sh`** schreibt nichts Globales mehr: Schritt 4 meldet eine alte Kit-Kopie,
  eine eigene CLAUDE.md und ob die Kit-Regeln eingerichtet sind, und verweist auf
  `/coding-kit:update-conventions global`. Die Personal-Config legt er mit
  `CLAUDE_CONFIG_DIR` in diesem Ordner an. `templates/global-CLAUDE.md` und der
  `curl`-Weg im README entfallen — der Befehl überschrieb eine eigene CLAUDE.md ohne
  Rückfrage.
- **README:** Abschnitte zu den globalen Kit-Regeln (was das Kit mit den globalen
  Einstellungen macht, Antwortsprache und Erklär-Niveau samt Optionen, wie man sie setzt
  und ändert, eigene Abweichungen und Ergänzungen), zu den Aufrufen von
  `update-conventions` und zum Session-Hinweis.
- **`teach-step`** liest und schreibt kein Lernprofil mehr in Graphiti (ohne Graphiti
  fehlte es ganz): Die Vorauswahl der Vertrautheitsfrage kommt aus der Stufe
  (`einsteiger` → Neuland, `junior` → Grundlagen, ab `fortgeschritten` → Routiniert), die
  des Lernziels aus der Notiz; am Ende schlägt der Skill höchstens einen neuen Notiz-Text
  vor.
- **`propose-to-template`** kennt die Fund-Art „globale Regel": eine Regel aus der
  persönlichen CLAUDE.md oder eine auf dem Rechner geänderte Zone der Kit-Regeln, mit der
  Kit-Datei als Ziel (Material deutsch, Issue-Titel `global: …`).
- **`scripts/template-sync.sh render-global` (neu):** rendert die Kit-Regeln mit den
  Werten der Personal-Config nach `OUT/rules/coding-kit.md`. Die Datei liest das Skript
  als Shell-Syntax, ohne sie auszuführen (Kommentare hinter Werten erlaubt); es meldet je
  Wert `set`, `empty` oder `missing` und lehnt eine Stufe ohne Block ab. `zones`
  vergleicht das Ergebnis mit dem Claude-Config-Ordner wie mit einem Projekt.
- **`/coding-kit:explain-level` (neu):** legt Antwortsprache und Erklär-Niveau fest. Ein
  kurzes Interview (Programmieren, Shell, Git, Frameworks, Projekt-Werkzeuge, wie viel
  Code der Nutzer mitliest) führt zu einem Vorschlag für Stufe und Notiz samt Stufentext
  aus der Kit-Datei; nach Freigabe schreibt der Skill die Werte in die Personal-Config.
  Er ist die einzige Stelle, die diese Werte abfragt, und jederzeit erneut aufrufbar. Ein
  bewusst leerer Wert gilt als beantwortet; nur ein fehlender Schlüssel wird nachgefragt.
- **`scripts/template-sync.sh set-global` (neu):** schreibt die Werte der globalen Regeln
  in eine Kopie der Personal-Config unter `OUT` (Modus 600): je Schlüssel eine Zeile
  `NAME="Wert"` mit dem Kommentar aus der Kit-Datei, so maskiert, dass die Shell den Wert
  wörtlich liest. Die erste Zuweisung (auch hinter `export`) wird ersetzt, spätere
  desselben Schlüssels fallen weg, fehlende kommen ans Ende; alle anderen Zeilen bleiben.
  Eine Stufe ohne Block, andere Schlüssel und Tab, Zeilenumbruch oder `{{` in einem Wert
  lehnt es ab.
- **Skill-Frontmatter (F-048):** Jeder Skill setzt `disable-model-invocation` und
  `user-invocable` ausdrücklich; zwölf Skills mit Argument zeigen beim Tippen ein
  `argument-hint` (z. B. `[F-Nummer]`). Kein Skill startet anders als zuvor. Der
  Validator verlangt beide Flags wörtlich als `true` oder `false`, lehnt einen Skill ab,
  den niemand starten könnte, lässt nur die Felder zu, die Claude Code für Skills kennt —
  ein Tippfehler bliebe sonst ohne Meldung wirkungslos —, und prüft die Grenze von 1536
  Zeichen, über der Claude Code die Beschreibung kürzt. Die Authoring-Doku listet die
  Felder mit dem, was das Kit davon nutzt; `default-enabled` war nie ein Skill-Feld und ist
  gestrichen.
- **`finalize`** (Platzhalter und optionale Blöcke) erkennt seine Wertetabelle nicht mehr
  an `NR == FNR`: Mit einer leeren Tabelle hätte es die ganze Datei als Werte gelesen.
  `render` hat nie eine leere Tabelle, für Projekte ändert sich nichts.
- **Kit:** Der Validator prüft die Kit-Regeln (Kennung in der ersten Zeile, Zonen, flache
  Blöcke, Platzhalter nur aus `GLOBAL_KEYS` des Skripts, Stufenliste im
  Schlüssel-Kommentar gleich den Stufenblöcken) und die `claudeMdExcludes`-Zeile in
  `.claude/settings.json` des Repos, die `template/core/CLAUDE.md` aus Sessions im
  Kit-Repo heraushält. Die Versionsregel zählt `global/` zum Plugin-Inhalt; Skript-Tests
  für `render-global`, `set-global` (samt Gegenprobe, dass die Shell die geschriebenen
  Werte wörtlich liest), `zones` auf einem Stellvertreter-Config-Ordner und den
  Session-Hinweis; der Validator gleicht die Stufen im README mit der Kit-Datei ab. Die
  Authoring-Doku verbietet Skills einen eigenen Erklärstil: Wie ausführlich Claude
  erklärt, regelt das Erklär-Niveau.

### Template

- `HOW-TO-CODE-WITH-CLAUDE.md` — die Zeile zu `/update-conventions` nennt `global`: Es
  gleicht die globalen Kit-Regeln auf dem Rechner ab (Antwortsprache, Erklär-Niveau,
  Haus-Regeln), jeder andere Lauf prüft sie einmal mit.

## 1.5.0 — 2026-10-26

Zonen, Fragmente und Lock-Datei prüft das Skript statt des Modells (F-045).

- **`scripts/template-sync.sh zones` (neu):** vergleicht die markierten Blöcke eines
  Projekts mit dem Render (`render --seeds`) — die `section:NAME`-Zonen der seed-Dateien
  und die `fragment:NAME`-Blöcke im Standards-Slot. Je Block eine Zeile mit Zustand
  (`identical`, `differs`, `override`, `new`, `opted-out`, `unmarked`, `local`, `no-file`,
  `broken`, `skipped`) und Diffstat; bei geschützten Fragmenten zählt er, was das Template
  seit der Basis geändert hat. Das Ergebnis schreibt er wie `merge` nach `OUT/<Ziel>`:
  abweichende Blöcke ersetzt, neue Fragmente hinter ihrem nächsten Vorgänger aus dem
  Render, in einem Slot ohne Fragmente anstelle des Platzhaltertexts — alle oder nur die
  genannten. Die Blöcke für die Diffs liegen unter `OUT/.zones/`.
- **`scripts/template-sync.sh lock-check` (neu):** prüft die `mise.lock` eines Projekts
  gegen `lockfile_platforms` der `mise.toml` und die Plattformen der CI (`runs-on` der
  Workflows mit `jdx/mise-action`, nach den Runner-Labels von GitHub; Ausdrücke und
  self-hosted Runner ergeben `unknown`). Kopfzeilen für Plattformen, CI und eine fehlende
  Einstellung oder Lock-Datei, dann je Lock-Eintrag bzw. konfiguriertem Tool `complete`,
  `gaps`, `ci-gap` (die CI scheitert mit `--locked`), `no-url`, `unlocked` oder `stale`.
  Backends, die laut mise keine Download-URL aufzeichnen (`npm`, `cargo`, `pipx` …),
  gelten nie als Lücke; ein Eintrag ganz ohne Plattform-Tabellen, wie ihn `mise install`
  allein schreibt, dagegen schon. Gegengeprüft mit echtem `mise lock`.
- **`snapshot`** weist ein Ziel ab, das weder gerendert ist noch eine Basis hat, bevor er
  etwas schreibt. Mehrere Ziele in einem Argument (zsh teilt Variablen nicht in Wörter)
  liefen bisher still als `removed` durch (Fund aus F-043c).
- **`detect`** zählt einen Fragment-Marker nur, wenn er allein auf seiner Zeile steht.
- **Skills angebunden:** `update-conventions` gleicht Fragmente (Schritt 6) und
  seed-Zonen (Schritt 7) über `zones` ab — ausdrücklich erst nach dem Kopieren der
  Merge-Ergebnisse — und übernimmt das Ergebnis des Skripts, bei teilweiser Zustimmung
  über einen zweiten Lauf mit den angenommenen Namen; die Lock-Prüfung (Schritt 11,
  Migration, Modus `status`) läuft über `lock-check`. `choose-stack` wertet in
  § Lock-Datei die Zeilen von `lock-check` aus und setzt Fragmente in Modus B über
  `zones` ein (Tausch des Modul-Fragments: das neue als `new`, das alte `local` nach
  Bestätigung entfernt); „ein Fragment anhängen" heißt in allen Skills: Name in
  `FRAGMENTS`, `render --seeds`, `zones` mit dem Namen. Kein Skill vergleicht Zonen,
  Fragmente oder die Lock-Datei mehr selbst.
- **Fund aus dem Testlauf:** `choose-stack` § Lock-Datei fragt, bevor ein Skill
  `mise trust` für ein Projekt ausführt, statt selbst zu vertrauen — mise führt danach
  Teile der Projektkonfiguration aus. `/new-project` vertraut weiter der `mise.toml`, die
  es gerade aus der Vorlage gerendert hat.
- **Kit:** Der Validator verlangt, dass Zonen- und Fragment-Marker im Template allein auf
  ihrer Zeile stehen; Skript-Tests für alle Zustände, das Einsetzen, die Auswahl per Name
  und frische Renders (docs-only mit und ohne Graphiti, ts-node); `lock-check`-Tests mit
  Fixtures im Format von `mise lock`, ohne Netz und ohne mise.

### Template

- MANIFEST § Markers: Ein Marker gilt nur allein auf einer Zeile. Ein Override
  (HTML-Kommentar mit `override:` und Grund) mitten in einer Textzeile schützt eine Zone
  oder ein Fragment nicht mehr — wer so eines nutzt, setzt es auf eine eigene Zeile.
- MANIFEST §§ Seed sections und Standards fragments nennen `template-sync.sh zones` als
  Vergleich; ein neues Fragment kommt hinter seinen nächsten Vorgänger aus dem Render.
- Die Kopfzone der `.claude/convention-overrides.md` (`overrides-head`) beschreibt das
  Override ohne marker-ähnlichen Text. Bisher hielt eine wörtliche Suche die Zone deshalb
  für geschützt und bot sie nie zur Aktualisierung an.

### Known limitation

- pnpm (Modul `ts-node`), Nachtrag zum Hinweis aus Template 0.13.3: Für
  `linux-arm64-musl` gibt es wieder ein Release — die Gegenprobe zu `lock-check` am
  2026-10-26 (pnpm 11.21.0) fand den Eintrag. Für `macos-x64` fehlt es weiterhin;
  Projekte mit ts-node können pnpm auf Intel-Macs nicht über die Lock-Datei installieren.

## 1.4.0 — 2026-10-25

Tools ohne Vorlage werden erkannt und können dem Template vorgeschlagen werden (F-044).

- **`scripts/template-sync.sh detect`:** meldet nach Modulen und Fragmenten jedes Tool aus
  `[tools]` der `mise.toml`, für das das Template keine Konvention hat — Zeile
  `tool <name> unknown`, mit Rules-Zeile `tool:NAME` `declined`. Bekannt ist ein Tool aus
  der Core-`mise.toml`, aus der `mise.part.toml` eines Moduls oder als deklariertes
  `tool:`-Signal; Tools mit Backend-Präfix (`npm:…`, `cargo:…`) zählen nie. Gilt für den
  ganzen Baum, `--changed` und übergebene Signale.
- **`propose-to-template` (neu):** der erste Hintergrund-Skill (`user-invocable: false`,
  kein Slash-Command). Claude startet ihn mit einem Fund — Tool ohne Vorlage,
  projektlokales Fragment, Abweichung an einer managed Datei — und bekommt einen
  generalisierten, personendatenfreien Übernahme-Vorschlag fürs Template: als Issue
  (Standard, mit `gh issue create` als Text) oder als Prompt für eine Session im Kit-Repo
  bzw. einem Fork, beides kopierfertig. Er sendet nichts ab und schreibt nirgends hin.
  Das Material trennt immer, was aus dem Projekt stammt, von dem, was Claude ohne
  Projektbeleg vorschlägt; der Prompt ist ein Entwurfsauftrag — erst recherchieren,
  beide Teile gewichten, den Entwurf mit Begründung zeigen, nach Zustimmung bauen.
  Wörtliche Datei-Inhalte stehen als eigene Codeblöcke, Backticks werden nie
  verschachtelt (Funde aus dem Testlauf von F-044c).
  Die `CONTRIBUTING.md` des Kit-Repos beschreibt solche Vorschläge.
- **Skills angebunden:** Je Tool `unknown` bieten `update-conventions` (Schritt 2, jeder
  Lauf), `step-done` (§ 1a, nur neue Tools) und `prep-step` (§ 2a, geplante Tools) an, es
  über `propose-to-template` dem Template vorzuschlagen oder dauerhaft mit `tool:NAME`
  abzulehnen; `choose-stack` Modus B rät für ein unbekanntes Tool kein Modul. Projektlokale
  Fragmente und Abweichungen an managed Dateien laufen ebenfalls über den neuen Skill —
  der Abschnitt „Übernahme-Vorschlag" in `update-conventions` entfällt. Die
  Registry-Revision bietet eine `tool:NAME`-Zeile zum Austragen an, sobald das Template
  das Tool kennt.
- **Kit:** Die Erkennungs-Tests decken bekannte Tools, Backend-Tools, `[tools.NAME]`-Tabellen,
  mehrere mise-Dateien, Ablehnung, `--changed` und übergebene Signale ab; ein frischer Render
  jedes Moduls meldet kein unbekanntes Tool.

### Template

- MANIFEST § Detection: Tools ohne Konvention mit den Zuständen `unknown` und `declined`;
  § Deviation registry: die Rules-Zeile `tool:NAME` lehnt einen Tool-Vorschlag dauerhaft ab.
- Die Kopfzone der `.claude/convention-overrides.md` (`overrides-head`) erklärt die
  Rules-Zeile `tool:NAME`.
- Die Spalte **Since** der Registry hat ein festes Format: das Datum, an dem die Zeile
  angelegt wurde (`YYYY-MM-DD`); MANIFEST § Deviation registry und die Kopfzone nennen
  es. Bestehende Zeilen bleiben, wie sie sind.
- `HOW-TO-CODE-WITH-CLAUDE.md`: prep-step, step-done und update-conventions nennen Tools
  ohne Vorlage, den Übernahme-Vorschlag (kopierfertiges Issue oder Prompt, nichts wird
  abgeschickt) und die Rules-Zeile `tool:NAME`.

## 1.3.0 — 2026-10-25

Sprachregeln gelten auch dort, wo eine Sprache ohne ihr Modul läuft (F-043).

- **`scripts/template-sync.sh detect`:** Ein Fragment, das das Modul der Antworten
  deklariert, ist `covered`, auch ohne Marker im Slot — der Render bringt es mit. So bietet
  `update-conventions` das Sprachfragment in Projekten mit Modul nicht vorab als fehlend
  an.
- **`update-conventions`** (A2 Schritt 6): Neue Fragmente kommen an ihre Stelle aus dem
  Render (hinter den nächsten Vorgänger, der im Slot steht) statt ans Slot-Ende;
  Bestehendes wird weiterhin nie umsortiert. Ein durch Override geschütztes Fragment, das
  sich im Template geändert hat, zeigt den Diff zur Info.
- **`choose-stack`:** setzt Fragmente ebenso an ihre Stelle aus dem Render und führt
  `FRAGMENTS` beim Modulwechsel in beide Richtungen nach — was das neue Modul deklariert,
  kommt heraus, ein stehen gebliebenes Fragment des Alt-Moduls hinein.
- **`scripts/template-sync.sh base-from-history`:** findet auch Releases ohne
  Template-Änderung (etwa 1.2.1) — dann gilt das Template des Commits, der die Version
  gesetzt hat. Bisher suchte der Befehl nur unter Template-Commits und brach ab (Fund aus
  den Tests von F-043).
- **Begriffe:** `new-project`, `choose-stack` und `update-conventions` sprechen vom
  Modul-Fragment (dem eigenen Fragment eines Moduls) und vom Sprachfragment
  (`<sprache>-lang`).
- **Kit:** Die Render-Tests prüfen die Reihenfolge im Slot (Modul-Fragment, Sprachfragment,
  `FRAGMENTS`), ein deklariertes Fragment in `FRAGMENTS` erscheint nur einmal, und ein
  docs-only-Projekt mit Werkzeugsprache bekommt das Sprachfragment allein; die
  Erkennungs-Tests melden es dort als fehlend und mit den Antworten eines Moduls, das es
  deklariert, als `covered`. Der Validator lässt kein Katalog-Fragment zu, das wie ein
  Modul heißt — Modul- und Katalog-Fragmente teilen sich die Namen.

### Template

- Die Fragmente der Module `python`, `ts-node` und `go` sind aufgeteilt. Die Regeln, die für
  jeden Code der Sprache gelten, stehen in neuen Katalog-Fragmenten (`python-lang`,
  `typescript-lang`, `go-lang`); das eigene Fragment des Moduls (`fragment:python` usw.)
  behält nur die Regeln seiner Toolchain und heißt jetzt Modul-Fragment. Keine Regel ist
  neu oder entfallen.
- Jedes der drei Module deklariert sein Sprachfragment unter `Standards fragments:`.
  `/update-conventions` erneuert das Modul-Fragment und hängt das Sprachfragment an —
  beides zusammen übernehmen, sonst fehlen Regeln oder stehen doppelt da.
- Trägt das Modul-Fragment im Projekt ein Inline-`<!-- override: … -->`, bleibt es
  unverändert; die Regeln, die jetzt im Sprachfragment stehen, dort von Hand entfernen.
- Signale der Sprachfragmente: `python-lang` über `tool:python`, `file:pyproject.toml`,
  `file:requirements*.txt`; `typescript-lang` über `npm:typescript`, `file:tsconfig.json`;
  `go-lang` über `tool:go`, `file:go.mod`. Ein Projekt, das eine Sprache als
  Werkzeugsprache nutzt, bekommt ihr Sprachfragment vorgeschlagen; es kommt in
  `FRAGMENTS`.
- MANIFEST (§§ Answers, Markers, Module contract, Standards fragments, Detection),
  Fragment-Katalog und §13 der `CODING-STANDARDS.md` beschreiben Modul- und Sprachfragment.
- `ts-node`: `biome.json` beschränkt Biome auf Code — `files.includes` schließt Markdown
  und YAML aus. Biome 2.6 formatiert beide, und ohne Lock-Datei bekommt ein neues Projekt
  diese Version: `just check` war dann in jedem neuen ts-node-Projekt rot, und in
  Bestandsprojekten würde der Renovate-PR für Biome rot (Fund aus den Tests von F-043).
  Die Ausschlussmuster gelten auch mit älteren Biome-2-Versionen.

## 1.2.1 — 2026-10-25

Skills kommen weiter, wenn ein Schreibzugriff unter `.claude/` auf Freigabe wartet (Fund
aus den Tests von F-042).

- **`scripts/template-sync.sh`:** neue Optionen `--answers FILE` (`detect`),
  `--registry FILE` (`status`, `changed`, `merge`, `detect`) und `--snapshot DIR`
  (`status`, `changed`, `merge`; `snapshot` schreibt dorthin) — Stellvertreter für die
  Dateien unter `.claude/`, die der Skill vorbereitet hat. Die Optionen liest eine
  gemeinsame Stelle; ein Befehl weist eine Option ab, die er nicht nimmt.
- **`update-conventions`:** Ohne Freigabe für `.claude/` rechnen die folgenden Schritte
  per Option mit dem vorbereiteten Stand; das Skript anzupassen oder das Projekt zu
  spiegeln, ist ausgeschlossen. Im Test hatte ein nicht-interaktiver Lauf dafür eine
  Spiegelkopie mit angepasstem Skript gebaut.
- **Authoring-Doku:** Hilfsskripte, die Projektdateien unter `.claude/` lesen, nehmen
  Stellvertreter-Optionen.

## 1.2.0 — 2026-10-25

Neue Sprachen und Frameworks fallen auf, auch wenn das Template seine Vorlagen erst später
bekommt (F-042).

- **`scripts/template-sync.sh detect`** gleicht die Signale eines Projekts mit Modulen
  und Fragment-Katalog ab: `package.json` (auch minifiziert), `pyproject.toml` (inklusive
  Poetry und `[dependency-groups]`), `requirements*.txt`, `go.mod` (ohne `// indirect`),
  `[tools]` der `mise.toml` und Dateimuster über alles, was git für das Projekt listet,
  ohne Snapshot. Eine Zeile je Treffer mit Zustand `covered`, `declined` oder `missing`
  und den auslösenden Signalen samt Fundort. `--changed` meldet nur, was der Arbeitsbaum
  gegenüber HEAD neu hat; mit Signalen als Argumenten prüft es geplante Dependencies,
  ohne den Baum zu lesen.
- **`update-conventions`** gleicht bei jedem Lauf, vor dem Rendern, die Signale des
  Projekts mit dem aktuellen Template ab: Ein fehlendes Fragment wird zum Anhängen
  angeboten (samt `FRAGMENTS`), ein fehlendes Modul an `choose-stack` verwiesen. Wer
  dauerhaft ablehnt, bekommt eine Rules-Zeile `module:NAME` oder `fragment:NAME` — bei
  einer Werkzeugsprache mit `keep`-Zeilen für die handgebaute Toolchain; „diesmal nicht"
  bietet der nächste Lauf wieder an. `status` berichtet die Erkennung, die Revision bietet
  Ablehnungen ohne Signale zum Austragen an.
- **`prep-step`** (§ 2a) prüft geplante Frameworks, Sprachen und Toolchains als Signale
  per `detect` gegen Katalog und Module — ein fehlendes Modul führt zu `choose-stack` oder
  zur Werkzeugsprache. **`step-done`** (§ 1a) nutzt `detect --changed`: gemeldet wird nur,
  was der Schritt neu einführt, nie blockierend.
- **`choose-stack`** empfiehlt im Bestandsprojekt das Modul aus den Signalen und bietet
  beim Wechsel an, eine Ablehnung des neuen Moduls und ihre `keep`-Zeilen auszutragen.
- **Kit:** Der Validator prüft die Signale: nur Typen aus MANIFEST § Detection, im
  Katalog nur typisierte Signale in Backticks oder ein Eigenschafts-Auslöser, jedes volle
  Modul mit `Signals:`-Zeile, Stubs ohne, und das Skript kennt genau diese Typen. Die
  Skript-Tests decken `detect` ab, auch an frisch gerenderten Projekten jedes Moduls.

### Template

- MANIFEST: neuer Abschnitt `## Detection`. Signale haben einen Typ — `npm:`, `pypi:`,
  `go:` für Dependencies, `tool:` für `[tools]` der `mise.toml`, `file:` für Dateimuster —
  und werden aus den Dateien gelesen, die git für das Projekt listet. Ein Modul oder
  Fragment mit Treffer ist `covered`, `declined` oder `missing`; eine Sprache ohne ihr
  Modul gilt als Werkzeugsprache.
- Fragment-Katalog: Die Auslöser-Spalte nennt typisierte Signale (`npm:react`,
  `file:Dockerfile*` …). `docker` erkennt auch `compose.yaml` und Varianten wie
  `Dockerfile.prod`, `nginx` Konfigurationsdateien und `nginx/`-Ordner statt des
  mehrdeutigen `nginx`. `api-design` erkennt NestJS über `@nestjs/core` und gilt jetzt
  auch für Python (FastAPI, Flask, Django, Litestar) und Go (Gin, Echo, chi, Fiber);
  `go:`-Signale treffen jede Hauptversion des Modulpfads.
- Module: `ts-node`, `python` und `go` nennen ihre Signale auf einer `Signals:`-Zeile im
  `MODULE.md`, `docs-only` hat `(none)`; Stubs bleiben ohne.
- Abweichungs-Registry: Eine Rules-Zeile `module:NAME` oder `fragment:NAME` lehnt einen
  Erkennungs-Vorschlag dauerhaft ab — so steht es im MANIFEST und im Kopf der
  `.claude/convention-overrides.md` (Zone `overrides-head`).
- HOW-TO: `/prep-step` prüft geplante Frameworks, Sprachen und Toolchains gegen Katalog
  und Module, `/step-done` hat einen Erkennungs-Backstop für das, was ein Schritt neu
  einführt, `/choose-stack` empfiehlt aus den Projektsignalen, `/update-conventions`
  erkennt bei jedem Lauf, wofür das Template inzwischen Vorlagen hat.

## 1.1.0 — 2026-10-24

Projektzusätze in managed Dateien überstehen Template-Updates, und Abweichungen fallen
früh auf (F-041).

- **`update-conventions`** gleicht managed Dateien per Drei-Wege-Merge gegen den
  Basis-Snapshot ab: Projektzusätze bleiben, Template-Änderungen kommen an, nur
  Überschneidungen werden Konflikte — mit Lösungsvorschlag, je Datei bestätigt. Je Datei:
  übernehmen, diesmal nicht oder dauerhaft ablehnen; Konflikte auch als `keep`
  registrieren. Ohne Argument bearbeitet der Skill nur das Projekt im aktuellen Ordner,
  alle Projekte nur mit `alle`; `status` berichtet nur, `revise` prüft die Registry
  (veraltete Zeilen austragen, unregistrierte Abweichungen eintragen). Rendern und Merge
  laufen auch bei aktuellem Stempel. Die seed-Zonen kommen aus dem Renderer. Projekte
  ohne Snapshot werden migriert: Antworten aus dem Projekt zurückgewinnen, Basis aus der
  Template-Historie (Stempel-Version, eine ältere oder eine Mischbasis, damit früher
  übersprungene Änderungen wieder angeboten werden) oder einmal zweiwegig, Registry in
  die Tabellen Files und Rules überführen. Schreibzugriffe unter `.claude/` fragt Claude
  Code einzeln ab; ohne Freigabe bereitet der Skill die Dateien vor und nennt den
  Kopierbefehl.
- **`new-project`** instanziiert über den Renderer (`render --seeds`): Antworten-Datei
  schreiben, rendern, dann nur noch `template:adapt`-Stellen, Lizenztext und
  Begleithandlungen von Hand; konkretisierte managed Dateien bekommen eine `adapt`-Zeile.
  Antworten und Basis-Snapshot gehören in den Erst-Commit; `status` prüft danach, dass
  nur die `adapt`-Dateien abweichen.
- **`choose-stack`** rüstet Module über Render und Drei-Wege-Merge nach oder wechselt sie
  (Projektzusätze bleiben, Dateien des Alt-Moduls fallen als `removed` heraus) und zieht
  Antworten und Snapshot nach. Fragment-Einbau überall: Fragmente, die das Modul nicht
  deklariert, kommen in `FRAGMENTS`; ändert eine Begleithandlung managed Dateien, gehören
  `keep`-Zeilen in die Registry — `prep-step` und `step-done` weisen beides im Vorschlag
  aus.
- **`step-done`** bekommt einen zweiten Backstop (Schritt 1b): Geänderte managed Dateien
  ohne Registry-Zeile werden gemeldet, mit der Wahl registrieren, zurücknehmen oder dem
  Template vorschlagen; Handänderungen am Snapshot gelten als Fehler. Nie blockierend.
- **`choose-license`** setzt im Bestandsprojekt `LICENSE_SPDX` in den Antworten und zieht
  die lizenzabhängigen managed Dateien (z. B. `CONTRIBUTING.md`) über Render und Merge nach.
- **`go-public`** setzt `VISIBILITY=public` in den Antworten im Nachzug-Commit.
- **Authoring-Doku:** neuer Baustein „Hilfsskripte" (deterministische Arbeit ins Skript,
  Aufruf über `sh` mit aufgelöstem Pfad, Tests unter `tests/`).
- **`scripts/template-sync.sh`** (POSIX sh, ohne Sprachmodell):
  - `render` schreibt die reine Instanziierung des Templates für ein Projekt: Core-Ziele
    laut MANIFEST, Modul-Teile, Platzhalter, `optional`-Blöcke und Fragment-Slot —
    wiederholbar und byte-gleich. Eingabe ist die neue Antworten-Datei
    `.claude/template-answers`.
  - `merge` führt je Datei einen Drei-Wege-Merge mit `git merge-file` aus: Basis-Snapshot
    (`.claude/template-base/<Ziel>.base`), Projekt und Soll-Fassung. Zeilenenden, eine
    fehlende Endzeile und der Inhalt des Fragment-Slots zählen nicht als Unterschied.
    `status` und `changed` vergleichen das Projekt mit dem Snapshot, `snapshot` setzt
    ihn, `base-from-history` holt das Template einer alten Version aus der Kit-Historie.
    Abweichungen mit Grund stehen in einer Files-Tabelle der `convention-overrides.md`
    (Arten `skip`, `keep`, `adapt`). `status` und `merge` nehmen mit `--base` auch eine
    gerenderte Basis statt des Snapshots (Migration, Vorschau).
- **Kit:** Die Versionsregel zählt `plugins/coding-kit/scripts/` zum Plugin-Inhalt. Der
  Validator prüft Plugin-Skripte (ausführbar, `sh -n`), die Datei-Policies der Module, ob
  der Renderer jeden Modul-Teil des MANIFEST kennt, und den Snapshot-Vertrag
  (MANIFEST-Abschnitte, Registry-Tabellen, `.gitattributes`). `just check` testet das
  Skript unter `dash` und bash; der Pre-Commit-Hook nur, wenn Skript, Template oder Tests
  sich ändern.

### Template

- **Basis-Snapshot und Registry** (`manifest-format: 2`): Projekte tragen unter
  `.claude/template-base/` die reine Template-Fassung jeder managed Datei
  (`<Datei>.base`) und unter `.claude/template-answers` die Werte, aus denen sie
  gerendert wird. Die `convention-overrides.md` hat neu eine Files-Tabelle (Pfad, Art
  `skip`/`keep`/`adapt` oder leer, Grund) und eine Rules-Tabelle; der Kopf erklärt die
  Arten. `<!-- override: … -->` gilt nur noch für seed-Zonen und Fragmente.
  `/update-conventions` legt alles bei der Migration an.
- `.gitattributes`: `.claude/template-base/**` ist `linguist-generated`.
- `.claude/README.md` und HOW-TO beschreiben Snapshot, Antworten und Registry; die HOW-TO
  den Merge in `/update-conventions` und `/choose-stack`, den neuen Backstop in
  `/step-done` und den Nachzug in `/choose-license`.
- Fragmente `nextjs` und `astro`: Abweichungen an managed Dateien als `keep` registrieren
  (Template-Änderungen kommen weiter an, bei Konflikten gewinnt das Projekt); die
  Import-Ausnahme gehört in die Rules-Tabelle.
- MANIFEST: neuer Abschnitt `## Answers` (Format der Antworten-Datei) und exakte
  Einsetzregeln im Modul-Kontrakt. Das `MODULE.md` des Python-Moduls nennt `py.typed`
  mit vollem Pfad.
- `CONTRIBUTING.md`: Der Lizenzabsatz hat zwei Varianten. Mit gewählter Lizenz bleibt er
  wie bisher. Bei Lizenz TBD verweist er nicht mehr auf eine `LICENSE`-Datei, die es
  dann nicht gibt. Welche Variante gilt, folgt aus `LICENSE_SPDX` (optionale Blöcke
  `license` und `license-tbd`).

## 1.0.0 — 2026-10-24

Ein Repo für Plugin und Template (F-039): Das project-template liegt jetzt unter
`plugins/coding-kit/template/` und kommt mit dem Plugin; Plugin und Template teilen ab
hier eine Version.

- **Template-Import:** Historie des project-template bis 0.16.0 mit umgeschriebenen
  Pfaden übernommen; seine Aufgaben-Nummern heißen in den Commit-Messages und hier
  `TPL-NNN`. Repo-eigene Dateien des Templates (Governance-Doku, Tooling, eigene
  `VERSION`) sind entfallen.
- **Skills lesen das Template aus dem Plugin:** `choose-stack` § 0 löst es als
  `${CLAUDE_PLUGIN_ROOT}/template` auf — kein Klon, kein lokaler Checkout, kein
  `CODING_KIT_TEMPLATE_REPO` mehr; wer am Template arbeitet, testet mit
  `claude --plugin-dir`. Die übrigen Skills verweisen weiter auf § 0; `define-requirements`
  liest den Fragment-Katalog jetzt immer, `choose-license` nennt die mitgelieferte
  LICENSE, `go-public` spricht nicht mehr von einem Template-Checkout.
- **`new-project`:** legt ein leeres Repo an (`gh repo create … --clone` ohne
  `--template`), schreibt nur die MANIFEST-Ziele hinein (das Aufräumen entfällt) und
  stempelt die Plugin-Version; der Erst-Commit heißt
  `feat: bootstrap from coding-kit <Version> (<Modul> module)`. Der Optional-Block
  `security-tool`, den das Template längst nicht mehr hat, ist aus der Anleitung
  gestrichen.
- **`update-conventions`:** Update-Fenster aus den `### Template`-Abschnitten dieses
  CHANGELOG — Stempel unter 1.0.0 zusätzlich aus dem eingefrorenen Template-Abschnitt;
  ohne Template-Änderung seit dem Stempel nur neu stempeln. Entfernte und umbenannte
  Dateien kommen aus der neuen MANIFEST-Tabelle statt aus der Git-Historie eines
  Checkouts. Der Übernahme-Vorschlag geht an eine coding-kit-Session bzw. als Issue an
  das Repo aus der `homepage` in `plugin.json`. Der Ausweichpfad für ein Template ohne
  § Seed sections entfällt.
- **MANIFEST:** neue Tabelle `## Removed and renamed targets` (leer — seit 0.1.0 wurde
  kein Ziel entfernt oder umbenannt); Stempel und `TEMPLATE_VERSION` kommen aus der
  Plugin-Version; Übernahme-Vorschläge gehen an das coding-kit-Repo.
- **Validator:** prüft jetzt auch das Template — Platzhalter gegen die Registry im
  MANIFEST (statt einer festen Liste im Skript), Fragment- und Section-Marker, den
  Fragment-Katalog und eine private Blocklist. Dazu der Vertrag zwischen Skills und
  Template: dasselbe `manifest-format`, Core-Tabelle und `core/`-Dateien decken sich in
  beide Richtungen, Seed-Inventar und Marker passen, die Optional-Blöcke im MANIFEST,
  im Template und in den Skills stimmen überein, jeder in einem Skill genannte
  `${CLAUDE_PLUGIN_ROOT}/…`-Pfad existiert.
- **Versionsregel geprüft:** `scripts/version-rule.py` lässt Änderungen an Skills, Hooks
  oder Template nur mit einer Version über dem gepushten Stand und einem
  CHANGELOG-Eintrag dafür zu — vor jedem Commit und in der CI. Verlässt ein Ziel die
  Core-Tabelle, verlangt sie eine Zeile in `## Removed and renamed targets`.

- **Nach dem Release:** project-template ist archiviert (nur lesbar, die README verweist
  hierher); die Template-Einstellung bleibt, damit die „generated from"-Labels bestehender
  Projekte gültig bleiben. Plugins unter 1.0.0 lesen es weiter; ob GitHub aus dem
  archivierten Repo noch neue Repos erzeugt, ist nicht ausprobiert — das hätte ein Repo
  angelegt.

### Template

- `HOW-TO-CODE-WITH-CLAUDE.md` (managed): `/step-done` verbucht die PROGRESS erst nach
  einer Vorschau und einer Freigabe zusammen mit der Commit-Message; `/add-feature` darf
  auch Claude starten, eingetragen wird erst nach OK (Nachzug zu Plugin 0.20.0).
- `.claude/README.md` (managed): Der Abschnitt `template-version` beschreibt den Stempel
  jetzt als coding-kit-Version (Template und Skills teilen sie) statt als eigene
  Template-`VERSION`.

## Eingefroren: coding-kit-Plugin bis 0.20.0

### 0.20.0 — 2026-10-23

Freigabe-Gate für PROGRESS-Einträge (F-038a): Claude darf Skills wie `add-feature` selbst
starten, aber jeder neue oder geänderte Eintrag in `PROGRESS.md`, `PROGRESS-ARCHIVE.md`
oder im FEATURE-INDEX wird zuerst als Vorschau gezeigt und erst nach ausdrücklichem OK
geschrieben.

- **`step-done`:** § 4 bereitet Done-Zeile, Archiv-Eintrag und `(DONE)`-Marker nur noch
  vor; § 5 zeigt sie zusammen mit der Commit-Message in **einer** Frage (verbuchen und
  committen / nur verbuchen / Text ändern), erst danach wird geschrieben und committet.
  „Direkt tun, ohne zu fragen" entfällt. Graphiti (jetzt § 6) läuft erst nach der
  Verbuchung; Commit-E-Mail und Co-Authored-By heißen jetzt § 5a/5b.
- **`build-step`:** Claude startet `add-feature` für unterwegs entdeckte Ideen selbst
  (statt den Nutzer darum zu bitten); im autonomen Lauf werden sie nur gesammelt und im
  Abschluss vorgeschlagen. Die Start-Freigabe des Laufs gilt für Verbuchen **und**
  Commits der geplanten Substeps, nicht für neue Einträge.
- **`add-feature`:** Beschreibung und Einleitung sagen ausdrücklich, dass Claude den
  Skill selbst starten darf — der Skill war immer modellaufrufbar, der Text legte das
  Gegenteil nahe.
- **Authoring-Konvention** (`docs/skill-authoring.md`): neuer Pflicht-Baustein
  „Freigabe-Gate" mit Standardsatz, plus Hinweis, dass Skill-Texte einem modellaufrufbaren
  Skill nicht widersprechen dürfen.

### 0.19.1 — 2026-10-23

Fix (F-031): Projekte aus `/new-project` bekamen eine `mise.lock` ohne Plattform-Einträge,
weil nur `mise install` lief — die CI (`jdx/mise-action`, installiert mit `--locked`)
scheiterte daran auf `linux-x64` seit dem Bootstrap-Commit. Gegenstück zu
project-template 0.13.3 (`lockfile_platforms` in `core/mise.toml`):

- **`choose-stack` § Lock-Datei erzeugen und prüfen** (neu, gemeinsame Mechanik): nach
  `mise install` schlicht `mise lock`, ohne `--platform` — die Plattformliste kommt
  allein aus `lockfile_platforms`. Prüfung: jedes Tool hat einen Eintrag je Plattform
  der Liste; eine Lücke auf der Plattform des CI-Runners blockiert den Commit, übrige
  Lücken werden gemeldet und gegen die „Known limitation"-Einträge des
  Template-CHANGELOG abgeglichen.
- **`new-project` § 4d** und **`choose-stack` § 4** führen `mise lock` nach
  `mise install` aus und prüfen danach.
- **`update-conventions`:** Lock-Abgleich am Projektabschluss (A2.9), auch bei
  aktuellem Stempel (A2.1) — betroffen sind auch Projekte aus Template 0.13.3, die
  ein älterer Kit-Stand angelegt hat. Tooling-Nachrüstung (A3.5) erzeugt und prüft
  die Lock-Datei ebenso.

### 0.19.0 — 2026-09-16

Neuer Utility-Skill **handoff** (F-028): kopierfertiger Handoff-Prompt für einen
frischen Chat, wenn eine Session ans Kontextlimit kommt — ersetzt den jedes Mal neu
getippten Auftrag „nur Kontext übergeben, nichts bauen":

- **Übergibt nur Undokumentiertes:** Maßstab je Zeile ist, ob der neue Chat ohne sie
  etwas falsch macht, doppelt tut oder erneut fragt. Entscheidungen samt verworfener
  Alternativen, Fallstricke, Absprachen und halbfertige Arbeit wandern in den Prompt;
  was schon in Dateien, Git, CLAUDE.md oder Memory steht, nur als Verweis. Richtwert
  typisch bis ~150 Zeilen ohne Untergrenze — die eigentliche Grenze ist der Maßstab.
- **Orientierung zuerst:** die Gliederung beginnt mit Zuletzt (letzte Aktion und was
  darauf wartet), Stand und Als Nächstes; Entscheidungen, Fallstricke und Absprachen
  folgen als Hintergrund. Leere Abschnitte entfallen; die Schlussanweisung lässt den
  neuen Chat den Stand bestätigen und auf die nächste Anweisung warten — der Nutzer
  führt den nächsten Befehl selbst aus.
- **Reihenfolge-Vorgabe der Aufgabenliste:** hat das Projekt eine ausdrückliche
  Reihenfolge (eigene Überschrift oder Zeile, Wortlaut frei), nennt der Handoff die
  Fundstelle als verbindlich und den nächsten Eintrag laut Vorgabe — ohne sie zu
  kopieren, die Datei bleibt maßgeblich. Sonst gilt die Reihenfolge der offenen Einträge.
- **Ausgabe als ein Codeblock mit vier Backticks**, damit innere Code-Schnipsel die
  Kopiervorlage nicht zerbrechen; außerhalb höchstens eine Zeile.
- **Kontextsparsam gebaut:** knapper Skill-Text, leeres Argument ohne Rückfrage, höchstens
  ein Shell-Aufruf (Git-Stand plus Überschriften-Suche nach einer Reihenfolge-Vorgabe),
  keine Datei-Lesevorgänge. Schreibverbot per `disallowed-tools` (Write, Edit,
  NotebookEdit); auch kein Memory-Update — Dokumentationsbedarf steht im Prompt unter
  „Offen" und wird im neuen Chat auf Anweisung erledigt.
- Projektunabhängig: setzt weder Kit-Struktur noch Git voraus. Nur manuell aufrufbar;
  wie `refine-prompt` nicht in der Skill-Übersicht des project-templates.

### 0.18.0 — 2026-08-11

Begleithandlungen beim Fragment-Einbau (F-022) — Gegenstück zu **project-template
0.13.1** (dortiges TPL-016), das im `nextjs`-Fragment eine Handlung fordert, die bisher
kein Skill ausgeführt hat:

- **Neuer Abschnitt `/choose-stack` § Begleithandlungen** als einzige Fundstelle der
  Mechanik: Verlangt ein Fragment beim Einbau eine Handlung am Projekt und nicht nur
  den Text im Slot, wird sie im selben Schritt ausgeführt, im Plan ausgewiesen und
  einzeln bestätigt. **Generisch statt fragmentspezifisch** — was zu tun ist, liest der
  Skill zur Laufzeit aus dem Fragment; das Kit hardcodet kein Framework-Wissen (gleiche
  Arbeitsteilung wie beim Trigger-Mapping: Template = Daten, Kit = Logik).
- **Die Prüfung ist von der Idempotenz-Regel entkoppelt:** liegt `fragment:NAME` schon
  im Slot, wird der Text übersprungen, die Begleithandlung aber trotzdem geprüft. Ohne
  das bliebe jedes Projekt ungedeckt, das ein Fragment bekam, bevor es die Anforderung
  enthielt.
- **Vier Aufrufstellen referenzieren den Abschnitt**, statt ihn zu duplizieren:
  `new-project` (Fragment-Assembly bei der Instanziierung), `choose-stack` Modus B
  (Idempotenz-Hinweis), `prep-step` § 2a und `step-done` § 1a weisen die
  Begleithandlung im Vorschlag mit aus.
- **`update-conventions` Schritt 6 zusätzlich:** die Begleithandlung wird je Fragment
  im Slot auch bei **unverändertem** Fragment-Text geprüft und offene Fälle mit Diff
  angeboten. Das ist der einzige Pfad, der Bestandsprojekte erreicht — die anderen vier
  greifen nur beim Einbau.

Konkreter Anlass, im Fragment beschrieben und hier nur benannt: Nexts
Agent-Rules-Generator schreibt seinen Managed-Block bevorzugt in die Datei, die ihn
schon hostet, sonst in `AGENTS.md`, falls vorhanden, sonst in `CLAUDE.md`. Projekte aus
dem Template haben immer eine `CLAUDE.md` und nie eine `AGENTS.md` — ohne
Begleithandlung landet der Block also in der Governance-Datei und wird dort bei jedem
`next dev` erneuert; ein nachträglich angelegtes `AGENTS.md` holt ihn nicht mehr heraus.

### 0.17.0 — 2026-07-20

Neuer Pflege-Skill **go-public** (F-019): Projekt nachträglich public-ready machen —
geführter Übergang statt riskantem Handgriff:

- Drei Startfälle zur Laufzeit erkannt (`gh repo view`): privates Repo →
  Sichtbarkeit umstellen; nur lokal → Repo-Anlage + initialer Push; schon public →
  nur Preflight/Nachzug/Check.
- **Preflight blockierend, fail-closed** (vier Gates): Secrets-Scan über die volle
  Git-Historie (Scanner zur Laufzeit aus lefthook/mise aufgelöst, gitleaks nur
  Fallback; fehlt jeder Scanner, blockiert das Gate), Privacy-Scan des committeten
  Baums inkl. Commit-Metadaten (Autor-/Committer-E-Mails), LICENSE nicht TBD,
  private/-Hygiene über die Historie. History-Rewrite (`git filter-repo` +
  Force-Push) nur als dokumentierte Anleitung, nie automatisch; begründete
  False-Positive-Einstufungen werden protokolliert.
- **Reihenfolge verbindlich: Nachzug vor Übergang** — public-only-Dateien und
  ausstehende Template-Updates entstehen lokal via `update-conventions` und werden
  committet, bevor das Repo öffentlich wird; nie unvollständig online.
- Übergang je Fall nur nach expliziter Bestätigung; initialer Push nur mit
  ausdrücklicher laufbezogener Push-Freigabe (einzige Ausnahme vom Push-Tabu).
  Repo-Settings wie new-project § 4c; der Languages-Block bleibt unangetastet
  (Sprache ist sichtbarkeitsentkoppelt). Abschluss-Check: CodeQL läuft an,
  Vollständigkeit, Settings, `just check`.
- `update-conventions` — neue **Sichtbarkeits-Prämisse**: ein Aufrufer (go-public)
  kann „behandle als public" übergeben; die public-only-Policy folgt dann der
  Prämisse statt der tatsächlichen Sichtbarkeit (A2.3, gilt auch für die
  A3-Heuristik).

### 0.16.0 — 2026-07-20

Entfernte/umbenannte Template-Dateien im Sync behandeln (F-021b — schließt mit
F-021a die Vollabdeckung aller Template-Dokumente ab):

- `update-conventions` — neuer A2-Schritt 8: die Core-Tabelle des Stempel-Stands
  wird über die Git-Historie des Template-Checkouts aufgelöst (Commit mit
  passendem `VERSION`-Inhalt, dann `git show <commit>:MANIFEST.md`) und mit der
  aktuellen verglichen; verschwundene Ziele → Rückbau anbieten, umbenannte →
  Umzug anbieten — je Datei bestätigt, Overrides gelten. Fallback ohne
  auflösbaren Stempel-Commit: nur im CHANGELOG des Update-Fensters dokumentierte
  Entfernungen/Umbenennungen, nichts erraten. seed-Dateien werden nie gelöscht
  oder verschoben, nur gemeldet.

### 0.15.0 — 2026-07-20

seed-Abgleich abschnittsweise (F-021a; Gegenstück zu project-template 0.11.0,
`section:NAME`-Zonen-Vertrag in MANIFEST § Seed sections):

- `update-conventions` — neuer A2-Schritt 7: die markierten Zonen der sechs
  seed-Skelette werden instanziiert (rückaufgelöste Projektwerte) und einzeln
  gegen die Ist-Zone gedifft — je Zone übernehmen / lassen / Override, nie die
  ganze Datei; gelöschtes Markerpaar = dauerhafter Opt-out (nur melden);
  `claude-graphiti` fehlt legitim bei Projekten ohne Graphiti-Block.
  Feature-Detection in § 0: ohne § Seed sections im Template entfällt der Schritt
  still. Neuer A3-Schritt 7: Marker-Migration für Alt-Projekte (Wrapper aus dem
  Inventar um wiedererkennbare Zonen, je Datei bestätigt). Grundsatz präzisiert:
  seed nie als Ganzes, markierte Zonen abschnittsweise.
- `new-project` — Klarstellung in § 4b: `section:NAME`-Markerpaare bleiben bei
  der Instanziierung unverändert erhalten.

### 0.14.0 — 2026-07-19

Sprach-Matrix: Projektsprachen sind granular wählbar und von der Sichtbarkeit
entkoppelt (Gegenstück zu project-template 0.10.0, Languages-Block + fünf
`LANG_*`-Platzhalter):

- `new-project` — die Sprachfrage ist eine Preset-Frage (Arbeitssprache + Englisch
  nach außen [Default] / alles Englisch / alles Arbeitssprache / individuell je
  Dimension mit freier Sprachwahl); der Vorschlag leitet sich aus der Short-Info ab,
  nicht mehr aus der Sichtbarkeit. §4b füllt die fünf `LANG_*`-Platzhalter. Immer
  englisch bleiben Identifier, Conventional-Tokens, Status-Tokens, Governance-Doku.
- `step-done` — liest den Languages-Block (§0), prüft die Kommentar-/
  Docstring-Sprache im Review (§1) und schlägt Commit-Prosa in der Commit-Sprache
  des Projekts vor (§6; ohne Block englisch, Format-Tokens immer englisch).
- `build-step` — schreibt Kommentare/Docstrings in der Kommentar-Sprache des
  Projekts (§2).
- `update-conventions` — löst die fünf Sprachen bei der Platzhalter-Rückauflösung
  auf (A2.2) und bietet die **Languages-Block-Migration** als bestätigten Schritt an
  (neuer A3-Schritt 6 + Hinweis in A2.7; CLAUDE.md ist `seed` und wird nie
  automatisch angefasst). Migrations-Semantik prospektiv: Bestandsinhalte werden
  nicht übersetzt, neue Einträge folgen den gewählten Sprachen,
  Struktur-Überschriften optional.
- `templates/global-CLAUDE.md` — Haus-Default bleibt Englisch; ein
  Projekt-Languages-Block gewinnt je Dimension.

### 0.13.0 — 2026-07-19

Konventions-Vererbung fließt nur noch **abwärts** (Template → Projekt) — die
AUFWÄRTS-Richtung („promote") ist gestrichen:

- `update-conventions` — promote-Argument, Richtungsfrage und der komplette
  AUFWÄRTS-Abschnitt entfallen; das Entscheidungsset je Datei/Fragment ist
  dreiteilig (übernehmen / so lassen / Override registrieren). Wer die
  Projekt-Fassung für besser hält, ändert zuerst die Vorlage und synct dann
  herunter. Veralteter Querverweis „wie A2.6" auf „wie A2.7" korrigiert.
- **Neu: Übernahme-Vorschlag** (Ersatz für promote) — projektlokale Fragmente
  bleiben erlaubt, werden aber nie ins Template geschrieben. Stattdessen gibt es
  fertiges Material zum manuellen Anstoßen: kopierfertiger Prompt für eine
  Template-Session (generalisieren, Katalog-Datei + README-Zeile, Sync-Invariante)
  oder ein GitHub-Request ins Template-Repo (`gh issue create`, OWNER zur
  Laufzeit). Ausgegeben an drei Stellen: `update-conventions` (Bestandsfälle beim
  Sync), `prep-step` 2a Fall B (direkt nach der Anlage) und `step-done` 1a (neu
  angelegte Fragment-Blöcke im Diff, auch ad-hoc entstandene).

### 0.12.0 — 2026-07-19

Eigenschafts-Trigger des Fragment-Katalogs werden ausgewertet — Fragmente wie
`audit-logging`, deren Trigger eine Projekteigenschaft statt einer Dependency ist,
finden jetzt ihren Weg ins Projekt:

- `define-requirements` — neuer Interview-Punkt 5: die `*characteristic:*`-Zeilen
  des Katalogs werden zur Laufzeit gelesen und als Ja/Nein-Fragen gestellt
  (Default nein; ohne erreichbares Template stilles Überspringen). Treffer landen
  als Constraint + Decision-Log-Eintrag in der REQUIREMENTS.md und in der Rückgabe
  an den Aufrufer.
- `new-project` — komponiert die im Interview bejahten Eigenschafts-Fragmente bei
  der Instanziierung in den CODING-STANDARDS-Slot mit.
- `choose-stack` (Modus B) — Eigenschafts-Fragmente sind nachrüstbar: sie sind in
  keinem `MODULE.md` deklariert; je Trigger wird gefragt, ob die Eigenschaft
  zutrifft (Projektentscheidung, Default nein), angehängt wird nur nach
  Bestätigung (gleiche idempotente Mechanik).
- Der prep-step-Teil (Trigger-Match in der Feature-Analyse) kam bereits mit 0.10.0.

### 0.11.0 — 2026-07-19

`step-done` bekommt den Standards-Abdeckungs-Backstop — Frameworks, die erst
während der Umsetzung dazukamen, rutschen nicht mehr ohne ihr Fragment durch:

- Neuer Schritt „1a. Standards-Abdeckung (Backstop)", **diff-basiert**: läuft nur,
  wenn der Diff des Schritts neue Dependencies in Paket-Manifesten oder neue
  Signal-Dateien (Dockerfile, nginx.conf, …) einführt und das Projekt einen
  `module:coding-standards`-Slot hat; sonst stilles Überspringen. Ein
  Projekt-Vollaudit je Substep wäre unverhältnismäßig und bleibt `/audit-code`.
- Match gegen das zur Laufzeit gelesene Katalog-Mapping (wie prep-step 2a);
  `*characteristic:*`-Zeilen matchen diff-basiert naturgemäß nicht.
- Lücke → melden + Anhängen vorschlagen (Mechanik wie `/choose-stack`,
  idempotent). Der Abschluss wird nicht blockiert; eine abgelehnte Ergänzung wird
  im Archiv-Eintrag vermerkt.

### 0.10.0 — 2026-07-19

`prep-step` prüft die Standards-Abdeckung — „Standards wachsen mit":

- Neuer Schritt „2a. Standards-Abdeckung prüfen" mit Kosten-Gate: nur wenn die
  Aufgabe neue Frameworks/Dependencies einführt und das Projekt einen
  `module:coding-standards`-Slot hat; sonst stilles Überspringen (kein
  Template-Clone je Lauf).
- Gematcht werden **beide** Signaltypen des Fragment-Katalogs
  (`modules/standards/README.md`, zur Laufzeit gelesen): Dependency-Signale gegen
  die neuen Dependencies und `*characteristic:*`-Eigenschafts-Trigger gegen die
  Aufgabenbeschreibung (prep-step-Touchpoint von F-017).
- Vorschlags-Pfade: vorhandenes Katalog-Fragment → Anhängen als Plan-Bestandteil
  (Mechanik wie `/choose-stack`, idempotent); kein Katalog-Fragment → Autoring
  eines projektlokalen Fragments + Promote via `/update-conventions` anbieten.
  Nie still einbauen — Entscheidung fällt mit der Plan-Freigabe. Die Plan-Vorlage
  hat dafür eine neue Zeile „Standards-Abdeckung".

### 0.9.0 — 2026-07-19

`update-conventions` gleicht CODING-STANDARDS fragment-granular ab (Gegenstück zum
choose-stack-Einbau aus 0.8.0):

- **Zwei Diff-Ebenen abwärts:** Der Datei-Diff der `CODING-STANDARDS.md` hält den
  §13-Slot konstant (Ist-Slot wird in die Soll-Fassung injiziert) und zeigt nur
  Core-Änderungen; die `fragment:NAME`-Blöcke im Slot werden einzeln gegen ihr
  Template-Pendant gedifft — Entscheidung je Fragment (übernehmen / lassen /
  Override / promoten). Projektlokale Fragmente ohne Template-Pendant werden nie
  angefasst, nur aufgelistet; Inline-Override-Marker schützen einzelne Fragmente.
- **Neu deklarierte Fragmente:** Fehlt im Projekt ein inzwischen vom `MODULE.md`
  deklariertes Katalog-Fragment, bietet der Abwärts-Lauf das Anhängen an (Mechanik
  wie `/choose-stack`, idempotent; Bestehendes in-place, Neues ans Slot-Ende, nie
  umsortieren).
- **Promote:** Ein bewährtes projektlokales Fragment kann generalisiert in den
  Katalog wandern (`modules/standards/<name>.md` + Katalog-Zeile im README).

### 0.8.0 — 2026-07-19

`choose-stack` baut Standards-Fragmente komponierbar ein (Vertrag: project-template
MANIFEST § Standards fragments):

- Statt EINEN `CODING-STANDARDS.part.md` in den §13-Slot einzufügen, hängt Modus B
  jetzt die Fragmentliste des Moduls an: eigenes Sprachfragment plus die im
  `MODULE.md` deklarierten Katalog-Fragmente (`Standards fragments:`-Zeile, tolerant
  gelesen — fett/plain, `(none)`/leer/fehlend = keine). Idempotent je
  `fragment:NAME`-Marker: Vorhandenes wird nie doppelt eingebaut und nie erneuert
  (Erneuern bleibt `/update-conventions`); der Platzhaltertext im Slot fällt beim
  Erst-Einbau weg.
- Modulwechsel: das Sprachfragment wird getauscht, Katalog-Fragmente bleiben stehen
  und werden nur zur Prüfung aufgelistet — Entfernen ist Projektentscheidung.
- `new-project` referenziert den Modul-Einbau entsprechend (Standards-Fragmente
  anhängen statt „Slot füllen").

### 0.7.0 — 2026-07-14

`build-step` entkoppelt den step-done-Handoff vom Bauen:

- **Interaktiv (Normalfall):** build-step baut und verifiziert den Substep, startet
  step-done aber **nicht mehr automatisch** — es empfiehlt `/coding-kit:step-done`,
  damit du prüfen und ggf. anpassen kannst, bevor der Schritt fertig ist. Der nächste
  Substep folgt erst nach deinem Abschluss bzw. ausdrücklichem „weiter".
- **Autonomer `/goal`-Lauf:** unverändert — step-done läuft je Substep automatisch
  durch (die `/goal`-Abschlussbedingung verlangt genau das). Modus-Signal: ein aktiver
  `/goal`-Lauf mit erteilter Commit-Freigabe = autonom, jede andere Nutzung = interaktiv.

### 0.6.0 — 2026-07-13

Status-Marker-Konvention + schärfere Grenze zwischen add-feature und prep-step:

- PROGRESS-Einträge tragen jetzt eine sprachinvariante `**Status:**`-Zeile:
  `BACKLOG` (nur aufgenommen → prep-step) → `PLANNED` (geplant → build-step);
  fertig bleibt Done-Tabelle + `(DONE)` im FEATURE-INDEX. prep-step markiert
  zusätzlich die Index-Zeile mit `(PLANNED)`. Alt-Einträge ohne Status-Zeile
  werden tolerant gelesen (Substeps vorhanden ≈ geplant) und beim nächsten
  Kontakt nachgezogen.
- `add-feature` — „Mögliche Umsetzung" heißt jetzt „Lösungsskizze" und ist
  explizit eine grobe, unverbindliche Richtung: keine Dateilisten, keine
  Zerlegung in Schritte, keine Abnahmekriterien (das bleibt prep-step);
  optionale Ablauf-/Ansatz-Zusatzabschnitte gestrichen. Neue Einträge starten
  mit `Status: BACKLOG`.
- `prep-step` — hinterfragt die Lösungsskizze, statt sie blind zu übernehmen:
  jede Annahme gegen den aktuellen Codestand verifizieren, eigene/bessere
  Ansätze mit Begründung vorschlagen; Plan-Vorlage um „Bewertung der
  Lösungsskizze" ergänzt. Setzt nach Freigabe `Status: PLANNED` (auch bei
  kleinen Aufgaben) und zieht die Skizze auf den beschlossenen Stand nach.
- `build-step` — prüft beim Plan-Laden den Status-Marker: `BACKLOG` → erst
  prep-step empfehlen statt ungeplant zu bauen.
- `step-done` — `(DONE)` ersetzt ein `(PLANNED)`-Suffix im FEATURE-INDEX; die
  Status-Zeile wandert nicht mit ins Archiv.
- `docs/skill-authoring.md` — Status-Marker-Konvention als Pflicht-Baustein.

### 0.5.0 — 2026-07-13

Neue Skills:

- `build-step` (Workflow) — die bisher fehlende Implementierungsphase als Skill:
  prep-step-Plan laden, Substeps mit Verifikation je Schritt abarbeiten
  (Write-then-Verify, just-Checks, Abnahmekriterien gegen Tool-Ausgaben abhaken),
  je Substep an step-done übergeben; Scope-Schutz (Entdeckungen → add-feature statt
  still mitbauen), nie pushen. Mit Argument `autonom` baut er nicht, sondern
  bereitet einen `/goal`-Lauf vor: Regeln laden, einmalige laufbezogene
  Commit-Freigabe einholen, fertige Goal-Zeile ausgeben (Varianten mit/ohne
  Commit-Freigabe, Turn-Limit als Stopp-Klausel).

- `teach-step` (Workflow) — Feature geführt selbst umsetzen: der Skill agiert als
  Coding-Lehrer, der Nutzer schreibt allen Code selbst. Sokratischer Lehr-Loop je
  Häppchen (orientieren → Arbeitsauftrag → kontrollieren via git diff/Re-Lesen →
  Tests über just → Verständnisfrage), gestufte Hilfe (Leitfrage → Tipp → Hinweis →
  Pseudocode → Musterlösung nur auf Anfrage), Lern-Interview mit Defaults, optionales
  Graphiti-Lernprofil (persönliche group_id). Schreibverbot hart via
  `disallowed-tools: Write, Edit, NotebookEdit`; Bash nur lesend/prüfend erlaubt.
  Abschluss (PROGRESS, Scans, Commit) bleibt bei `step-done`.
- `refine-prompt` (Utility) — übergebenen Prompt analysieren (Ziel, Zielgruppe,
  Format, Kontext), Schwachstellen benennen, nach Prompt-Engineering-Best-Practices
  neu formulieren und den verbesserten Prompt anschließend ausführen. Nur manuell
  aufrufbar (`disable-model-invocation`).

Geänderte Skills & Vorlagen:

- `step-done` — Ausnahme-Regel zur Commit-Frage: Bei ausdrücklicher, laufbezogener
  Commit-Freigabe des Nutzers (autonomer build-step-Lauf) wird nach grünen Checks
  und Scans ohne erneute Nachfrage committet — nie gepusht, keine History-Rewrites.
  Ohne Freigabe im autonomen Lauf: Commit-Vorschlag festhalten und weiterarbeiten
  statt blockieren.
- `templates/global-CLAUDE.md` — Halbsatz zur Commit-Regel: eine ausdrückliche,
  laufbezogene Freigabe zählt als Fragen; Push bleibt auch dann tabu.

### 0.4.0 — 2026-07-07

Pflege-Skills:

- `update-conventions` — bidirektionaler Konventions-Sync. Abwärts: Projekte via
  Marker-Topic + lokale Checkouts finden, deterministischer Abgleich über
  template-version-Stempel + MANIFEST (Soll-Fassung instanziieren, Diff + Bestätigung
  je Datei, Override-Schutz vor dem Diffen, seed nie anfassen), Altprojekt-Migrationen
  als einzeln bestätigte Schritte (heuristischer Abgleich, instructions.md→CLAUDE.md,
  Core-Skill-Kopien entfernen bei installiertem Plugin, Renovate-Onboarding,
  Tooling-Nachrüstung, Stempel setzen). Aufwärts („promote"): projektlokale Änderung
  generalisieren und mit VERSION-Bump + CHANGELOG (+ MANIFEST) in den Kern heben —
  oder als Override registrieren.
- `check-upstreams` — Watchliste externer Vorbild-Repos (`upstreams.json` im Kit-Repo):
  Neuerungen seit dem persistierten Ref zusammenfassen (gh compare/releases),
  Übernahme-Vorschläge, Ref-Update nach Bestätigung. Startliste: die Muster-Quelle
  ai-coding-starter-kit (Ref auf Analysestand) und betterleaks als
  gitleaks-Nachfolge-Kandidat (Erstprüfung offen).

### 0.3.0 — 2026-07-07

- `new-project` — der Orchestrator: Short-Info-Erhebung (M1), Abfragen mit Defaults
  (Name/Lizenz/Sichtbarkeit/Modul/Doku-Sprache/group_id/Anforderungen, Sub-Skills
  aufrufbar, Aufschieben erlaubt), Plan mit Bestätigung, dann: `gh repo create
  --template` (kein git init), Instanziierung streng nach MANIFEST (Platzhalter,
  adapt-/optional-Marker, public-only, Modul-Kontrakt, Aufräumen der Template-Dateien),
  `template-version`-Stempel, Repo-Settings inkl. Marker-Topic `coding-kit`,
  Verifikation `mise install && just setup && just check`, Personendaten-grep,
  Erst-Commit nur nach OK, Graphiti-Seeding. Trockenlauf via Argument `dry-run`;
  jeder außenwirksame Schritt einzeln bestätigt. Prüft `manifest-format` und bricht
  bei unbekannter Formatversion ab.

### 0.2.0 — 2026-07-07

Begleit-Skills (einzeln nutzbar und von `/new-project` aufrufbar):

- `name-it` — Namenskandidaten nach Kriterien, Verfügbarkeits-Checks (GitHub/npm/PyPI,
  Domain optional) zur Laufzeit.
- `choose-license` — M1-Kurzinterview → Empfehlung (Default Apache-2.0; MIT/MPL-2.0
  als Alternativen; GPL/AGPL nur bewusst; „TBD" gültig).
- `choose-stack` — Modus Neuanlage (Modul-Empfehlung, Websuche-verifiziert) und Modus
  Bestandsprojekt (EIN Modul nachrüsten/wechseln, Diff + Bestätigung je Datei,
  Override-Schutz); Grenze zu `/update-conventions` dokumentiert.
- `define-requirements` — M1-Interview → REQUIREMENTS.md (M5-Struktur) → initiale
  PROGRESS.md (eine F-Nummer je Anforderung); verwaltet den Auflöse-Trigger.
- `refine-requirements` — M2-Diagnose mit drei Pfaden (Änderung von außen /
  Implementierungs-Lücke / Grundsatz-Challenge), darf Features splitten, schreibt
  datierte Decision-Log-Einträge.

### 0.1.0 — 2026-07-07

Erstes Grundgerüst:

- Vier Core-Skills: `add-feature`, `prep-step`, `step-done` (mit Privacy-Scan der
  lebenden Doku), `audit-code` — stack-agnostisch, personendatenfrei, F-NNN-tolerant.
- Projekterkennender Stop-Hook (PROGRESS.md mit FEATURE-INDEX oder
  `.claude/template-version`; blockt höchstens einmal pro Stopp).
- Marketplace `xnyzer` mit Plugin-Quelle im selben Repo.
- Renovate-Shareable-Preset (`default.json`): `config:recommended` + Action-Digest-
  Pinning + Label `dependencies`.
- Idempotenter Installer (`install.sh`) inkl. Personal-Config `~/.claude/coding-kit.env`.

## Eingefroren: project-template bis 0.16.0

All notable changes to the **template content** (`core/` + `modules/`) are documented here.
Every entry corresponds to a `VERSION` bump. `/update-conventions` reads this file to
explain pending updates to projects.

### [0.16.0] — 2026-10-23

#### Added
- `modules/standards/nextjs.md`: an adoption-time requirement up front, mirroring `astro`.
  On the `ts-node` module a Next project deviates from managed files and registers each in
  `.claude/convention-overrides.md` in the same step: `tsconfig.json` shaped for Next
  (bundler resolution, DOM libs, `include`, `next` plugin) — Next rewrites it in place on
  every `next dev` / `next build` / `next typegen` unless it uses `extends` or `references`,
  but leaves the non-fitting `lib` and `nodenext` resolution untouched; `justfile` recipes
  via `next dev` / `next build` and `next typegen` before `tsc --noEmit` in the gate;
  `tsconfig.build.json` removed; `.next/` and `next-env.d.ts` in `.gitignore`. `biome.json`
  needs no change (Biome's `next` domain activates from the dependency).

#### Migration note
- A project that adopted `nextjs` earlier: `/update-conventions` re-checks the requirement.
  Register the deviations the project already made; make the missing ones (most likely
  `next typegen` in the gate and `next-env.d.ts` in `.gitignore`).

### [0.15.0] — 2026-10-23

#### Added
- `modules/standards/astro.md`: new catalog fragment `astro` for static-first sites —
  islands only where needed (`client:only` names its framework, personal data never
  prerendered), Astro's built-in CSP via `security.csp` (not active under `astro dev`,
  `<ClientRouter />` and Shiki not covered, header-only directives from the proxy), build &
  quality gate (client-side imports as the shipped set, sharp/libvips licensing, self-hosted
  fonts, `astro check`, Biome's documented `.astro` override), and the extensionless-import
  exception to the `ts-node` fragment. Catalog row in `modules/standards/README.md`
  (trigger: `astro`).
- The fragment states an adoption-time requirement: on the `ts-node` module an Astro project
  changes the managed `tsconfig.json`, `biome.json` and `justfile`, registers each deviation
  in `.claude/convention-overrides.md` in the same step, and ignores `.astro/`.
- No module pulls the fragment by default. Like `nextjs` it is retrofitted per project via
  `/choose-stack` or `/prep-step`, because its import rule contradicts the `ts-node`
  fragment's `.js`-extension rule.

### [0.14.1] — 2026-10-23

#### Changed
- `core/HOW-TO-CODE-WITH-CLAUDE.md`: a short paragraph below *Overview: skills* states
  where the workflow skills come from (the coding-kit plugin, see *Contributor setup*),
  both call forms — the namespaced `/coding-kit:<skill>` and the short form, which works
  only while no other command or skill has the same name — and that the workflow also
  works by hand without the plugin (PROGRESS.md + `just` recipes).

### [0.14.0] — 2026-10-23

#### Added
- `core/CODING-STANDARDS.md` §1 (Mindset): two readability rules — *simplest viable
  solution wins* (no abstraction on speculation) and *write for the next maintainer*, with
  a checkable yardstick (a teammate new to the code understands it without explanation).
- `core/CODING-STANDARDS.md` §6 (Control flow): *readable over clever* — no dense
  one-liners, long chains or nested loops that must be decoded before changing them; name
  the intermediate steps or extract a helper.
- `core/CODING-STANDARDS.md` §8: secure-coding rules beyond secrets — validate input at
  every trust boundary (allowlist), no injection paths (parameterised queries, argument-list
  process spawning, no dynamic code execution, context-appropriate output encoding),
  authorize every access on the concrete resource (not only at login), least privilege,
  and *secure by default* linking §7 (fail closed, no leaked internals) and §10 (negative
  tests as proof).
- Language fragments `python`, `go`, `ts-node`: one *Safe calls* line each with the
  language's safe variant of the core §8 injection rule (`subprocess` argument lists and
  `yaml.safe_load`, no `pickle` on untrusted data; `exec.Command` with separate args and
  `database/sql` placeholders; `execFile`/`spawn` over `exec`, no `eval`).

#### Changed
- `core/CODING-STANDARDS.md` §8 is renamed from "Security & secrets" to "Secure coding &
  secrets". Section numbers §1–§13 are unchanged, so every "core §N" reference stays valid.
- `core/CODING-STANDARDS.md` §6: the nesting-depth rule now covers loops as well as
  conditionals (target max 2–3 levels).
- `modules/standards/api-design.md`: de-duplicated against core §8 — input validation and
  route authorization reference core §8; the "forbidden by default" list drops dynamic code
  execution, shell strings and interpolated SQL (now core §8) and keeps the web-specific
  items (raw HTML, browser web storage, unstructured logging). "No sensitive data in URLs"
  stays here because it is HTTP-specific.
- `modules/standards/api-design.md`, `modules/standards/nextjs.md`: "whitelist" →
  "allowlist", aligned with core §8.

#### Migration note
- The core changes sit outside the `module:coding-standards` slot of the managed
  `CODING-STANDARDS.md`; the fragment changes sit inside it. `/update-conventions` takes
  over both. Projects that edited §1, §6 or §8 locally merge the new rules by hand.

### [0.13.3] — 2026-10-23

#### Fixed
- `core/mise.toml`: `[settings]` now pins `lockfile_platforms` to the seven common mise
  platforms (`linux-x64`, `linux-x64-musl`, `linux-arm64`, `linux-arm64-musl`,
  `macos-x64`, `macos-arm64`, `windows-x64`), and the header names `mise lock` as the
  generator. Before, the header named `mise install`, which writes versions without
  download URLs for tools already installed on the machine; and a lockfile holding only
  some platforms kept exactly that set through every later `mise install` or plain
  `mise lock`. CI then failed with "No lockfile URL found … on platform linux-x64
  (--locked mode)" (reported from a downstream project). With the setting, plain
  `mise lock` always covers the full set — on first generation, when repairing an
  incomplete lockfile, and on Renovate updates (Renovate runs `mise lock` without a
  platform flag). The setting is the single source of the set; no `--platform` flag is
  used anywhere.
- `MANIFEST.md` § Version stamp: `mise.lock` is generated with `mise lock`, platform set
  from `lockfile_platforms`. Counterpart: coding-kit F-031 (`/new-project`,
  `/choose-stack` and `/update-conventions` run the lock command).

#### Migration note
- Existing projects regenerate `mise.lock` once with `mise lock` after taking over the
  new `core/mise.toml`, then commit it. `/update-conventions` performs this step; until
  it does, run the command by hand.

#### Not changed (recorded decision)
- The template CI (`core/.github/workflows/ci.yml`, `modules/go/ci.part.yml`) gets no
  explicit `--locked`: `jdx/mise-action` adds it on its own whenever the repository holds
  a `mise.lock`, so the lock is already enforced. An explicit `install_args` would only
  add diff to every downstream workflow.

#### Known limitation
- pnpm stopped publishing a `macos-x64` binary during the 11.x line, and the most recent
  releases also lack `linux-arm64-musl`. Projects on the `ts-node` module therefore
  cannot lock (or install) pnpm on those platforms. This is an upstream gap that the
  lockfile cannot close.

### [0.13.2] — 2026-08-11

#### Changed
- `core/HOW-TO-CODE-WITH-CLAUDE.md`: three skill rows now mention that a standards fragment
  can require a change in the project itself, not just the text in the `§13` slot —
  `/choose-stack` (the change is made in the same step and confirmed with it),
  `/update-conventions` (re-checked even when the fragment text is unchanged, the only route
  that reaches a project which adopted a fragment before it carried the requirement) and
  `/prep-step` (the change becomes part of the plan). Counterpart: coding-kit plugin 0.18.0
  / its F-022, which formulates the mechanism once in `/choose-stack` and references it from
  the other skills. `/step-done` is deliberately left as it stands — its backstop only
  reports gaps and its row is terse by design.

#### Not changed (recorded decision)
- The catalog does **not** get a column or marker announcing that a fragment carries such a
  requirement, and `MANIFEST.md` gets no field for it. The requirement lives in the fragment
  prose, which is also what the kit reads; any marker would be a second assertion about that
  prose which no check can enforce — "contains a requirement" is not mechanically decidable,
  so the validator cannot catch drift. A fragment that gains a requirement without gaining
  its marker would then be skipped silently, trading a cheap read of seven fragments for a
  fail-open gap. Revisit when several fragments carry requirements or one is missed in
  practice; the form to prefer then is a declaration line *inside the fragment*, next to the
  prose it summarises, rather than a catalog column — co-location is what keeps the two from
  drifting apart.

### [0.13.1] — 2026-08-11

#### Fixed
- `modules/standards/nextjs.md`: the `agentRules` rule described the wrong branch of Next's
  agent-file routing. It claimed the managed block always lands in `AGENTS.md` with only an
  import added to `CLAUDE.md` — that is the greenfield path, taken only when **neither** file
  exists. A project from this template always has a `CLAUDE.md` and never an `AGENTS.md`, so it
  hits the branch that writes the block **into `CLAUDE.md`**, rewriting the governance file on
  every `next dev` — the exact outcome the rule meant to prevent. The rule now states the
  routing by file state and requires `AGENTS.md` to be created when Next is adopted, before the
  first `next dev`, which is what makes the block land in `AGENTS.md`.
- Same rule: added the remediation order. Once the block sits in `CLAUDE.md`, adding an
  `AGENTS.md` afterwards does not move it — Next keeps updating whichever file hosts it, so the
  block has to be removed from `CLAUDE.md` in the same step. A project currently holding
  `agentRules: false` can drop that override once it creates `AGENTS.md`.

### [0.13.0] — 2026-08-11

#### Changed
- `core/.claude/settings.json`: the env enumeration introduced in 0.12.0 is replaced by a
  deny set that carves the `.env.example` exception out by hand, using positive character
  classes that exclude one letter each (`**/.env.[0-9a-df-z_-]*`, `**/.env.e[0-9a-wy-z_-]*`,
  `**/.env.ex[0-9b-z_-]*`, `**/.env.example?*`, plus `**/.env` and `**/.env[0-9a-z_-]*` for
  the undotted forms such as `.envrc`). Six patterns per tool; `.env.example` is the only
  spelling no deny rule matches, and its allow entries are back in force. The placeholder
  keeps its conventional name.
- `core/.gitignore`: `.env` + `.env.*` collapse to `.env*`, keeping `!.env.example`.
- `core/.claude/README.md`: the TPL-001 caveat about `.env.example` possibly being blocked is
  replaced by the rationale for the deny set, including the two matcher properties it depends
  on (no negation; case-insensitive matching) and the known residual.
- `modules/standards/nextjs.md`: the `agentRules` rule is reversed — the generator stays **on**.
  It writes a managed block into `AGENTS.md` and an import into `CLAUDE.md`, upserting both, so
  content outside the markers survives; the block is committed with the work rather than
  deleted. `AGENTS.md` is framework-owned, `CLAUDE.md` keeps its governance role. Turning the
  generator off is now the documented exception, not the rule.

#### Fixed
- 0.12.0 traded the template's documented fail-safe posture for a fail-open one: with the
  enumerated deny, unlisted variants such as `.env.bak` (a literal copy of a real `.env`),
  `.env.prod`, `.env.ci` or `.env.keys` were readable **without a prompt**, since read-only
  tools need no approval inside the working directory. The new deny set restores the
  fail-closed behaviour TPL-001 intended *and* keeps `.env.example` writable — 0.12.0 could
  only have one of the two.

### [0.12.0] — 2026-08-11

#### Added
- `modules/standards/nextjs.md`: new catalog fragment `nextjs` for the App Router — the
  server/client boundary (`"use client"` as a leaf, `server-only` on credential-bearing
  modules, `NEXT_PUBLIC_*` as a publication decision, Server Actions as public endpoints),
  routing & caching, assets & build (standalone `HOSTNAME`, `agentRules: false`), the
  `NODE_ENV`/`PORT` and `instrumentation.ts` configuration traps, and the extensionless-import
  exception to the `ts-node` fragment. Catalog row in `modules/standards/README.md`
  (trigger: `next`).
- No module pulls the fragment by default. Like `react` and `prisma` it is retrofitted per
  project via `/choose-stack` or `/prep-step`: `ts-node` stays framework-neutral, and its
  `.js`-extension rule directly contradicts Next's bundler resolution — declaring `nextjs` on
  the module would ship two contradictory import rules to every plain TypeScript project.

#### Fixed
- `core/.claude/settings.json`: the tracked `.env.example` placeholder was unreadable and
  unwritable. `permissions.deny` carried the broad `Read(**/.env.*)` / `Edit(**/.env.*)`,
  which shadowed the explicit `Read(**/.env.example)` / `Edit(**/.env.example)` allow entries —
  deny wins over allow, and a deny rule cannot carry allowlist exceptions. The broad pattern is
  replaced by the secret-bearing variants (`.env.local`, `.env.*.local`, `.env.development`,
  `.env.production`, `.env.test`, `.env.staging`), so every real env file stays blocked while
  the placeholder that `.gitignore` includes via `!.env.example` can be created and edited.

### [0.11.3] — 2026-08-11

#### Fixed
- `modules/ts-node`: a freshly instantiated project no longer starts with a red
  `just check` — `files/src/index.test.ts` and `files/vitest.config.ts` used single
  quotes while Biome (no quote-style override) formats to double quotes, so the very
  first `biome ci` failed on two format errors.

#### Changed
- `modules/ts-node/files/biome.json`: `$schema` now resolves from
  `./node_modules/@biomejs/biome/configuration_schema.json` instead of a version-pinned
  biomejs.dev URL, so it always matches the installed CLI and cannot drift when Renovate
  bumps the dependency; `linter.rules.recommended` replaced by `linter.rules.preset`
  (the former is deprecated and goes away in the next Biome major).

### [0.11.2] — 2026-07-20

#### Added
- `core/HOW-TO-CODE-WITH-CLAUDE.md`: new maintenance-table row for `/go-public` —
  the guided, fail-closed transition of a private or local-only project to public
  (blocking preflight audit, file catch-up before the switch, per-run push
  approval; counterpart: coding-kit plugin 0.17.0).

### [0.11.1] — 2026-07-20

#### Changed
- `core/HOW-TO-CODE-WITH-CLAUDE.md`: the `/update-conventions` row now reflects the
  seed-section sync — updates arrive per managed file, per standards fragment and per
  marked seed section (`section:NAME`); seed files are never replaced as a whole
  (counterpart: coding-kit plugin 0.15.0).

### [0.11.0] — 2026-07-20

#### Added
- Section-marker contract for updatable zones in seed files: seed files stay living
  documents, but template-owned zones are wrapped in `<!-- section:NAME -->` …
  `<!-- /section:NAME -->` markers that `/update-conventions` may diff and offer
  individually — never the whole file. `MANIFEST.md` registers the marker, adjusts the
  seed policy wording, and documents the contract plus the zone inventory in a new
  § Seed sections (CLAUDE.md Graphiti/startup/conventions/workflow zones; the PROGRESS,
  PROGRESS-ARCHIVE and REQUIREMENTS head notes; the README getting-started block; the
  convention-overrides head). `manifest-format` stays 1 — the change is additive and the
  kit feature-detects by marker presence. The validator's balanced-marker check now
  covers `section:` markers alongside `fragment:` and enforces unique section names per
  file. All six seed skeletons carry their markers (wrappers only, no prose changed).

### [0.10.0] — 2026-07-19

Per-dimension language matrix — project languages are chosen at instantiation and
decoupled from repo visibility.

#### Changed
- `core/CLAUDE.md`: the single living-doc language line becomes a **Languages block**
  with five independently chosen dimensions — living docs (`{{LANG_LIVING_DOCS}}`),
  CLAUDE.md prose (`{{LANG_CLAUDE_MD}}`), code comments & docstrings
  (`{{LANG_COMMENTS}}`), commit-message prose (`{{LANG_COMMITS}}`), README & public
  docs (`{{LANG_README}}`). Identifiers, Conventional-Commit tokens, status tokens,
  and governance docs stay English regardless. The git convention bullet now reads
  "Conventional Commits (tokens English), prose in {{LANG_COMMITS}}".
- `core/PROGRESS.md`, `core/REQUIREMENTS.md`, `core/HOW-TO-CODE-WITH-CLAUDE.md`:
  reference the new placeholders instead of `LIVING_DOC_LANGUAGE`.
- `MANIFEST.md` placeholder registry: `LIVING_DOC_LANGUAGE` replaced by the five
  `{{LANG_*}}` placeholders; the former visibility-coupled default
  ("German (private) / English (public)") is gone — values come from the
  `/new-project` language preset (default: English). Downstream, the coding-kit
  interview offers presets (all-English, working-language docs with English
  outward-facing content, all-working-language, custom per dimension).

#### Migration note
- Projects instantiated before 0.10.0 carry the old single-line language convention;
  `/update-conventions` migrates it to the Languages block (existing living-doc
  language kept, other dimensions defaulting to English).

### [0.9.0] — 2026-07-19

Docs alignment with the current coding-kit skill set; no rule text or file set changed.

#### Changed
- `core/HOW-TO-CODE-WITH-CLAUDE.md`: refresh the skill overview for the current coding-kit —
  `/prep-step` additionally checks standards coverage when a task introduces new
  frameworks/dependencies (matching the catalog's dependency signals **and** characteristic
  triggers; proposes appending missing catalog fragments, or authoring a project-local
  fragment with a manual adoption proposal for the template); `/step-done` gains a
  non-blocking, diff-based standards-coverage backstop (new manifest dependencies or signal
  files without a fragment are reported with an append proposal); `/choose-stack` composes
  the module's declared catalog fragments (append, idempotent per `fragment:NAME` marker)
  and retrofits characteristic fragments after confirmation; `/update-conventions` syncs
  fragment-granular and downward only, never touching project-local fragments;
  `/define-requirements` asks the catalog's characteristic triggers in the interview.
- `modules/standards/README.md`: describe trigger evaluation as implemented — `/prep-step`
  matches both signal types; characteristic triggers are asked in the requirements
  interview, at feature planning, and retrofittable via `/choose-stack`.
- Sync direction made explicit across the docs (`MANIFEST.md` § Sync direction, root
  `README.md`, root `CONTRIBUTING.md`): convention flow is exclusively downward
  (template → project); the former upstream/promote path is gone — contributions from
  projects arrive as manually initiated adoption proposals (template session or GitHub
  issue), never as automatic writes.

### [0.8.0] — 2026-07-18

#### Added
- `core/scripts/privacy-lint.sh` plus a `privacy-lint` pre-commit job in
  `core/lefthook.yml`: every project now blocks commits that would leak private
  identifiers. Generic patterns (absolute local paths, IPs and email addresses outside
  the documentation allowlists) always apply; an optional gitignored
  `private/blocklist.txt` adds project-private terms and is silently skipped where
  absent (e.g. in CI). POSIX sh + grep only — no new toolchain dependency. Convention
  documented in `core/private/README.md`; the secrets-policy section in
  `core/CONTRIBUTING.md` now names the full pre-commit gate; registered as a managed
  file in `MANIFEST.md`.

### [0.7.1] — 2026-07-18

#### Changed
- `modules/README.md`: clarify that `standards/` is not a stack module but the
  cross-cutting catalog of reusable CODING-STANDARDS fragments, with a pointer to its
  own README.

### [0.7.0] — 2026-07-18

#### Added
- Standards fragment `audit-logging` in the `modules/standards/` catalog: accountability
  trail for services with user/admin mutations — what must be logged (domain mutations,
  permission/role changes, auth and admin operations, including denied attempts), what an
  entry carries (actor, action, target, timestamp, outcome — never secrets or full
  payloads), properties (append-only, coupled to the mutation, queryable, deliberate
  retention), and the separation from application logging.

#### Changed
- `modules/standards/README.md`: the catalog mapping now supports **project-characteristic
  triggers** alongside dependency signals — for fragments (like `audit-logging`) that no
  package manifest can reveal; evaluating those triggers stays coding-kit logic.

### [0.6.0] — 2026-07-18

#### Added
- `core/CODING-STANDARDS.md` §7 (heading extended to "Error handling, resilience &
  concurrency"): two language-agnostic concurrency rules — deduplicate concurrent async
  work via an in-flight promise/future that every concurrent caller awaits (applies where
  shared mutable state, several independent async triggers, and expensive or side-effectful
  work meet; cheap idempotent reads need no guard), and set the completion marker only
  after the awaited work finishes, so concurrent readers never observe a half-finished
  state as done. No section renumbering.

### [0.5.0] — 2026-07-17

#### Added
- Standards fragments `api-design`, `docker`, and `nginx` in the `modules/standards/` catalog,
  completing the initial web set. `api-design` covers thin-routes/fat-services, URL/method/
  status conventions, schema-validated request/response, and the web security boundary
  (explicit authorization, rate limiting, forbidden patterns, credentials & data protection,
  security headers); `docker` covers multi-stage images, non-root runtime, layer caching,
  healthchecks, PID-1 signal handling, compose and entrypoint/startup; `nginx` covers the
  reverse-proxy hardening (per-location header re-declaration, WebSocket, compression, SPA
  cache strategy, HSTS placement). Generalized and senior-hardened; registered in the mapping.

### [0.4.0] — 2026-07-17

#### Added
- Standards fragments `react` and `prisma` in the `modules/standards/` catalog (the first
  entries), generalized from real full-stack sources and senior-hardened: `react` covers
  function-component/hooks discipline, component size, design-token/slot-based styling,
  accessibility, i18n and performance; `prisma` covers deliberate querying (no N+1,
  paginate, transactions, one client, explicit constraint handling) and immutable
  migrations with DB-enforced integrity. Registered in the framework→fragment mapping.

### [0.3.1] — 2026-07-17

#### Changed
- Migrated the existing stack modules to the fragment scheme: each module's
  `CODING-STANDARDS.part.md` (go/python/ts-node) is now wrapped in `<!-- fragment:<module> -->`
  … `<!-- /fragment:<module> -->` markers (content otherwise unchanged), and each `MODULE.md`
  declares its (empty) `Standards fragments` set. Makes the parts conform to the append
  contract without changing any rule text.

### [0.3.0] — 2026-07-17

#### Added
- Composable CODING-STANDARDS fragments — contract + scaffold. The §13 stack slot is now
  append-capable: standards fragments are each wrapped in `<!-- fragment:NAME -->` …
  `<!-- /fragment:NAME -->` and appended inside `<!-- module:coding-standards -->`, so a project
  composes several language/framework fragments instead of a single inserted block. Adds the
  `modules/standards/` catalog (`README.md` with the framework→fragment mapping; the fragments
  themselves are authored next) and documents the marker, the module `Standards fragments:`
  declaration, and the catalog in `MANIFEST.md`. Migrating the existing go/python/ts-node parts
  and validator support follow separately.

### [0.2.0] — 2026-07-17

Refinements surfaced by running `/update-conventions` against an instantiated project, and
one template bug it exposed. Project-specific divergences there (a pnpm toolchain, filled
`template:adapt` slots, a fuller stack-specific CODING-STANDARDS, a bilingual HOW-TO) stay as
registered overrides in that project and were not promoted.

#### Added
- `core/AI-DISCLOSURE.md`: a general "Why this matters" section (human/AI collaboration
  model), present for every project.
- `core/CODING-STANDARDS.md`: new language-agnostic section 5 "Comments & documentation"
  (comment the *why*; document the public surface; English identifiers) — sections 6–13
  renumbered accordingly.
- `core/CODING-STANDARDS.md` §8: the "never commit" list now names real identifiers
  (people, customers, concrete projects) alongside secrets and deployment internals.

#### Changed
- `core/CLAUDE.md`: add `/build-step` to the build chain in both "Status & where to start"
  (`prep-step → build-step → step-done`) and the "Workflow & skills" skill list.
- `core/CLAUDE.md`: scale the startup reading guidance — read `README`/`REQUIREMENTS` and
  `PROGRESS.md`'s open tasks + `FEATURE-INDEX`; scan (don't fully read) a large Done
  table/backlog; consult `PROGRESS-ARCHIVE.md` on demand, not at startup. Saves context.
- `core/HOW-TO-CODE-WITH-CLAUDE.md`: refresh the skill overview to match the current
  coding-kit — add `/build-step`, `/teach-step` and a grouped "project maintenance" table
  (`/choose-stack`, `/choose-license`, `/update-conventions`, define/refine-requirements);
  note `/audit-code`'s optional scope; rewrite Workflow 2 as the `prep-step → build-step →
  step-done` loop with the `BACKLOG → PLANNED → done` status markers.
- `modules/{go,python,ts-node}`: section cross-references follow the renumbering above —
  `CODING-STANDARDS.part.md` (§6→§7 errors, §9→§10 tests, §7→§8 licenses) and `MODULE.md`
  (§12→§13, the stack slot). References to §1–§4 are unaffected.

#### Removed
- `core/AI-DISCLOSURE.md`: the optional `security-tool` block. Its content was
  engineering-practice claims (vetted libraries, fail-closed, mandatory security review),
  not AI disclosure, and it duplicated `CODING-STANDARDS.md` §7/§8; the security policy
  belongs in `SECURITY.md`. The file is now identical in every project — `MANIFEST.md`
  updated accordingly (the `template:optional` mechanism remains, used by `graphiti`).

#### Fixed
- `core/private/README.md` now exists. `MANIFEST.md` listed it as a managed source and
  `.gitignore` whitelists it (`!private/README.md`), but the file was missing — every
  instantiation lacked the `private/` convention marker.

### [0.1.0] — 2026-07-07

#### Added
- Initial `core/`: governance documents (CODING-STANDARDS, CONTRIBUTING, SECURITY,
  HOW-TO-CODE-WITH-CLAUDE, AI-DISCLOSURE, CODE_OF_CONDUCT), PROGRESS/PROGRESS-ARCHIVE
  skeletons with FEATURE-INDEX, REQUIREMENTS template, hardened `.claude/settings.json`,
  convention-overrides registry, issue forms + PR template, hardened CI (`just check`),
  CodeQL toggle workflow, justfile/mise/lefthook/renovate/editorconfig/gitattributes/
  gitignore, `private/` convention, ADR scaffold, README scaffold, LICENSE default.
- Initial modules: `docs-only`, `ts-node`, `python`, `go` (full); `swift-ios`, `java` (stubs).
- `MANIFEST.md` (manifest-format 1) with placeholder/marker conventions and file policies.
