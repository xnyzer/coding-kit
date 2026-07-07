---
name: new-project
description: Neues Projekt anlegen — der Orchestrator. Erhebt die Short-Info, klärt Name/Lizenz/Stack/Sichtbarkeit/Doku-Sprache/group_id/Anforderungen (mit Defaults, Sub-Skills aufrufbar), zeigt einen Plan und baut nach Bestätigung ein Repo aus dem project-template — Platzhalter füllen, Modul einsetzen, template-version stempeln, Repo-Settings, Verifikation via just check. Trockenlauf mit Argument „dry-run". Nie ohne Bestätigung nach außen wirken.
disable-model-invocation: true
---

# Neues Projekt anlegen

Orchestrator über dem [project-template]-Repo. **Jeder außenwirksame Schritt (Repo
anlegen, Settings, Commit, Push) wird einzeln bestätigt. Nie automatisch committen.**

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

Wie in `/choose-stack` § 0: lokaler Checkout unter `$CODING_KIT_PROJECTS_DIR/
project-template`, sonst `gh repo clone "$(gh api user --jq .login)/project-template"
<tmp> -- --depth 1` (Override: `CODING_KIT_TEMPLATE_REPO`). Dann `MANIFEST.md` lesen —
sie ist der Vertrag für alles Folgende. **`manifest-format` prüfen:** dieser Skill kann
Format `1`; bei einer anderen Formatversion abbrechen und auf ein Kit-Update verweisen.
Template-`VERSION` merken (wird gestempelt).

## Schritt 2 — Abfragen (eine Frage pro Antwort, je mit Default; Aufschieben erlaubt)

1. **Name?** — direkt eingeben oder `/name-it` (nutzt die Short-Info). Ergebnis:
   lowercase-kebab; `PROJECT_NAME_SNAKE` ableiten.
2. **Sichtbarkeit?** _(Default: privat)_ — bestimmt public-only-Dateien und den
   Sprach-Default.
3. **Lizenz?** _(Default: Apache-2.0)_ — direkt, `/choose-license`, oder „später" (TBD;
   bei public nicht erlaubt — public braucht eine LICENSE).
4. **Stack/Modul?** — direkt oder `/choose-stack` (Modus Neuanlage); „offen" →
   `docs-only`. Ergebnis inkl. CodeQL-Sprache aus dem `MODULE.md`.
5. **Sprache der lebenden Doku?** _(Default: Deutsch bei privat, Englisch bei public;
   Governance ist immer englisch)_
6. **Graphiti-group_id?** _(Default: Projektname)_ — „kein Graphiti" entfernt den
   optionalen Graphiti-Block.
7. **Anforderungen jetzt oder später?** _(Default: jetzt via `/define-requirements`)_ —
   „später" lässt das REQUIREMENTS-Skelett unangetastet.

Bereits Bekanntes (aus Argument/Verlauf) nicht erneut abfragen.

## Schritt 3 — Plan anzeigen

