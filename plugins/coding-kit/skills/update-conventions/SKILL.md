---
name: update-conventions
description: Konventionen vom mitgelieferten Template in Projekte verteilen — ausschließlich abwärts. Managed Dateien per Drei-Wege-Merge gegen den Basis-Snapshot des Projekts (Projektzusätze bleiben, nur echte Überschneidungen werden Konflikte), Diff und Bestätigung je Datei, je Standards-Fragment und je markierter seed-Zone (section:NAME); Abweichungs-Registry mit den Arten skip, keep, adapt; erkennt bei jedem Lauf per Signal, wofür das Template inzwischen Module oder Fragmente hat und welche Tools es nicht kennt (dauerhafte Ablehnung als Rules-Zeile); Migration für Projekte ohne Snapshot; erkennt im Template entfernte/umbenannte Dateien. Ohne Argument nur das Projekt im aktuellen Ordner, alle Projekte nur mit `alle`; Modi `status` (nur Bericht) und `revise` (Registry prüfen). Projektlokale Fragmente werden nie angefasst; sie und Tools ohne Vorlage meldet er mit dem Angebot, sie dem Template vorzuschlagen (Hintergrund-Skill propose-to-template). Mit `global` — und einmal in jedem anderen Lauf, sobald sie eingerichtet sind — gleicht er auch die globalen Kit-Regeln auf dem Rechner ab (`~/.claude/rules/coding-kit.md`, aus der Kit-Datei und den Werten der Personal-Config gerendert) — Ersteinrichtung, Diff und Bestätigung je Abschnitt, Migration einer alten Kit-Kopie in `~/.claude/CLAUDE.md`; eine selbst angelegte CLAUDE.md fasst er nie an. Nichts wird ungefragt überschrieben.
argument-hint: "[Projekt | alle | global [Ordner]] [status | revise]"
disable-model-invocation: true
user-invocable: true
---

# Konventions-Sync (Template → Projekte)

**Grundsätze:** Vererbung fließt **ausschließlich abwärts** — Konventionen werden immer
zuerst in der Vorlage geändert und von dort verteilt, in die Projekte wie auf den Rechner
(Teil G); dieser Skill schreibt nie ins Template und nie in die Kit-Datei. Nichts ungefragt überschreiben, nie automatisch committen. Seed-Dateien
(lebende Doku) werden **nie als Ganzes** ersetzt — nur markierte `section:NAME`-Zonen
(A2 Schritt 7). **Rendern, Mergen, Vergleichen — auch von Zonen, Fragmenten und
Lock-Datei — und den Snapshot setzt das Skript** deterministisch; du zeigst die
Ergebnisse, berätst bei Konflikten und führst den Dialog — managed Dateien, Zonen und
Fragmente nie selbst zusammenführen, einsetzen oder aus dem Template abschreiben.

**Argumente** (optional, kombinierbar):

- **ohne Projektangabe:** nur das Projekt im aktuellen Arbeitsverzeichnis (Kit-Projekt =
  `.claude/template-version` oder `PROGRESS.md` mit FEATURE-INDEX). Ist es keins: fragen
  (Pfad, `alle` oder `global`) — nie von selbst Projektordner durchsuchen.
- **Projektpfad oder -name:** genau dieses Projekt.
- **`alle`:** alle Projekte (A1).
- **`global`:** nur die globalen Kit-Regeln auf diesem Rechner (Teil G), auch außerhalb
  eines Projekts; richtet sie beim ersten Mal ein. Folgt ein Ordner (`global <ordner>`),
  gilt er als Claude-Config-Ordner — für Tests, das echte `~/.claude` bleibt unberührt.
- **`status`:** nur Bericht — nichts im Projekt schreiben (keine Antworten, kein
  Snapshot, keine Registry, kein Stempel) und nichts im Config-Ordner.
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
  Klassen.
