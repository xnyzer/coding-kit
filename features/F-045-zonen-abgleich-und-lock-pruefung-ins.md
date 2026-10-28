---
id: F-045
title: Zonen-Abgleich und Lock-Prüfung ins Skript
type: feature
status: DONE
size:
created: 2026-10-25
done: 2026-10-26
depends-on:
superseded-by:
---

# F-045 — Zonen-Abgleich und Lock-Prüfung ins Skript

## Verlauf

### F-045a — `zones` und die Override-Regel (2026-10-26)

Teil von F-045 (Zonen-Abgleich und Lock-Prüfung ins Skript; F-045b–d folgen).

**Problem:** Den Abgleich der seed-Zonen und der Fragmente im Slot (update-conventions A2
Schritte 6 und 7) machte das Sprachmodell selbst — Testläufe bauten ihn mit eigenem awk
nach oder ließen ihn aus. Die Kopfzone der Registry-Vorlage nannte den Override-Marker als
Doku-Text, sodass eine wörtliche Suche die Zone für geschützt hielt. `snapshot` meldete
Ziele, die als ein einziges Argument kamen, still als `removed` (Fund aus F-043c).

**Was entstanden ist (1.5.0, unveröffentlicht):**

- **`template-sync.sh zones [--base DIR] [--registry FILE] [--snapshot DIR] PROJECT SEEDS
  OUT [NAME…]`:** vergleicht die `section:NAME`-Zonen der gerenderten Dateien
  (`render --seeds`) und die `fragment:NAME`-Blöcke im Slot mit dem Projekt. Je Block eine
  Zeile `<Ziel> <section|fragment> <Name> <Zustand> <+a -d>` mit den Zuständen
  `identical`, `differs`, `override`, `new`, `opted-out`, `unmarked`, `local`, `no-file`,
  `broken` und `skipped`; ein Block, den keine Seite hat, bekommt keine Zeile (z. B.
  `claude-graphiti` ohne Graphiti). Bei geschützten Fragmenten zählt die Spalte, was das
  Template seit der Basis geändert hat.
- **Ergebnis wie bei `merge`:** `OUT/<Ziel>` ist die Projektdatei mit allen abweichenden
  und neuen Blöcken eingesetzt, mit Namen nur den genannten. Abweichende Blöcke werden
  ersetzt; ein neues Fragment kommt hinter seinen nächsten Vorgänger aus dem Render, der
  im Slot steht, ohne Vorgänger an den Slot-Anfang, in einem Slot ohne Fragmente anstelle
  des Platzhaltertexts. `OUT/.zones/<Art>/<Name>.<project|template|base>` halten die
  Blöcke für die Diffs. Ein Name ohne einsetzbaren Block, mehrere Namen in einem Argument
  und kaputte Marker im Render brechen mit Exit 1 ab.
- **Marker-Regel:** Ein Marker (Slot, Zone, Fragment, Override) gilt nur allein auf einer
  Zeile. `zones` wertet nur solche Zeilen aus, `detect` zählt einen Fragment-Marker mit
  Text auf derselben Zeile nicht mehr, und der Validator verlangt die Regel für Zonen- und
  Fragment-Marker im Template. MANIFEST §§ Markers, Seed sections und Standards fragments
  beschreiben Regel und Befehl.
- **Registry-Vorlage:** Die Kopfzone `overrides-head` beschreibt das Override ohne
  marker-ähnlichen Text; sie kommt per `zones` in die Projekte.
- **`snapshot`** prüft alle Ziele vor dem ersten Schreiben und weist eines ab, das weder
  gerendert ist noch eine Basis hat.
- **Tests:** `tests/template-sync/zones.sh` (neu): alle Zustände, CRLF, Override-Zeile und
  Override im Text, Prosa-Zeilen mit Markern (Text davor und dahinter, auch im Slot),
  Einsetzen an der Stelle aus dem Render, Platzhalter, Slot-Anfang, `skip`, Auswahl per
  Name, `--snapshot`, `--base` und Fehlerfälle. Frische Renders (docs-only mit und ohne
  Graphiti, ts-node) ergeben nur `identical`; die Kopfzone mit dem alten Override-Text
  ergibt `differs`, und das Ergebnis ist wieder die gerenderte Datei. Die
  `snapshot`-Fälle stehen in `sync.sh`, der Prosa-Marker für `detect` in `detect.sh`.
- **Version:** `plugin.json` 1.5.0, CHANGELOG-Eintrag mit `### Template` samt Hinweis zur
  strengeren Override-Regel.

