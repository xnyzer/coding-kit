---
name: update-conventions
description: Konventionen vom mitgelieferten Template in Projekte verteilen — ausschließlich abwärts. Managed Dateien per Drei-Wege-Merge gegen den Basis-Snapshot des Projekts (Projektzusätze bleiben, nur echte Überschneidungen werden Konflikte), Diff und Bestätigung je Datei, je Standards-Fragment und je markierter seed-Zone (section:NAME); Abweichungs-Registry mit den Arten skip, keep, adapt; erkennt bei jedem Lauf per Signal, wofür das Template inzwischen Module oder Fragmente hat (dauerhafte Ablehnung als Rules-Zeile); Migration für Projekte ohne Snapshot; erkennt im Template entfernte/umbenannte Dateien. Ohne Argument nur das Projekt im aktuellen Ordner, alle Projekte nur mit `alle`; Modi `status` (nur Bericht) und `revise` (Registry prüfen). Projektlokale Fragmente werden nie angefasst, aber mit einem manuell anstoßbaren Übernahme-Vorschlag fürs Template gemeldet. Nichts wird ungefragt überschrieben.
disable-model-invocation: true
---

# Konventions-Sync (Template → Projekte)

**Grundsätze:** Vererbung fließt **ausschließlich abwärts** — Konventionen werden immer
zuerst in der Vorlage geändert und von dort verteilt; dieser Skill schreibt nie ins
Template. Nichts ungefragt überschreiben, nie automatisch committen. Seed-Dateien
(lebende Doku) werden **nie als Ganzes** ersetzt — nur markierte `section:NAME`-Zonen
(A2 Schritt 7). **Rendern, Mergen, Vergleichen und den Snapshot setzt das Skript**
deterministisch; du zeigst die Ergebnisse, berätst bei Konflikten und führst den Dialog —
managed Dateien nie selbst zusammenführen oder aus dem Template abschreiben.

**Argumente** (optional, kombinierbar):

- **ohne Projektangabe:** nur das Projekt im aktuellen Arbeitsverzeichnis (Kit-Projekt =
  `.claude/template-version` oder `PROGRESS.md` mit FEATURE-INDEX). Ist es keins: fragen
  (Pfad oder `alle`) — nie von selbst Projektordner durchsuchen.
- **Projektpfad oder -name:** genau dieses Projekt.
- **`alle`:** alle Projekte (A1).
- **`status`:** nur Bericht — nichts im Projekt schreiben (keine Antworten, kein
  Snapshot, keine Registry, kein Stempel).
