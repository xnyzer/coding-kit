---
name: new-project
description: Neues Projekt anlegen — der Orchestrator. Erhebt die Short-Info, klärt Git-Host (GitHub, Azure DevOps oder nur Git)/Name/Lizenz/Stack/Sichtbarkeit/Sprachen-Preset/group_id/Anforderungen (mit Defaults, Sub-Skills aufrufbar), zeigt einen Plan und baut nach Bestätigung ein Repo aus dem mitgelieferten Template — Platzhalter füllen, Modul einsetzen, template-version stempeln, Repo-Settings, Verifikation via just check. Trockenlauf mit Argument „dry-run". Nie ohne Bestätigung nach außen wirken.
argument-hint: "[Short-Info] [dry-run]"
disable-model-invocation: true
user-invocable: true
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

1. **Git-Host?** _(Default: was `sh ${CLAUDE_PLUGIN_ROOT}/scripts/template-sync.sh
   default-host <config>/coding-kit.env` nennt — `CODING_KIT_DEFAULT_HOST` der
   Personal-Config, ohne Eintrag `github`; `<config>` ist `$CLAUDE_CONFIG_DIR`, sonst
   `~/.claude`; meldet die Zeile `invalid`, den Wert nennen)_ — die Hosts aus
   `MANIFEST.md` § Hosts. `github` legt das Repo dort an; `azure` verbindet das Projekt
   mit einem leeren Repo, das der Nutzer im Web in seinem Azure-Projekt anlegt (Azure
   DevOps Services, ohne `az`); `git` legt das Projekt nur lokal per `git init` an, ohne
   Remote und ohne `gh`. Der Host steht danach als `HOST` in den Antworten und
   entscheidet, welche Dateien und Textblöcke das Projekt bekommt; wechseln lässt er sich
   später mit `/coding-kit:update-conventions host`.
2. **Name?** — direkt eingeben oder `/name-it` (nutzt die Short-Info und den Host).
   Ergebnis: lowercase-kebab; `PROJECT_NAME_SNAKE` ableiten.
3. **Sichtbarkeit?** _(Default: privat)_ — bestimmt die public-only-Dateien; auf die
   Sprachwahl hat sie keinen Einfluss. Auf `azure` entfällt die Frage: immer privat,
   denn Azure DevOps hat keine öffentlichen Projekte mehr (der Renderer lehnt `public`
   dort ab).
4. **Lizenz?** _(Default: Apache-2.0)_ — direkt, `/choose-license`, oder „später" (TBD;
   bei public nicht erlaubt — public braucht eine LICENSE).
5. **Stack/Modul?** — direkt oder `/choose-stack` (Modus Neuanlage); „offen" →
   `docs-only`. Ergebnis inkl. CodeQL-Sprache aus dem `MODULE.md`.