**Verifikation:** `just check` grün (Validator, 690 Skript-Tests unter dash und bash, 138
davon neu); dieselbe Suite auch mit mawk als `awk` grün. Fehlerinjektion an einer Kopie:
Override-Erkennung aus, Override im Text zählt, neues Fragment immer an den Slot-Anfang,
`skip` ignoriert, Platzhalter nicht ersetzt, Ziel-Prüfung in `snapshot` aus, Marker ohne
Anker am Zeilenanfang bzw. -ende — alle gefangen (16, 6, 6, 4, 2, 6, 4 und 2
Fehlschläge). Versionsregel gegen `origin/main` grün.

**Notable decisions:**
- `zones` nimmt über den Plan hinaus auch `--base` (Migration mit gerenderter Basis) und
  `--registry` (eine `skip`-Zeile gilt auch für Zonen) — wie `merge`.
- Ohne Basis bekommt ein geschütztes Fragment keine Zählung: Ob das Template sich
  geändert hat, lässt sich dann nicht sagen. Bisher zeigte der Skill in diesem Fall den
  Diff Projekt → Template.
- Text im Slot außerhalb von Fragmenten gilt als Platzhalter und weicht dem ersten neuen
  Fragment, wie beim Render (MANIFEST § Module contract).
- Ergebnisse sind wie bei `merge` auf LF normalisiert.
- mawk-Fund: Ein awk-Array namens `NF` (eingebaute Variable) nimmt das macOS-awk hin,
  mawk — Standard auf Ubuntu und in der CI — nicht; umbenannt. Die Tests liefen deshalb
  zusätzlich mit mawk per PATH-Link; mawk bleibt außerhalb der Toolchain (GPL-2.0).

**Geänderte Dateien:**
`plugins/coding-kit/scripts/template-sync.sh`, `tests/template-sync/zones.sh` (neu),
`tests/template-sync/run.sh`, `tests/template-sync/sync.sh`,
`tests/template-sync/detect.sh`, `plugins/coding-kit/template/MANIFEST.md`,
`plugins/coding-kit/template/core/.claude/convention-overrides.md`,
`scripts/validate.py`, `plugins/coding-kit/.claude-plugin/plugin.json`,
`plugins/coding-kit/CHANGELOG.md`, `PROGRESS.md`, `PROGRESS-ARCHIVE.md`.

### F-045b — `lock-check` (2026-10-26)

Teil von F-045 (Zonen-Abgleich und Lock-Prüfung ins Skript; F-045a siehe darunter,
F-045c–d folgen).

**Problem:** Die Prüfung der `mise.lock` auf Plattform-Einträge (choose-stack
§ Lock-Datei, update-conventions A2 Schritt 11) machte das Sprachmodell selbst — mit
eigenem awk oder gar nicht. Ob Backend-Tools wie `npm:` Plattform-Einträge brauchen, war
ungeklärt.

**Was entstanden ist (1.5.0, unveröffentlicht):**

- **`template-sync.sh lock-check PROJECT`:** liest `lockfile_platforms` aus `[settings]`
  der `mise.toml` (ein- und mehrzeilig, mit Kommentaren, beide Anführungszeichen), die
  Einträge der `mise.lock` (auch Schlüssel in Anführungszeichen, ein Eintrag je Version;
  eine Plattform-Tabelle gehört wie in TOML zum letzten Eintrag ihres Tools) und die
  CI-Plattform aus den `runs-on`-Zeilen der Workflows mit `jdx/mise-action`.
- **Ausgabe:** Kopfzeilen `platforms` (Liste oder `missing`), `ci` je Runner (Plattform,
  Label, Workflow; `unknown` für Ausdrücke und self-hosted Runner, `none` ohne
  mise-Workflow) und `lockfile missing`; ohne Einstellung oder Lock-Datei folgt nichts
  weiter. Dann je Lock-Eintrag bzw. konfiguriertem Tool
  `tool <Name> <Version> <Zustand> <fehlende Plattformen>` mit `complete`, `gaps`,
  `ci-gap`, `no-url`, `unlocked` oder `stale`.
- **Runner-Labels** nach der GitHub-Doku: `ubuntu-*-arm` → linux-arm64, übrige
  `ubuntu-*` → linux-x64; `macos-13`, `macos-*-intel` und `macos-*-large` → macos-x64,
  übrige `macos-*` (auch `-xlarge`) → macos-arm64; `windows-*-arm` → windows-arm64,
  übrige `windows-*` → windows-x64.
- **Backends ohne URL:** `NO_URL_BACKENDS` im Skript nach der mise-Doku (mise.lock
  § Backend support): `asdf`, `cargo`, `dotnet`, `gem`, `go`, `npm`, `pipx`, `pypi`,
  `spinel`, `spm`, `ubi`, `core:dotnet`, `core:rust`, `core:swift`. Ihre Einträge sind
  `no-url`, nie eine Lücke.