- **Globale Regeln (Teil G):** Kit-Datei `${CLAUDE_PLUGIN_ROOT}/global/coding-kit.md`;
  der Stand des letzten Abgleichs liegt als Basis unter
  `${CLAUDE_PLUGIN_DATA}/global-base` (Claude Code setzt den Pfad im Skill-Text ein; in
  Shell-Befehlen den aufgelösten Pfad verwenden). Render- und Merge-Ergebnisse gehören in ein frisches Temp-Verzeichnis
  (`mktemp -d`, im Folgenden `<tmp>`), nie ins Projekt.
- Schreibzugriffe unter `.claude/` (Antworten, Snapshot, Registry, Stempel,
  `.claude/README.md`) stuft Claude Code als sensibel ein und fragt sie einzeln ab — das
  ist erwartet, nie umgehen. Ohne Freigabe die Dateien in `<tmp>` vorbereiten und den
  Kopierbefehl nennen.
  Die folgenden Schritte rechnen dann mit dem vorbereiteten Stand: Die Skript-Befehle
  nehmen ihn per Option — `--answers <tmp>/…` (`detect`; `render` bekommt den Pfad
  ohnehin), `--registry <tmp>/…` und `--snapshot <tmp>/…` (Kopf des Skripts). Für den
  Snapshot den vorhandenen Ordner erst nach `<tmp>` kopieren, dann `snapshot --snapshot`
  dorthin schreiben lassen. Nie das Skript oder eine Kopie davon anpassen und keine
  Spiegelkopie des Projekts bauen.

## Kontext-Recovery

Bei Wiederaufnahme: bereits behandelte Projekte und Dateien aus dem Verlauf übernehmen,
`git status` im Projekt prüfen; ist `<tmp>` weg, ab Schritt 3 neu rendern und mergen —
das Ergebnis ist dasselbe (Teil G: ab G1). Beim nächsten offenen Punkt weitermachen.

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
- **Nach dem letzten Projekt:** Teil G, sofern die globalen Kit-Regeln eingerichtet sind
  oder eine alte Kit-Kopie da ist (G1); sonst kein Wort dazu. `revise` lässt G aus.

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
   Fragmente im Slot ohne das Modul-Fragment und ohne die im `MODULE.md` deklarierten).
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

   Je `tool`-Zeile `unknown` (das Template hat für das Tool weder Modul noch Fragment):
   melden und anbieten — **dem Template vorschlagen** → den Hintergrund-Skill
   `propose-to-template` mit dem Fund starten (Art Tool, Name, mise-Datei);
   **dauerhaft ablehnen** (das Tool braucht keine Konvention) → Rules-Zeile `tool:NAME`
   mit Grund; **diesmal nicht** → nichts speichern. Ins Projekt kommt dadurch nichts.
3. **Soll rendern:** `sh <skript> render <template> <projekt>/.claude/template-answers
   <tmp>/soll`.
4. **Mergen:** `sh <skript> merge <projekt> <tmp>/soll <tmp>/out` — die Tabelle zeigen
   (nur Zeilen, die nicht `identical` sind, dazu deren Anzahl).
