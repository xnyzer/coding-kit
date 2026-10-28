---
id: F-044
title: Sprachen ohne Vorlage erkennen und dem Template vorschlagen
type: feature
status: DONE
size:
created: 2026-10-25
done: 2026-10-25
depends-on:
superseded-by:
---

# F-044 — Sprachen ohne Vorlage erkennen und dem Template vorschlagen

## Verlauf

### F-044a — Erkennung: Zustand `unknown` und Ablehnung `tool:NAME` (2026-10-25)

Teil von F-044 (Sprachen ohne Vorlage erkennen und dem Template vorschlagen; F-044b–c
folgen).

**Problem:** `detect` kannte nur Signale, die das Template deklariert. Nutzte ein Projekt
eine Sprache ohne volles Modul — Rust, Ruby oder die Stubs `java` und `swift-ios` —,
meldete kein Skill etwas.

**Was entstanden ist (1.4.0, unveröffentlicht):**

- **`template-sync.sh detect`:** Nach den Modul- und Fragment-Zeilen folgt je Tool ohne
  Konvention eine Zeile `tool <name> <unknown|declined> <tool:name (erster Pfad[ +weitere])>`,
  nach Namen sortiert. `known_tools` sammelt die bekannten Tools (`[tools]` der
  Core-`mise.toml` und aller `mise.part.toml`, deklarierte `tool:`-Signale), `report_tools`
  gleicht ab; ein Name mit `:` (Backend-Präfix) zählt nie. `declined_rows` liest auch
  `tool:NAME`. Gilt für den ganzen Baum, `--changed` und übergebene Signale; der
  Skriptkopf beschreibt die Zeile.
- **MANIFEST:** § Detection mit dem neuen Absatz „Tools without a convention"
  (Bekannt-Regel, Backend-Regel, Zustände `declined` und `unknown`, Stubs zählen als
  `unknown`, Ablehnung für Tools ohne Konventionsbedarf); § Deviation registry nennt
  `tool:NAME`.
- **Registry-Vorlage:** Die Kopfzone `overrides-head` der `convention-overrides.md`
  erklärt `tool:NAME`; sie kommt per Zonen-Abgleich in die Projekte.
- **Tests:** Ein Projekt mit bekannten Tools (`just`, `uv`, `pnpm`, `golangci-lint`,
  `python`), Backend-Tools (`npm:markdownlint-cli2`, `[tools."cargo:ripgrep"]`), `rust` in
  zwei mise-Dateien, `zig` als `[tools.NAME]`-Tabelle und einer Rules-Zeile für
  `terraform`; dazu `--changed` (nur das neue Tool), übergebene Signale (bekannt,
  Backend, unbekannt) und eine Ablehnung über `--registry`. Ein frischer Render jedes
  Moduls meldet kein unbekanntes Tool.
- **Version:** `plugin.json` 1.4.0, CHANGELOG-Eintrag mit `### Template`.

**Verifikation:** `just check` grün (Validator, 552 Skript-Tests unter dash und bash,
54 davon neu). Fehlerinjektion an einer Kopie: Modul-`mise.part.toml` nicht gelesen,
Backend-Regel entfernt, Tool-Zeilen abgeschaltet, `tool:`-Ablehnung entfernt — alle vier
gefangen (12, 6, 14 und 4 Fehlschläge). Versionsregel gegen `origin/main` grün.

**Notable decisions:**
- Die Tool-Zeilen kommen aus einer eigenen Funktion hinter `report_hits`, statt dessen
  Sortierung zu erweitern: `report_hits` sortiert nach Art absteigend, `tool` stünde dort
  vor `module`.
- `tool:NAME` erlaubt Punkte, Unterstriche und Großbuchstaben — mise-Tools folgen nicht
  dem Namensschema der Module.
- `scripts/validate.py` bleibt unverändert: Er liest aus § Detection nur die
  Signal-Typen, nicht die Zustände.

**Geänderte Dateien:**
`plugins/coding-kit/scripts/template-sync.sh`, `tests/template-sync/detect.sh`,
`plugins/coding-kit/template/MANIFEST.md`,
`plugins/coding-kit/template/core/.claude/convention-overrides.md`,
`plugins/coding-kit/.claude-plugin/plugin.json`, `plugins/coding-kit/CHANGELOG.md`.