- **Tests:** `tests/template-sync/lock.sh` (neu) mit Fixtures im Format von `mise lock`:
  alle Zustände, zwei Versionen eines Tools, `[tools.NAME]`-Tabelle in der `mise.toml`,
  CRLF, einzeilige Einstellung, keine CI, fehlende Einstellung und Lock-Datei, eine
  nachgestellte Plattform-Tabelle, Fehlerfälle und elf Runner-Labels.
- **CHANGELOG:** Eintrag für `lock-check`; Abschnitt „Known limitation" mit dem Nachtrag
  zu pnpm — für `linux-arm64-musl` gibt es wieder ein Release, für `macos-x64` weiterhin
  nicht.

**Gegenprobe mit echtem `mise lock`** (Wegwerf-Projekte, `MISE_TRUSTED_CONFIG_PATHS`):

- Voller Lock mit `just`, `node`, `pnpm`, `github:BurntSushi/ripgrep`, `npm:prettier` und
  `cargo:tokei`: URL-Backends `complete`; npm und cargo ohne Plattform-Tabellen →
  `no-url`; pnpm 11 ohne `macos-x64` → `gaps`.
- Ein Lock nur für `macos-arm64` → `ci-gap` für alle URL-Backends.
- `npm:prettier` installiert mit `mise install --locked` auch ohne Plattform-Einträge.
- `mise install` allein schreibt Einträge ganz ohne Plattform-Tabellen. Deshalb
  entscheidet das Backend, nicht das Fehlen der Tabellen — sonst bliebe der Fehler aus
  F-031 unentdeckt.
- Aufgeräumt: die Testinstallation von prettier entfernt, zwei Trust-Einträge gelöscht,
  die `mise install` trotz `MISE_TRUSTED_CONFIG_PATHS` anlegte.

**Verifikation:** `just check` grün (Validator, 780 Skript-Tests unter dash und bash, 90
davon neu); dieselbe Suite mit mawk grün; die Lock-Datei dieses Repos ergibt mit gesetzter
Einstellung `complete` für alle vier Tools. Fehlerinjektion an einer Kopie: Liste ohne URL
leer, CI-Lücke nie blockierend, Plattform-Tabelle beim falschen Eintrag, `stale` und
`unlocked` aus, arm-Runner nicht erkannt, Workflows ohne mise mitgezählt, mehrzeilige
Einstellung nicht gelesen, Eintrag ohne Tabellen als vollständig — alle gefangen (4, 4,
4, 2, 6, 2, 2, 28 und 2 Fehlschläge). Versionsregel gegen `origin/main` grün.

**Notable decisions:**
- Eine Zeile je Lock-Eintrag statt je Tool, mit Version: Zwei Versionen eines Tools
  können verschiedene Lücken haben.