5. **Je Datei entscheiden.** Das Ergebnis liegt in `<tmp>/out/<Ziel>`; übernehmen heißt
   dorthin kopieren. Hält der Nutzer die Projektfassung für besser als das Template:
   `propose-to-template` mit dem Fund starten (managed Datei, Ziel, Diff).
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
6. **Blöcke abgleichen — Fragmente im Slot.** Erst nach dem Kopieren aus Schritt 5, sonst
   überschreibt das Ergebnis den Merge der `CODING-STANDARDS.md`:
   `sh <skript> render --seeds <template> <projekt>/.claude/template-answers <tmp>/seeds`,
   dann `sh <skript> zones <projekt> <tmp>/seeds <tmp>/zones` (bei der Migration mit
   `--base <tmp>/base`, Stellvertreter wie § 0). Das Skript vergleicht die
   `fragment:NAME`-Blöcke im Slot (dieser Schritt) und die seed-Zonen (Schritt 7) mit dem
   Render und der Basis des letzten Syncs (`.claude/template-base/`, für seed-Dateien
   `<Ziel>.seed`) und wertet Marker, Override-Zeilen und die Stelle neuer Blöcke selbst
   aus. Diffs zeigen aus `<tmp>/zones/.zones/<Art>/<Name>.project` → `.template`; nie
   selbst Blöcke herausschneiden, einsetzen, entfernen oder abschreiben.
   **Übernehmen:** Das Ergebnis `<tmp>/zones/<Ziel>` enthält alle Blöcke mit `differs`,
   `new` und `removed`. Sind genau diese angenommen, es ins Projekt kopieren; sonst
   `zones` mit den Namen der angenommenen Blöcke in ein frisches `<tmp>/zones-ok` laufen
   lassen und dieses Ergebnis kopieren — immer so, wenn eine `opted-out`- oder
   `unconfirmed`-Zone hinein soll, denn die setzt das Skript nur per Name ein. Je
   Fragment-Zeile:
   - `differs` → Diff zeigen; **übernehmen** / **diesmal nicht**.
   - `new` → das `MODULE.md` deklariert es inzwischen, oder es kam aus der Erkennung
     (Schritt 2) nach `FRAGMENTS`: Anhängen anbieten. Das Skript setzt es hinter seinen
     nächsten Vorgänger aus dem Render bzw. anstelle des Platzhaltertexts — nie
     umsortieren.
   - `override` → eine Override-Zeile schützt das Fragment: nicht anbieten. Steht statt
     `-` eine Zählung, hat das Template den Block seit dem letzten Sync geändert: den Diff
     `.base` → `.template` **zur Info** zeigen; übernommen wird von Hand.
   - `local` → kein Template-Pendant, **nie anfassen**. Steht der Name im Katalog
     (`modules/standards/<name>.md`), fehlt er nur in `FRAGMENTS` (Schritt 2); sonst
     auflisten mit dem Hinweis, dass dieses Set im Template fehlt, und anbieten, es dem
     Template vorzuschlagen (`propose-to-template` mit dem Fund starten, Block aus
     `.project`).
   - `unmarked` (kein Slot) oder `broken` (Marker kaputt) → melden und die Reparatur von
     Hand anbieten; `identical` und `skipped` nur zählen.

   **Begleithandlungen (auch bei unverändertem Text):** je Fragment im Slot prüfen, ob die
   dort formulierte Einbau-Anforderung im Projekt erfüllt ist (`/choose-stack`
   § Begleithandlungen), und offene Fälle mit Diff zur Bestätigung anbieten. Dieser Pfad
   ist der einzige, der **Bestandsprojekte** erreicht: wer ein Fragment bekam, bevor es
   seine Anforderung enthielt, wird sonst von keinem Skill je eingeholt.
