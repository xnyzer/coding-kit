---
name: choose-stack
description: Stack-Modul wählen oder nachrüsten. Modus Neuanlage empfiehlt ein Modul des mitgelieferten Templates aus der Short-Info (aktuelle Framework-Lage per Websuche verifiziert); Modus Bestandsprojekt rüstet EIN Modul nach bzw. wechselt es — mit Diff und Bestätigung je Datei. Laufende Modul-Updates macht /update-conventions, nicht dieser Skill.
disable-model-invocation: false
---

# Stack-Modul wählen / nachrüsten

**Grenze (verbindlich):** Dieser Skill macht den **Erst-Einbau oder Wechsel EINES
Moduls**. Laufende Updates bereits eingebauter Module laufen über `/update-conventions`
(via MANIFEST) — nicht hier.

## 0. Template auflösen

Das Template liegt im Plugin: **`${CLAUDE_PLUGIN_ROOT}/template`**. Es kommt mit jedem
Plugin-Update und gehört immer zur Version dieser Skills (`version` in
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`) — kein Klon, kein lokaler Checkout,
kein Override. Der Pfad steht hier bereits aufgelöst; in Shell-Befehlen genau ihn
verwenden, als Umgebungsvariable gibt es `CLAUDE_PLUGIN_ROOT` nicht. Pfad und Version im
Lauf nennen. Wer am Template selbst arbeitet, startet die Session mit
`claude --plugin-dir <coding-kit-Checkout>/plugins/coding-kit` — dann kommen Skills und
Template aus dem Arbeitsstand.

Dort lesen: `MANIFEST.md` (§ Module contract und § Standards fragments — der Vertrag,
wie Teile und Fragmente angewendet werden), `modules/README.md` (verfügbare Module +
Status), `modules/standards/README.md` (Fragment-Katalog) und das `MODULE.md` des
Kandidaten.

## Modus A — Neuanlage (aus /new-project oder ohne bestehendes Projekt)

1. Aus der Short-Info den Bedarf ableiten (CLI? Web? Library? Automatisierung? iOS?).
2. **Aktuelle Lage per Websuche verifizieren** — nicht aus dem Gedächtnis: Ist die
   naheliegende Modul-Toolchain noch der sinnvolle Default für diesen Anwendungsfall?
   Gibt es einen klaren Nachfolger? (Kurz halten: 1–2 gezielte Suchen.)
3. Empfehlung: **ein** Modul mit 2–3 Sätzen Begründung + nächstbeste Alternative.
   Stubs (laut `modules/README.md`) klar als „dokumentiert, nicht ausgebaut" ausweisen —
   wer sie wählt, bekommt heute nur docs-only-Niveau plus Vorarbeit.
   „Offen/weiß noch nicht" → **docs-only** (Default).
4. **Eine** Frage: „Welches Modul?" — Default = Empfehlung.

## Modus B — Bestandsprojekt (Modul nachrüsten oder wechseln)

1. **Projektkontext:** Projekt-CLAUDE.md lesen; die Files-Tabelle der
   `.claude/convention-overrides.md` (Arten laut MANIFEST § Deviation registry — `skip`
   gilt) und Inline-`<!-- override: … -->` in Fragmenten erfassen. Prüfen, ob schon ein
   Modul eingebaut ist (`MODULE` in `.claude/template-answers`, justfile-Kopf): Gleiches
   Modul aktualisieren wollen → an `/update-conventions` verweisen und stoppen. **Fehlen
   `.claude/template-answers` oder `.claude/template-base/`** (Projekt vor dem
   Snapshot-Vertrag): zuerst die Migration über `/update-conventions` empfehlen und
   stoppen — der Modulwechsel braucht die Basis.
2. **Plan zeigen:** Das Skript `${CLAUDE_PLUGIN_ROOT}/scripts/template-sync.sh` (in
   Shell-Befehlen der aufgelöste Pfad, Aufruf über `sh`) wendet den Modul-Kontrakt an
   (MANIFEST § Module contract) — nie Teile selbst einsetzen. Eine Kopie der Antworten
   mit `MODULE=<neu>` in ein Temp-Verzeichnis `<tmp>` legen, dann
   `sh <skript> render <template> <tmp>/answers <tmp>/soll` und
   `sh <skript> merge <projekt> <tmp>/soll <tmp>/out`. Die Klassen zeigen den Plan:
   justfile, `mise.toml`, `.gitignore`, CI und CodeQL ändern sich (`template-only`,
   `merged`, bei Projektzusätzen auch `conflict`), managed Dateien des neuen Moduls kommen
   dazu (`new`), die des Alt-Moduls entfallen (`removed`). Die seed-Dateien des Moduls
   (`files/**` mit Policy seed, z. B. Paket-Manifest und Beispielcode) liefert
   `sh <skript> render --seeds <template> <tmp>/answers <tmp>/seeds` — nur anlegen, was
   es im Projekt noch nicht gibt, nie überschreiben.
   - **Standards-Fragmente** (der Slot ist im Merge ausgeblendet, er läuft hier) → im
     Slot `<!-- module:coding-standards -->` **anhängen**, nie ersetzen. Fragmentliste in
     Reihenfolge: eigenes Sprachfragment des Moduls
     (`CODING-STANDARDS.part.md`), dann die Katalog-Fragmente
     (`modules/standards/<name>.md`) laut `Standards fragments:`-Zeile des `MODULE.md`
     — tolerant lesen (fett/plain; `(none)`, leer oder fehlend = keine). Die
     Quell-Dateien tragen ihre `<!-- fragment:NAME -->`-Marker bereits: unverändert vor
     dem schließenden `<!-- /module:coding-standards -->` einfügen. **Idempotent:** ist
     `fragment:NAME` im Projekt schon vorhanden → überspringen — nie doppelt einbauen,
     nie erneuern (Erneuern macht `/update-conventions`); die **Begleithandlung** des
     Fragments wird davon unabhängig geprüft (§ Begleithandlungen). Beim Erst-Einbau den
     Platzhaltertext im Slot entfernen. **Eigenschafts-Fragmente**
     (`*characteristic:*`-Zeilen des Katalogs) sind in keinem `MODULE.md`
     deklariert: je Trigger fragen, ob die Eigenschaft auf das Projekt zutrifft
     _(Default: nein)_ — Anhängen nur nach Bestätigung, gleiche Mechanik.
3. **Je Datei Diff zeigen und einzeln bestätigen lassen** — dieselben Entscheidungen wie
   `/update-conventions` A2 Schritt 5 (übernehmen heißt, das Ergebnis aus `<tmp>/out`
   kopieren). Beim **Wechsel** auch das Entfernen der `removed`-Dateien des Alt-Moduls
   bestätigen lassen. Das Sprachfragment des Alt-Moduls wird gegen das neue getauscht;
   vorhandene Katalog-Fragmente bleiben stehen und werden nur aufgelistet („noch
   aktuell?") — Entfernen ist eine Projektentscheidung, kein Automatismus.
4. **Nachziehen:** `MODULE` in `.claude/template-answers` setzen (und `FRAGMENTS` laut
   § Begleithandlungen), dann `sh <skript> snapshot <projekt> <tmp>/soll <Ziele>` für jedes
   übernommene oder entfernte Ziel — sonst meldet der nächste Abgleich den Modulwechsel
   als Abweichung.
5. **Verifikation:** `mise install && mise lock && just setup && just check` muss grün
   sein, danach die Prüfung aus § Lock-Datei erzeugen und prüfen — der Modulwechsel
   ändert die Tools, `mise lock` nimmt neue auf und entfernt gestrichene
   (Write-then-Verify). `sh <skript> status <projekt>` zeigt danach keine neue
   Abweichung ohne Registry-Zeile. Kein Commit ohne Nachfrage;
   `.claude/template-version` wird hier **nicht** gestempelt (das macht /new-project bzw.
   /update-conventions).

## Begleithandlungen beim Fragment-Einbau

Gilt überall, wo ein Standards-Fragment in ein Projekt gelangt — Modus B, `/new-project`,
`/update-conventions` und die Vorschläge aus `/prep-step` und `/step-done`.

Manche Fragmente verlangen beim Einbau **eine Handlung am Projekt**, nicht nur den Text im
Slot — typisch dort, wo das Framework selbst in Projektdateien schreibt und die Reihenfolge
über das Ergebnis entscheidet. Deshalb vor dem Anhängen das Fragment lesen (und seine
Katalog-Zeile): Formuliert es eine Anforderung, die **beim Einbau** erfüllt sein muss und
nicht erst beim späteren Coden, im selben Schritt ausführen. Was dabei entsteht oder sich
ändert, gehört wie jede andere Dateiänderung in den Plan und wird einzeln bestätigt.
**Nichts hardcoden:** was zu tun ist, steht im Fragment, nicht hier.

Zwei Eigenheiten, die diese Prüfung von der Fragment-Mechanik trennen:

- **Unabhängig von der Idempotenz-Regel.** Liegt `fragment:NAME` schon im Slot, wird der
  Text übersprungen — die Begleithandlung wird trotzdem geprüft und bei Bedarf nachgeholt.
  Sonst bleiben Projekte ungedeckt, die das Fragment bekommen haben, bevor es die
  Anforderung enthielt.
- **Reihenfolge kann bindend sein.** Eine Begleithandlung darf vorschreiben, dass etwas
  *vor* dem ersten Lauf des Frameworks passiert, und einen Zustand benennen, den ein
  späteres Nachholen allein nicht mehr heilt (dann gehört das Aufräumen in denselben
  Schritt). Fragmente mit solcher Fallhöhe sagen das selbst — die Anweisung im Fragment
  ist maßgeblich, nicht die Zusammenfassung hier.

Ist alles erfüllt → still überspringen, nichts melden.

**Antworten und Registry** — gehören in denselben Schritt wie das Fragment selbst:

- **`FRAGMENTS`:** Ein angehängtes Fragment, das das Modul nicht selbst deklariert
  (Eigenschafts-Fragment oder Katalog-Fragment für ein später eingeführtes Framework),
  kommt in `FRAGMENTS` der `.claude/template-answers` — die Antworten beschreiben den Slot
  vollständig, und `/update-conventions` gleicht beides ab.
- **`keep`-Zeilen:** Ändert eine Begleithandlung **managed** Dateien (z. B. `nextjs` und
  `astro`: `tsconfig.json`, `biome.json`, justfile), je Datei eine Zeile mit Art `keep` und
  dem Fragment als Grund in die Files-Tabelle der `.claude/convention-overrides.md`.
  Template-Updates kommen dann weiter an, bei Konflikten gewinnt das Projekt — und
  `/step-done` meldet die Änderung nicht als unregistriert.

Aktuell einziger Fall im Katalog: **`nextjs`** — verlangt eine `AGENTS.md` im Projektroot,
bevor `next dev` das erste Mal läuft, weil Nexts Agent-Rules-Generator seinen Managed-Block
sonst in die `CLAUDE.md` schreibt und ihn dort bei jedem Lauf erneuert. Bedingungen und
Nachbesserung stehen im Fragment.

## Lock-Datei erzeugen und prüfen

Gilt überall, wo ein Skill die Toolchain eines Projekts installiert — Modus B,
`/new-project` und `/update-conventions`. Die CI (`jdx/mise-action`) installiert mit
`--locked`, sobald eine `mise.lock` existiert, und braucht dafür je Tool eine
Download-URL für die Plattform des Runners. `mise install` schreibt diese Einträge nicht.

- **Erzeugen:** nach `mise install` schlicht `mise lock` — **ohne `--platform`**. Welche
  Plattformen hineingehören, steht allein in `lockfile_platforms` (`[settings]` der
  `mise.toml`, aus der Vorlage); ein Flag daneben würde die Liste doppelt führen.
  Fehlt die Einstellung (Projekt vor dem Template-Stand mit `lockfile_platforms`), kein
  Flag als Ersatz setzen, sondern auf `/update-conventions` verweisen — die
  `mise.toml` ist managed und bringt die Einstellung mit.
- **Prüfen:** jedes Tool in der `mise.lock` (`[[tools.<tool>]]`) hat einen Eintrag
  `[tools.<tool>."platforms.<p>"]` für jede Plattform `<p>` aus `lockfile_platforms`.
  - **Lücke auf der Plattform des CI-Runners** (aus `runs-on` der Projekt-CI ableiten,
    z. B. `ubuntu-*` → `linux-x64`) → blockiert den Commit; die CI wäre rot. Ursache
    klären (Netz, Tool-Version ohne Release für die Plattform), nicht übergehen.
  - **Übrige Lücken** → melden und gegen die „Known limitation"-Einträge im
    `${CLAUDE_PLUGIN_ROOT}/CHANGELOG.md` abgleichen; dort dokumentierte Upstream-Lücken
    sind bekannt und blockieren nicht.
- Die `mise.lock` wird mitcommittet — sie ist Projektdatei, nie Template-Inhalt.

## Rückgabe an den Aufrufer

Der Modulname (z. B. `python`, `ts-node`, `docs-only`) — für `/new-project` inklusive
`{{CODEQL_LANGUAGES}}`-Wert aus dem `MODULE.md`. In Modus B zusätzlich: Liste der
tatsächlich geschriebenen Dateien.
