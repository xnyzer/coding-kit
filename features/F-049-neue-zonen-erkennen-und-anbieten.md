---
id: F-049
title: Neue Zonen erkennen und anbieten
type: feature
status: DONE
size:
created: 2026-10-26
done: 2026-10-27
depends-on:
superseded-by:
---

# F-049 — Neue Zonen erkennen und anbieten

## Verlauf

### F-049a — Skript, Tests, Vertrag (2026-10-27)

Teil von F-049 (Neue Zonen erkennen und anbieten; F-049b–c folgen).

**Problem:** `zones` meldete jede Zone, die im Render steht und der Datei fehlt, als
`opted-out` und bot sie nie an. Eine neue Zone erreichte so keine bestehende
Installation — weder in den seed-Dateien noch in den globalen Kit-Regeln, auch nicht nach
einer Umbenennung oder einem später eingeschalteten `template:optional`-Block.

**Was entstanden ist (1.7.0, unveröffentlicht):**

- **`zones`:** Die Basis einer Datei ist `<Ziel>.base` des Snapshots, sonst
  `<Ziel>.seed`, mit `--base DIR` weiter `DIR/<Ziel>`. Eine Zone, die der Render hat und
  die Datei nicht, ist `new` (auch nicht in der Basis), `opted-out` (in der Basis) oder
  `unconfirmed` (die Datei hat keine Basis). Eine Zone in Datei und Basis, die der Render
  nicht mehr hat, ist `removed`; mit Override-Zeile bleibt sie `local`. Ohne Namen wendet
  das Skript `differs`, `new` und `removed` an, `opted-out` und `unconfirmed` nur per
  Name. Eine neue Zone kommt hinter ihren nächsten Vorgänger aus dem Render, der in der
  Datei steht oder mit ihr kommt; ohne Vorgänger vor den nächsten Nachfolger, ohne beide
  ans Dateiende, mehrere in der Reihenfolge des Renders. Eine entfernte Zone geht samt
  Inhalt. Die Zählung bei Override zeigt jetzt auch für Zonen, was das Template seit der
  Basis geändert hat.
- **`snapshot --seeds`:** schreibt und entfernt `<Ziel>.seed`; ein Ziel mit managed
  Basis lehnt er ab, bevor er etwas schreibt. `status`, `merge` und `changed` lesen nur
  `*.base` und sehen die Seed-Basen nicht.
- **MANIFEST:** § Base snapshot beschreibt die Seed-Basen, § Seed sections neue,
  abgewählte und entfernte Zonen samt Einsetz-Stelle und die einmalige Nachfrage ohne
  Basis.
- **Tests:** `zones.sh` mit einem Block für Seed-Basen (neue, abgewählte, entfernte,
  umbenannte und geschützte Zonen, alle Einsetz-Stellen, Auswahl per Name, `--base` ohne
  Seed-Basis), `snapshot --seeds` (setzen, entfernen, Ablehnung, `status` und `merge`
  unberührt) und einem echten Render, in dem Graphiti nachträglich eingeschaltet wird.
  `global.sh` mit einer neuen Kit-Zone und dem Opt-out mit und ohne Basis. Die zwei
  bisherigen Opt-out-Tests ohne Basis prüfen jetzt `unconfirmed`.
- Version 1.7.0, CHANGELOG mit `### Template`.

**Verifikation:** `just check` grün mit 1734 Checks unter dash, bash und mawk (144
neu). Der Kern von Hand an einem Beispiel nachgeprüft: Zustände, Diffstat und
Ergebnisdatei wie geplant. Secrets- und Privacy-Scan samt Blocklist ohne Fund.

**Notable decisions:**
- Die Seed-Basis liegt mit eigener Endung im selben Ordner: Die `.gitattributes`-Zeile
  des Snapshots gilt weiter, und kein Befehl außer `zones` muss davon wissen.
- `removed` gibt es nur für Zonen. Welche Fragmente ein Projekt hat, entscheiden die
  Antworten (`FRAGMENTS`); ein Fragment, das nur das Projekt hat, bleibt `local`.
- Beim Einsetzen hinter einem Vorgänger kommt eine Leerzeile davor, vor einem Nachfolger
  eine danach (und davor, wenn dort Text steht). Beim Entfernen zwischen zwei Leerzeilen
  geht eine davon mit.