- Die Backends ohne URL stehen als Liste aus der mise-Doku im Skript; eine strukturelle
  Regel („keine Tabelle = harmlos") ließe den F-031-Fehler durch.
- Ohne `lockfile_platforms` oder ohne Lock-Datei gibt es keine Tool-Zeilen: Die
  Einstellung bringt update-conventions, die Lock-Datei `mise lock`.
- Die Fehlerinjektion zeigte, dass eine Plattform-Tabelle hinter dem Eintrag eines
  anderen Tools verworfen wurde; der Parser folgt jetzt der TOML-Regel.
- `sed` mit `\t` im Ersatztext durch awk ersetzt — POSIX legt `\t` dort nicht fest.
- Bekannte Grenzen: vfox-Backend-Plugins stehen nicht in der Liste (Namensformat unklar)
  und würden als Lücke gemeldet; Tools, die nur mise-Tasks deklarieren, erscheinen als
  `stale` — das Kit nutzt keine mise-Tasks.

**Geänderte Dateien:** `plugins/coding-kit/scripts/template-sync.sh`,
`tests/template-sync/lock.sh` (neu), `tests/template-sync/run.sh`,
`plugins/coding-kit/CHANGELOG.md`, `PROGRESS.md`, `PROGRESS-ARCHIVE.md`.

### F-045c — Skills anbinden (2026-10-26)

Teil von F-045 (Zonen-Abgleich und Lock-Prüfung ins Skript; F-045a–b siehe darunter,
F-045d folgt).

**Problem:** update-conventions und choose-stack beschrieben den Abgleich von Fragmenten
und seed-Zonen und die Prüfung der Lock-Datei als Arbeit des Modells; die Befehle `zones`
und `lock-check` aus F-045a–b nutzte noch kein Skill.

**Was entstanden ist (1.5.0, unveröffentlicht):**

- **update-conventions:**
  - Grundsatz: Auch Zonen, Fragmente und die Lock-Datei vergleicht und setzt das Skript;
    der Skill setzt nie selbst etwas ein.
  - A2 Schritt 6: `render --seeds` und `zones` — ausdrücklich erst nach dem Kopieren der
    Merge-Ergebnisse aus Schritt 5. Diffs kommen aus den Blockdateien unter `.zones/`.
    Übernehmen heißt, das Ergebnis zu kopieren; bei teilweiser Zustimmung läuft `zones`
    ein zweites Mal mit den angenommenen Namen. Je Fragment-Zustand eine Handlung:
    `local` mit Katalog-Prüfung vor `propose-to-template`, `override` mit Info-Diff aus
    der Basis.
  - A2 Schritt 7: die seed-Zonen aus demselben Lauf, je Zustand eine Handlung; die
    Sonderregel für `claude-graphiti` entfällt, weil das Skript eine Zone ohne beide
    Seiten nicht meldet.
  - Schritt 11, A3 Schritt 4 und der Modus `status` prüfen die Lock-Datei über
    `lock-check`; die Marker-Migration nutzt die Template-Blöcke aus `zones`.
- **choose-stack:**
  - § Lock-Datei: `lock-check` mit einer Handlung je Zeile — `ci-gap` blockiert, `gaps`
    gegen „Known limitation", `ci unknown` → nach der Plattform des Runners fragen,
    `ci none` blockiert nicht, `lockfile missing`/`unlocked`/`stale` → `mise lock`,
    `no-url` → nichts zu tun.
  - Modus B: Fragmente über `zones` — der Plan zeigt `new` und `local`, eingesetzt wird
    nach dem Kopieren der Merge-Ergebnisse mit den bestätigten Namen. Tausch des
    Modul-Fragments: das neue als `new`, der alte Block nach Bestätigung entfernt.
  - „Ein Fragment anhängen" heißt für alle Skills: Name in `FRAGMENTS`, `render --seeds`,
    `zones` mit dem Namen, Ergebnis kopieren.
- **README:** Die Zeilen zu update-conventions und choose-stack nennen das Skript.
- **`docs/skill-authoring.md`** § Hilfsskripte: Auch das Einsetzen gehört ins Skript,
  teilweise Zustimmung über einen zweiten Lauf; neues awk vor dem Commit zusätzlich mit
  mawk testen.
- **CHANGELOG:** Punkt „Skills angebunden".

**Verifikation:** `just check` grün (Validator, 780 Skript-Tests); Versionsregel gegen
`origin/main` grün; grep nach den alten Formulierungen (Fragment gegen sein
Template-Pendant diffen, Zone gegen die gleichnamige Zone diffen, Inline-Override,
Plattform-Tabellen von Hand zählen, Stelle aus `<tmp>/soll`, `runs-on` von Hand ableiten,
Platzhaltertext von Hand entfernen) ohne Treffer in Skills, README und HOW-TO.

**Notable decisions:**
- Die Schrittnummern von update-conventions bleiben (6 Fragmente, 7 Zonen), obwohl ein
  `zones`-Lauf beide bedient — andere Skills und die Doku verweisen auf sie.
- new-project bleibt unverändert: Es verweist auf choose-stack § Lock-Datei und bekommt
  die Änderung darüber.
- Die HOW-TO im Template bleibt unverändert; sie beschreibt das Verhalten aus
  Nutzersicht, das gleich bleibt. F-045c ändert damit keinen Template-Inhalt.
- Die geänderten Skill-Texte testet erst der Lauf in F-045d mit `--plugin-dir`.

**Geänderte Dateien:** `plugins/coding-kit/skills/update-conventions/SKILL.md`,
`plugins/coding-kit/skills/choose-stack/SKILL.md`, `README.md`,
`docs/skill-authoring.md`, `plugins/coding-kit/CHANGELOG.md`, `PROGRESS.md`,
`PROGRESS-ARCHIVE.md`.

### F-045d — Testlauf, Release, Gegenprobe (2026-10-26)

Schließt F-045 ab (Zonen-Abgleich und Lock-Prüfung ins Skript; F-045a–c siehe darunter).

**Problem:** Die Befehle `zones` und `lock-check` und ihre Anbindung in update-conventions
und choose-stack (F-045a–c) waren nur durch Skript-Tests belegt. Ob ein Modell-Lauf sie
wirklich nutzt und nichts mehr von Hand einsetzt, zeigt erst ein echter Lauf.

**Was entstanden ist (Release 1.5.0):**

- **Testlauf** (`claude -p --plugin-dir`, Opus auf `medium`, Budget-Cap 4 USD; 0,91 USD,
  17 Turns, 105 s, 15 Werkzeugaufrufe) an einem docs-only-Projekt, gerendert aus Template
  1.4.0 (`base-from-history`) mit Stempel 1.4.0: zwei abweichende Zonen in `CLAUDE.md`,
  eine Override-Zeile in `python-lang`, ein `Dockerfile` (die Erkennung schlägt `docker`
  vor) und eine Lücke für `just` auf linux-x64 in der `mise.lock`. Vorgabe im Prompt:
  `claude-workflow` diesmal nicht, alles andere übernehmen.
  - Der Lauf nahm `docker` in `FRAGMENTS` auf, ließ `zones` laufen, zeigte die Diffs aus
    `.zones/` und setzte nach der teilweisen Zustimmung mit einem zweiten Lauf nur
    `overrides-head`, `claude-startup` und `docker` ein — nichts von Hand.
  - `lock-check` zeigte `ci-gap` für `just`, nach `mise lock` `complete`.
  - Endstand per Skript (die vorbereiteten Dateien unter `.claude/` vom Tester kopiert):
    angenommene Blöcke `identical`, `claude-workflow` weiter `differs`, `python-lang`
    `override`; `lock-check` ohne `ci-gap`; `status` ohne Abweichung; `docker`
    `covered`; Stempel 1.5.0.
- **Fund mitgenommen:** Der Lauf führte `mise trust` selbst aus, weil `mise install` im
  nicht vertrauten Projekt abbrach. choose-stack § Lock-Datei fragt jetzt vorher;
  new-project vertraut weiter der frisch gerenderten `mise.toml` (eigener `fix:`-Commit
  vor dem Release).
- **Release 1.5.0:** CHANGELOG datiert; gepusht nach Personendaten-grep über Diff,
  Commit-Metadaten und Messages sowie Blocklist-Abgleich; CI grün;
  Plugin aktualisiert, Cache dateigleich mit dem Arbeitsstand.
- **Gegenprobe** an einem Downstream-Projekt (docs-only, Stempel 1.3.0) mit dem
  installierten 1.5.0 (0,56 USD, 7 Turns, 40 s): Update-Fenster 1.4.0 und 1.5.0;
  `HOW-TO-CODE-WITH-CLAUDE.md` `template-only`, die Kopfzone der Registry über `zones`,
  die aufgelöste `REQUIREMENTS.md` als `no-file` richtig übergangen; `lock-check` alles
  `complete`, `ci none`; die Registry-Revision ohne Vorschlag. Kein Fund. Den Sync
  übernimmt der Nutzer selbst; das Projekt ist wieder im Ausgangszustand.

**Planungsentscheidungen von F-045** (aus dem Elterneintrag):
- Ein Befehl `zones` für seed-Zonen und Fragmente im Slot; er schreibt das Ergebnis wie
  `merge`, teilweise Zustimmung über einen zweiten Lauf mit Namen.
- Marker gelten nur allein auf einer Zeile; ein Override mitten in einer Zeile schützt
  nicht mehr (Hinweis im CHANGELOG, keine Sonderbehandlung).
- Ein Block, den keine Seite hat, bekommt keine Zeile; `local` heißt nur „nicht im
  Render", den Katalog prüft der Skill.
- `lock-check` mit einer Zeile je Lock-Eintrag und der CI-Plattform aus `runs-on` ohne
  YAML-Parser; der Abgleich mit „Known limitation" bleibt beim Skill.
- `snapshot` weist unbekannte Ziele ab, kein `--all`; A2 Schritt 8 bleibt beim Modell.

**Notable decisions:**
- Testprojekt aus der Historie (Template 1.4.0) statt aus dem aktuellen Template: So ist
  die alte Kopfzone der Registry ein echter Update-Fall.
- Kein zweiter Testlauf für den `mise trust`-Fund: Es ist eine reine Textregel, und ein
  `claude -p`-Lauf kann den Nutzer nicht fragen.
- Die Gegenprobe prüfte nur den Ablauf und wurde zurückgesetzt; den Sync des
  Downstream-Projekts macht der Nutzer selbst.

**Geänderte Dateien:** `plugins/coding-kit/skills/choose-stack/SKILL.md`,
`plugins/coding-kit/CHANGELOG.md` (Fund und Release), `PROGRESS.md`,
`PROGRESS-ARCHIVE.md`.