7. **seed-Zonen** (Zeilen `section` aus dem `zones`-Lauf von Schritt 6, übernommen wie
   dort). **Nie die ganze Datei ersetzen oder neu anlegen** — das Ergebnis des Skripts
   ändert nur die Zonen. Je Zeile:
   - `differs` → Diff zeigen; **übernehmen** / **diesmal nicht**.
   - `new` → Datei und Basis kennen die Zone nicht: Das Template hat sie neu, oder ein
     eingeschalteter Optional-Block bringt sie (z. B. `claude-graphiti` nach Schritt 2).
     Den Inhalt (`.template`) zeigen, mit dem Grund aus dem Update-Fenster; das Skript
     setzt sie hinter ihren nächsten Vorgänger aus dem Render. **einsetzen** / **nicht
     einsetzen (Opt-out)** — ein „diesmal nicht" gibt es nicht: Schritt 9 setzt den
     Render als Basis, eine nicht eingesetzte Zone gilt danach als abgewählt.
   - `opted-out` → die Basis kennt die Zone, ihr Markerpaar fehlt = **dauerhafter
     Opt-out**: nur auflisten, mit dem Angebot, sie zurückzuholen (Lauf mit dem Namen,
     Schritt 6); nie ungefragt.
   - `unconfirmed` → die Datei hat noch keine Seed-Basis (Projekt aus der Zeit davor,
     Migration): Ob die Zone neu ist oder abgewählt wurde, lässt sich nicht sagen. Einmal
     fragen: **einsetzen** (Lauf mit dem Namen) / **abgewählt lassen**. Ab Schritt 9 hat
     die Datei eine Basis; die Frage kommt nicht wieder.
   - `removed` → das Template hat die Zone gestrichen (Datei und Basis haben sie): den
     Inhalt (`.project`) mit dem Grund aus dem Update-Fenster zeigen; **entfernen** (das
     Skript nimmt die Zone samt Inhalt heraus) / **behalten** (bleibt als Projekttext,
     ab dem nächsten Lauf `local`). Kommt im selben Lauf eine `new`-Zone und nennt das
     Update-Fenster eine Umbenennung, beide zusammen als Umzug anbieten.
   - `override` → eine Override-Zeile schützt die Zone; nur auflisten. Steht statt `-`
     eine Zählung, hat das Template die Zone seit dem letzten Sync geändert: den Diff
     `.base` → `.template` **zur Info** zeigen; übernommen wird von Hand.
   - `unmarked` → der Datei fehlen alle Markerpaare (Projekt vor dem Zonen-Vertrag): die
     Marker-Migration aus A3 Schritt 4 anbieten.
   - `local` → weder Render noch Basis kennen die Zone (eine eigene Zone des Projekts),
     oder eine gestrichene Zone trägt eine Override-Zeile: melden, nicht anfassen. Ohne
     Seed-Basis landet hier auch `claude-graphiti`, wenn `OPTIONAL` kein `graphiti`
     enthält (mit Basis kommt sie als `removed`) — mit Schritt 2 abgleichen.
   - `no-file` → die seed-Datei fehlt (z. B. eine aufgelöste `REQUIREMENTS.md`): nur
     melden. `broken` → melden; `identical` und `skipped` nur zählen.

   Eine Zone, die weder Projekt noch Render haben (`claude-graphiti` ohne Graphiti),
   meldet das Skript nicht.
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
   verlieren ihre Basis über denselben Aufruf. **Seed-Basen:** `sh <skript> snapshot
   --seeds <projekt> <tmp>/seeds <Ziele…>` für jede seed-Datei mit `section`-Zeilen aus
   Schritt 7 außer `no-file` und `skipped` — immer, auch wenn Zonen abgelehnt wurden: Die
   Basis hält fest, was angeboten wurde; `differs` bietet der nächste Lauf ohnehin
   wieder an.