- Mit `--base` (Migration) bleiben Seed-Basen ungenutzt; fehlende Zonen sind dort
  `unconfirmed`.

**Geänderte Dateien:** `plugins/coding-kit/scripts/template-sync.sh`,
`tests/template-sync/zones.sh`, `tests/template-sync/global.sh`,
`plugins/coding-kit/template/MANIFEST.md`, `plugins/coding-kit/.claude-plugin/plugin.json`,
`plugins/coding-kit/CHANGELOG.md`, `PROGRESS.md`.

### F-049b — Skills anbinden (2026-10-27)

Teil von F-049 (Neue Zonen erkennen und anbieten; F-049a siehe darunter, F-049c folgt).

**Problem:** Seit F-049a kennt `zones` neue, abgewählte, unbestätigte und entfernte Zonen
und liest Seed-Basen, aber kein Skill bot die neuen Zustände an oder setzte die Basen.

**Was entstanden ist (1.7.0, unveröffentlicht):**

- **update-conventions A2 Schritt 6:** `zones` vergleicht mit Render und Basis; das
  Ergebnis ohne Namen enthält `differs`, `new` und `removed`, `opted-out` und
  `unconfirmed` kommen nur über einen Lauf mit den Namen hinein. Der Skill entfernt keine
  Blöcke selbst.
- **A2 Schritt 7:** `new` → **einsetzen** / **nicht einsetzen (Opt-out)**, ohne „diesmal
  nicht"; `opted-out` → auflisten und das Zurückholen anbieten; `unconfirmed` → einmal
  fragen; `removed` → **entfernen** / **behalten**, mit einer `new`-Zone und einer
  Umbenennung im Update-Fenster als Umzug; `override` mit Zählung → Diff `.base` →
  `.template` zur Info; `local` neu gefasst (`claude-graphiti` ohne Graphiti kommt mit
  Basis als `removed`).
- **A2 Schritt 9:** `snapshot --seeds` für jede seed-Datei mit Zonen-Zeilen außer
  `no-file` und `skipped`, in jedem Lauf, auch nach abgelehnten Zonen.
- **A3:** Bei der Migration gibt es keine Seed-Basis; fehlende Zonen kommen als
  `unconfirmed`, Schritt 9 setzt die Basen.
- **G3:** dieselben Zustände für die globalen Kit-Regeln; `no-file` und `skipped` kommen
  dort nicht vor (steht so im Skill). G6 bleibt.
- **new-project Schritt 4:** setzt die Seed-Basen aus dem Render von Schritt 2 für die
  seed-Dateien aus MANIFEST § Seed sections.
- **README:** Die Zeile zu `update-conventions` nennt die Erkennung neuer und
  gestrichener Zonen an der Basis.
- CHANGELOG 1.7.0 um beide Skills ergänzt.

**Verifikation:** `just check` grün (1734 Checks unter dash, bash und mawk). Per Skript
gezählt, dass A2 Schritt 7 und G3 jeden Zustand von `zones` nennen. Secrets- und
Privacy-Scan samt Blocklist ohne Fund. Ob die Texte im Lauf wirken, prüft F-049c.

**Notable decisions:**
- Die Seed-Basen setzt Schritt 9 auch nach „diesmal nicht" bei `differs`: Die Basis
  entscheidet nur, ob eine Zone neu ist; `differs` bietet der nächste Lauf ohnehin
  wieder an.
- Eine Umbenennung erkennt der Skill nur über das Update-Fenster (CHANGELOG), nicht über
  eine Tabelle — wie in F-049 entschieden.
- Abweichung vom Plan: die README-Zeile kam dazu (Checkliste von `/add-skill`).

**Geänderte Dateien:** `plugins/coding-kit/skills/update-conventions/SKILL.md`,
`plugins/coding-kit/skills/new-project/SKILL.md`, `README.md`,
`plugins/coding-kit/CHANGELOG.md`, `PROGRESS.md`.

### F-049c — Text ohne Marker erkennen (2026-10-27)

Teil von F-049 (Neue Zonen erkennen und anbieten; F-049a–b siehe darunter, F-049d folgt).

