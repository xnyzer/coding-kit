---
name: propose-to-template
description: Übernahme-Vorschlag fürs Template (Projekt → coding-kit) aus einem Fund erzeugen — ein Tool ohne Vorlage (detect meldet `unknown`), ein projektlokales Fragment ohne Katalog-Pendant oder eine Abweichung an einer managed Datei, die allen Projekten nützt. Gibt generalisierten, personendatenfreien Text kopierfertig aus — als Issue (Standard) oder als Prompt für eine Session im Kit-Repo bzw. einem Fork —, sendet nichts ab und schreibt weder ins Template noch ins Projekt. Claude startet ihn bei einem solchen Fund aus update-conventions, step-done, prep-step oder choose-stack, oder wenn der Nutzer etwas dem Template vorschlagen will.
user-invocable: false
---

# Übernahme-Vorschlag fürs Template

Konventionen fließen nur abwärts (Template → Projekt). Was ein Projekt besser macht oder
was dem Template fehlt, kommt deshalb als **Vorschlag** zum Kit — der Nutzer schickt ihn
ab oder führt ihn aus. Dieser Skill erzeugt nur Text: Er schreibt nie ins Template, nie
ins Projekt, ruft kein `gh` auf und pusht nichts.

## 0. Fund und Kontext

**Eingabe** ist ein Fund — Art, Name, Evidenz —, meist vom aufrufenden Skill übergeben:

- **Tool** — eine Zeile `tool <name> unknown` aus
  `${CLAUDE_PLUGIN_ROOT}/scripts/template-sync.sh detect` (`MANIFEST.md` § Detection):
  Das Template hat für dieses Tool weder Modul noch Fragment.
- **Fragment** — ein `fragment:NAME`-Block im Slot der `CODING-STANDARDS.md` ohne
  Katalog-Pendant (projektlokal).
- **Managed Datei** — eine Abweichung an einer Datei aus dem Template, die allen
  Projekten nützt (Pfad, Diff gegen den Basis-Snapshot).

Fehlt die Übergabe, den Fund aus dem Gespräch nehmen. Ist er dort nicht eindeutig,
**genau eine** Frage: „Was soll ins Template — ein Tool, ein Fragment oder eine Änderung
an einer managed Datei, und welche?" Nie selbst im Projekt nach Funden suchen — das tun
`/coding-kit:update-conventions` und `/coding-kit:step-done`.

**Kontext:**

- Projekt-CLAUDE.md: Projektname (für die Generalisierung in Schritt 2) und Sprache des
  Gesprächs.
- Template unter `${CLAUDE_PLUGIN_ROOT}/template`: `MANIFEST.md`
  (§§ Placeholders, Module contract, Standards fragments, Detection), die
  Modul-Übersicht `${CLAUDE_PLUGIN_ROOT}/template/modules/README.md` (volle Module und
  Stubs) und der Fragment-Katalog `${CLAUDE_PLUGIN_ROOT}/template/modules/standards/README.md`.
- **Ziel-Repo:** `homepage` in `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`
  (`https://github.com/<owner>/<repo>`) — nie aus dem eigenen Konto ableiten. Ist es keine
  GitHub-URL, das Issue ohne `gh`-Befehl ausgeben und das Ziel-Repo offen lassen.

## Kontext-Recovery

Nach Kompaktierung oder Neustart: den Fund aus dem Gespräch neu lesen, `git status` für
den Stand des Projekts; schon ausgegebene Vorschläge nicht wiederholen — beim nächsten
offenen Schritt weitermachen.

## 1. Ausgangsmaterial sammeln (nur lesen)