Kompakt: alle geklärten Werte + die Ausführungsschritte aus Schritt 4 (inkl. exakter
`gh repo create`-Zeile). **Explizit bestätigen lassen** („Ausführen? j/N"). Im
**Trockenlauf** hier enden: zusätzlich die Ziel-Dateiliste aus den MANIFEST-Tabellen
zeigen (core-managed + Modul-Parts), nichts ausführen.

## Schritt 4 — Ausführen

### 4a. Repo anlegen (bestätigt)

```bash
cd "$CODING_KIT_PROJECTS_DIR"
gh repo create "$(gh api user --jq .login)/<name>" --private|--public \
  --template <owner>/project-template --clone
```

**Kein separates `git init`.** Danach lokale Autor-Config (nie hardcoden):

```bash
git config user.name  "$(gh api user --jq '.name // .login')"
git config user.email "$(gh api user --jq '.id')+$(gh api user --jq '.login')@users.noreply.github.com"
```

Schlägt `create` fehl (Name belegt): zurück zu Schritt 2.1.

### 4b. Instanziieren (MANIFEST ist die Quelle — nichts roh kopieren)

Je Zeile der **Core-managed-Tabelle**: `core/<Quelle>` → `<Ziel>` instanziieren:

- **Platzhalter** der Registry ersetzen (PROJECT_NAME, PROJECT_NAME_SNAKE,
  PROJECT_DESCRIPTION, OWNER, YEAR, GROUP_ID, LIVING_DOC_LANGUAGE, LICENSE_SPDX,
  CODEQL_LANGUAGES, TEMPLATE_VERSION) — Werte aus Schritt 2 bzw. zur Laufzeit.
- **`<!-- template:adapt: … -->`**-Stellen aus der Short-Info **konkretisieren** (Zweck/
  Scope in CLAUDE.md, README-Intro, Status-Zeile) und den Marker entfernen.
- **`<!-- template:optional:NAME -->`**-Blöcke behalten oder samt Inhalt entfernen:
  `graphiti` je Schritt 2.6; `security-tool` nur behalten, wenn das Projekt ein
  Security-/Auth-Tool ist (aus der Short-Info ableiten, im Zweifel fragen).
- **public-only**-Dateien (CODE_OF_CONDUCT, codeql.yml) nur bei public instanziieren.
- **LICENSE:** kanonischen Text der gewählten Lizenz einsetzen; bei **TBD** keine
  LICENSE-Datei anlegen und im README „License: TBD" vermerken.

Dann **Modul einsetzen** (Modul-Kontrakt, wie `/choose-stack` Modus B): justfile
ersetzen, `mise.part.toml` in `[tools]` mergen, gitignore-/CI-Parts an ihre Marker,
CODING-STANDARDS-Slot füllen, `files/**` nach Substitution kopieren
(`src/…{{PROJECT_NAME_SNAKE}}…`-Umbenennung beachten; Datei-Policies laut `MODULE.md`).

**Aufräumen:** Nach der Instanziierung bleiben nur Manifest-Ziele + Modul-Dateien.
Template-Eigenes löschen: `core/`, `modules/`, `MANIFEST.md`, `VERSION`, `CHANGELOG.md`,
`scripts/` sowie alle Template-Root-Dateien, die kein Manifest-Ziel sind (Template-eigene
CLAUDE.md/PROGRESS*/README/justfile/mise*/lefthook/renovate/.github wurden durch die
instanziierten Core-Fassungen ersetzt). Mit `git status` gegenprüfen, dass nichts
Template-Eigenes übrig ist.

**Stempeln:** Template-`VERSION` nach `.claude/template-version`.

### 4c. Repo-Settings (bestätigt)

Via `gh repo edit` / `gh api`: Beschreibung = Short-Info; **Topics** lowercase-kebab:
Stack-Topic (z. B. `python`) + 2–4 Domain-Topics aus der Short-Info + Marker-Topic
`coding-kit` (Discovery für `/update-conventions`); Issues an, Wiki/Projects aus,
Squash-Merge + delete-branch-on-merge; Push-Protection/Secret-Scanning via `gh api`
mit Feature-Detection (bei privaten Repos planabhängig — Fehler nicht fatal, gitleaks
bleibt lokaler Backstop).

### 4d. Verifikation (Write-then-Verify)

```bash
mise trust && mise install && just setup && just check
```

Muss grün sein — rote Ergebnisse erst fixen. `mise.lock` entsteht dabei und wird
mitcommittet.

### 4e. Anforderungen

Je Schritt 2.7: jetzt `/define-requirements` mit der Short-Info aufrufen (schreibt
REQUIREMENTS.md + initiale F-Nummern in PROGRESS.md) — oder Skelett belassen.

### 4f. Abschlussprüfung + Erst-Commit (nur nach OK)

- **Personendaten-grep** über den Baum: private E-Mail-Adressen, absolute lokale Pfade,
  private IPs/Hostnames, Klarnamen (Muster wie `/step-done` § 3). Quell-Dokumente mit
  Privatbezug (z. B. die STARTPROMPT-Datei) nach `private/` des Projekts verschieben.
- Erst-Commit **erst nach explizitem OK** — Vorschlag:
  `feat: bootstrap from project-template <TEMPLATE_VERSION> (<modul> module)`,
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