**Problem:** Der erste Projekt-Testlauf (vor diesem Substep, 0,78 USD) fand eine Lücke:
Wer eine Zone abwählt, löscht ihr Markerpaar und behält meist den Text. `zones` hätte
eine solche Zone beim Einsetzen ein zweites Mal geschrieben — `progress-head` ohne Basis
und ohne gemeinsame Zone sogar ans Dateiende hinter den FEATURE-INDEX. Der Lauf legte
die Marker stattdessen von Hand um den Text (Marker-Migration aus A3); der Skill-Text
verlangte diese Prüfung aber nirgends.

**Was entstanden ist (1.7.0, unveröffentlicht):**

- **`zones`:** sucht den Inhalt einer fehlenden Zone wörtlich und zusammenhängend in der
  Datei, außerhalb aller Blöcke und des Slots und ohne Text, den schon eine andere Zone
  gefunden hat; eine Zone ohne nicht-leere Zeile wird nicht gesucht. Kennt die Basis die
  Zone nicht und steht ihr Text da → neuer Zustand `bare`. Kennt die Basis sie, bleibt
  sie `opted-out` — jetzt auch in einer Datei ganz ohne Marker (bisher `unmarked`).
  `bare` wird nur per Name angewendet: Das Skript legt die Marker der Zone um den
  vorhandenen Text. Ebenso eine per Name zurückgeholte `opted-out`-Zone, deren Text noch
  dasteht. Eine neue Zone hinter einer so umrahmten kommt hinter deren Endmarker.
- **update-conventions:** A2 Schritt 7 und G3 bieten `bare` als **Marker setzen** /
  **so lassen** an; beim Zurückholen einer abgewählten Zone setzt das Skript nur die
  Marker. A3 Schritt 4: wörtlich gefundene Zonen umrahmt das Skript, von Hand bleibt nur
  geänderter Text. `unmarked` heißt jetzt: keine Marker, keine Basis, kein wörtlicher
  Text.
- **MANIFEST § Seed sections:** Abwahl auch bei Datei ohne Marker; Text ohne Marker
  bekommt auf Wunsch nur seine Marker.
- **Tests:** `zones.sh` mit einem Block „text without markers" (ohne Basis, Datei ohne
  Marker, Abwahl mit stehendem Text, alle Marker weg mit Basis, geänderter Text, leere
  Zone, zwei Zonen mit gleichem Text, Text in einer anderen Zone, neue Zone hinter einer
  umrahmten) und dem Fall aus dem Testlauf am echten Render (`progress-head`); in
  `global.sh` erwartet der Fall ohne Basis jetzt `bare`.
- Fehlermeldung bei einem Namen ohne passenden Block nennt alle anwendbaren Zustände.
- CHANGELOG 1.7.0 ergänzt.
- **PROGRESS:** Entscheidung „Text ohne Marker" im Elterneintrag, neuer Substep F-049c;
  das bisherige F-049c (Testlauf und Release) heißt F-049d.

**Verifikation:** `just check` grün mit 1800 Checks unter dash, bash und mawk (66 neu).
Von Hand am Testprojekt aus dem ersten Lauf: `progress-head` `bare`, per Name nur die
zwei Markerzeilen; `claude-workflow` per Name zurückgeholt ebenso. A2 Schritt 7 und G3
nennen jeden Zustand (per Skript gezählt). Secrets- und Privacy-Scan samt Blocklist ohne
Fund.

**Notable decisions:**
- Im Skript statt nur im Skill-Text (Nutzerentscheidung): Der Vergleich ist
  deterministisch, und das Einsetzen gehört nach der Authoring-Regel ins Skript.
- Nur wörtlicher Text zählt; geänderter Text bleibt Handarbeit (A3), damit das Skript
  nie rät.
- Eine Abwahl mit stehendem Text bleibt `opted-out`, nicht `bare` — sonst fragte jeder
  Lauf erneut nach.
- `bare` nur per Name, nie im Standard-Ergebnis: Ob der Text wieder eine Zone werden
  soll, entscheidet der Nutzer.

**Geänderte Dateien:** `plugins/coding-kit/scripts/template-sync.sh`,
`tests/template-sync/zones.sh`, `tests/template-sync/global.sh`,
`plugins/coding-kit/skills/update-conventions/SKILL.md`,
`plugins/coding-kit/template/MANIFEST.md`, `plugins/coding-kit/CHANGELOG.md`,
`PROGRESS.md`.