- **Tool:** die Einträge in `mise.toml` bzw. `.mise.toml`; was das Projekt damit tut —
  justfile-Rezepte, die das Tool aufrufen, CI-Schritte, Manifeste und Konfigdateien der
  Toolchain (nur Namen und Struktur, keine Projektwerte), eine Regel dazu in der
  `CODING-STANDARDS.md`. Daraus die Richtung empfehlen und begründen:
  - **Modul**, wenn es eine Sprache mit eigener Toolchain ist (Runtime, Paketmanager,
    Lint, Format, Test). Dazu gehört ein Sprachfragment `<sprache>-lang` mit den Regeln,
    die unabhängig von der Toolchain gelten (§ Standards fragments).
  - **Fragment**, wenn es ein Werkzeug ohne eigene Sprache ist, für das Regeln allen
    Projekten nützen (etwa ein Infra-CLI).
  - Kein Vorschlag, wenn das Tool keine Konvention braucht — dann dem Aufrufer sagen,
    dass die Rules-Zeile `tool:NAME` passt, und enden.

  Nennt `modules/README.md` einen **Stub** für diese Sprache, ihn als Ausgangspunkt
  angeben (`modules/<name>/MODULE.md`, Abschnitt „Intended shape").
- **Fragment:** den Block selbst, dazu die Signale, an denen er im Projekt hängt
  (Dependencies, Dateien, Tools — typisiert wie in § Detection).
- **Managed Datei:** den Diff Basis → Projekt
  (`git diff --no-index .claude/template-base/<Ziel>.base <Ziel>`), gekürzt auf den Teil,
  der allen Projekten nützt.

## 2. Generalisieren (Pflicht vor jeder Ausgabe)

- Template-Material (Fragment-Text, Datei-Ausschnitte, Modul-Skizze) ist **englisch**.
- Projektwerte werden Platzhalter aus MANIFEST § Placeholders oder eine neutrale
  Beschreibung. Nicht hinein: Projekt-, Personen-, Kunden- und Hostnamen, lokale Pfade,
  IPs, private Domains (Platzhalter wie `example.com` sind erlaubt), Secrets. Das
  Projekt heißt im Text „a downstream project".
- Keine Versionsstände in Prosa; Tool-Pins grob wie in den `mise.part.toml` der Module
  (Hauptversion).
- **Vor der Ausgabe prüfen:** den Entwurf nach dem Projektnamen, nach
  `git config user.name` und `git config user.email` und nach `/Users/` und `/home/`
  durchsuchen; Treffer ersetzen.

## 3. Format wählen (M1)

**Eine** Frage, sofern der Aufrufer kein Format vorgibt: „Als **Issue** (empfohlen —
geht ohne Kit-Checkout) oder als **Prompt** für eine Session im Kit-Repo bzw. einem
Fork, oder beides?" Default: Issue.

## 4. Ausgabe — immer kopierfertig

**Herkunft trennen (beide Formate):** Was aus dem Projekt stammt und dort läuft, und was
Claude ohne Projektbeleg ergänzt, stehen nie gemischt. Material und Erkenntnisse kommen
in zwei Teile:

- **From the project** — die generalisierten Auszüge aus Schritt 1 (mise-Einträge,
  Rezepte, CI-Schritte, Fragment-Block, Diff) und was das Projekt damit erreicht bzw.
  nicht abdeckt.
- **Suggested, not from the project** — eigene Ideen (weitere Rezepte, Regeln, Tools,
  Struktur), ausdrücklich als ungeprüft markiert: Wer die Ergänzung baut, entscheidet,
  was davon trägt.

Fehlt einer der Teile, „none" schreiben statt ihn wegzulassen.

**Formatierung:**

- Äußere Codeblöcke mit `~~~~` umzäunen, damit Codeblöcke im Material erhalten bleiben.
- Was wörtlich in eine Datei soll (eine `Signals:`-Zeile, eine Katalog-Zeile, ein
  Rezept), steht als eigener Codeblock, nicht als Inline-Code im Satz.
- Inline-Code, der selbst Backticks enthält, mit doppelten Backticks umschließen
  (``` `` `tool:rust` `` ```); nie Backticks in Backticks verschachteln.

**Issue** (englisch — das Kit-Repo ist öffentlich):

- Titel je Fund: `template: add a <language> module`, `standards: add a <name> fragment`
  oder `template: <file> — <change in a few words>`.
- Body genau nach diesem Gerüst — Überschriften und Ebenen wie hier, keine weiteren:

  ```
  ## Summary
  (was fehlt, in zwei Sätzen)
  ## Today
  (was das Projekt stattdessen tut, generalisiert)
  ## Proposal
  (Modul oder Fragment, wohin es gehört, Signale, ein passender Stub, offene Fragen)
  ## Material
  ### From the project
  ### Suggested, not from the project (unverified)
  ## Kit rules
  (MANIFEST im selben Commit, Versions-Bump und CHANGELOG mit „### Template",
  just check grün)
  ```
- Ein Block mit dem vollständigen Befehl — Titel und Body eingesetzt, der Body über
  stdin:

  ~~~~
  gh issue create -R <owner>/<repo> --title "<title>" --body-file - <<'EOF'
  <body>
  EOF
  ~~~~

  Ohne `gh`: `https://github.com/<owner>/<repo>/issues/new` öffnen und Titel und Body aus
  dem Befehl einfügen.

**Prompt** (in der Sprache des Gesprächs, das Material darin englisch) — ohne Vorwissen
ausführbar, ein einziger Block. Er ist ein **Entwurfsauftrag**, keine Bauanleitung mit
fertigem Ergebnis:

- Einstieg: „Du arbeitest in einem Checkout des coding-kit-Repos (`<homepage>`) oder
  eines Forks. Entwirf für <Fund> eine Ergänzung des Templates (<Modul / Fragment /
  Änderung an Datei>)."
- **Das Kit kennenlernen:** `CLAUDE.md`, `CONTRIBUTING.md`,
  `plugins/coding-kit/template/MANIFEST.md`, dazu je Art:
  - Modul: `plugins/coding-kit/template/modules/README.md` und ein volles Modul als
    Vorbild (`plugins/coding-kit/template/modules/python/`). Ein Modul besteht aus
    `MODULE.md` mit `Signals:`-Zeile, `mise.part.toml`, justfile, `ci.part.yml` und
    `CODING-STANDARDS.part.md`, dazu das Sprachfragment im Katalog; der Status in
    `modules/README.md` wird full.
  - Fragment: `plugins/coding-kit/template/modules/standards/README.md`; ein Fragment
    ist `modules/standards/<name>.md` plus eine Katalog-Zeile mit Signalen.
  - Managed Datei: die Datei unter `plugins/coding-kit/template/` und ihre Zeile im
    MANIFEST.
- **Recherchieren:** den aktuellen Stand der Toolchain bzw. des Themas per Websuche
  klären (Werkzeuge, Versionen, gängige Praxis), bevor etwas entsteht.
- **Bisherige Erkenntnisse gewichten** — die beiden Teile *From the project* und
  *Suggested, not from the project* stehen im Prompt selbst, getrennt und je mit
  Codeblöcken: *From the project* ist im Einsatz belegt; *Suggested, not from the
  project* sind Hypothesen, die die Recherche bestätigt, ändert oder verwirft.
- **Erst entwerfen, dann bauen:** den Entwurf zeigen — was hineinkommt, was aus den
  Erkenntnissen übernommen und was verworfen wurde, je mit Grund — und erst nach
  Zustimmung des Nutzers die Dateien anlegen.
- Regeln: keine Personendaten, Versionsregel
  (`plugin.json`, CHANGELOG mit `### Template`, MANIFEST im selben Commit),
  `just check` grün, erst committen, wenn der Nutzer zustimmt. In einem Fork endet der
  Lauf mit einem PR, dessen Beschreibung die geänderten Dateien nennt.

## 5. Abschluss

Kurz sagen: abgeschickt ist nichts; nach einem Release mit der Ergänzung bringt
`/coding-kit:update-conventions` sie in die Projekte. Eine dauerhafte Ablehnung
(Rules-Zeile `tool:NAME`, `fragment:NAME` oder `module:NAME`) trägt der aufrufende Skill
ein, nicht dieser.