10. **Registry-Revision** (jeder Lauf; Modus `revise` macht nur diesen Schritt):
    `sh <skript> status <projekt>` und die Files-Tabelle der
    `.claude/convention-overrides.md` nebeneinanderlegen —
    - Zeile, deren Ziele alle `unchanged` sind (Abweichung verschwunden) oder die in
      Schritt 5 `caught-up` waren → **austragen** anbieten;
    - `deviates` ohne Zeile → Zeile mit Grund anbieten (Art leer, `keep` oder `adapt`);
    - `skip`-Zeilen und die Rules-Tabelle nur auflisten („noch gültig?"); eine Ablehnung
      `module:NAME`, `fragment:NAME` oder `tool:NAME`, für die die Erkennung (Schritt 2)
      keine Zeile mehr meldet — das Projekt hat die Signale nicht mehr, oder das Template
      kennt das Tool inzwischen —, zum Austragen anbieten.

    Jede Änderung einzeln bestätigen. Sinngleiche Zeilen eines Alt-Formats übernimmt A3
    Schritt 3.
11. **Abschluss:** **Lock-Abgleich** — `sh <skript> lock-check <projekt>`, ausgewertet
    wie `/choose-stack` § Lock-Datei; meldet es `lockfile missing`, `unlocked` oder
    `stale` (die `mise.toml` hat sich geändert) oder eine Lücke:
    `mise install && mise lock` anbieten, danach erneut prüfen. Stempel auf die aktuelle
    Version setzen, `just check` muss grün sein (Write-then-Verify), Commit-Vorschlag (z. B.
    `chore: sync template conventions <alt> -> <neu>`) — **nur nach OK**, dann Push-Frage.
    Fehlt der Languages-Block in der Projekt-CLAUDE.md: die Migration aus A3 Schritt 4
    anbieten — CLAUDE.md ist `seed` und wird nie automatisch angefasst.

**Modus `status`:** Schritte 1–4 (ohne Snapshot über die Vorschau aus A3 Schritt 2) und
die Tabelle aus `sh <skript> status <projekt>` (ohne Snapshot: `status --base
<tmp>/base`); die Erkennung aus Schritt 2 als Bericht (fehlende Module und Fragmente,
Tools ohne Vorlage, Ablehnungen), die Zeilen aus `zones` (Schritt 6, nichts kopieren)
und `lock-check` (Schritt 11) und was Schritt 10 vorschlagen würde, als Hinweis. Ohne
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
   Seed-Basen gibt es bei der Migration nicht (der Basis-Render enthält nur managed
   Ziele): Fehlende Zonen meldet `zones` als `unconfirmed` (A2 Schritt 7), die
   Seed-Basen setzt A2 Schritt 9 wie in jedem Lauf.
3. **Registry überführen:** Zeilen einer Alt-Tabelle („File / rule | Deviation | …")
   einzeln in die Tabellen `## Files` (eine Datei bzw. ein Glob; „nie anlegen/anbieten" →
   `skip`, „Projekt behält seine Fassung" → `keep`, konkretisierte `template:adapt`-Stellen
   → `adapt`, sonst Art leer) oder `## Rules` überführen, jeweils bestätigt; den Kopf
   bringt der Zonen-Abgleich (A2 Schritt 7). Override-Kommentare in managed Dateien
   (außerhalb von Zonen und Fragmenten) → `keep`-Zeile anbieten; der Kommentar darf
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
     `mise install && mise lock && just setup && just check` und
     `sh <skript> lock-check <projekt>` (Auswertung wie `/choose-stack` § Lock-Datei).
   - **Languages-Block:** trägt die CLAUDE.md noch die einzeilige Alt-Sprachkonvention,
     die Migration zum Languages-Block anbieten — bisherige Doku-Sprache behalten, übrige
     Dimensionen englisch (bzw. Preset nach Wunsch); **prospektiv**: Bestandsinhalte
     werden nicht übersetzt, Struktur-Überschriften auf Wunsch.
   - **section-Marker:** fehlen seed-Dateien die `section:NAME`-Markerpaare (in A2 meldet
     `zones` sie als `unmarked`, den Template-Inhalt jeder Zone liefert
     `<tmp>/zones/.zones/section/<Name>.template`), je Datei anbieten, sie aus dem
     MANIFEST-Inventar um die wiedererkennbaren Zonen zu setzen — jeder Marker allein auf
     seiner Zeile, reine Wrapper, Inhalt unverändert; nicht Wiederauffindbares auslassen
     (Opt-out).

---

## Teil G — Globale Kit-Regeln (Kit → Rechner)

Die globalen Kit-Regeln liegen als `rules/coding-kit.md` im Claude-Config-Ordner; Claude
Code lädt sie in jeder Session wie die CLAUDE.md. Sie entstehen aus der Kit-Datei und den
Werten der Personal-Config (Antwortsprache, Erklär-Niveau, Notiz). Die `CLAUDE.md` im
selben Ordner gehört allein dem Nutzer.

**Wann:** mit `global` immer; in jedem anderen Lauf außer `revise` einmal nach dem letzten
Projekt, aber nur, wenn `rules/coding-kit.md` existiert oder G1 eine alte Kit-Kopie
findet. Im Modus `status` nur berichten (G1, die Zeilen aus G3, Hinweise aus G5) und
nichts schreiben — weder Werte noch Regeln noch Basis.

### G1. Stand

- **Config-Ordner** `<config>`: der Ordner hinter `global`, sonst `$CLAUDE_CONFIG_DIR`,
  sonst `~/.claude` (in der Shell: `printf '%s\n' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"`).
  Darin `rules/coding-kit.md` (Kit-Regeln), `CLAUDE.md` (persönlich) und
  `coding-kit.env` (Personal-Config). Mit `global <ordner>` liegt auch die Basis im
  Stellvertreter-Ordner (`<ordner>/.global-base` statt `${CLAUDE_PLUGIN_DATA}/global-base`).
- **Kit-Regeln:** Gibt es `<config>/rules/coding-kit.md` und steht in der ersten Zeile
  `<!-- coding-kit:global-rules -->`? Ohne diese Kennung ist die Datei **fremd**: nie
  anfassen, melden und Teil G beenden.
- **Alte Kit-Kopie:** Enthält `<config>/CLAUDE.md` die Kopfzeile der früheren Vorlage
  („Gepflegt als Vorlage im coding-kit …"), ist sie eine Kopie aus der Zeit, als das Kit
  die CLAUDE.md selbst setzte → G4. Ohne diese Zeile ist die CLAUDE.md **selbst
  angelegt** → nur G5.
- **Werte:** `sh <skript> render-global <kit> <config>/coding-kit.env <tmp>/global` — die
  `key`-Zeilen zeigen, was gesetzt (`set`), bewusst leer (`empty`) oder noch nie
  festgelegt ist (`missing`). Die env-Datei nicht ausgeben, die `key`-Zeilen von
  `render-global` genügen — sie enthält auch Identitätswerte.

### G2. Werte ergänzen

Fehlt einer der Werte (`missing`), den Skill `explain-level` mit `<config>/coding-kit.env`
als Personal-Config starten; er fragt nur, was offen ist, und gibt den Pfad der Datei mit
den Werten zurück — die echte oder, solange das Kopieren nicht freigegeben ist, eine in
`<tmp>`. Danach `<tmp>/global` löschen und mit genau dieser Datei neu rendern. `empty`
ist eine bewusste Wahl: nicht nachfragen. Werte nie selbst in die env-Datei schreiben.

### G3. Abgleich

- **Erstmals einrichten** (keine `rules/coding-kit.md`, keine alte Kopie): die gerenderte
  Datei `<tmp>/global/rules/coding-kit.md` zeigen, auf Widersprüche zur CLAUDE.md hinweisen
  (G5) und nach Freigabe nach `<config>/rules/coding-kit.md` kopieren (den Ordner `rules/`
  bei Bedarf anlegen).
- **Vorhanden:** `sh <skript> zones --snapshot <basis> <config> <tmp>/global <tmp>/gzones`
  (`<basis>` wie G1). Je Zeile (Ziel `rules/coding-kit.md`, Art `section`):
  - `differs` → Diff `<tmp>/gzones/.zones/section/<Name>.project` → `.template` zeigen,
    mit dem Grund, wenn er erkennbar ist (neue Kit-Fassung laut CHANGELOG oder geänderter
    Wert); **übernehmen** / **diesmal nicht**.
  - `new` → eine Kit-Zone, die die Basis nicht kennt (neue Kit-Fassung): Inhalt
    `<tmp>/gzones/.zones/section/<Name>.template` mit dem Grund aus dem CHANGELOG zeigen;
    **einsetzen** / **nicht einsetzen (Opt-out)** — G6 setzt danach den Render als Basis,
    eine nicht eingesetzte Zone gilt dann als abgewählt.
  - `override` → der Nutzer hat die Zone geschützt: nur auflisten; steht statt `-` eine
    Zählung, hat sich die Kit-Zone seit dem letzten Abgleich geändert — den Diff `.base`
    → `.template` zur Info zeigen.
  - `opted-out` → die Basis kennt die Zone, ihr Markerpaar fehlt = dauerhafter Opt-out:
    nur auflisten, mit dem Angebot, sie zurückzuholen (Lauf mit dem Namen).
  - `unconfirmed` → es gibt keine Basis (G6 lief nie, oder der Datenordner des Plugins
    ist neu): einmal fragen — **einsetzen** (Lauf mit dem Namen) / **abgewählt lassen**.
  - `removed` → das Kit hat die Zone gestrichen: Inhalt `.project` mit dem Grund aus dem
    CHANGELOG zeigen; **entfernen** (das Skript nimmt die Zone samt Inhalt heraus) /
    **behalten** (bleibt als eigener Text, ab dem nächsten Abgleich `local`).
  - `local` → eine Zone, die weder Kit-Datei noch Basis kennen, oder eine gestrichene
    mit Override-Zeile: melden, nicht anfassen.
  - `unmarked` → die Datei hat keine Zonen mehr: mit Kennung hat der Nutzer alle
    abgewählt (nur melden), ohne Kennung ist sie fremd (G1).
  - `broken` → melden und die Reparatur von Hand anbieten; `identical` nur zählen.
    `no-file` und `skipped` kommen hier nicht vor: Der Abgleich läuft nur, wenn die
    Regeldatei existiert, und der Config-Ordner hat keine Registry.

  **Übernehmen** wie in A2 Schritt 6: Sind genau die Zonen mit `differs`, `new` und
  `removed` angenommen, `<tmp>/gzones/rules/coding-kit.md` nach
  `<config>/rules/coding-kit.md` kopieren; sonst `zones` mit den Namen der angenommenen
  Zonen in ein frisches `<tmp>/gzones-ok` laufen lassen (`opted-out` und `unconfirmed`
  nur so) und dieses Ergebnis kopieren. Nie selbst Zonen einsetzen, entfernen oder
  abschreiben.
- Ist eine Zone `differs`, weil der Nutzer sie auf dem Rechner geändert hat, und nützt
  die Änderung allen: anbieten, sie dem Kit vorzuschlagen (`propose-to-template`, Art
  globale Regel).

### G4. Migration einer alten Kit-Kopie

Die alte `CLAUDE.md` enthält die Kit-Regeln von damals; daneben die neuen einzurichten
hieße, sie doppelt und teils widersprüchlich zu laden. Deshalb beides in einem Schritt:

1. **Regeln vorbereiten** wie G3 „Erstmals einrichten", noch nicht schreiben.
2. **CLAUDE.md bereinigen:** einen Entwurf `<tmp>/CLAUDE.md` ohne Titel und Kopfzeile der
   alten Vorlage und ohne die Abschnitte, die die Kit-Datei abdeckt (Sprache & Stil,
   Git & Commits, Graphiti Memory, Arbeitsweise). Zeilen in diesen Abschnitten, die nicht
   wörtlich in der gerenderten Kit-Datei stehen, einzeln vorlegen: **persönlich
   behalten** (bleibt in der CLAUDE.md) / **dem Kit vorschlagen** (`propose-to-template`,
   Art globale Regel) / **streichen** (eine frühere Kit-Fassung, z. B. die alte
   Sprachregel). Alles außerhalb dieser Abschnitte bleibt unverändert.
3. **Vorschau:** die neue Regeldatei und den Diff alte → neue CLAUDE.md. Nach Freigabe
   erst die Regeldatei, dann die CLAUDE.md schreiben. Bleibt in der CLAUDE.md nichts
   Persönliches, stattdessen das Löschen anbieten. Lehnt der Nutzer die Bereinigung ab,
   auch die Regeldatei nicht schreiben und den Grund nennen.

### G5. Selbst angelegte CLAUDE.md

Nie schreiben. Sie lesen und gegen die gerenderte Kit-Datei halten: Widerspricht eine
Regel einer Kit-Regel (z. B. eine andere Antwortsprache oder Commit-Regel), das melden —
bei Widersprüchen folgt Claude beliebig einer Seite. Lösungen anbieten, nicht selbst
umsetzen: den Wert ändern (`explain-level`), die Kit-Zone ändern und mit einer
Override-Zeile schützen, ihr Markerpaar löschen (Opt-out) oder die eigene Regel
streichen. Eine allgemein nützliche eigene Regel → `propose-to-template` anbieten (Art
globale Regel).

### G6. Stand merken

Nach dem Dialog — auch wenn der Nutzer Änderungen abgelehnt hat — und nur, wenn die
Kit-Regeln jetzt eingerichtet sind: `sh <skript> snapshot --snapshot <basis> <config>
<tmp>/global rules/coding-kit.md`. Der Hinweis beim Session-Start vergleicht den Render
mit dieser Basis; abgelehnte Änderungen meldet er erst wieder, wenn sich Kit oder Werte
erneut ändern. Danach sagen, dass die neuen Regeln ab der nächsten Session gelten.
