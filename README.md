# coding-kit

Mein persönliches Claude-Code-Kit: ein **Plugin** mit generischen Workflow-Skills, ein
**Marketplace** zum Installieren, ein **Renovate-Preset** für alle Projekte und ein
**Installer** für neue Rechner. Zusammen mit
[project-template](https://github.com/xnyzer/project-template) bildet es das
Scaffolding-System, mit dem neue Projekte entstehen und Bestandsprojekte aktuell bleiben.

> Kit-Sprache ist Deutsch (das Kit ist primär für den Eigenbedarf). Englisch ist nur, was
> in Projekte gelangt oder dort wirkt: Governance-Doku, Commit-Messages, Hook-Ausgaben.

**Das Kit baut auf GitHub auf.** Marketplace und Plugin kommen von github.com, das
project-template ist ein GitHub-Template-Repo, und ein Teil der Skills spricht über `gh`
mit der API — Repo-Anlage, Repo-Settings, projektübergreifende Discovery,
Sichtbarkeitswechsel. Wer GitHub nicht hat oder nicht nutzen will, verliert genau diese
Teile; der Arbeitszyklus (Planen, Bauen, Abschließen) läuft rein lokal über git und just
weiter. Was das im Einzelnen heißt: [Ohne GitHub](#ohne-github-nur-git) und die Spalte
**GitHub** in der [Skill-Tabelle](#tägliche-nutzung).

## Einrichtung

Zwei **alternative** Wege zum selben Ergebnis — der Installer führt automatisiert genau
die Schritte aus, die unten manuell stehen. Eins von beiden genügt. Voraussetzung für
beide: `gh` (authentifiziert) und `claude` sind installiert. Ohne GitHub-Konto führt nur
der [dritte Weg](#ohne-github-nur-git).

### Automatisiert (empfohlen)

Repo klonen und den Installer ausführen — er prüft die Voraussetzungen, richtet
Marketplace + Plugin ein, legt die Personal-Config an (via `gh api` vorbefüllt), bietet
die globale `~/.claude/CLAUDE.md` aus der Kit-Vorlage an und prüft die Toolchain
(Installation auf Wunsch via brew):

```bash
git clone https://github.com/xnyzer/coding-kit.git && cd coding-kit && ./install.sh
```

> **Der Installer läuft nur mit vollständig eingerichtetem GitHub.** Er prüft als erstes
> `gh` **inklusive Login** und bricht sonst sofort ab (`gh auth status` muss grün sein,
> [install.sh:40-41](install.sh#L40-L41)); die Personal-Config befüllt er über
> `gh api user`. Ohne Konto oder ohne Login ist er kein gangbarer Weg — dann
> [manuell](#manuell) bzw. [ohne GitHub](#ohne-github-nur-git) einrichten. Und ihn in
> einer **Shell** starten, nicht per Doppelklick: bei einem Abbruch schließt sich das
> per Dateizuordnung geöffnete Fenster mitsamt der Fehlermeldung.

Der Installer ist **idempotent**: jeder Schritt prüft erst den Zustand, mehrfaches
Ausführen ist gefahrlos und überspringt, was schon da ist — auch geeignet, um nach den
zwei `/plugin`-Befehlen nur den Rest nachzuziehen. Der Klon wird bloß für den Installer
und die CLAUDE.md-Vorlage gebraucht; das Plugin selbst kommt über den Marketplace von
GitHub. Für die reine Nutzung brauchst du das Repo also nicht lokal.

### Manuell

**1. Marketplace + Plugin** (in einer Claude-Code-Session):

```
/plugin marketplace add xnyzer/coding-kit
/plugin install coding-kit@xnyzer
```

**2. Personal-Config `~/.claude/coding-kit.env`** — praktisch erforderlich:
`CODING_KIT_PROJECTS_DIR` hat keinen Fallback und wird direkt in Shell-Kommandos
eingesetzt. Fehlt er, scheitert das nicht laut, sondern falsch — neue Projekte landen im
Verzeichnis, in dem die Session gerade steht, und die lokale Projekt-Discovery von
`/update-conventions` findet nichts. Die Identitäts-Schlüssel sind dagegen nur
Offline-Fallback (primär löst alles zur Laufzeit über `gh api user` auf):

```bash
mkdir -p ~/.claude
cat > ~/.claude/coding-kit.env <<EOF
CODING_KIT_GITHUB_LOGIN="$(gh api user --jq .login)"
CODING_KIT_GIT_AUTHOR_NAME="$(gh api user --jq '.name // .login')"
CODING_KIT_GIT_NOREPLY_EMAIL="$(gh api user --jq .id)+$(gh api user --jq .login)@users.noreply.github.com"
CODING_KIT_PROJECTS_DIR="$HOME/Documents/Coding-Projects"
EOF
chmod 600 ~/.claude/coding-kit.env
```

Projekte-Verzeichnis vorher prüfen und ggf. anpassen. Schlüssel-Referenz:
[Personal-Config](#personal-config).

**3. Globale `~/.claude/CLAUDE.md`** — optional: kein Skill liest sie, das Kit
funktioniert ohne. Sie setzt die House-Defaults (Antwortsprache, „nie automatisch
committen", Noreply-Mail-Pflicht, Graphiti-Konventionen) — ohne sie fehlen diese
Leitplanken außerhalb der Skills. Ohne Klon direkt aus dem Repo holen:

```bash
curl -fsSL https://raw.githubusercontent.com/xnyzer/coding-kit/main/templates/global-CLAUDE.md \
  -o ~/.claude/CLAUDE.md
```

**4. Toolchain** — `mise`, `just`, `lefthook`, `gitleaks`: die Skills rufen die
just-Standardrezepte, die Projekt-Hooks nutzen lefthook + gitleaks. Auf macOS:
`brew install mise just lefthook gitleaks`.

Frisch installierte Skills sind ggf. erst nach einem Session-Neustart sichtbar.

> **Windows:** Beide Wege brauchen eine Bash (Git for Windows) — `install.sh` und die
> Snippets sind Bash, und der Stop-Hook des Plugins ruft `bash` auf. Ausführen in
> derselben Umgebung, in der `claude` läuft: in Git Bash ist `$HOME` das
> Windows-Benutzerverzeichnis, ein Lauf unter WSL schreibt dagegen ins WSL-Home und
> bleibt für eine native Windows-Installation unsichtbar. Die Toolchain kommt dort über
> scoop/winget statt brew.

### Ohne GitHub (nur git)

Für Rechner ohne GitHub-Konto oder mit dem Verbot, Code dorthin zu pushen — etwa
Firmenrechner mit eigenem Git-Host. Voraussetzung ist nur, dass github.com **lesend**
erreichbar ist; ein Login braucht keiner dieser Schritte. Ist auch das Lesen gesperrt,
müssen Plugin und Template über einen Firmen-Mirror oder Datenträger auf den Rechner —
einen eingebauten Pfad dafür hat das Kit nicht.

1. **Marketplace + Plugin** wie im manuellen Weg — die zwei `/plugin`-Befehle lesen nur.
   `install.sh` ist hier keine Option (er verlangt ein authentifiziertes `gh`).
2. **Personal-Config von Hand**, ohne `gh api`-Vorbefüllung. `CODING_KIT_GITHUB_LOGIN`
   entfällt, als Commit-Adresse gehört die des jeweiligen Hosts hinein:

   ```bash
   mkdir -p ~/.claude
   cat > ~/.claude/coding-kit.env <<EOF
   CODING_KIT_GIT_AUTHOR_NAME="Vorname Nachname"
   CODING_KIT_GIT_NOREPLY_EMAIL="adresse@example.org"
   CODING_KIT_PROJECTS_DIR="$HOME/Documents/Coding-Projects"
   EOF
   chmod 600 ~/.claude/coding-kit.env
   ```

3. **Template lokal auslegen** — der entscheidende Schritt, er ersetzt jeden
   `gh`-Zugriff aufs Template. `project-template` ist public, der Klon braucht also keine
   Anmeldung:

   ```bash
   source ~/.claude/coding-kit.env
   mkdir -p "$CODING_KIT_PROJECTS_DIR"
   git clone https://github.com/xnyzer/project-template.git \
     "$CODING_KIT_PROJECTS_DIR/project-template"
   ```

   `/choose-stack`, `/update-conventions` und `/new-project` prüfen **zuerst** diesen
   Checkout und greifen nur ersatzweise zu `gh repo clone`. Liegt er da, fragt keiner
   mehr nach GitHub; aktuell halten mit `git pull`.
4. **Toolchain** wie im manuellen Weg (Schritt 4).

**Projekte anlegen:** `/new-project` legt das Repo über `gh repo create --template` an —
das ist der einzige Schritt, der sich nicht lokal erfüllen lässt. Ersatz: den
Template-Checkout kopieren und selbst initialisieren, dann den Skill auf den bestehenden
Ordner ansetzen (sein Schritt 0 sieht einen vorhandenen Projektordner vor).

```bash
cd "$CODING_KIT_PROJECTS_DIR"
cp -r project-template <name> && cd <name>
rm -rf .git && git init -b main
git config user.name  "Vorname Nachname"     # lokal, nicht global
git config user.email "adresse@example.org"
```

Die Instanziierung ab Schritt 4b (MANIFEST, Modul, Fragmente, `just check`) läuft
unverändert lokal; die Repo-Settings aus 4c entfallen. Die projektübergreifende Discovery
von `/update-conventions` findet lokale Projekte über `.claude/template-version` unter
`$CODING_KIT_PROJECTS_DIR`, das Marker-Topic braucht sie dafür nicht.

**Commit-Identität:** Die Kit-Vorlage der globalen `~/.claude/CLAUDE.md` schreibt die
GitHub-Noreply-Adresse als Pflicht fest und löst sie über `gh api user` auf. Auf einem
Rechner ohne GitHub ist das die falsche Regel — dort den Abschnitt auf die Adresse des
eigenen Hosts umschreiben und `git config user.email` **pro Repo** setzen, damit die
Firmenadresse nicht in private Projekte wandert.

## Tägliche Nutzung

Die Skills erscheinen namespaced als `/coding-kit:<skill>`:

Die Spalte **GitHub** sagt, was ohne GitHub bleibt: `–` = rein lokal über git und just,
`teils` = der Skill läuft, einzelne Teilschritte entfallen (Details unter der Tabelle),
`ja` = braucht GitHub, ohne ist er gegenstandslos.

| Skill | GitHub | Zweck |
|-------|:------:|-------|
| `/coding-kit:new-project` | teils | **Der Orchestrator:** Short-Info → Abfragen (Name/Lizenz/Stack/…, Sub-Skills aufrufbar) → Plan → Repo aus dem project-template bauen, verifizieren, Erst-Commit nach OK. Trockenlauf: Argument `dry-run`. |
| `/coding-kit:add-feature` | – | Neue Aufgabe analysieren und mit F-Nummer ins PROGRESS-Backlog aufnehmen (Status `BACKLOG`); Umsetzungsideen nur als grobe Lösungsskizze. |
| `/coding-kit:prep-step` | – | Aufgabe vor der Umsetzung analysieren: Lösungsskizze gegen den aktuellen Codestand hinterfragen, Standards-Abdeckung neuer Frameworks prüfen (Fragment-Vorschlag), ggf. in Substeps zerlegen, Plan festhalten (Status `PLANNED`). |
| `/coding-kit:build-step` | – | Aufgabe plan-treu umsetzen: Substep für Substep mit Verifikation. Interaktiv endet jeder Substep mit einer step-done-Empfehlung (du prüfst und schließt selbst ab); nur im autonomen `/goal`-Lauf läuft step-done je Substep automatisch. Mit `autonom` bereitet er stattdessen einen `/goal`-Lauf vor. |
| `/coding-kit:step-done` | teils | Abschluss-Checkliste: Review, `just check`, Standards-Abdeckungs-Backstop (neue Frameworks ohne Fragment), Secrets-Scan, Privacy-Scan der lebenden Doku, PROGRESS-Pflege, Commit-Frage. |
| `/coding-kit:audit-code` | – | Vollaudit (Code, Security, Deps, Deployment) → `AUDIT-RESULTS.md`, fixt nichts. |
| `/coding-kit:teach-step` | – | Lehrer-Modus: Aufgabe selbst umsetzen, der Skill leitet sokratisch an, prüft und testet — schreibt nie Code. |
| `/coding-kit:name-it` | teils | Namenskandidaten nach Kriterien + Verfügbarkeits-Checks (GitHub/npm/PyPI, Domain optional). |
| `/coding-kit:choose-license` | – | Kurzinterview → Lizenz-Empfehlung (Default Apache-2.0, „TBD" gültig). |
| `/coding-kit:choose-stack` | teils | Modul-Empfehlung für Neuanlage oder Nachrüsten/Wechsel EINES Moduls im Bestand (Diff + Bestätigung); baut die vom Modul deklarierten Standards-Fragmente komponierbar ein, Eigenschafts-Fragmente nachrüstbar auf Bestätigung; hält die Begleithandlungen, die einzelne Fragmente beim Einbau verlangen (referenziert von new-project, update-conventions, prep-step, step-done). |
| `/coding-kit:define-requirements` | – | Interview → REQUIREMENTS.md (Übergangs-Artefakt) → initiale PROGRESS.md mit F-Nummern; fragt die Eigenschafts-Trigger des Fragment-Katalogs ab. |
| `/coding-kit:refine-requirements` | – | Zurück zur Spec: Diagnose mit drei Pfaden, darf Features splitten, datiertes Decision Log. |
| `/coding-kit:update-conventions` | teils | Konventions-Sync Template → Projekte (nur abwärts): Diff + Bestätigung je Datei, je Standards-Fragment und je markierter seed-Zone (`section:NAME`), Override-Schutz, Altprojekt-Migrationen; erkennt im Template entfernte/umbenannte Dateien (Rückbau/Umzug je Datei bestätigt); projektlokale Fragmente werden mit manuell anstoßbarem Übernahme-Vorschlag fürs Template gemeldet. |
| `/coding-kit:check-upstreams` | ja | Watchliste externer Vorbild-Repos prüfen (`upstreams.json`), Neuerungen seit letztem Ref, Übernahme-Vorschläge. |
| `/coding-kit:go-public` | ja | Projekt nachträglich public machen: blockierendes Preflight-Audit (Secrets in der vollen Historie, Privacy inkl. Commit-Metadaten, Lizenz, `private/`-Hygiene), Datei-Nachzug **vor** dem Umstellen (update-conventions mit Sichtbarkeits-Prämisse), dann Sichtbarkeitswechsel bzw. Repo-Anlage + Push nur nach laufbezogener Freigabe; Abschluss-Check (CodeQL, Settings). |
| `/coding-kit:refine-prompt` | – | Übergebenen Prompt analysieren, Schwachstellen benennen, nach Best Practices neu formulieren und ausführen. |
| `/coding-kit:handoff` | – | Am Kontextlimit: kopierfertigen Handoff-Prompt für einen frischen Chat schreiben — übergibt nur, was aus der Session noch nicht dokumentiert ist, verweist sonst auf die Quelldateien; baut und ändert nichts. |

Was bei `teils` konkret entfällt — der Rest des Skills läuft lokal weiter:

- **`new-project`:** die Repo-Anlage über `gh repo create --template` (Schritt 4a) und die
  Repo-Settings samt Topics (4c). Instanziierung, Verifikation und Erst-Commit sind lokal;
  Ersatz für 4a steht unter [Ohne GitHub](#ohne-github-nur-git).
- **`update-conventions`:** die projektübergreifende Discovery über das Marker-Topic
  (`gh search repos`). Lokale Projekte findet sie weiter über `.claude/template-version`
  unter `$CODING_KIT_PROJECTS_DIR`.
- **`choose-stack`:** nur der Ersatzpfad zum Template (`gh repo clone`) — mit lokalem
  Template-Checkout gar nicht berührt.
- **`name-it`:** der GitHub-Verfügbarkeitscheck; npm, PyPI und Domain bleiben.
- **`step-done`:** allein die Zeile, die `git config user.email` auf die
  GitHub-Noreply-Adresse setzt. Review, `just check`, Scans und PROGRESS-Pflege sind
  lokal.

Die beiden `ja`-Skills: **`go-public`** dreht GitHub-Sichtbarkeit und -Settings, ist ohne
GitHub also gegenstandslos; **`check-upstreams`** liest fremde GitHub-Repos (im Kit über
`gh api`) — ohne `gh` bleibt nur manuelles Nachsehen.

Der übliche Zyklus: `add-feature` → `prep-step` → `build-step` → `step-done` (je
Substep). Interaktiv rufst du `step-done` bewusst selbst auf, wenn du den Substep
geprüft hast — build-step empfiehlt es nur; im autonomen `/goal`-Lauf läuft es
automatisch durch. Die `**Status:**`-Zeile im PROGRESS-Eintrag zeigt die Station: `BACKLOG` =
nur aufgenommen (→ prep-step), `PLANNED` = geplant (→ build-step), fertig =
Done-Tabelle + `(DONE)` im FEATURE-INDEX. Für die Implementierungsphase gibt es drei
Wege: `build-step` baut diszipliniert, `teach-step` leitet dich durch die eigene
Umsetzung, oder du implementierst frei und schließt mit `step-done` ab.

### Autonomer Lauf (build-step + /goal)

Ganze Features samt Substeps unbeaufsichtigt bauen lassen — über den eingebauten
Claude-Code-Befehl `/goal`, der die Session Turn für Turn weiterarbeiten lässt, bis
eine Abschlussbedingung erfüllt ist:

1. `/coding-kit:prep-step F-NNN` — Plan mit Substeps steht in der PROGRESS.md.
2. `/coding-kit:build-step F-NNN autonom` — lädt Plan und Disziplin-Regeln, fragt
   einmalig die Commit-Freigabe für den Lauf ab (je Substep ein Commit als
   Checkpoint; Push bleibt immer tabu) und gibt die fertige `/goal`-Zeile aus.
3. Die ausgegebene `/goal`-Zeile absenden — der Lauf startet sofort. `/goal` ohne
   Argument zeigt den Status, `/goal clear` bricht ab.

Für unbeaufsichtigte Läufe zusätzlich den Auto-Modus aktivieren (sonst stoppt der
Lauf am ersten Permission-Prompt). Der Stop-Hook des Kits meldet sich während des
Laufs weiter — die Arbeits-Turns schieben die Erinnerung planmäßig auf.

Alle Skills sind **stack-agnostisch**: Sie rufen nur die just-Standardrezepte
(`just check` / `test` / `lint`) auf und lesen Projektspezifika (Graphiti-group_id,
Sprache der lebenden Doku, Sicherheits-Postur) aus der Projekt-CLAUDE.md — nichts ist
hartkodiert.

### Stop-Hook

Das Plugin bringt einen **projekterkennenden** Stop-Hook mit: Endet ein Claude-Turn,
während im Projekt uncommittete Änderungen liegen, erinnert er einmal pro Stopp an
`/coding-kit:step-done`.

- **Feuert nur in Kit-Projekten:** erkannt an einer `PROGRESS.md` mit
  `FEATURE-INDEX`-Block **oder** einer Datei `.claude/template-version`. In allen anderen
  Repos ist der Hook vollständig still.
- **Loop-Schutz:** pro Stopp maximal eine Erinnerung (`stop_hook_active`).
- Als „uncommitted" zählen geänderte und neue (nicht ignorierte) Dateien; `private/` und
  anderes Gitignoriertes lösen nichts aus.
- Abschalten: Plugin deaktivieren (`claude plugin disable coding-kit`) oder committen. 😉

## Renovate-Preset

`default.json` im Repo-Root ist ein Shareable Preset; Projekte binden es so an:

```json
{ "extends": ["github>xnyzer/coding-kit"] }
```

Inhalt: `config:recommended` + Digest-Pinning für GitHub Actions + Label `dependencies`.
Details und die (bewusst manuelle) App-Installation: [docs/renovate-preset.md](docs/renovate-preset.md).

## Personal-Config

`~/.claude/coding-kit.env` (dotenv, shell-sourcebar, **nie committen**) — legt der
Installer an. Enthält, was nicht zur Laufzeit ermittelbar ist, plus Offline-Fallbacks:

| Schlüssel | Bedeutung |
|-----------|-----------|
| `CODING_KIT_GITHUB_LOGIN` | GitHub-Login (Fallback; primär via `gh api user`) |
| `CODING_KIT_GIT_AUTHOR_NAME` | Git-Autorname |
| `CODING_KIT_GIT_NOREPLY_EMAIL` | GitHub-Noreply-Adresse für Commits |
| `CODING_KIT_PROJECTS_DIR` | Wurzelverzeichnis der Projekte |
| `CODING_KIT_TEMPLATE_REPO` | _(optional)_ Override für das Template-Repo; Default: `<github-login>/project-template` |

## Repo-Struktur

```
.claude-plugin/marketplace.json   Marketplace „xnyzer" (Quelle: dieses Repo)
plugins/coding-kit/               Das Plugin
  .claude-plugin/plugin.json      Name, Version, Beschreibung
  skills/<name>/SKILL.md          Die Skills (ein Ordner je Skill)
  hooks/hooks.json + *.sh         Projekterkennender Stop-Hook
default.json                      Renovate-Shareable-Preset (Root = Preset-Konvention)
upstreams.json                    Watchliste für /check-upstreams (persistierte Refs)
templates/global-CLAUDE.md        Vorlage der globalen ~/.claude/CLAUDE.md (House-Defaults)
docs/                             Pflege-Doku (Skill-Authoring, Renovate-Preset)
install.sh                        Neuer-Rechner-Bootstrap (idempotent)
scripts/validate.py               Kit-Validator (läuft in `just check` + CI)
private/                          Gitignoriert — private Notizen/Quellen
```

## Pflege

- Regeln für neue/geänderte Skills: [docs/skill-authoring.md](docs/skill-authoring.md).
- Installierte Version aktualisieren: `claude plugin marketplace update xnyzer`, dann
  `claude plugin update coding-kit@xnyzer` (voll qualifiziert — der kurze Name wird
  nicht gefunden); Session-Neustart wendet die Änderung an.
- Jede inhaltliche Plugin-Änderung bumpt die Version in `plugin.json` und bekommt einen
  `CHANGELOG.md`-Eintrag (im selben Commit).
- `just setup` installiert die Git-Hooks (gitleaks + Validator), `just check` ist das
  Vollgate — muss vor jedem Commit grün sein.
- Aufgaben laufen als F-Nummern in `PROGRESS.md` — das Kit nutzt seine eigenen Skills
  (Dogfooding).

## Lizenz

Apache-2.0 — siehe [LICENSE](LICENSE).