6. **Sprachen?** Eine Frage mit Presets — den Vorschlag aus der Short-Info ableiten
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
7. **Graphiti-group_id?** _(Default: Projektname, wenn die Session Graphiti-Werkzeuge
   hat (`add_memory`, `search_memory_facts`); sonst „kein Graphiti")_ — „kein Graphiti"
   entfernt den optionalen Graphiti-Block; Wissen ohne Ort im Repo geht dann nach
   `docs/notes.md`, die das Template anlegt. Nachrüsten lässt sich der Block später per
   `/coding-kit:update-conventions` (`graphiti` in `OPTIONAL` und eine `GROUP_ID` in den
   Antworten, Schritt 2). Eine group_id trotz fehlender Werkzeuge ist erlaubt: Ein
   anderer Rechner kann Graphiti haben.
8. **Anforderungen jetzt oder später?** _(Default: jetzt via `/define-requirements`)_ —
   „später" lässt die Ziel-Abschnitte der CLAUDE.md mit ihren Platzhaltern und
   `features/INDEX.md` leer, wie gerendert.

Bereits Bekanntes (aus Argument/Verlauf) nicht erneut abfragen.

## Schritt 3 — Plan anzeigen

Kompakt: alle geklärten Werte + die Ausführungsschritte aus Schritt 4 (inkl. der exakten
Zeile zum Anlegen — `gh repo create` bzw. `git init`, auf `azure` die Web-Schritte und
`git init` mit `origin`) und die Host-Schritte, die der gewählte Host nicht kann, als
übersprungen. **Explizit bestätigen lassen** („Ausführen? j/N"). Im **Trockenlauf** hier
enden: zusätzlich die Ziel-Dateiliste zeigen — die Zeilen von `render --seeds` (§ 4b) mit
Antworten in einem Temp-Verzeichnis —, sonst nichts ausführen.

## Schritt 4 — Ausführen

### 4a. Repo anlegen (bestätigt)

Host-Schritte nach `MANIFEST.md` § Hosts (Absatz „Host steps in a skill"): Kann der Host
einen Schritt nicht oder ist seine CLI nicht angemeldet, den Schritt als übersprungen
ausweisen und weitermachen.

Zuerst prüfen, dass es den Ordner `$CODING_KIT_PROJECTS_DIR/<name>` noch nicht gibt —
sonst zurück zu Schritt 2.2, bevor auf dem Host etwas entsteht (ein angelegtes Repo
bliebe sonst verwaist).

**Host `github`** — ist `gh` nicht angemeldet, nicht anlegen: auf `gh auth login`
hinweisen und fragen, ob es danach weitergeht oder das Projekt als `git` entsteht.

```bash
cd "$CODING_KIT_PROJECTS_DIR"
gh repo create "$(gh api user --jq .login)/<name>" --private|--public --clone
```

Das Repo entsteht **leer**; die Dateien schreibt erst 4b. **Kein separates `git init`** —
der Klon des leeren Repos übernimmt den Default-Branch des Remotes; `git branch
--show-current` muss `main` zeigen (die CI-Vorlage triggert auf `main`), sonst vor dem
ersten Commit `git symbolic-ref HEAD refs/heads/main`.

**Host `git`** — lokal anlegen, ohne Remote und ohne `gh`:

```bash
mkdir "$CODING_KIT_PROJECTS_DIR/<name>" && git -C "$CODING_KIT_PROJECTS_DIR/<name>" init -b main
```

Einen Remote — etwa ein Bare-Repo auf einem NAS — setzt der Nutzer später selbst
(`git remote add origin <url>`); ein Umzug auf einen Host geht mit
`/coding-kit:update-conventions host`.

**Host `azure`** — der Web-Weg aus `MANIFEST.md` § Hosts: Das Kit ruft kein `az` auf,
legt auf Azure nichts an und fragt nie nach einem Token.

1. **Repo im Web anlegen lassen** — die Schritte zeigen: in Azure DevOps das
   Azure-Projekt öffnen → Repos → oben in der Repo-Auswahl „New repository" → Typ Git,
   Name `<name>`, **„Add a README" aus, kein `.gitignore`** (das Repo muss leer sein) →
   Create. Ein neues Azure-Projekt bringt schon ein leeres Repo mit seinem Namen mit;
   das taugt ebenso. Repos anlegen dürfen standardmäßig nur Projekt-Admins — fehlt die
   Schaltfläche, legt ein Admin das Repo an.
2. **Clone-Adresse erfragen** — im Repo „Clone": SSH (Schlüssel unter User settings →
   SSH public keys; Azure nimmt nur RSA-Schlüssel an) oder HTTPS (Anmeldung über den Git
   Credential Manager). Eine Antwort mit Leerzeichen oder einfachem Anführungszeichen ist
   keine Adresse — erneut fragen.
3. **Prüfen:** `sh <skript> remote-check '<adresse>'` (`<skript>` wie in 4b, die
   Adresse in einfachen Anführungszeichen). Verbunden wird nur, wenn die Zeile `remote`
   `azure` nennt und die Zeile `reach` `empty` lautet. Sonst `origin` nicht setzen, den
   Grund nennen und fragen: **andere Adresse** (zurück zu 2), **als `git` weiter** (wie
   oben bei Host `git`, `HOST=git`) oder **abbrechen**:
   - `credentials` — die Adresse trägt ein Passwort oder einen Token: um eine Adresse
     ohne Zugangsdaten bitten und die Adresse nie wiederholen. War es ein echter Token,
     steht er im Gesprächsverlauf — raten, ihn in Azure zu widerrufen.
   - `remote` nennt nicht `azure` (etwa `other` für Azure DevOps Server): unterstützt
     ist nur Azure DevOps Services; ein anderer Server läuft als `git`.
   - `refs` — das Repo ist nicht leer (etwa mit README angelegt): nie verbinden, nie
     force-pushen; das Repo im Web löschen und leer neu anlegen oder eine andere Adresse.
   - `not-found` — das Repo gibt es nicht oder es fehlen Rechte (Azure unterscheidet das
     nicht): Adresse auf Tippfehler prüfen, Rechte im Azure-Projekt.
   - `denied` — Anmeldung abgelehnt: per SSH ist der Schlüssel nicht im Profil oder kein
     RSA-Schlüssel; per HTTPS trägt die Anmeldung des Git Credential Managers nicht.
   - `host-key` — ssh kennt den Server noch nicht: einmal `ssh -T git@ssh.dev.azure.com`
     im Terminal ausführen und den Fingerabdruck mit dem in Azure (User settings → SSH
     public keys) vergleichen. Der Befehl endet auch nach erfolgreicher Anmeldung mit
     einem Fehler und „Shell access is not supported" — das ist richtig so. Dann erneut
     prüfen.
   - `timeout` — keine Antwort: kurz warten und erneut prüfen (viele Verbindungen kurz
     hintereinander bremst Azure).
   - `failed` — sonst: die Adresse prüfen.
4. **Lokal anlegen und verbinden:**

   ```bash
   mkdir "$CODING_KIT_PROJECTS_DIR/<name>" && git -C "$CODING_KIT_PROJECTS_DIR/<name>" init -b main
   git -C "$CODING_KIT_PROJECTS_DIR/<name>" remote add origin '<adresse>'
   ```

Danach die lokale Autor-Config (nie hardcoden): der Name auf GitHub über
`git config --local user.name "$(gh api user --jq '.name // .login')"`, auf `azure` und
bei `git` aus `git config --global user.name`, sonst fragen; die Commit-Adresse ermitteln und setzen wie
`/coding-kit:step-done` § 5a — über `template-sync.sh commit-email` die Adresse des
Projekt-Hosts, immer `--local`.

Schlägt `create` fehl (Name belegt) oder gibt es den Ordner schon (`mkdir` scheitert):
zurück zu Schritt 2.2 — nichts Vorhandenes überschreiben.

### 4b. Instanziieren (der Renderer schreibt — MANIFEST ist die Quelle)

Instanziiert wird mit `${CLAUDE_PLUGIN_ROOT}/scripts/template-sync.sh` (in Shell-Befehlen
der aufgelöste Pfad, Aufruf über `sh`; der Skriptkopf beschreibt die Befehle) — nie
Template-Dateien selbst abschreiben. Render-Ergebnisse gehören in ein frisches
Temp-Verzeichnis (`mktemp -d`, im Folgenden `<tmp>`).

1. **Antworten schreiben:** `.claude/template-answers` nach MANIFEST § Answers mit den
   Werten aus Schritt 2 — `PROJECT_NAME`, `PROJECT_DESCRIPTION`, `OWNER` (nur auf
   `github`), `YEAR`, `GROUP_ID` (nur mit Graphiti), die fünf `LANG_*`, `LICENSE_SPDX`,
   `MODULE`, `VISIBILITY`, `HOST`, `OPTIONAL` (`graphiti`, wenn gewählt) und
   `FRAGMENTS` (schon bekannte Eigenschafts-Fragmente; die Lizenz- und Host-Blöcke
   leitet der Renderer selbst ab).
2. **Rendern:** `sh <skript> render --seeds <template> <projekt>/.claude/template-answers
   <tmp>/neu` und den Inhalt von `<tmp>/neu` ins Projekt kopieren. Der Renderer setzt
   Platzhalter, `template:optional`-Blöcke, public-only-Dateien, Modul-Teile,
   `files/**` (mit Pfad-Platzhaltern) und den Fragment-Slot (Modul-Fragment, deklarierte
   Katalog-Fragmente samt Sprachfragment, `FRAGMENTS`); `section:NAME`-Markerpaare
   bleiben, wie sie sind.
3. **Was der Renderer offen lässt, jetzt konkretisieren:**
   - **`<!-- template:adapt: … -->`**-Stellen aus der Short-Info konkretisieren (Zweck/
     Scope in CLAUDE.md, README-Intro, Status-Zeile) und den Marker entfernen. Die
     Ziel-Abschnitte im Überblick der CLAUDE.md (Goals, Non-goals, Constraints) füllt
     `/define-requirements` in 4e; bei „später" (Schritt 2.8) bleiben ihre Marker
     stehen. Für jede
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
   aus Schritt 3 sind ab jetzt Projektabweichungen mit Registry-Zeile. **Seed-Basen:**
   `sh <skript> snapshot --seeds <projekt> <tmp>/neu <seed-Ziele>` für jede seed-Datei
   aus MANIFEST § Seed sections, die der Render aus Schritt 2 geschrieben hat (Zeilen mit
   `seed`). An ihr erkennt `/coding-kit:update-conventions` später neue Zonen des
   Templates.
5. **Prüfen:** `sh <skript> status <projekt>` — nur die Dateien aus Schritt 3 dürfen
   `deviates` zeigen, und zwar mit Art `adapt`. **Nur Manifest-Ziele:** mit `git status`
   gegenprüfen, dass außer den gerenderten Dateien, der LICENSE, den Antworten und dem
   Snapshot nichts im Projekt liegt — nie Template-Interna wie `MANIFEST.md`, `modules/`
   oder `MODULE.md`.
6. **Stempeln:** die Version aus Schritt 1 nach `.claude/template-version`.

Bejaht das Requirements-Interview (4e) weitere Eigenschafts-Fragmente, kommen sie nach der
Mechanik von `/choose-stack` in den Slot und nach `FRAGMENTS`.

### 4c. Repo-Settings (bestätigt)

Nur auf einem Host mit Repo-Settings und Topics (`MANIFEST.md` § Hosts); bei `azure` und
`git` als übersprungen ausweisen. Auf `github` via `gh repo edit` / `gh api`: Beschreibung =
Short-Info; **Topics** lowercase-kebab: Stack-Topic (z. B. `python`) + 2–4 Domain-Topics
aus der Short-Info + Marker-Topic `coding-kit` (Discovery für `/update-conventions`);
Issues an, Wiki/Projects aus, Squash-Merge + delete-branch-on-merge;
Push-Protection/Secret-Scanning via `gh api` mit Feature-Detection (bei privaten Repos
planabhängig — Fehler nicht fatal, gitleaks bleibt lokaler Backstop).

### 4d. Verifikation (Write-then-Verify)

```bash
mise trust && mise install && mise lock && just setup && just check
```

Muss grün sein — rote Ergebnisse erst fixen. Die `mise.lock` erzeugt `mise lock` (nicht
`mise install` — das schreibt keine Plattform-Einträge, und die CI scheitert dann im
`--locked`-Modus); danach die Prüfung aus `/choose-stack` § Lock-Datei erzeugen und
prüfen. Die Lock-Datei wird mitcommittet.

### 4e. Anforderungen

Je Schritt 2.8: jetzt `/define-requirements` mit der Short-Info aufrufen (füllt Ziele,
Nicht-Ziele und Rahmenbedingungen im Überblick der CLAUDE.md, legt je Kern-Feature eine
Datei in `features/` an, schlägt die Reihenfolge vor und erzeugt die Tabelle) — oder die
Platzhalter belassen.

### 4f. Abschlussprüfung + Erst-Commit (nur nach OK)

- **Personendaten-grep** über den Baum: private E-Mail-Adressen, absolute lokale Pfade,
  private IPs/Hostnames, Klarnamen (Muster wie `/step-done` § 3). Quell-Dokumente mit
  Privatbezug (z. B. die STARTPROMPT-Datei) nach `private/` des Projekts verschieben.
- Erst-Commit **erst nach explizitem OK**, mit `.claude/template-answers` und
  `.claude/template-base/` — sonst stimmt die Basis späterer Updates nie. Vorschlag:
  `feat: bootstrap from coding-kit <TEMPLATE_VERSION> (<modul> module)`,
  Body mit den Kernentscheidungen (Lizenz, Sichtbarkeit, Modul), Abschluss
  `Co-Authored-By: Claude <noreply@anthropic.com>`. Danach Push (bestätigt,
  `git push -u origin main`); ohne Remote (Host `git`) entfällt er.

### 4g. Graphiti-Gründungsepisode (nur mit Graphiti-Block)

`add_memory` mit `group_id` aus Schritt 2.7, nach der Graphiti-Regel der globalen
Kit-Regeln (Abschnitt Graphiti Memory): eine kurze Episode aus der Short-Info — Zweck,
Zielnutzer, gewähltes Modul. Ohne Graphiti-Block nichts schreiben. Ist der Graph nicht
erreichbar (kein MCP, oder `add_memory` scheitert), im Abschlussbericht in einem Satz
melden, mit dem Text der Episode zum Nachtragen.

## Abschlussbericht

Kurz zusammenfassen: Repo-URL (bei `git` der Ordner), Host, Modul, Lizenz,
Template-Version, Verifikationsstatus, die übersprungenen Host-Schritte (bei `git`: Repo
anlegen, Settings, Topics, Push; bei `azure`: Repo anlegen — im Web —, Beschreibung und
Topics, Repo-Einstellungen, Sichtbarkeit — immer privat), was aufgeschoben wurde
(TBD-Lizenz? Anforderungen später?) — und der Hinweis, dass es
jetzt mit `/add-feature` → `/prep-step` → `/step-done` weitergeht.

Auf `azure` zusätzlich, was nur im Web oder in der Organisation geht:

- **Pipeline registrieren** (nach dem ersten Push, sie liest die Datei aus dem Repo):
  Pipelines → New pipeline → Azure Repos Git → das Repo → Existing Azure Pipelines YAML
  file → Branch `main`, Pfad `/azure-pipelines.yml` → Continue → Run. Beim ersten Lauf
  kann Azure eine Freigabe verlangen (der Lauf wartet mit „needs permission", im Lauf
  „Permit" wählen). Fehlen die Rechte für das Registrieren, macht es ein Projekt-Admin;
  das Projekt bleibt verbunden.
- **Agent:** `azure-pipelines.yml` läuft im Pool `Default`, also auf einem eigenen Agenten
  der Organisation (Organization settings → Agent pools). Ohne Agenten — oder ohne
  gekaufte Laufzeit, wenn die Zeile `pool` auf Microsoft-gehostete Agenten zeigt — bricht
  der Lauf ab; das Kit kann das nicht prüfen.
- **Renovate:** `renovate.json` wirkt nur, wenn die Organisation Renovate über ihre Repos
  laufen lässt. Das Preset liegt auf GitHub; ein zentraler Lauf über viele Repos braucht
  dafür einen GitHub-Token, sonst greift das Abruflimit von GitHub.
