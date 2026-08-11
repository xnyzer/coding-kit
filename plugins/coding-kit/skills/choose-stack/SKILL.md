---
name: choose-stack
description: Stack-Modul wählen oder nachrüsten. Modus Neuanlage empfiehlt ein project-template-Modul aus der Short-Info (aktuelle Framework-Lage per Websuche verifiziert); Modus Bestandsprojekt rüstet EIN Modul nach bzw. wechselt es — mit Diff und Bestätigung je Datei. Laufende Modul-Updates macht /update-conventions, nicht dieser Skill.
disable-model-invocation: false
---

# Stack-Modul wählen / nachrüsten

**Grenze (verbindlich):** Dieser Skill macht den **Erst-Einbau oder Wechsel EINES
Moduls**. Laufende Updates bereits eingebauter Module laufen über `/update-conventions`
(via MANIFEST) — nicht hier.

## 0. Template auflösen

Quelle ist das project-template — zur Laufzeit auflösen, nie hardcoden:

1. Lokaler Checkout: `$CODING_KIT_PROJECTS_DIR/project-template` (Personal-Config
   `~/.claude/coding-kit.env`), falls vorhanden.
2. Sonst: `gh repo clone "$(gh api user --jq .login)/project-template" <tmp> -- --depth 1`
   (Override möglich via `CODING_KIT_TEMPLATE_REPO` in der Personal-Config).

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

1. **Projektkontext:** Projekt-CLAUDE.md lesen; `.claude/convention-overrides.md` und
   `<!-- override: … -->`-Marker erfassen — **Overrides werden nie überschrieben.**
   Prüfen, ob schon ein Modul eingebaut ist (justfile-Kopf, `mise.toml`,
   `.claude/template-version`): Gleiches Modul aktualisieren wollen → an
   `/update-conventions` verweisen und stoppen.
2. **Plan zeigen** — je Part aus dem Modul-Kontrakt (MANIFEST § Module contract):
   - `justfile` **ersetzt** das Core-justfile (Standard-Rezepte bleiben der Vertrag),
   - `mise.part.toml` → Merge in `[tools]` der `mise.toml`,
   - `gitignore.part` → unter dem Marker `# module:gitignore` anhängen,
   - **Standards-Fragmente** → im Slot `<!-- module:coding-standards -->` **anhängen**,
     nie ersetzen. Fragmentliste in Reihenfolge: eigenes Sprachfragment des Moduls
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
     _(Default: nein)_ — Anhängen nur nach Bestätigung, gleiche Mechanik,
   - `ci.part.yml` → Jobs unter `# module:ci-jobs` anhängen,
   - `files/**` → nach Platzhalter-Substitution kopieren (Werte aus dem Projekt
     ableiten: Name aus Repo, Owner via `gh api user`, Beschreibung aus README/CLAUDE.md;
     Policies je Datei laut `MODULE.md` — seed-Dateien nie überschreiben, wenn sie
     schon existieren).
3. **Je Datei Diff zeigen und einzeln bestätigen lassen.** Kollisionen mit bestehenden
   Dateien: Diff + Frage statt Überschreiben. Beim **Wechsel** zusätzlich auflisten, was
   vom Alt-Modul entfernt/zurückgebaut wird — ebenfalls bestätigen lassen. Das
   Sprachfragment des Alt-Moduls wird dabei gegen das neue getauscht; vorhandene
   Katalog-Fragmente bleiben stehen und werden nur aufgelistet („noch aktuell?") —
   Entfernen ist eine Projektentscheidung, kein Automatismus.
4. **Verifikation:** `mise install && just setup && just check` muss grün sein
   (Write-then-Verify). Kein Commit ohne Nachfrage; `.claude/template-version` wird hier
   **nicht** gestempelt (das macht /new-project; Projekte ohne Stempel gleicht später
   /update-conventions heuristisch ab).

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

Aktuell einziger Fall im Katalog: **`nextjs`** — verlangt eine `AGENTS.md` im Projektroot,
bevor `next dev` das erste Mal läuft, weil Nexts Agent-Rules-Generator seinen Managed-Block
sonst in die `CLAUDE.md` schreibt und ihn dort bei jedem Lauf erneuert. Bedingungen und
Nachbesserung stehen im Fragment.

## Rückgabe an den Aufrufer

Der Modulname (z. B. `python`, `ts-node`, `docs-only`) — für `/new-project` inklusive
`{{CODEQL_LANGUAGES}}`-Wert aus dem `MODULE.md`. In Modus B zusätzlich: Liste der
tatsächlich geschriebenen Dateien.