### F-049d — Testlauf und Release (2026-10-27)

Schließt F-049 ab (Neue Zonen erkennen und anbieten; F-049a–c siehe darunter).

**Problem:** F-049a–c waren nur durch Skript-Tests belegt. Ob update-conventions die neuen
Zustände im echten Lauf ohne Handarbeit anbietet und umsetzt, zeigt erst ein Modell-Lauf.

**Was entstanden ist (Release 1.7.0):**

- **Drei Testläufe** (`claude -p --plugin-dir`, Opus auf `medium`, Budget-Cap 4 USD je
  Lauf; zusammen 2,11 USD) an Stellvertreter-Ordnern; das echte `~/.claude` blieb
  unverändert (Prüfsummen):
  - Projekt, erster Versuch (0,78 USD, 13 Turns): ein Projekt aus der aktuellen Vorlage
    mit Stempel 1.6.0, Graphiti in den Antworten eingeschaltet, Seed-Basen außer für
    `PROGRESS.md`, einer Zone `claude-legacy` nur in Projekt und Basis, abgewählter
    `claude-workflow` und `progress-head` ohne Marker neben einer eigenen Zone. Fund:
    `progress-head` wäre ein zweites Mal ans Dateiende gekommen; der Lauf setzte die
    Marker von Hand → F-049c.
  - Projekt, wiederholt nach F-049c (0,80 USD, 12 Turns): `claude-graphiti` eingesetzt
    (vor `claude-startup`), `claude-legacy` entfernt, `progress-head` als `bare` nur
    umrahmt, `claude-workflow` abgewählt gelassen, Seed-Basen für alle sechs Dateien
    gesetzt, Stempel 1.7.0 — alles über `zones` und `snapshot`, keine Datei von Hand.
  - Global (0,53 USD, 5 Turns): Stellvertreter-Config mit Testwerten, Regeldatei und
    Basis ohne `global-workflow`, `global-git` abgewählt; die neue Zone eingesetzt, die
    Abwahl respektiert, Basis gleich dem vollen Render; die env-Datei nicht ausgegeben.
  Den Endstand prüfte jeweils ein eigener `zones`-Lauf.
- **Release 1.7.0** (`c095e66`, CHANGELOG datiert): Personendaten-Grep über die fünf
  Commits samt Metadaten und Messages, Blocklist und gitleaks ohne Fund; Push, CI grün
  (Lauf 40489982920, 1800 Checks unter gawk und mawk); Marketplace und Plugin von 1.6.0
  auf 1.7.0 aktualisiert, der Cache dateigleich mit dem Repo.

**Notable decisions:**
- Testprojekt gemischt statt „aus 1.6.0 ohne Seed-Basis" (Nutzerentscheidung): Ohne
  Basis wären alle fehlenden Zonen `unconfirmed`; nur mit Basen deckt ein Lauf `new`,
  `opted-out`, `removed` und `unconfirmed` ab.
- Die überzählige Leerzeile am Ende der globalen Regeldatei stammt aus dem Testaufbau
  (beim Herausschneiden der Zone blieb die trennende Leerzeile stehen), nicht aus
  `zones`.
- Gefunden, nicht verfolgt: Mit `--plugin-dir` meldet der Session-Hinweis immer
  geänderte globale Regeln, weil das Testplugin einen eigenen Datenordner ohne Basis hat.

**Planungsentscheidungen von F-049** (aus dem Elterneintrag):

**Problem:** `zones` kann eine Zone, die im Render steht und der Datei fehlt, nicht von
einer abgewählten unterscheiden: Beide heißen `opted-out`, und angeboten wird nichts. So
erreicht eine neue Zone keine bestehende Installation — in den seed-Dateien der Projekte,
in den globalen Kit-Regeln auf dem Rechner (F-040) und bei einer umbenannten Zone (die
alte gilt als `local`, die neue als `opted-out`). Dasselbe gilt für eine Zone in einem
`template:optional`-Block, den ein Projekt später einschaltet (z. B. `claude-graphiti`).
Fragmente haben das Problem nicht, sie kennen den Zustand `new`.

