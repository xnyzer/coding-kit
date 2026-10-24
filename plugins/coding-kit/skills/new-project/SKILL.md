---
name: new-project
description: Neues Projekt anlegen — der Orchestrator. Erhebt die Short-Info, klärt Name/Lizenz/Stack/Sichtbarkeit/Sprachen-Preset/group_id/Anforderungen (mit Defaults, Sub-Skills aufrufbar), zeigt einen Plan und baut nach Bestätigung ein Repo aus dem mitgelieferten Template — Platzhalter füllen, Modul einsetzen, template-version stempeln, Repo-Settings, Verifikation via just check. Trockenlauf mit Argument „dry-run". Nie ohne Bestätigung nach außen wirken.
disable-model-invocation: true
---

# Neues Projekt anlegen

Orchestrator über dem Template, das im Plugin mitkommt (`${CLAUDE_PLUGIN_ROOT}/template`).
**Jeder außenwirksame Schritt (Repo anlegen, Settings, Commit, Push) wird einzeln
bestätigt. Nie automatisch committen.**

Argument (optional): Short-Info — und/oder `dry-run` (Trockenlauf: alles zeigen — Fragen,
Plan, anzulegende Dateien — aber nichts ausführen).

## Kontext-Recovery

Bei Wiederaufnahme (Kompaktierung/Neustart): geklärte Werte aus dem bisherigen Verlauf
übernehmen; existiert der Projektordner schon, mit `git -C <dir> status` den Stand
feststellen und beim nächsten offenen Schritt weitermachen — nichts doppelt anlegen,
nichts ungefragt überschreiben.

## Schritt 0 — Short-Info erheben (M1)

Frage: **„Was soll das Projekt können?"** (Zweck, Scope, Zielnutzer, grobe Features).
Daraus die **Short-Info** destillieren: ein Satz, publishbar (keine privaten Details).
Bestätigen lassen — sie wird mehrfach wiederverwendet: Repo-Beschreibung, CLAUDE.md,
README-Intro, Graphiti-Episode, Namensfindung.

Stammt das Projekt aus einem vorhandenen Dokument (z. B. einer STARTPROMPT-Datei), dieses
zuerst lesen und die Short-Info daraus vorschlagen statt offen zu fragen.

## Schritt 1 — Template auflösen

Wie in `/choose-stack` § 0: das Template unter `${CLAUDE_PLUGIN_ROOT}/template`. Dann
`MANIFEST.md` lesen — sie ist der Vertrag für alles Folgende. **`manifest-format`
prüfen:** dieser Skill kann Format `2`; bei einer anderen Formatversion abbrechen und auf
ein Kit-Update verweisen. Die Version aus `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`
merken — sie wird gestempelt und füllt `TEMPLATE_VERSION`.

## Schritt 2 — Abfragen (eine Frage pro Antwort, je mit Default; Aufschieben erlaubt)

1. **Name?** — direkt eingeben oder `/name-it` (nutzt die Short-Info). Ergebnis:
   lowercase-kebab; `PROJECT_NAME_SNAKE` ableiten.
2. **Sichtbarkeit?** _(Default: privat)_ — bestimmt die public-only-Dateien; auf die
   Sprachwahl hat sie keinen Einfluss.
3. **Lizenz?** _(Default: Apache-2.0)_ — direkt, `/choose-license`, oder „später" (TBD;
   bei public nicht erlaubt — public braucht eine LICENSE).
4. **Stack/Modul?** — direkt oder `/choose-stack` (Modus Neuanlage); „offen" →
   `docs-only`. Ergebnis inkl. CodeQL-Sprache aus dem `MODULE.md`.
5. **Sprachen?** Eine Frage mit Presets — den Vorschlag aus der Short-Info ableiten
   (Thema/Publikum des Projekts), **nicht** aus der Sichtbarkeit:
   - **A — Arbeitssprache + Englisch nach außen** _(Default)_: lebende Doku +
     CLAUDE.md-Prosa in der Arbeitssprache des Nutzers; Kommentare, Commit-Prosa,
     README englisch.
   - **B — alles Englisch.**
   - **C — alles Arbeitssprache** (Conventional-Tokens bleiben englisch).
   - **D — individuell:** die fünf Dimensionen einzeln abfragen (lebende Doku,
     CLAUDE.md-Prosa, Kommentare, Commit-Prosa, README) — freie Sprachwahl.

   Ergebnis sind die Werte der fünf `LANG_*`-Platzhalter. Immer englisch (nicht
   konfigurierbar): Identifier, Conventional-Commit-Tokens, Status-Tokens,
   Governance-Doku.