### F-044b — Skill `propose-to-template` (2026-10-25)

Teil von F-044 (Sprachen ohne Vorlage erkennen und dem Template vorschlagen; F-044a siehe
darunter, F-044c folgt).

**Problem:** Den Übernahme-Vorschlag gab es nur als Abschnitt in `update-conventions`, nur
für projektlokale Fragmente und nur als Prompt oder `gh`-Aufruf. prep-step und step-done
verwiesen auf diesen Abschnitt eines Skills, den Claude nicht starten darf
(`disable-model-invocation: true`).

**Was entstanden ist (1.4.0, unveröffentlicht):**

- **`plugins/coding-kit/skills/propose-to-template/SKILL.md` (neu):** Hintergrund-Skill
  mit `user-invocable: false`.
  - Eingabe ist ein Fund (Tool aus `detect` mit `unknown`, projektlokales Fragment,
    Abweichung an einer managed Datei). Ohne Übergabe nimmt er ihn aus dem Gespräch oder
    stellt genau eine Rückfrage; er sucht nie selbst im Projekt.
  - Das Ziel-Repo kommt aus `homepage` in `plugin.json`.
  - Er sammelt das Material nur lesend: mise-Einträge, justfile-Rezepte, CI-Schritte und
    Konfigdateien, den Fragment-Block oder den Diff gegen die Basis. Dann empfiehlt er ein
    Modul (Sprache mit Toolchain, samt Sprachfragment), ein Fragment (Werkzeug ohne
    Sprache) oder die Rules-Zeile `tool:NAME`. Einen passenden Stub nennt er als
    Ausgangspunkt.
  - Vor jeder Ausgabe generalisiert er (Material englisch, Platzhalter, „a downstream
    project", keine Versionsstände) und durchsucht den Entwurf nach Projektname,
    Git-Name, E-Mail und lokalen Pfaden.
  - Eine Frage zum Format, Default Issue.
  - Das Issue ist englisch und hat die Abschnitte Summary, Today, Proposal, Material und
    Kit rules. Ausgegeben wird es als ein Block mit
    `gh issue create … --body-file - <<'EOF'`, ohne `gh` über `…/issues/new`.
  - Der Prompt ist ein Block in der Sprache des Gesprächs und ohne Vorwissen ausführbar:
    Lesereihenfolge, Ergebnisdateien je Art, Material, Kit-Regeln, im Fork ein PR mit
    Dateiliste.
  - Die äußeren Blöcke sind mit `~~~~` umzäunt.
- **Begleit-Änderungen:**
  - `plugin.json`: In der Beschreibung steht der Hintergrund-Skill. Die Version bleibt
    1.4.0.
  - CHANGELOG-Eintrag.
  - README: eine Zeile `propose-to-template` *(Hintergrund)*.
  - `CONTRIBUTING.md`: Abschnitt „Proposing a module or fragment" mit beiden Formaten und
    der Faustregel Modul plus Sprachfragment gegen Fragment.
  - `docs/skill-authoring.md`: `user-invocable: false` mit Beispiel. Andere Skills nennen
    einen Hintergrund-Skill ohne Slash, die README führt ihn mit *(Hintergrund)*.

**Verifikation:** `just check` grün (Validator, 552 Skript-Tests). Laut Claude-Code-Doku
kann Claude Skills mit `user-invocable: false` über das Skill-Tool starten, auch
Plugin-Skills; `gh issue create --help` bestätigt `--body-file -` für stdin. Beispiel nach
dem Skill-Text an einem Scratch-Projekt mit `rust` in der `mise.toml` (`detect` meldete
`tool rust unknown`):
- Der Issue-Befehl ist syntaktisch gültig (`bash -n`), und ein Ersatz für `gh` bekam Titel
  und Body (41 Zeilen) korrekt.
- Grep nach Projektname, Git-Name, E-Mail und lokalen Pfaden sowie die Blocklist: kein
  Treffer.

**Notable decisions:**
- Das Issue ist englisch, weil das Kit-Repo öffentlich und die `CONTRIBUTING.md` englisch
  ist. Der Prompt folgt der Sprache des Gesprächs; das Template-Material darin ist
  englisch.
- Der Issue-Body geht über stdin in denselben Block wie der Befehl. So bleibt es ein
  einziger kopierfertiger Block, und es entsteht keine Datei im Projekt.
- Die Template-HOW-TO bleibt unverändert: Sie listet Befehle, die man selbst aufruft.
- Die Verweise der anderen Skills auf „update-conventions § Übernahme-Vorschlag" bleiben
  bis F-044c stehen.

**Geänderte Dateien:**
`plugins/coding-kit/skills/propose-to-template/SKILL.md` (neu),
`plugins/coding-kit/.claude-plugin/plugin.json`, `plugins/coding-kit/CHANGELOG.md`,
`README.md`, `CONTRIBUTING.md`, `docs/skill-authoring.md`.

### F-044c — Skills anbinden, Testlauf, Release (2026-10-25)

Schließt F-044 ab (Sprachen ohne Vorlage erkennen und dem Template vorschlagen; F-044a–b
siehe darunter).

**Problem:** `detect` meldete Tools ohne Vorlage, und `propose-to-template` konnte den
Vorschlag erzeugen — aber kein Skill nutzte beides. prep-step, step-done und
update-conventions verwiesen noch auf den alten Abschnitt in update-conventions.

**Was entstanden ist (Release 1.4.0):**

- **update-conventions:** Schritt 2 bietet je `tool`-Zeile `unknown` an, das Tool dem
  Template vorzuschlagen (`propose-to-template` mit dem Fund), es dauerhaft abzulehnen
  (`tool:NAME`) oder diesmal nicht. Die Schritte 5 und 6 starten den Skill für bessere
  managed Dateien und projektlokale Fragmente. Die Registry-Revision (Schritt 10) bietet
  `tool:NAME` zum Austragen an, sobald das Template das Tool kennt. `status` nennt Tools
  ohne Vorlage. Der Abschnitt „Übernahme-Vorschlag" entfällt; die Beschreibung ist
  angepasst.
- **step-done:** § 1a mit den Zuständen für Tools und dem Angebot für ein neues Tool ohne
  Vorlage, nicht blockierend; der Fragment-Hinweis in § 1a und Option (c) in § 1b starten
  den Skill.
- **prep-step:** § 2a erklärt die `tool`-Zeile; Punkt 6 empfiehlt für ein Tool ohne
  Vorlage den Bau von Hand im Projekt (Werkzeugsprache mit `keep`-Zeilen bzw.
  projektlokales Fragment) plus Vorschlag fürs Template nach dem Bau, oder `tool:NAME`;
  Punkt 7 und die Plan-Vorlage nennen `tool:NAME`.
- **choose-stack** Modus B: Für eine `tool`-Zeile `unknown` wird kein Modul geraten —
  bestehendes Modul bzw. `docs-only` behalten und den Vorschlag fürs Template anbieten.
- **README** (Zeilen von update-conventions und step-done) und **HOW-TO im Template**
  (prep-step, step-done, update-conventions, Detection backstop) nennen Tools ohne
  Vorlage, den Übernahme-Vorschlag und `tool:NAME`.
- **Funde aus dem ersten Testlauf, mitgenommen:**
  - `propose-to-template` trennt das Material immer in *From the project* und *Suggested,
    not from the project (unverified)*; fehlt ein Teil, steht „none" da.
  - Der Prompt ist ein Entwurfsauftrag: Kit kennenlernen, recherchieren, beide Teile
    gewichten, den Entwurf mit Übernommenem und Verworfenem zeigen, erst nach Zustimmung
    bauen. CONTRIBUTING beschreibt das ebenso.
  - Wörtliche Datei-Inhalte stehen als eigene Codeblöcke, Inline-Code mit Backticks
    bekommt doppelte Backticks.
  - Die Spalte **Since** der Registry ist das Datum, an dem die Zeile angelegt wurde
    (`YYYY-MM-DD`; MANIFEST § Deviation registry, Kopfzone der Registry-Vorlage).
- **Fund aus dem zweiten Testlauf, mitgenommen:** Der Issue-Body folgt einem festen
  Gerüst mit Überschriften-Ebenen; der Prosa-Satz war mehrdeutig, „Kit rules" landete
  als Unterabschnitt von „Material".
- **Release 1.4.0:** CHANGELOG datiert, gepusht, CI grün, Plugin aktualisiert und der
  Cache gegen den Arbeitsstand geprüft.

**Testläufe** (`claude -p --plugin-dir`, Opus auf `medium`, Budget-Cap 6 USD, ein
docs-only-Projekt aus dem aktuellen Template mit `rust` und `terraform` in der
`mise.toml`, einem Rust-Rezept im justfile und Entscheidungen im Prompt):

- **Lauf 1** (1,13 USD, 15 Turns): `rust` und `terraform` als `unknown` erkannt;
  `propose-to-template` über das Skill-Tool gestartet, Issue und Prompt kopierfertig;
  `terraform` als `tool:terraform` abgelehnt, `justfile` und `mise.toml` als `keep`
  registriert, Lock-Abgleich wie vorgegeben übersprungen. Funde: Material mischte
  Projektbelegtes und Erfundenes, verschachtelte Backticks, Format von Since offen.
- **Lauf 2** (1,14 USD, 19 Turns) mit den Nachbesserungen: Material getrennt, Prompt als
  Entwurfsauftrag mit konkreten Recherchefragen, `Signals:`-Zeile als eigener Codeblock,
  alle neuen Registry-Zeilen mit Datum. Fund: Gerüst des Issues (siehe oben).
- Endstand beider Läufe per Skript (der blockierte Schreibzugriff unter `.claude/` vom
  Tester nachgeholt): `detect` meldet `rust unknown` und `terraform declined`, `status`
  zeigt beide Abweichungen als `keep`, die Kopfzone ist unverändert; weder Projektname
  noch Personendaten im Vorschlag, nur das Ziel-Repo aus `homepage`.

**Planungsentscheidungen von F-044** (aus dem Elterneintrag):
- Bekannt ist ein Tool aus der Core-`mise.toml`, einer `mise.part.toml` oder einem
  deklarierten `tool:`-Signal; die Signale allein hätten `uv`, `pnpm` und
  `golangci-lint` gemeldet. Keine hartcodierte Sprachliste.
- Nur `tool:` kann `unknown` werden, Backend-Tools (Name mit `:`) nie. Fehlalarme lehnt
  man mit `tool:NAME` ab.
- Stubs bleiben ohne Signale und ohne eigenen Zustand (F-042a); der Vorschlag nennt einen
  passenden Stub.
- Der Übernahme-Vorschlag ist ein Hintergrund-Skill (`user-invocable: false`), den
  Claude mit einem Fund startet; ohne Fund eine Rückfrage, nie eine eigene Suche.
- Zwei Formate: Issue (Standard) und Prompt, immer kopierfertig; keine PR-Beschreibung,
  keine Issue-Vorlage im Kit-Repo, dafür ein Abschnitt in der CONTRIBUTING.

**Notable decisions:**
- Abgelehnt wurde im Test `terraform` statt `rust` (Plan): So zeigt ein Lauf beide Wege,
  den Vorschlag und die Ablehnung.
- prep-step empfiehlt den Vorschlag fürs Template erst nach dem Bau, weil das Material
  dann steht.
- Kein dritter Testlauf für das Gerüst: Es ist eindeutig, eine Fehlinterpretation bleibt
  dem Modell nicht.
- Die Spalte Since gehörte nicht zum Plan; sie kam mit, weil 1.4.0 MANIFEST und
  Registry-Kopf ohnehin ändert und Projekte so ein Update-Fenster bekommen.

**Geänderte Dateien:**
`plugins/coding-kit/skills/{update-conventions,step-done,prep-step,choose-stack,propose-to-template}/SKILL.md`,
`plugins/coding-kit/template/MANIFEST.md`,
`plugins/coding-kit/template/core/.claude/convention-overrides.md`,
`plugins/coding-kit/template/core/HOW-TO-CODE-WITH-CLAUDE.md`, `README.md`,
`CONTRIBUTING.md`, `plugins/coding-kit/CHANGELOG.md`.
