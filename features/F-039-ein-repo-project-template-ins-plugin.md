---
id: F-039
title: Ein Repo — project-template ins Plugin, gemeinsame Version 1.0.0
type: feature
status: DONE
size:
created: 2026-10-23
done: 2026-10-24
depends-on:
superseded-by:
---

# F-039 — Ein Repo — project-template ins Plugin, gemeinsame Version 1.0.0

## Verlauf

### F-039a — Import und Grundgerüst (2026-10-23)

Teil von F-039 (Ein Repo: project-template ins Plugin, gemeinsame Version 1.0.0;
F-039b–e folgen).

**Problem:** Bevor Skills und Doku auf ein Repo umgestellt werden können, müssen
Historie, Inhalt und Prüfwerkzeug des Templates im Kit liegen — mit grünen Checks.

**Was entstanden ist (1.0.0, unveröffentlicht):**

- **Historien-Import:** project-template (37 Commits, bis 0.16.0) auf einem Scratch-Klon
  per `git filter-repo --to-subdirectory-filter plugins/coding-kit/template`
  umgeschrieben und per `git merge --allow-unrelated-histories` übernommen
  (Merge-Commit `b7b9fcd`). In den Commit-Messages heißen die Template-Nummern
  `TPL-NNN`; die drei Verweise auf Kit-Nummern blieben (kein Umbenennen nach „kit ",
  „kit's ", „its ", „there as "). Vor dem Merge: gitleaks über die Historie, Blocklist
  über Patches und Messages, Adressen, Pfade, IPs — ohne Befund.
- **Bereinigung:** Repo-eigene Template-Dateien entfernt (Governance-Doku, Tooling,
  `.github/`, `.claude/`, `scripts/`, `private/`, README, CLAUDE.md, CHANGELOG, PROGRESS,
  Archiv, VERSION). Übrig: `MANIFEST.md`, `core/`, `modules/` (78 Dateien). PROGRESS und
  Archiv des Templates bleiben für F-039b über `b7b9fcd` lesbar.
- **CHANGELOG:** nach `plugins/coding-kit/CHANGELOG.md` (liegt damit im Plugin-Cache).
  Der Kopf erklärt die eine Version, den Abschnitt `### Template` und die eingefrorenen
  Abschnitte; Eintrag 1.0.0 (unveröffentlicht); darunter „Eingefroren:
  coding-kit-Plugin bis 0.20.0" (21 Einträge) und „Eingefroren: project-template bis
  0.16.0" (25 Einträge), Überschriften je eine Ebene tiefer; TPL-Regel auch hier.
- **Validator (`scripts/validate.py`):** Template-Checks übernommen und auf
  `plugins/coding-kit/template/` beschränkt (Marker-Paare, Fragment-Deklarationen,
  Katalog). Platzhalter-Registry aus MANIFEST § Placeholders statt fester Liste (behebt
  die `LIVING_DOC_LANGUAGE`/`LANG_*`-Drift); Registry-Platzhalter in Template-Inhalt und
  allen Markdown-Dateien erlaubt, sonst keine. Blocklist-Check repo-weit
  (`private/blocklist.txt`, gitignoriert, in der CI still übersprungen).
- **Versionsregel (`scripts/version-rule.py`, `just version-rule`):** Änderungen unter
  `plugins/coding-kit/{skills,hooks,template}/` verlangen eine Version über dem
  Vergleichsstand und einen `## <Version>`-Eintrag im CHANGELOG. Pre-Commit
  (`--staged`, Basis = Upstream, sonst HEAD) als lefthook-Job; CI (`--since` mit der
  Basis von PR bzw. Push, `fetch-depth: 0`).
- **Version:** `plugin.json` 1.0.0.
- **Nebenbei:** Der jetzt repo-weite Blocklist-Check fand im Archiv-Eintrag F-011 den
  Namen eines Downstream-Projekts (öffentlich seit Plugin 0.7.0) — neutral
  umformuliert; die Historie bleibt (Entscheidung des Nutzers).

**Verifikation:** `git log -- plugins/coding-kit/template/VERSION` zeigt 25 Stände,
`git show <ältester Commit>:plugins/coding-kit/template/MANIFEST.md` liest das erste
MANIFEST. `just check` grün; `claude plugin validate plugins/coding-kit` grün (einzige
Warnung: fehlendes Icon, schon bei 0.20.0). Fehlerinjektion in einer Scratch-Kopie:
unbekannter und verirrter Platzhalter, offener Section-Marker, fehlendes MANIFEST und
Katalogdatei ohne Tabellenzeile werden gemeldet, ein Registry-Token in einem Skill
nicht. Versionsregel in acht Szenarien: fehlender Bump, fehlender CHANGELOG-Eintrag und
unbekannte Basis werden gemeldet; ungepushte Folge-Commits auf derselben Version,
reine Doku-Änderungen und neue Branches gehen durch.

**Notable decisions:**
- Versionsregel als eigenes Skript statt in `validate.py`: arbeitet auf `git diff` statt
  auf Dateien, braucht kein PyYAML und läuft getrennt im Pre-Commit und in der CI.
- Vergleichsbasis ist der gepushte Stand, nicht der vorige Commit — ein Release darf aus
  mehreren Commits bestehen (F-039 selbst).
- Merge-Commit ohne zusätzliche Änderungen; er besteht `just check` allein nicht, der
  Folge-Commit macht den Stand grün, dazwischen wird nicht gepusht.
- Kit-Verweise beim Umbenennen über eine Ausschlussregel statt einer Liste — an
  Messages, Archiv und CHANGELOG geprüft: genau die zehn bekannten Kit-Verweise bleiben
  `F-`.

**Geänderte Dateien:** `plugins/coding-kit/template/**` (Import, Bereinigung),
`plugins/coding-kit/CHANGELOG.md` (aus `CHANGELOG.md`),
`plugins/coding-kit/.claude-plugin/plugin.json`, `scripts/validate.py`,
`scripts/version-rule.py` (neu), `justfile`, `lefthook.yml`, `.github/workflows/ci.yml`,
`PROGRESS-ARCHIVE.md` (F-011 neutral), `PROGRESS.md`.

### F-039b — Dokumente zusammenführen (2026-10-23)

Teil von F-039 (Ein Repo: project-template ins Plugin, gemeinsame Version 1.0.0;
F-039c–e folgen).

**Problem:** Nach dem Import standen zwei Aufgabenreihen nebeneinander — PROGRESS und
Archiv des Kits hier, die des Templates nur noch in der Historie —, und die offenen
Kit-Einträge planten noch mit Übergaben zwischen zwei Repos (F-035).

**Was entstanden ist (repo-lokal, nur lebende Doku):**

- **Archiv:** Kit- und Template-Archiv zu einem zusammengeführt — 55 Einträge (27 Kit,
  28 Template), neueste oben, bei gleichem Datum nach dem Commit, der den Eintrag
  angelegt hat. Template-Einträge heißen `TPL-NNN` (86 Verweise umbenannt, 5 Kit-Verweise
  blieben); in Kit-Einträgen 5 Template-Nummern umgestellt („project-template TPL-020",
  „(dortiges TPL-016)"). Neuer Kopf erklärt beide Reihen; zwischen allen Einträgen jetzt
  `---`.
- **Done-Tabelle:** Zeilen bis F-038b entfernt (alle im Archiv), F-039a bleibt als erste
  Zeile von 1.0.0; Hinweis auf das Archiv über der Tabelle.
- **Offene Einträge:** F-024, F-025, F-032, F-033, F-034, F-036 und F-037 auf das
  Ein-Repo-Modell umgeschrieben — Template-Gegenstücke „im selben Commit" statt
  Übergabe, Pfade als `template/core/…`, der Paarungs-Prüfer aus F-035 gestrichen;
  F-025 braucht keinen Template-Checkout mehr.
- **F-026:** in F-039 aufgegangen (Aktualität, Klontiefe und Herkunft des Templates);
  der Rest — Kit-Repo-Herkunft in `check-upstreams` — steht jetzt in F-032. Eintrag
  entfernt, Index-Zeile markiert, Reihenfolge angepasst.

**Verifikation:** Alle 27 Kit- und 28 Template-Done-Zeilen haben einen Archiv-Eintrag
(per Skript gegen die Archiv-Überschriften geprüft); in TPL-Einträgen stehen nur die
fünf Kit-Verweise auf `F-`, in Kit-Einträgen kein unumbenannter Template-Verweis;
`just check` grün. Die Entwürfe hat der Nutzer vorab gesehen und freigegeben.

**Notable decisions:**
- F-039a bleibt in der Done-Tabelle — sie gehört schon zu 1.0.0; der Neustart betrifft
  nur alte Zeilen (Entscheidung des Nutzers).
- In Kit-Einträgen nur die Nummer ersetzt („project-template TPL-020"), keine Sätze
  umformuliert.
- Reihenfolge im Archiv per Merge zweier bereits sortierter Listen — die Reihenfolge
  innerhalb jedes Archivs bleibt erhalten.

**Geänderte Dateien:** `PROGRESS.md`, `PROGRESS-ARCHIVE.md`.

### F-039c — Skills und Vertrag auf das gebündelte Template (2026-10-23)

Teil von F-039 (Ein Repo: project-template ins Plugin, gemeinsame Version 1.0.0;
F-039d–e folgen).

**Problem:** Die Skills suchten das Template in einem lokalen Checkout oder klonten es von
GitHub, `new-project` legte Repos per `gh repo create --template` an, und
`update-conventions` löste alte Stempel über die Git-Historie eines Checkouts auf — alles
Annahmen aus der Zeit zweier Repos.

**Was entstanden ist (Plugin 1.0.0, unveröffentlicht):**

- **`choose-stack` § 0:** Template = `${CLAUDE_PLUGIN_ROOT}/template`, Version aus
  `plugin.json`; kein Klon, kein Checkout, kein Override. Hinweis, dass die Variable nur
  im Skill-Text ersetzt wird; Arbeit am Template per `claude --plugin-dir`.
  Known-limitation-Abgleich gegen das Plugin-CHANGELOG.
- **`new-project`:** leeres Repo per `gh repo create … --clone` (Branch-Prüfung auf
  `main`), Quellen relativ zu `${CLAUDE_PLUGIN_ROOT}/template`, „Aufräumen" ersetzt
  durch „nur Manifest-Ziele", Stempel und `TEMPLATE_VERSION` aus `plugin.json`,
  Erst-Commit `feat: bootstrap from coding-kit <Version> (<Modul> module)`. Den toten
  Verweis auf den Optional-Block `security-tool` gestrichen (im Template seit 0.2.0
  entfernt, TPL-Commit `380aaa1`).
- **`update-conventions`:** § 0 auf das gebündelte Template; Update-Fenster aus den
  `### Template`-Abschnitten, Stempel unter 1.0.0 zusätzlich aus dem eingefrorenen
  Template-Abschnitt, leeres Fenster → nur neu stempeln; A2.8 über MANIFEST § Removed
  and renamed targets statt Git-Historie; Übernahme-Vorschlag an eine
  coding-kit-Session bzw. als Issue an das Repo aus der `homepage` in `plugin.json`;
  Ausweichpfad für ein MANIFEST ohne § Seed sections entfernt.
- **Übrige Skills:** `define-requirements` (Katalog und REQUIREMENTS-Skelett aus dem
  Plugin), `choose-license` (mitgelieferte LICENSE), `go-public` (kein
  Template-Checkout mehr).
- **MANIFEST:** Einleitung (eine Version mit dem Plugin), `TEMPLATE_VERSION` aus
  `plugin.json`, Sync direction an das coding-kit-Repo, neue Tabelle
  `## Removed and renamed targets` (leer), § Version stamp auf Plugin-Version und
  CHANGELOG-Fenster.
- **HOW-TO (Template, managed):** Nachzug aus F-038a — `/step-done` verbucht nach
  Vorschau und einer Freigabe mit der Commit-Message, `/add-feature` startet auch
  Claude, eingetragen wird nach OK.
- **Validator:** Vertragsprüfungen als eigene kleine Funktionen — `manifest-format`
  gegen die Formatangaben der Skills, Core-Tabelle ↔ Dateien unter `template/core/`,
  Seed-Inventar ↔ Section-Marker, Plausibilität der Tabelle für entfernte/umbenannte
  Ziele, Optional-Blöcke (MANIFEST „used" ↔ Template ↔ Skills),
  `${CLAUDE_PLUGIN_ROOT}/…`-Pfade in Skills.
- **Versionsregel:** Verlässt ein Ziel die Core-Tabelle, verlangt sie eine Zeile für die
  aktuelle Version in `## Removed and renamed targets`.
- **CHANGELOG 1.0.0** mit Abschnitt `### Template` (HOW-TO); `plugin.json`-Description
  nennt das Template.

**Verifikation:** `just check` grün. Fehlerinjektion in Scratch-Kopien: 9
Vertragsfälle und 3 Optional-Block-Fälle werden gemeldet, die echte Fassung ist grün.
grep: kein Skill nennt mehr den lokalen project-template-Checkout, `gh repo clone` des
Templates oder `CODING_KIT_TEMPLATE_REPO`. Headless-Trockenlauf (`claude -p
--plugin-dir plugins/coding-kit --permission-mode plan`, `/coding-kit:new-project
dry-run`): Template `plugins/coding-kit/template`, Version 1.0.0, `manifest-format: 1`,
`gh repo create … --clone` ohne `--template`, 31 Core-Ziele (privat, ohne public-only)
plus python-Modul, Erst-Commit `bootstrap from coding-kit 1.0.0`; der Lauf fand dabei
den `security-tool`-Verweis. `claude plugin validate` grün (einzige Warnung: fehlendes
Icon, schon bei 0.20.0).

**Notable decisions:**
- `prep-step`, `step-done` und `check-upstreams` unverändert: Sie verweisen auf
  `/choose-stack` § 0 bzw. auf das Kit-Repo, das bleibt richtig.
- Issue-Ziel aus der `homepage` in `plugin.json` statt aus `gh api user` — deklarierte
  Quelle statt Ableitung aus dem eigenen Konto.
- Prüfung „entferntes Core-Ziel ohne Tabellenzeile" in der Versionsregel statt im
  Validator, weil sie einen Diff braucht.
- Den `security-tool`-Fund in diesem Schritt behoben, samt Prüfung, statt ins Backlog
  (Entscheidung des Nutzers) — eine Abweichung zwischen Skill und Template ist genau
  das, was F-039 abstellen soll.
- Ein leerer Klon übernimmt den Default-Branch des Remotes (lokal geprüft); die
  Anleitung prüft trotzdem auf `main`, weil die CI-Vorlage darauf triggert.

**Geänderte Dateien:**
`plugins/coding-kit/skills/{choose-stack,new-project,update-conventions,define-requirements,choose-license,go-public}/SKILL.md`,
`plugins/coding-kit/template/MANIFEST.md`,
`plugins/coding-kit/template/core/HOW-TO-CODE-WITH-CLAUDE.md`, `scripts/validate.py`,
`scripts/version-rule.py`, `plugins/coding-kit/CHANGELOG.md`,
`plugins/coding-kit/.claude-plugin/plugin.json`, `PROGRESS.md`, `PROGRESS-ARCHIVE.md`.

### F-039d — Repo-Doku und Regeln (2026-10-23)

Teil von F-039 (Ein Repo: project-template ins Plugin, gemeinsame Version 1.0.0;
F-039e folgt).

**Problem:** Regeln und Doku des Kits beschrieben noch zwei Repos — das Template als
Schwester-Repo, die Sync-Invariante nur für Skills und Hooks, die Einfrier-Regel für
project-template, die README mit Template-Klon und `CODING_KIT_TEMPLATE_REPO`.

**Was entstanden ist (repo-lokal plus eine Template-Datei):**

- **`CLAUDE.md`:** Überblick und Strukturregel für das Template im Plugin (Zugriff nur
  über `${CLAUDE_PLUGIN_ROOT}/template`, MANIFEST als geprüfter Vertrag); Sprachgrenze
  nennt `template/**` und den CHANGELOG; Publishing-Hygiene um „Downstream-Projekte nie
  beim Namen nennen", registrierte Platzhalter und die Blocklist ergänzt; Versionsregel
  statt Sync-Invariante (Template, `### Template`, MANIFEST-Pflege, `just version-rule`);
  Nummern-Regel für `TPL-NNN`; Graphiti-Hinweis auf die alte group_id
  `project-template`; Test mit `--plugin-dir`; Einfrier-Regel entfernt.
- **`README.md`:** Einleitung (ein Scaffolding-System, Template im Plugin seit 1.0.0);
  „Ohne GitHub" ohne Template-Klon — statt `cp -r project-template` ein leerer Ordner
  mit `git init`; Skill-Tabelle (`new-project` befüllt ein leeres Repo,
  `update-conventions` mit Update-Fenster, `choose-stack` braucht kein GitHub mehr);
  Personal-Config ohne `CODING_KIT_TEMPLATE_REPO`; Repo-Baum mit `template/`, CHANGELOG,
  `scripts/version-rule.py` und PROGRESS; Pflege-Abschnitt mit Versionsregel und
  `--plugin-dir`.
- **`CONTRIBUTING.md`:** Versionsregel für Skills, Hooks und Template; „Where
  conventions originate" und „Rules for template content" aus der CONTRIBUTING des
  Templates übernommen; Template-Zugriff und Test für Skills.
- **`docs/skill-authoring.md`:** Muster „Template nur über
  `${CLAUDE_PLUGIN_ROOT}/template`, die Variable wird nur im Skill-Text ersetzt";
  Template-Inhalt englisch; Versionsregel; Test mit `--plugin-dir` und
  `/reload-plugins`.
- **`docs/renovate-preset.md`:** Dogfooding ohne Template-Repo; Renovate-PRs an
  Template-Pins brauchen Versions-Bump und `### Template`; CHANGELOG-Pfad.
- **`add-skill`:** Schritt 3 zieht die HOW-TO im selben Commit nach und nennt sie unter
  `### Template` (statt Vermerk in F-039); CHANGELOG-Pfad und Versionsregel; Schritt 4
  testet mit `--plugin-dir`.
- **`marketplace.json`:** Beschreibungen nennen Template, `/new-project` und
  `/update-conventions`.
- **Template `core/.claude/README.md`:** Der Abschnitt `template-version` nennt den
  Stempel jetzt coding-kit-Version (CHANGELOG 1.0.0 unter `### Template`).

**Verifikation:** `just check` grün; interne Links und Anker der geänderten Doku geprüft
(keine toten); grep: außer Historie, Archiv, eingefrorenem CHANGELOG und Plan-Einträgen
nennt nichts project-template als Quelle; gitleaks ohne Fund.

**Notable decisions:**
- Die Template-Datei `core/.claude/README.md` in diesem Schritt korrigiert — direkte
  Folge der Stempel-Änderung aus F-039c, deshalb kein eigener Eintrag.
- „Downstream-Projekte nie beim Namen nennen" aus der Template-CLAUDE.md ins Kit
  übernommen — genau das hatte der Blocklist-Fund in F-039a gezeigt.
- In F-039c liefen die Skill-Änderungen ohne `/add-skill`; die Checkliste wurde hier
  nachträglich geprüft, offen waren nur README-Zeilen und das Authoring-Muster —
  beides erledigt.

**Geänderte Dateien:** `CLAUDE.md`, `README.md`, `CONTRIBUTING.md`,
`docs/skill-authoring.md`, `docs/renovate-preset.md`, `.claude/skills/add-skill/SKILL.md`,
`.claude-plugin/marketplace.json`, `plugins/coding-kit/template/core/.claude/README.md`,
`plugins/coding-kit/CHANGELOG.md`, `PROGRESS.md`, `PROGRESS-ARCHIVE.md`.

### F-039e — Test, Release, Gegenprobe (2026-10-24)

Schließt F-039 ab (Ein Repo: project-template ins Plugin, gemeinsame Version 1.0.0;
F-039a–d siehe darunter).

**Problem:** Die Umstellung war gebaut, aber weder im echten Betrieb getestet noch
veröffentlicht; project-template lief parallel weiter.

**Was entstanden ist (Release 1.0.0):**

- **Lokaler Test:** `update-conventions` ohne Schreibrechte (`claude -p --plugin-dir …
  --permission-mode plan`) an der Kopie eines docs-only-Projekts mit Stempel 0.13.2:
  Template aus dem Plugin, Version 1.0.0, Update-Fenster 0.13.3–0.16.0 aus dem
  eingefrorenen Abschnitt plus 1.0.0 `### Template`, Schritt 8 leer, Ziel-Stempel 1.0.0;
  keine Freigabe-Abfrage blockierte das Lesen des Templates außerhalb des Projekts. Der
  `new-project`-Trockenlauf aus F-039c galt weiter.
- **Funde aus dem Test:** kein Zusammenführen von Projektzusätzen in managed Dateien, nie
  eingetragene Abweichungen — als F-041 aufgenommen und nach einem unabhängigen
  Design-Review auf einen Drei-Wege-Merge mit Basis-Snapshot umgeplant (nach 1.0.0, als
  1.1.0); dazu: `update-conventions` ohne Argument nur für das aktuelle Projekt.
- **Release:** CHANGELOG datiert (`b09549f`), Push von 45 Commits nach Personendaten-,
  gitleaks- und Versionsregel-Prüfung; CI grün (Validator und Versionsregel); Plugin beim
  Nutzer auf 1.0.0 aktualisiert, der Cache enthält alle 78 Template-Dateien identisch zum
  Repo.
- **Gegenprobe:** `/update-conventions` am echten docs-only-Projekt: CODING-STANDARDS,
  HOW-TO und `.claude/README.md` übernommen, drei Projektdateien einmalig gelassen (bis
  F-041), Stempel 1.0.0, `just check` grün. Im Projekt zusätzlich die Override-Zeile ohne
  `private/README.md` (die Datei ist identisch mit dem Template, die Ausnahme steht in der
  Projekt-CLAUDE.md).
- **project-template:** README-Hinweis auf coding-kit gepusht, Repo archiviert
  (Template-Einstellung bleibt, die „generated from"-Labels bestehender Projekte bleiben
  gültig), lokaler Checkout entfernt; im CHANGELOG vermerkt.

**F-039 im Ganzen (a–e):** Template-Historie importiert (`TPL-NNN`), Dokumente
zusammengeführt, Skills lesen das Template aus `${CLAUDE_PLUGIN_ROOT}/template`, der
Vertrag zwischen Skills und Template wird mechanisch geprüft, die Versionsregel läuft vor
jedem Commit und in der CI, eine Version für alles ab 1.0.0. Entscheidungen der Planung:
Repo bleibt `coding-kit` (Marketplace und Renovate-Preset hängen am Namen); kein Override
für die Template-Arbeit, sondern `claude --plugin-dir`; Stempel-Auflösung über die
MANIFEST-Tabelle statt Git-Historie; `template/VERSION` entfällt; CHANGELOG ab 1.0.0
deutsch mit `### Template`, darunter beide alten Reihen eingefroren.

**Verifikation:** CI-Lauf auf `b09549f` grün; Cache-Ordner 1.0.0 mit `template/`
(78 Dateien) identisch zum Repo; Gegenprobe-Projekt auf 1.0.0 mit grünem `just check`;
GitHub-API: project-template `archived: true`, `is_template: true`.

**Notable decisions:**
- 1.0.0 vor F-041 freigegeben — F-041 wurde groß (Merge-Skript, Renderer,
  `manifest-format: 2`, Migration) und hätte 45 ungepushte Commits tagelang lokal
  gehalten (Entscheidung des Nutzers).
- Kein echter `--template`-Versuch am archivierten Repo, weil er ein Repo angelegt hätte;
  betrifft nur Plugins unter 1.0.0.
- project-template nur archiviert, nicht gelöscht.

**Geänderte Dateien:** `plugins/coding-kit/CHANGELOG.md` (Release-Datum, Archiv-Vermerk),
`PROGRESS.md`, `PROGRESS-ARCHIVE.md`; außerhalb des Repos: README im project-template-Repo,
Override-Zeile im Gegenprobe-Projekt.