6. **Graphiti-group_id?** _(Default: Projektname)_ — „kein Graphiti" entfernt den
   optionalen Graphiti-Block.
7. **Anforderungen jetzt oder später?** _(Default: jetzt via `/define-requirements`)_ —
   „später" lässt das REQUIREMENTS-Skelett unangetastet.

Bereits Bekanntes (aus Argument/Verlauf) nicht erneut abfragen.

## Schritt 3 — Plan anzeigen

Kompakt: alle geklärten Werte + die Ausführungsschritte aus Schritt 4 (inkl. exakter
`gh repo create`-Zeile). **Explizit bestätigen lassen** („Ausführen? j/N"). Im
**Trockenlauf** hier enden: zusätzlich die Ziel-Dateiliste zeigen — die Zeilen von
`render --seeds` (§ 4b) mit Antworten in einem Temp-Verzeichnis —, sonst nichts
ausführen.

## Schritt 4 — Ausführen

### 4a. Repo anlegen (bestätigt)

```bash
cd "$CODING_KIT_PROJECTS_DIR"
gh repo create "$(gh api user --jq .login)/<name>" --private|--public --clone
```

Das Repo entsteht **leer**; die Dateien schreibt erst 4b. **Kein separates `git init`** —
der Klon des leeren Repos übernimmt den Default-Branch des Remotes; `git branch
--show-current` muss `main` zeigen (die CI-Vorlage triggert auf `main`), sonst vor dem
ersten Commit `git symbolic-ref HEAD refs/heads/main`. Danach lokale Autor-Config (nie
hardcoden):

```bash
git config user.name  "$(gh api user --jq '.name // .login')"
git config user.email "$(gh api user --jq '.id')+$(gh api user --jq '.login')@users.noreply.github.com"
```

Schlägt `create` fehl (Name belegt): zurück zu Schritt 2.1.

### 4b. Instanziieren (der Renderer schreibt — MANIFEST ist die Quelle)

Instanziiert wird mit `${CLAUDE_PLUGIN_ROOT}/scripts/template-sync.sh` (in Shell-Befehlen
der aufgelöste Pfad, Aufruf über `sh`; der Skriptkopf beschreibt die Befehle) — nie
Template-Dateien selbst abschreiben. Render-Ergebnisse gehören in ein frisches
Temp-Verzeichnis (`mktemp -d`, im Folgenden `<tmp>`).

1. **Antworten schreiben:** `.claude/template-answers` nach MANIFEST § Answers mit den
   Werten aus Schritt 2 — `PROJECT_NAME`, `PROJECT_DESCRIPTION`, `OWNER`, `YEAR`,
   `GROUP_ID` (nur mit Graphiti), die fünf `LANG_*`, `LICENSE_SPDX`, `MODULE`,
   `VISIBILITY`, `OPTIONAL` (`graphiti`, wenn gewählt) und `FRAGMENTS` (schon bekannte
   Eigenschafts-Fragmente; die Lizenzblöcke leitet der Renderer selbst ab).
2. **Rendern:** `sh <skript> render --seeds <template> <projekt>/.claude/template-answers
   <tmp>/neu` und den Inhalt von `<tmp>/neu` ins Projekt kopieren. Der Renderer setzt
   Platzhalter, `template:optional`-Blöcke, public-only-Dateien, Modul-Teile,
   `files/**` (mit Pfad-Platzhaltern) und den Fragment-Slot (Sprachfragment, deklarierte
   Katalog-Fragmente, `FRAGMENTS`); `section:NAME`-Markerpaare bleiben, wie sie sind.
3. **Was der Renderer offen lässt, jetzt konkretisieren:**
   - **`<!-- template:adapt: … -->`**-Stellen aus der Short-Info konkretisieren (Zweck/
     Scope in CLAUDE.md, README-Intro, Status-Zeile) und den Marker entfernen. Für jede
     **managed** Datei mit konkretisierter Stelle (z. B. `SECURITY.md`) eine Zeile mit
     Art `adapt` in die Files-Tabelle der `.claude/convention-overrides.md`.
   - **LICENSE:** kanonischen Text der gewählten Lizenz einsetzen; bei **TBD** die
     gerenderte LICENSE löschen und im README „License: TBD" vermerken. Paket-Metadaten
     ohne gültigen SPDX-Wert (z. B. `[project].license` bei TBD) laut `MODULE.md`
     anpassen.
   - **Begleithandlungen:** Verlangt ein Fragment eine Handlung beim Einbau
     (`/choose-stack` § Begleithandlungen), gehört sie in denselben Schritt — hier ist
     sie am billigsten, weil sie greift, bevor der Stack das erste Mal läuft.
4. **Snapshot:** `sh <skript> render <template> <projekt>/.claude/template-answers
   <tmp>/soll` (nur managed Ziele), dann `sh <skript> snapshot <projekt> <tmp>/soll
   <alle Ziele dieser Liste>`. Der Snapshot ist die reine Fassung — die Konkretisierungen
   aus Schritt 3 sind ab jetzt Projektabweichungen mit Registry-Zeile.
5. **Prüfen:** `sh <skript> status <projekt>` — nur die Dateien aus Schritt 3 dürfen
   `deviates` zeigen, und zwar mit Art `adapt`. **Nur Manifest-Ziele:** mit `git status`
   gegenprüfen, dass außer den gerenderten Dateien, der LICENSE, den Antworten und dem
   Snapshot nichts im Projekt liegt — nie Template-Interna wie `MANIFEST.md`, `modules/`
   oder `MODULE.md`.
6. **Stempeln:** die Version aus Schritt 1 nach `.claude/template-version`.

Bejaht das Requirements-Interview (4e) weitere Eigenschafts-Fragmente, kommen sie nach der
Mechanik von `/choose-stack` in den Slot und nach `FRAGMENTS`.

### 4c. Repo-Settings (bestätigt)

Via `gh repo edit` / `gh api`: Beschreibung = Short-Info; **Topics** lowercase-kebab:
Stack-Topic (z. B. `python`) + 2–4 Domain-Topics aus der Short-Info + Marker-Topic
`coding-kit` (Discovery für `/update-conventions`); Issues an, Wiki/Projects aus,
Squash-Merge + delete-branch-on-merge; Push-Protection/Secret-Scanning via `gh api`
mit Feature-Detection (bei privaten Repos planabhängig — Fehler nicht fatal, gitleaks
bleibt lokaler Backstop).

### 4d. Verifikation (Write-then-Verify)

```bash
mise trust && mise install && mise lock && just setup && just check
```

Muss grün sein — rote Ergebnisse erst fixen. Die `mise.lock` erzeugt `mise lock` (nicht
`mise install` — das schreibt keine Plattform-Einträge, und die CI scheitert dann im
`--locked`-Modus); danach die Prüfung aus `/choose-stack` § Lock-Datei erzeugen und
prüfen. Die Lock-Datei wird mitcommittet.

### 4e. Anforderungen

Je Schritt 2.7: jetzt `/define-requirements` mit der Short-Info aufrufen (schreibt
REQUIREMENTS.md + initiale F-Nummern in PROGRESS.md) — oder Skelett belassen.

### 4f. Abschlussprüfung + Erst-Commit (nur nach OK)

- **Personendaten-grep** über den Baum: private E-Mail-Adressen, absolute lokale Pfade,
  private IPs/Hostnames, Klarnamen (Muster wie `/step-done` § 3). Quell-Dokumente mit
  Privatbezug (z. B. die STARTPROMPT-Datei) nach `private/` des Projekts verschieben.
- Erst-Commit **erst nach explizitem OK**, mit `.claude/template-answers` und
  `.claude/template-base/` — sonst stimmt die Basis späterer Updates nie. Vorschlag:
  `feat: bootstrap from coding-kit <TEMPLATE_VERSION> (<modul> module)`,
  Body mit den Kernentscheidungen (Lizenz, Sichtbarkeit, Modul), Abschluss
  `Co-Authored-By: Claude <noreply@anthropic.com>`. Danach Push (bestätigt).

### 4g. Graphiti-Seeding (falls MCP verfügbar)

`add_memory` mit `group_id` aus Schritt 2.6: Foundational-Episode aus der Short-Info
(Zweck, Scope, Zielnutzer, Kernentscheidungen, gewähltes Modul, Template-Version).
Ohne MCP still überspringen.

## Abschlussbericht

Kurz zusammenfassen: Repo-URL, Modul, Lizenz, Template-Version, Verifikationsstatus,
was aufgeschoben wurde (TBD-Lizenz? Anforderungen später?) — und der Hinweis, dass es
jetzt mit `/add-feature` → `/prep-step` → `/step-done` weitergeht.