**Idee:** `zones` unterscheidet über eine Basis, den Render beim letzten Abgleich: Fehlt
eine Zone auch dort, ist sie neu (`new`) und wird an ihrer Stelle aus dem Render
eingesetzt, wie heute ein neues Fragment; steht sie in der Basis, hat der Nutzer sie
abgewählt. Die globalen Regeln haben diese Basis schon (F-040c), für seed-Dateien fehlt
sie bisher.

**Entschieden (2026-10-27):**
- **Basis für seed-Dateien:** der volle Seed-Render beim letzten Abgleich, als
  `.claude/template-base/<target>.seed`. Die eigene Endung hält sie aus `status`, `merge`
  und `changed` heraus, die nur `*.base` lesen; die `.gitattributes`-Zeile des Ordners
  gilt weiter. `snapshot --seeds` schreibt sie, `zones` liest `<target>.base`, sonst
  `<target>.seed`. Verworfen: eine Liste der Zonen mit der Version, seit der es sie gibt —
  sie erkennt keine Zone, die erst ein eingeschaltetes `template:optional` bringt.
- **Zustände einer Zone,** die der Render hat und das Projekt nicht: `new` (auch nicht in
  der Basis — anbieten und einsetzen), `opted-out` (in der Basis — der Nutzer hat sie
  abgewählt), `unconfirmed` (keine Basis für die Datei — einmal fragen; danach hat sie
  eine). Eine Zone, die Projekt und Basis haben und der Render nicht mehr: `removed`
  (anbieten, die ganze Zone samt Inhalt zu entfernen). Trägt sie eine Override-Zeile,
  bleibt sie `local` und wird nicht angefasst.
- **Einsetzen:** hinter die nächste vorangehende Zone aus der Reihenfolge des Renders, die
  das Projekt hat; ohne Vorgänger vor die nächste folgende, ohne beide ans Dateiende. Ohne
  Namen setzt `zones` `differs`, `new` und `removed` um; `opted-out` und `unconfirmed`
  nur, wenn sie per Name genannt sind — so lässt sich eine abgewählte Zone nachträglich
  einsetzen.
- **Keine „diesmal nicht"-Wahl bei neuen Zonen:** Der Snapshot setzt danach den Render als
  Basis, aus „diesmal nicht" würde still ein Opt-out. Angeboten wird **einsetzen** /
  **nicht einsetzen (Opt-out)**; jeder Lauf listet die abgewählten Zonen und bietet an,
  eine per Name einzusetzen.
- **Keine Tabelle umbenannter Zonen:** Mit Basis erscheint eine Umbenennung als `removed`
  plus `new`, beides wird angeboten. Braucht F-036 einen echten Umzug, kommt die Tabelle
  dort.
- **Override in seed-Zonen:** Wie bei Fragmenten zeigt die Zählung einer geschützten Zone,
  was das Template seit der Basis geändert hat (Diff `.base` → `.template` zur Info).
- **Migration:** Bestehende Projekte haben keine `.seed`-Basis; ihre fehlenden Zonen
  kommen einmal als `unconfirmed`. `/new-project` setzt die Seed-Basen ab dem Anlegen.
- **Text ohne Marker (Fund aus dem ersten Testlauf):** Wer eine Zone abwählt, löscht ihr
  Markerpaar und behält meist den Text. Steht der Inhalt einer fehlenden Zone wörtlich
  ohne Marker in der Datei und kennt die Basis sie nicht, meldet `zones` sie als `bare`
  und legt beim Anwenden (nur per Name) die Marker um den vorhandenen Text, statt sie ein
  zweites Mal einzusetzen. Kennt die Basis sie, bleibt sie `opted-out`, auch in einer
  Datei ganz ohne Marker; holt man sie per Name zurück, kommen ebenfalls nur die Marker
  um den stehenden Text.

**Abhängigkeiten:** keine. Sinnvoll vor F-036, das die seed-Zonen umbaut — dessen neue
Zonen erreichen bestehende Projekte sonst nicht. Ergänzt F-040: Teil G und der
Session-Hinweis melden eine neue Kit-Zone, angeboten wird sie erst mit F-049.

**Geänderte Dateien:** `plugins/coding-kit/CHANGELOG.md` (Release), `PROGRESS.md`,
`PROGRESS-ARCHIVE.md`.