- **`revise`:** nur die Registry-Revision (A2 Schritt 10).
- Ein Aufrufer kann eine **Sichtbarkeits-Prämisse** übergeben (z. B.
  `/coding-kit:go-public` vor dem Übergang: „behandle als public") — sie gilt für diesen
  Lauf als `VISIBILITY` (A2 Schritt 2).

## 0. Template, Vertrag, Skript

- Template wie `/choose-stack` § 0 unter `${CLAUDE_PLUGIN_ROOT}/template`. `MANIFEST.md`
  lesen; **`manifest-format` prüfen** (dieser Skill kann Format `2` — sonst abbrechen und
  auf ein Kit-Update verweisen). Version (`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`)
  und CHANGELOG (`${CLAUDE_PLUGIN_ROOT}/CHANGELOG.md`) merken.
- MANIFEST §§ Answers, Base snapshot, Deviation registry, Standards fragments (mit dem
  Fragment-Katalog `modules/standards/README.md`), Detection und Seed sections lesen.
- **Skript:** `${CLAUDE_PLUGIN_ROOT}/scripts/template-sync.sh`, in Shell-Befehlen mit dem
  aufgelösten Pfad über `sh` aufrufen; sein Kopf beschreibt Befehle, Ausgabezeilen und
  Klassen. Render- und Merge-Ergebnisse gehören in ein frisches Temp-Verzeichnis
  (`mktemp -d`, im Folgenden `<tmp>`), nie ins Projekt.
- Schreibzugriffe unter `.claude/` (Antworten, Snapshot, Registry, `.claude/README.md`)
  stuft Claude Code als sensibel ein und fragt sie einzeln ab — das ist erwartet, nie
  umgehen. Ohne Freigabe die Dateien in `<tmp>` vorbereiten und den Kopierbefehl nennen.

## Kontext-Recovery

Bei Wiederaufnahme: bereits behandelte Projekte und Dateien aus dem Verlauf übernehmen,
`git status` im Projekt prüfen; ist `<tmp>` weg, ab Schritt 3 neu rendern und mergen —
das Ergebnis ist dasselbe. Beim nächsten offenen Punkt weitermachen.

---

## Ablauf — Template → Projekte

### A1. Projekte bestimmen

- **Standard:** das Projekt im aktuellen Ordner (siehe Argumente).
- **`alle`:** GitHub-Discovery über das Marker-Topic
  (`gh search repos "user:$(gh api user --jq .login) topic:coding-kit" --json name`) plus
  lokale Ordner unter `$CODING_KIT_PROJECTS_DIR` mit `.claude/template-version` oder
  `PROGRESS.md` mit FEATURE-INDEX. Liste zeigen, Auswahl bestätigen lassen; nur lokale
  Checkouts bearbeiten (fehlt einer: klonen anbieten).
- Je Projekt: Liegen `.claude/template-answers` **und** `.claude/template-base/` vor →
  A2. Sonst zuerst A3 (Migration), dann A2.

### A2. Abgleich

1. **Stand zeigen:** Stempel (`.claude/template-version`) und das **Update-Fenster** aus
   dem CHANGELOG: von jedem Release über dem Stempel bis zur aktuellen Version nur den
   Abschnitt `### Template`; Stempel unter 1.0.0 nehmen zusätzlich die Einträge über dem
   Stempel aus dem eingefrorenen Abschnitt „project-template bis 0.16.0" — den Abschnitt
   „coding-kit-Plugin bis 0.20.0" nie lesen, seine Nummern gehören zu einer anderen Reihe.
   **Kein Abbruch bei aktuellem Stempel:** Antworten können sich geändert haben (z. B.
   eine Lizenz gewählt), deshalb laufen Rendern und Merge immer.
2. **Antworten prüfen:** `.claude/template-answers` lesen und mit dem Projekt
   abgleichen — Sichtbarkeit (`gh repo view --json visibility`; ohne Remote `private`;
   eine Prämisse des Aufrufers gilt vor beidem), Languages-Block der Projekt-CLAUDE.md
   (`LANG_*`), Lizenz (`LICENSE`), Modul (justfile-Kopf, `mise.toml`), Graphiti-Block der
   CLAUDE.md (`OPTIONAL` enthält `graphiti`), Fragmente im Slot (`FRAGMENTS` = die
   Fragmente im Slot ohne Sprachfragment und ohne die im `MODULE.md` deklarierten).
   Unterschiede zeigen und je Wert fragen, welcher gilt; die Antworten-Datei nur nach
   Bestätigung ändern. Die Prämisse eines Aufrufers rendert nur diesen Lauf, sie ändert
   die Datei nicht.

   **Erkennung** (jeder Lauf, nach den Antworten, vor dem Rendern): `sh <skript> detect
   <template> <projekt>` gleicht die Signale des Projekts mit den Modulen und dem
   Fragment-Katalog des aktuellen Templates ab (`MANIFEST.md` § Detection) — so kommt
   an, wofür das Template inzwischen Vorlagen hat, auch für längst Genutztes. `covered`
   nur zählen, `declined` nur auflisten (Schritt 10). Je `missing`:
   - **Fragment:** anhängen anbieten. Bei Zustimmung kommt es in `FRAGMENTS` der
     Antworten, sofern das `MODULE.md` es nicht selbst deklariert, damit der Render es
     enthält und Schritt 6 es anhängt — samt Begleithandlung (`/choose-stack`
     § Begleithandlungen). **Dauerhaft ablehnen** →
     Rules-Zeile `fragment:NAME` mit Grund; **diesmal nicht** → nichts speichern, der
     nächste Lauf bietet wieder an.
   - **Modul:** Module wechselt dieser Skill nicht — nach dem Lauf
     `/coding-kit:choose-stack` empfehlen. **Als Werkzeugsprache dauerhaft ablehnen** →
     Rules-Zeile `module:NAME` (was das Projekt stattdessen tut, mit Grund) und
     `keep`-Zeilen für die managed Dateien der handgebauten Toolchain; **diesmal nicht**
     → nichts speichern.
3. **Soll rendern:** `sh <skript> render <template> <projekt>/.claude/template-answers
   <tmp>/soll`.
4. **Mergen:** `sh <skript> merge <projekt> <tmp>/soll <tmp>/out` — die Tabelle zeigen
   (nur Zeilen, die nicht `identical` sind, dazu deren Anzahl).
5. **Je Datei entscheiden.** Das Ergebnis liegt in `<tmp>/out/<Ziel>`; übernehmen heißt
   dorthin kopieren. Hält der Nutzer die Projektfassung für besser als das Template: den
   **Übernahme-Vorschlag** (s. u.) ausgeben.
   - `template-only`, `merged`, `two-way` (keine Basis): Diff Projekt → Ergebnis zeigen;
     **übernehmen** / **diesmal nicht** (beim nächsten Lauf wieder angeboten) /
     **dauerhaft ablehnen** (Registry-Zeile mit Grund).
   - `conflict`: die Konfliktblöcke zeigen (diff3: Projekt, Basis, Template), eine
     Auflösung vorschlagen und begründen; Wahl: **Vorschlag** / **Projekt** /
     **Template** / **als `keep` registrieren** (Projekt gewinnt, auch künftig) /
     **diesmal nicht**. Die gewählte Fassung schreiben — Konfliktmarker gelangen nie ins
     Projekt.
   - `kept`: zeigen, wo das Projekt gewonnen hat (`keep`-Zeile); übernehmen.
   - `caught-up`: Das Template enthält die Abweichung jetzt selbst — übernehmen und eine
     vorhandene Registry-Zeile zum Austragen vormerken (Schritt 10).
   - `project-only`: nichts zu übernehmen; ohne Registry-Zeile als unregistrierte
     Abweichung melden (Schritt 10).
   - `new`: anlegen anbieten — oder als `skip` registrieren.
   - `missing`: das Projekt hat die Datei gelöscht — wiederherstellen anbieten oder als
     `skip` registrieren.
   - `removed`: Schritt 8. `skipped`: nur auflisten.

   Nach dem Übernehmen geänderte JSON-Dateien auf Gültigkeit prüfen (Schritt 11 prüft
   ohnehin `just check`).
6. **Fragment-Abgleich (CODING-STANDARDS-Slot, je Fragment):** die
   `fragment:NAME`-Blöcke im Slot einzeln gegen ihr Template-Pendant diffen — das
   Sprachfragment gegen `CODING-STANDARDS.part.md` des Moduls, Katalog-Fragmente gegen
   `modules/standards/<name>.md`. Je Fragment **übernehmen** / **diesmal nicht**; ein
   Inline-`<!-- override: … -->` im Block schützt genau dieses Fragment. **Ohne
   Template-Pendant → projektlokal: nie anfassen**; auflisten mit dem Hinweis, dass dieses
   Set im Template fehlt, und je Fragment einen **Übernahme-Vorschlag** ausgeben —
   anstoßen muss ihn der Nutzer. Deklariert das `MODULE.md` inzwischen Fragmente, die im
   Projekt fehlen, oder kam eines aus der Erkennung (Schritt 2) nach `FRAGMENTS` →
   Anhängen anbieten (Mechanik wie `/choose-stack`, idempotent);
   bestehende in-place ersetzen, Neues ans Slot-Ende — nie umsortieren.
   **Begleithandlungen (auch bei unverändertem Text):** je Fragment im Slot prüfen, ob die
   dort formulierte Einbau-Anforderung im Projekt erfüllt ist (`/choose-stack`
   § Begleithandlungen), und offene Fälle mit Diff zur Bestätigung anbieten. Dieser Pfad
   ist der einzige, der **Bestandsprojekte** erreicht: wer ein Fragment bekam, bevor es
   seine Anforderung enthielt, wird sonst von keinem Skill je eingeholt.
7. **seed-Abgleich (je `section:NAME`-Zone):** die Zonen aus dem Render nehmen —
   `sh <skript> render --seeds <template> <projekt>/.claude/template-answers <tmp>/seeds` —
   und einzeln gegen die gleichnamige Zone des Projekts diffen; je Zone **übernehmen** /
   **diesmal nicht**; ein Inline-`<!-- override: … -->` in der Zone schützt genau diese
   Zone. **Nie die ganze Datei ersetzen oder neu anlegen.** **Fehlendes Markerpaar =
   dauerhafter Opt-out:** nur informativ auflisten, Marker nie ungefragt wiederherstellen.
   Die Zone `claude-graphiti` liegt im `template:optional:graphiti`-Block — ohne Graphiti
   fehlt sie legitim. Fehlen einer Datei **alle** Markerpaare (Projekt vor dem
   Zonen-Vertrag): die Marker-Migration aus A3 Schritt 4 anbieten.
8. **Im Template entfernte/umbenannte Dateien:** aus MANIFEST § Removed and renamed
   targets die Zeilen mit einer Version über dem Stempel nehmen (Version, altes Ziel, neues
   Ziel bzw. `removed`, frühere Policy) — nichts erraten. Liegt das alte Ziel nicht (mehr)
   im Projekt, still überspringen; sonst **Umbenennung** → Umzug anbieten,
   **Entfernung** → Rückbau anbieten, je Datei bestätigt; `skip`-Zeilen gelten.
   **seed-Dateien** nie löschen oder verschieben — nur melden. Die Klasse `removed` aus
   Schritt 4 meint dasselbe aus Sicht des Snapshots.
9. **Snapshot setzen:** `sh <skript> snapshot <projekt> <tmp>/soll <Ziele…>` für jedes
   Ziel dieses Laufs **außer** „diesmal nicht", `skipped`, nicht angelegten `new`- und
   nicht wiederhergestellten `missing`-Zielen. Damit ist die neue Template-Fassung die
   Basis; „dauerhaft abgelehnt" zählt ab jetzt als Projektabweichung. `removed`-Ziele
   verlieren ihre Basis über denselben Aufruf.
10. **Registry-Revision** (jeder Lauf; Modus `revise` macht nur diesen Schritt):
    `sh <skript> status <projekt>` und die Files-Tabelle der
    `.claude/convention-overrides.md` nebeneinanderlegen —
    - Zeile, deren Ziele alle `unchanged` sind (Abweichung verschwunden) oder die in
      Schritt 5 `caught-up` waren → **austragen** anbieten;
    - `deviates` ohne Zeile → Zeile mit Grund anbieten (Art leer, `keep` oder `adapt`);
    - `skip`-Zeilen und die Rules-Tabelle nur auflisten („noch gültig?"); eine Ablehnung
      `module:NAME` oder `fragment:NAME`, für die die Erkennung (Schritt 2) keine Zeile
      mehr meldet — das Projekt hat die Signale nicht mehr —, zum Austragen anbieten.

    Jede Änderung einzeln bestätigen. Sinngleiche Zeilen eines Alt-Formats übernimmt A3
    Schritt 3.
11. **Abschluss:** **Lock-Abgleich** — die Prüfung aus `/choose-stack` § Lock-Datei
    erzeugen und prüfen; hat sich die `mise.toml` geändert, die Prüfung Lücken gezeigt
    oder fehlt die Lock-Datei: `mise install && mise lock` anbieten, danach erneut
    prüfen. Stempel auf die aktuelle Version setzen, `just check` muss grün sein
    (Write-then-Verify), Commit-Vorschlag (z. B.
    `chore: sync template conventions <alt> -> <neu>`) — **nur nach OK**, dann Push-Frage.
    Fehlt der Languages-Block in der Projekt-CLAUDE.md: die Migration aus A3 Schritt 4
    anbieten — CLAUDE.md ist `seed` und wird nie automatisch angefasst.

**Modus `status`:** Schritte 1–4 (ohne Snapshot über die Vorschau aus A3 Schritt 2) und
die Tabelle aus `sh <skript> status <projekt>` (ohne Snapshot: `status --base
<tmp>/base`); die Erkennung aus Schritt 2 als Bericht (fehlende Module und Fragmente,
Ablehnungen) und was Schritt 10 vorschlagen würde, als Hinweis. Ohne
`.claude/template-answers` prüft das Skript keine Module — das im Bericht sagen.
Antworten für die Vorschau nur in `<tmp>` anlegen. Nichts im Projekt schreiben.

### A3. Migration — Projekte ohne Snapshot oder Antworten

Jede Migration ist ein eigener bestätigter Schritt; danach die Erkennung aus A2 Schritt 2,
dann A2 ab Schritt 3.

1. **Antworten-Datei anlegen:** die Werte aus dem Projekt zurückgewinnen — Name (Repo
   bzw. Ordner), `OWNER` (`gh api user`), Beschreibung (Repo-Beschreibung, sonst README),
   `GROUP_ID` und die fünf `LANG_*` (Languages-Block der Projekt-CLAUDE.md; Alt-Projekte
   mit einzeiliger Doku-Sprach-Angabe: deren Wert für die lebende Doku, übrige Dimensionen
   englisch), `LICENSE_SPDX` (`LICENSE`, ohne Datei `TBD`), `MODULE` (justfile-Kopf,
   `mise.toml`, Modul-Dateien; im Zweifel fragen), `VISIBILITY` wie A2 Schritt 2,
   `OPTIONAL` (Graphiti-Block vorhanden → `graphiti`) und `FRAGMENTS` wie A2 Schritt 2.
   Zeigen, bestätigen lassen, als `.claude/template-answers` schreiben (MANIFEST
   § Answers).
2. **Basis wählen** — sie entscheidet, was der erste Merge als Projektabweichung sieht:
   - **(a) Template-Historie** (Standard): die Template-Fassung einer Version aus der
     Historie eines coding-kit-Checkouts. **Version:** standardmäßig der Stempel; auf
     Wunsch eine ältere — z. B. die beim Anlegen gestempelte (`git log --diff-filter=A
     -- .claude/template-version`) —, damit früher abgelehnte Template-Änderungen erneut
     angeboten werden. **Checkout:** liegt `${CLAUDE_PLUGIN_ROOT}` in einem
     Git-Checkout (Test mit `--plugin-dir`), diesen nehmen; sonst nach einem Pfad fragen
     oder einen Klon des Repos aus `homepage` in `plugin.json` nach `<tmp>` anbieten
     (Netzzugriff — nur nach OK). Dann `sh <skript> base-from-history <checkout> <version>
     <tmp>/kit` und `sh <skript> render <tmp>/kit/template <antworten> <tmp>/base`.
     Fragmente aus `FRAGMENTS`, die es in dieser Version noch nicht gab, für den
     Basis-Render weglassen — der Slot zählt beim Vergleich ohnehin nicht.
     **Mischbasis** (empfohlen bei älterer Version): Dateien, die ein früherer Sync schon
     übernommen hat, tragen den Zwischenstand und würden mit der älteren Basis
     unnötig kollidieren. Deshalb beide Versionen rendern und in `<tmp>/base` für die
     Dateien, die der Commit mit dem letzten Stempel-Wechsel geändert hat (`git show
     --stat` auf `git log -1 -- .claude/template-version`), die Fassung der
     Stempel-Version nehmen, für alle übrigen die ältere.
   - **(b) Zweiwegig:** ohne Historie (oder ohne Stempel) — der erste Merge vergleicht
     Projekt und Soll direkt (`two-way`).

   Danach A2 Schritte 3–5, bei (a) mit `merge --base <tmp>/base`. In Schritt 9 erhalten
   „diesmal nicht"-Ziele bei (a) die gewählte Basis (`snapshot <projekt> <tmp>/base
   <Ziele…>`), damit der nächste Lauf sie wieder anbietet; bei (b) bekommen sie keine.
3. **Registry überführen:** Zeilen einer Alt-Tabelle („File / rule | Deviation | …")
   einzeln in die Tabellen `## Files` (eine Datei bzw. ein Glob; „nie anlegen/anbieten" →
   `skip`, „Projekt behält seine Fassung" → `keep`, konkretisierte `template:adapt`-Stellen
   → `adapt`, sonst Art leer) oder `## Rules` überführen, jeweils bestätigt; den Kopf
   bringt der Zonen-Abgleich (A2 Schritt 7). Inline-`<!-- override: … -->` in managed
   Dateien (außerhalb von Zonen und Fragmenten) → `keep`-Zeile anbieten; der Marker darf
   bleiben, er wirkt dort nicht mehr.
4. **Altprojekte** (ohne Stempel oder vor dem jeweiligen Vertrag), je Punkt bestätigt:
   - `.claude/instructions.md` (bzw. Legacy-Orte) → in die Root-CLAUDE.md überführen
     (Graphiti-Block mit group_id!), Alt-Datei entfernen.
   - Lokale Kopien von add-feature/prep-step/step-done/audit-code unter
     `.claude/skills/` löschen — **nur wenn** das coding-kit-Plugin installiert ist
     (`claude plugin list`); projektspezifische Skills immer behalten.
   - Renovate: `renovate.json` mit `"extends": ["github>OWNER/coding-kit"]` (OWNER zur
     Laufzeit); die Freigabe der Renovate-App ist eine manuelle Nutzeraktion.
   - Tooling (`mise.toml`, justfile, `lefthook.yml`) kommt über den Merge; danach
     `mise install && mise lock && just setup && just check` und die Prüfung aus
     `/choose-stack` § Lock-Datei.
   - **Languages-Block:** trägt die CLAUDE.md noch die einzeilige Alt-Sprachkonvention,
     die Migration zum Languages-Block anbieten — bisherige Doku-Sprache behalten, übrige
     Dimensionen englisch (bzw. Preset nach Wunsch); **prospektiv**: Bestandsinhalte
     werden nicht übersetzt, Struktur-Überschriften auf Wunsch.
   - **section-Marker:** fehlen seed-Dateien die `section:NAME`-Markerpaare, je Datei
     anbieten, sie aus dem MANIFEST-Inventar um die wiedererkennbaren Zonen zu setzen —
     reine Wrapper, Inhalt unverändert; nicht Wiederauffindbares auslassen (Opt-out).

---

## Übernahme-Vorschlag (Projekt → Template — nur manuell angestoßen)

Dieser Skill schreibt nie ins Template. Findet ein Lauf projektlokale Fragmente ohne
Template-Pendant (oder gehört eine lokale Verbesserung in die Vorlage), wird
stattdessen **fertiges Material** ausgegeben — ausführen bzw. absenden tut es der
Nutzer:

- **Kopierfertiger Beispiel-Prompt** für eine Session im coding-kit-Repo: das Fragment
  generalisieren (Projektwerte zu Platzhaltern, Englisch, personendatenfrei), als
  `plugins/coding-kit/template/modules/standards/<name>.md` anlegen, Katalog-Zeile mit
  Trigger im dortigen README ergänzen, die Versionsregel des Kits beachten
  (Versions-Bump in `plugin.json` und CHANGELOG-Eintrag mit Abschnitt `### Template`
  im selben Commit) — den generalisierten Fragment-Inhalt in den Prompt beilegen.
- **Alternativ ein Issue** im coding-kit-Repo mit demselben Inhalt. Das Repo steht als
  `homepage` in `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` (nicht aus dem
  eigenen Konto ableiten), z. B. `gh issue create -R <owner>/<repo> --title
  "standards: add <name> fragment" --body <Vorschlag>`.

Nach einem Release mit dem neuen Fragment bringt ein regulärer Abwärts-Lauf es in alle
Projekte.
