# coding-kit

Mein persönliches Claude-Code-Kit — das Scaffolding-System, mit dem neue Projekte entstehen
und Bestandsprojekte aktuell bleiben: ein **Plugin** mit Workflow-Skills, dem
**Projekt-Template** (Core, Stack-Module, Standards-Fragmente) und den **globalen
Kit-Regeln** für jede Claude-Session, ein **Marketplace** zum Installieren, ein
**Renovate-Preset** für alle Projekte und ein **Installer** für neue Rechner. Das Template lag bis 0.16.0 im eigenen Repo project-template; seit 1.0.0 kommt
es mit dem Plugin, Skills und Template teilen eine Version.

> Kit-Sprache ist Deutsch (das Kit ist primär für den Eigenbedarf). Englisch ist nur, was
> in Projekte gelangt oder dort wirkt: der Template-Inhalt, Governance-Doku,
> Commit-Messages, Hook-Ausgaben.

**Das Kit baut auf GitHub auf.** Marketplace und Plugin samt Template kommen von
github.com, und ein Teil der Skills spricht über `gh` mit der API — Repo-Anlage,
Repo-Settings, projektübergreifende Discovery, Sichtbarkeitswechsel. Wer GitHub nicht hat
oder nicht nutzen will, verliert genau diese Teile; der Arbeitszyklus (Planen, Bauen,
Abschließen) läuft rein lokal über git und just weiter. Was das im Einzelnen heißt: [Ohne
GitHub](#ohne-github-nur-git) und die Spalte **GitHub** in der
[Skill-Tabelle](#tägliche-nutzung).

## Einrichtung

Zwei **alternative** Wege zum selben Ergebnis — der Installer führt automatisiert genau
die Schritte aus, die unten manuell stehen. Eins von beiden genügt. Voraussetzung für
beide: `gh` (authentifiziert) und `claude` sind installiert. Ohne GitHub-Konto führt nur
der [dritte Weg](#ohne-github-nur-git).

### Automatisiert (empfohlen)

Repo klonen und den Installer ausführen — er prüft die Voraussetzungen, richtet
Marketplace + Plugin ein, legt die Personal-Config an (via `gh api` vorbefüllt), meldet
den Stand der [globalen Kit-Regeln](#globale-kit-regeln) und prüft die Toolchain
(Installation auf Wunsch via brew). Die Kit-Regeln schreibt er nicht; die richtest du
danach in einer Claude-Session mit `/coding-kit:update-conventions global` ein:

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
gebraucht; das Plugin samt Kit-Regeln kommt über den Marketplace von GitHub. Für die reine Nutzung brauchst du das Repo also nicht lokal.

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

**3. Globale Kit-Regeln** — optional: Das Kit funktioniert ohne. Sie setzen die
House-Defaults für jede Session (Antwortsprache, Erklär-Niveau, „nie automatisch
committen", Noreply-Mail-Pflicht, Graphiti-Konventionen) — ohne sie fehlen diese
Leitplanken außerhalb der Skills. Einrichten in einer Claude-Session:

```
/coding-kit:update-conventions global
```

Das fragt Antwortsprache und Erklär-Niveau ab und zeigt die Regeln, bevor es sie
schreibt. Was dabei mit deinen Einstellungen geschieht:
[Globale Kit-Regeln](#globale-kit-regeln).

**4. Toolchain** — `mise`, `just`, `lefthook`, `gitleaks`: die Skills rufen die
just-Standardrezepte, die Projekt-Hooks nutzen lefthook + gitleaks. Auf macOS:
`brew install mise just lefthook gitleaks`.

Frisch installierte Skills sind ggf. erst nach einem Session-Neustart sichtbar.

> **Windows:** Beide Wege brauchen eine Bash (Git for Windows) — `install.sh` und die
> Snippets sind Bash, und die Hooks des Plugins rufen `bash` auf. Ausführen in
> derselben Umgebung, in der `claude` läuft: in Git Bash ist `$HOME` das
> Windows-Benutzerverzeichnis, ein Lauf unter WSL schreibt dagegen ins WSL-Home und
> bleibt für eine native Windows-Installation unsichtbar. Die Toolchain kommt dort über
> scoop/winget statt brew.

### Ohne GitHub (nur git)

Für Rechner ohne GitHub-Konto oder mit dem Verbot, Code dorthin zu pushen — etwa
Firmenrechner mit eigenem Git-Host. Voraussetzung ist nur, dass github.com **lesend**
erreichbar ist; ein Login braucht keiner dieser Schritte. Ist auch das Lesen gesperrt,
muss das Plugin (mit dem Template darin) über einen Firmen-Mirror oder Datenträger auf
den Rechner — einen eingebauten Pfad dafür hat das Kit nicht.

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

3. **Toolchain** wie im manuellen Weg (Schritt 4).

Das Template kommt mit dem Plugin; ein eigener Klon ist nicht nötig, und kein Skill fragt
dafür nach GitHub.

**Projekte anlegen:** `/new-project` legt das Repo über `gh repo create` an — das ist der
einzige Schritt, der sich nicht lokal erfüllen lässt. Ersatz: einen leeren Ordner selbst
initialisieren und den Skill darauf ansetzen; er setzt bei einem vorhandenen
Projektordner auf, statt ihn neu anzulegen, und schreibt die Dateien aus dem Template im
Plugin.

```bash
cd "$CODING_KIT_PROJECTS_DIR"
mkdir <name> && cd <name>
git init -b main
git config user.name  "Vorname Nachname"     # lokal, nicht global
git config user.email "adresse@example.org"
```

Die Instanziierung ab Schritt 4b (MANIFEST, Modul, Fragmente, `just check`) läuft lokal;
die Repo-Settings aus 4c entfallen. Die projektübergreifende Discovery
von `/update-conventions alle` findet lokale Projekte über `.claude/template-version` unter
`$CODING_KIT_PROJECTS_DIR`, das Marker-Topic braucht sie dafür nicht.

**Commit-Identität:** Die [globalen Kit-Regeln](#globale-kit-regeln) schreiben die
GitHub-Noreply-Adresse als Pflicht fest und lösen sie über `gh api user` auf. Auf einem
Rechner ohne GitHub ist das die falsche Regel — dort den Abschnitt „Git & Commits" in
`~/.claude/rules/coding-kit.md` auf die Adresse des eigenen Hosts umschreiben, mit einer
Override-Zeile schützen (siehe [Eigene Abweichungen](#eigene-abweichungen-und-ergänzungen))
und `git config user.email` **pro Repo** setzen, damit die Firmenadresse nicht in private
Projekte wandert.

## Tägliche Nutzung

Die Skills erscheinen namespaced als `/coding-kit:<skill>`:

Die Spalte **GitHub** sagt, was ohne GitHub bleibt: `–` = rein lokal über git und just,
`teils` = der Skill läuft, einzelne Teilschritte entfallen (Details unter der Tabelle),
`ja` = braucht GitHub, ohne ist er gegenstandslos.

| Skill | GitHub | Zweck |
|-------|:------:|-------|
| `/coding-kit:new-project` | teils | **Der Orchestrator:** Short-Info → Abfragen (Name/Lizenz/Stack/…, Sub-Skills aufrufbar) → Plan → leeres Repo anlegen und aus dem mitgelieferten Template befüllen (Renderer, Antworten-Datei und Basis-Snapshot im Erst-Commit), verifizieren, Erst-Commit nach OK. Trockenlauf: Argument `dry-run`. |
| `/coding-kit:add-feature` | – | Neue Aufgabe aufnehmen: erst das Problem, dann Beratung (stärkstes Gegenargument, Alternativen, eine von vier Empfehlungen — auch „nicht aufnehmen"), dann eine Datei `features/F-NNN-kurzname.md` mit Status `BACKLOG` und ein Vorschlag für die Reihenfolge; Umsetzungsideen nur als grobe Lösungsskizze. Startest du oder Claude selbst, angelegt wird nach deinem OK. |
| `/coding-kit:prep-step` | – | Feature vor der Umsetzung spezifizieren und planen: Größe S/M/L aus Aufwand, Unsicherheit und Reichweite; Spezifikation in der Tiefe je Größe (Abnahmekriterien, Randfälle, Nicht-Ziele, Tests, Einbettung; ab M Interview, bei L Example Mapping), darf abraten; neue Frameworks, Sprachen und Toolchains per Erkennungs-Skript gegen Fragment-Katalog und Stack-Module prüfen; Substeps planen, Ready prüfen, Status `PLANNED`. |
| `/coding-kit:build-step` | – | Aufgabe plan-treu aus ihrer Feature-Datei umsetzen: Substep für Substep mit Verifikation, Nicht-Ziele als Grenze, Abweichungen gesammelt für step-done. Interaktiv endet jeder Substep mit einer step-done-Empfehlung (du prüfst und schließt selbst ab); nur im autonomen `/goal`-Lauf läuft step-done je Substep automatisch. Mit `autonom` bereitet er stattdessen einen `/goal`-Lauf vor. |
| `/coding-kit:step-done` | teils | Abschluss-Checkliste: Review, `just check`, Erkennungs-Backstop (in diesem Schritt neue Frameworks ohne Fragment, Sprachen ohne Modul, Tools ohne Vorlage), Backstop für geänderte managed Dateien ohne Registry-Zeile, Secrets-Scan, Privacy-Scan der lebenden Doku, Verbuchung in der Feature-Datei (Verlauf-Eintrag, Abnahmekriterien mit Beleg, Status `IN-PROGRESS` bzw. `DONE`, erzeugte Tabelle) und Commit nach einer gemeinsamen Freigabe (Vorschau vor dem Schreiben). |
| `/coding-kit:audit-code` | – | Vollaudit (Code, Security, Deps, Deployment) → `AUDIT-RESULTS.md`, fixt nichts. |
| `/coding-kit:teach-step` | – | Lehrer-Modus: Aufgabe aus ihrer Feature-Datei selbst umsetzen, der Skill leitet sokratisch an, prüft und testet — schreibt nie Code. |
| `/coding-kit:name-it` | teils | Namenskandidaten nach Kriterien + Verfügbarkeits-Checks (GitHub/npm/PyPI, Domain optional). |
| `/coding-kit:choose-license` | – | Kurzinterview → Lizenz-Empfehlung (Default Apache-2.0, „TBD" gültig); im Bestandsprojekt zieht sie Antworten-Datei und lizenzabhängige managed Dateien nach. |
| `/coding-kit:choose-stack` | – | Modul-Empfehlung für Neuanlage oder Nachrüsten/Wechsel EINES Moduls im Bestand (Empfehlung aus den Projektsignalen, Render und Drei-Wege-Merge, Diff + Bestätigung, Snapshot nachgezogen); baut die vom Modul deklarierten Standards-Fragmente komponierbar ein (an ihre Stelle aus dem Render, per Skript), Eigenschafts-Fragmente nachrüstbar auf Bestätigung; hält die Begleithandlungen, die einzelne Fragmente beim Einbau verlangen, samt `FRAGMENTS`-Eintrag und `keep`-Zeilen (referenziert von new-project, update-conventions, prep-step, step-done), und die Regel zum Erzeugen und Prüfen der `mise.lock` mit Plattform-Einträgen (Prüfung per `template-sync.sh lock-check`; referenziert von new-project, update-conventions). |
| `/coding-kit:define-requirements` | – | Interview → Ziele, Nicht-Ziele und Rahmenbedingungen im Überblick der Projekt-CLAUDE.md → je Kern-Feature eine Datei in `features/` (Status `BACKLOG`) mit empfohlener Reihenfolge; fragt die Eigenschafts-Trigger des Fragment-Katalogs ab. |
| `/coding-kit:refine-requirements` | – | Zurück zur Spec: Diagnose mit drei Pfaden; arbeitet auf den Ziel-Abschnitten der CLAUDE.md, den Feature-Dateien und ADRs; teilt Features (`SUPERSEDED`), streicht sie (`DROPPED`), datiert Entscheidungen, plant die Reihenfolge um. |
| `/coding-kit:update-conventions` | teils | Konventions-Sync Template → Projekte (nur abwärts), Update-Fenster aus dem CHANGELOG: managed Dateien per Drei-Wege-Merge gegen den Basis-Snapshot des Projekts (`scripts/template-sync.sh`) — Projektzusätze bleiben, Konflikte kommen mit Lösungsvorschlag; Diff + Bestätigung je Datei, je Standards-Fragment und je markierter seed-Zone (`section:NAME`; Zonen und Fragmente vergleicht und setzt das Skript ein, neue und gestrichene Zonen erkennt es an der Basis des letzten Syncs); Abweichungs-Registry mit den Arten `skip`, `keep`, `adapt` samt Revision; erkennt bei jedem Lauf, wofür das Template inzwischen Module oder Fragmente hat und welche Tools es nicht kennt (dauerhafte Ablehnung als Rules-Zeile); ohne Argument nur das aktuelle Projekt, `alle` für alle, Modi `status` und `revise`; Migration für Projekte ohne Snapshot (Basis aus der Template-Historie) und für Altprojekte; erkennt im Template entfernte/umbenannte Dateien (Rückbau/Umzug je Datei bestätigt); projektlokale Fragmente und Tools ohne Vorlage meldet er mit dem Angebot eines Übernahme-Vorschlags fürs Template (`propose-to-template`); prüft die `mise.lock` per Skript auf Plattform-Einträge für die CI und bietet `mise lock` an. Mit `global` gleicht er die globalen Kit-Regeln auf dem Rechner ab (`~/.claude/rules/coding-kit.md`, Ersteinrichtung und Migration einer alten Kit-Kopie in `~/.claude/CLAUDE.md` inklusive), jeder andere Lauf prüft sie einmal mit; eine selbst angelegte CLAUDE.md fasst er nie an. |
| `/coding-kit:explain-level` | – | Antwortsprache und Erklär-Niveau festlegen: kurzes Interview (Programmieren, Shell, Git, Frameworks, Projekt-Werkzeuge, Code mitlesen) → Vorschlag für Stufe (`einsteiger`, `junior`, `fortgeschritten`, `senior`) und Notiz mit dem Stufentext der Kit-Regeln; schreibt die Werte nach Freigabe in die Personal-Config. Wirksam, sobald `/coding-kit:update-conventions global` die globalen Regeln neu erzeugt; jederzeit erneut aufrufbar. |
| `/coding-kit:check-upstreams` | ja | Watchliste externer Vorbild-Repos prüfen (`upstreams.json`), Neuerungen seit letztem Ref, Übernahme-Vorschläge. |
| `/coding-kit:go-public` | ja | Projekt nachträglich public machen: blockierendes Preflight-Audit (Secrets in der vollen Historie, Privacy inkl. Commit-Metadaten, Lizenz, `private/`-Hygiene), Datei-Nachzug **vor** dem Umstellen (update-conventions mit Sichtbarkeits-Prämisse), dann Sichtbarkeitswechsel bzw. Repo-Anlage + Push nur nach laufbezogener Freigabe; Abschluss-Check (CodeQL, Settings). |
| `/coding-kit:refine-prompt` | – | Übergebenen Prompt analysieren, Schwachstellen benennen, nach Best Practices neu formulieren und ausführen. |
| `/coding-kit:handoff` | – | Am Kontextlimit: kopierfertigen Handoff-Prompt für einen frischen Chat schreiben — übergibt nur, was aus der Session noch nicht dokumentiert ist, verweist sonst auf die Quelldateien; baut und ändert nichts. |
| `propose-to-template` *(Hintergrund)* | – | Kein Slash-Command — Claude startet ihn bei einem Fund: ein Tool ohne Vorlage, ein projektlokales Fragment, eine Abweichung an einer managed Datei, die allen Projekten nützt, oder eine globale Regel für die Kit-Datei. Erzeugt den Übernahme-Vorschlag fürs Template, generalisiert und personendatenfrei, kopierfertig als Issue (Standard, `gh`-Befehl als Text) oder als Prompt für eine Session im Kit-Repo; sendet nichts ab. |

Was bei `teils` konkret entfällt — der Rest des Skills läuft lokal weiter:

- **`new-project`:** die Repo-Anlage über `gh repo create` (Schritt 4a) und die
  Repo-Settings samt Topics (4c). Instanziierung, Verifikation und Erst-Commit sind lokal;
  Ersatz für 4a steht unter [Ohne GitHub](#ohne-github-nur-git).
- **`update-conventions`:** die projektübergreifende Discovery (`alle`) über das
  Marker-Topic (`gh search repos`). Lokale Projekte findet sie weiter über `.claude/template-version`
  unter `$CODING_KIT_PROJECTS_DIR`.
- **`name-it`:** der GitHub-Verfügbarkeitscheck; npm, PyPI und Domain bleiben.
- **`step-done`:** allein die Zeile, die `git config user.email` auf die
  GitHub-Noreply-Adresse setzt. Review, `just check`, Scans und Verbuchung sind lokal.

Die beiden `ja`-Skills: **`go-public`** dreht GitHub-Sichtbarkeit und -Settings, ist ohne
GitHub also gegenstandslos; **`check-upstreams`** liest fremde GitHub-Repos (im Kit über
`gh api`) — ohne `gh` bleibt nur manuelles Nachsehen.

Der übliche Zyklus: `add-feature` → `prep-step` → `build-step` → `step-done` (je Substep).
Interaktiv rufst du `step-done` bewusst selbst auf, wenn du den Substep geprüft hast —
build-step empfiehlt es nur; im autonomen `/goal`-Lauf läuft es automatisch durch. Jede
Aufgabe ist eine Datei `features/F-NNN-kurzname.md`, die mitwächst (Erfassung,
Spezifikation, Plan, Verlauf); `features/INDEX.md` zeigt die empfohlene Reihenfolge
(Nummern verlinkt) und erzeugte Tabellen aller Features — offene oben, erledigte darunter.
Das Feld `status` im Kopfblock zeigt die Station: `BACKLOG` = nur aufgenommen (→
prep-step), `PLANNED` = geplant (→ build-step), `IN-PROGRESS` = erster Substep verbucht,
`DONE` = fertig; dazu `DROPPED` und `SUPERSEDED` für Verworfenes und Aufgegangenes. Für
die Implementierungsphase gibt es drei Wege: `build-step` baut diszipliniert, `teach-step`
leitet dich durch die eigene Umsetzung, oder du implementierst frei und schließt mit
`step-done` ab.

**Freigabe für Feature-Dateien:** Kein Skill schreibt ungefragt eine Feature-Datei,
`features/INDEX.md` oder die Ziel-Abschnitte der Projekt-CLAUDE.md — du siehst den Text
vorher und gibst ihn frei; lange Entwürfe liegen dafür in `private/`. `step-done`
bündelt das mit der Commit-Frage; im autonomen `/goal`-Lauf gilt die Freigabe beim Start
für die geplanten Substeps, neue Ideen werden gesammelt und am Ende vorgeschlagen.

### update-conventions: die Aufrufe

`/coding-kit:update-conventions` holt, was das Kit inzwischen anders macht — in Projekte
und auf den Rechner, immer nur abwärts und nie ohne deine Bestätigung je Datei bzw.
Abschnitt:

| Aufruf | Wann | Was passiert |
|--------|------|--------------|
| `/coding-kit:update-conventions` | im Projekt, nach einem Plugin-Update | Projekt abgleichen (managed Dateien, Fragmente, seed-Zonen, Lock-Datei); danach einmal die globalen Kit-Regeln, sofern eingerichtet |
| `… <pfad>` oder `… <name>` | ein anderes Projekt | wie oben, für dieses Projekt |
| `… alle` | alle Projekte auf einmal | Liste bestätigen, dann je Projekt; danach einmal die globalen Kit-Regeln |
| `… global` | Ersteinrichtung der Kit-Regeln, nach einer Änderung der Werte, nach dem Hinweis beim Session-Start | nur die [globalen Kit-Regeln](#globale-kit-regeln), auch außerhalb eines Projekts |
| `… status` | vorher sehen, was käme | nur Bericht, schreibt nichts (auch nicht global) |
| `… revise` | die Abweichungs-Registry aufräumen | nur die Registry-Revision, ohne globale Regeln |

`global <ordner>` nimmt einen anderen Ordner als `~/.claude` — gedacht für Tests, das
echte `~/.claude` bleibt dabei unberührt.

### Autonomer Lauf (build-step + /goal)

Ganze Features samt Substeps unbeaufsichtigt bauen lassen — über den eingebauten
Claude-Code-Befehl `/goal`, der die Session Turn für Turn weiterarbeiten lässt, bis
eine Abschlussbedingung erfüllt ist:

1. `/coding-kit:prep-step F-NNN` — Spezifikation und Plan mit Substeps stehen in der
   Feature-Datei.
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

- **Feuert nur in Kit-Projekten:** erkannt an einer Datei `.claude/template-version`,
  an `features/INDEX.md` **oder** — bis zur Migration — an einer `PROGRESS.md` mit
  `FEATURE-INDEX`-Block. In allen anderen Repos ist der Hook vollständig still.
- **Loop-Schutz:** pro Stopp maximal eine Erinnerung (`stop_hook_active`).
- Als „uncommitted" zählen geänderte und neue (nicht ignorierte) Dateien; `private/` und
  anderes Gitignoriertes lösen nichts aus.
- Abschalten: Plugin deaktivieren (`claude plugin disable coding-kit`) oder committen. 😉

### Session-Hinweis

Ein zweiter Hook läuft beim Start einer Session und meldet sich in einer Zeile, wenn die
[globalen Kit-Regeln](#globale-kit-regeln) einen Abgleich brauchen — Claude sagt es dir
dann einmal:

- `~/.claude/CLAUDE.md` ist noch eine Kopie der früheren Kit-Vorlage;
- die Kit-Regeln oder deine Werte haben sich seit dem letzten Abgleich geändert (etwa
  nach einem Plugin-Update oder einer Änderung der Personal-Config);
- die Personal-Config lässt sich nicht lesen.

Er liest nur, schreibt nichts und schweigt, wenn du die globalen Regeln nicht eingerichtet
hast oder eine eigene Datei unter `~/.claude/rules/coding-kit.md` liegt. Abgelehnte
Änderungen meldet er nicht erneut, erst die nächste Änderung des Kits oder der Werte.

## Renovate-Preset

`default.json` im Repo-Root ist ein Shareable Preset; Projekte binden es so an:

```json
{ "extends": ["github>xnyzer/coding-kit"] }
```

Inhalt: `config:recommended` + Digest-Pinning für GitHub Actions + Label `dependencies`.
Details und die (bewusst manuelle) App-Installation: [docs/renovate-preset.md](docs/renovate-preset.md).

## Globale Kit-Regeln

Die Haus-Regeln des Kits für jede Claude-Session: Antwortsprache, Erklär-Niveau, Git- und
Commit-Regeln, Graphiti, Arbeitsweise. Sie kommen mit dem Plugin
(`plugins/coding-kit/global/coding-kit.md`) und liegen auf dem Rechner als
`~/.claude/rules/coding-kit.md` — Claude Code lädt jede Datei in `~/.claude/rules/` in
jeder Session, wie die CLAUDE.md. Eingerichtet und abgeglichen werden sie mit
`/coding-kit:update-conventions global`.

> **Was das Kit mit deinen globalen Claude-Einstellungen macht**
>
> - **Es legt eine eigene Datei an:** `~/.claude/rules/coding-kit.md`, nur nach deiner
>   Bestätigung. Sie gehört dem Kit; nach Plugin-Updates bietet `update-conventions` die
>   Änderungen abschnittsweise an, wieder mit Diff und Bestätigung.
> - **Deine `~/.claude/CLAUDE.md` schreibt das Kit nie.** Einzige Ausnahme: Sie ist eine
>   Kopie der früheren Kit-Vorlage (Titel „Globale House-Defaults — Claude Code",
>   darunter „Gepflegt als Vorlage im coding-kit …"). Dann bietet
>   `update-conventions global` an, den Kit-Teil herauszunehmen; persönliche Zeilen
>   bleiben, und du siehst den Diff vorher. Bleibt nichts Persönliches übrig, schlägt es
>   vor, die Datei zu löschen.
> - **Widersprüche:** Claude Code lädt CLAUDE.md und Kit-Regeln zusammen, ohne Vorrang.
>   Widersprechen sie sich, folgt Claude einer beliebigen Seite. Der Abgleich weist darauf
>   hin; auflösen kannst du es wie unter
>   [Eigene Abweichungen](#eigene-abweichungen-und-ergänzungen) beschrieben.
> - **Eine fremde Datei** unter `~/.claude/rules/coding-kit.md` — ohne die Kennung des
>   Kits in der ersten Zeile — fasst das Kit nicht an.
> - Mit `CLAUDE_CONFIG_DIR` gilt statt `~/.claude` dieser Ordner.

### Antwortsprache und Erklär-Niveau

Drei Werte in der [Personal-Config](#personal-config) bestimmen, wie Claude mit dir
spricht:

```sh
CODING_KIT_REPLY_LANGUAGE=""  # Sprache der Antworten, z. B. Deutsch, English; leer = Claude-Standard
CODING_KIT_EXPLAIN_LEVEL=""   # einsteiger | junior | fortgeschritten | senior; leer = Claude-Standard
CODING_KIT_EXPLAIN_NOTE=""    # freier Text, präzisiert die Stufe; leer = keine Notiz
```

| Stufe | Wie Claude antwortet |
|-------|----------------------|
| `einsteiger` | wenig oder keine Programmiererfahrung: einfache Sprache, jeder Fachbegriff erklärt, eine Frage auf einmal, bei größeren Änderungen der Hinweis, was sich zu lesen lohnt |
| `junior` | Grundlagen sitzen, Frameworks und Werkzeuge sind neu: Zusammenhänge und das Warum erklärt, übliche Wege genannt und einer empfohlen |
| `fortgeschritten` | selbstständig: nur Neues, Ungewöhnliches und Abwägungen erklärt |
| `senior` | knapp und in Fachsprache, Trade-offs und Risiken, Details auf Nachfrage |

Die Notiz ergänzt die Stufe um das, was keine Stufe ausdrückt (z. B. „Python sicher, Git
und Frameworks neu"); bei einem Widerspruch gilt die Notiz. Das Niveau betrifft nur
Claudes Antworten, Rückfragen, Pläne und Zusammenfassungen — nie den Code, die Commits
oder die Doku im Projekt; dafür gelten die Coding-Regeln.

- **Setzen:** `/coding-kit:explain-level` — ein kurzes Interview zu Programmieren, Shell,
  Git, Frameworks und Projekt-Werkzeugen, danach ein Vorschlag für Stufe und Notiz.
  `update-conventions global` startet es selbst, wenn Werte fehlen. Einen Wert, den du
  bewusst leer lässt, fragt kein Lauf erneut ab.
- **Ändern:** `/coding-kit:explain-level` erneut aufrufen oder die Zeile in der env-Datei
  ändern — **danach `/coding-kit:update-conventions global`**. Nur die env-Datei zu ändern
  reicht nicht: Die Regeln auf dem Rechner entstehen erst beim Abgleich neu; der
  [Session-Hinweis](#session-hinweis) erinnert daran.

### Eigene Abweichungen und Ergänzungen

| Wunsch | Weg |
|--------|-----|
| Antwortsprache, Erklär-Niveau | die Werte oben — nicht die Regeldatei ändern |
| Eine Kit-Regel anders | den Abschnitt in `~/.claude/rules/coding-kit.md` ändern und darin eine eigene Zeile `<!-- override: Grund -->` ergänzen; der Abgleich lässt ihn dann stehen |
| Eine Kit-Regel gar nicht | die beiden `section:`-Markerzeilen des Abschnitts löschen; der Abgleich bietet ihn nie wieder an |
| Eigene Zusatzregeln | in `~/.claude/CLAUDE.md`, die das Kit nie anfasst |
| In einem Projekt anders | in der Projekt-CLAUDE.md, wo die Kit-Regel das vorsieht (z. B. der Languages-Block) |

Nicht das Gegenteil einer Kit-Regel in die CLAUDE.md schreiben — Claude folgt dann
beliebig einer Seite. Eine allgemein nützliche Regel aus deiner CLAUDE.md bietet der
Abgleich als Vorschlag fürs Kit an.

## Personal-Config

`~/.claude/coding-kit.env` (dotenv, shell-sourcebar, **nie committen**; mit
`CLAUDE_CONFIG_DIR` in diesem Ordner) — legt der Installer an. Enthält, was nicht zur
Laufzeit ermittelbar ist, plus Offline-Fallbacks:

| Schlüssel | Bedeutung |
|-----------|-----------|
| `CODING_KIT_GITHUB_LOGIN` | GitHub-Login (Fallback; primär via `gh api user`) |
| `CODING_KIT_GIT_AUTHOR_NAME` | Git-Autorname |
| `CODING_KIT_GIT_NOREPLY_EMAIL` | GitHub-Noreply-Adresse für Commits |
| `CODING_KIT_PROJECTS_DIR` | Wurzelverzeichnis der Projekte |
| `CODING_KIT_REPLY_LANGUAGE` | Antwortsprache der [globalen Kit-Regeln](#antwortsprache-und-erklär-niveau) |
| `CODING_KIT_EXPLAIN_LEVEL` | Erklär-Niveau: `einsteiger`, `junior`, `fortgeschritten` oder `senior` |
| `CODING_KIT_EXPLAIN_NOTE` | Notiz, die die Stufe präzisiert |

Die letzten drei setzt `/coding-kit:explain-level`; wirksam werden sie mit
`/coding-kit:update-conventions global`.

## Repo-Struktur

```
.claude-plugin/marketplace.json   Marketplace „xnyzer" (Quelle: dieses Repo)
plugins/coding-kit/               Das Plugin
  .claude-plugin/plugin.json      Name, Version (gilt für Skills und Template), Beschreibung
  CHANGELOG.md                    Ein CHANGELOG ab 1.0.0, darunter die eingefrorenen Reihen
  skills/<name>/SKILL.md          Die Skills (ein Ordner je Skill)
  hooks/hooks.json + *.sh         Projekterkennender Stop-Hook und Session-Hinweis
  global/coding-kit.md            Globale Kit-Regeln (→ ~/.claude/rules/coding-kit.md, deutsch)
  scripts/template-sync.sh        Rendern, Drei-Wege-Merge, Snapshot und Erkennung (von Skills aufgerufen)
  template/                       Projekt-Template (englisch): MANIFEST.md, core/, modules/
default.json                      Renovate-Shareable-Preset (Root = Preset-Konvention)
upstreams.json                    Watchliste für /check-upstreams (persistierte Refs)
docs/                             Pflege-Doku (Skill-Authoring, Renovate-Preset, Verlauf der TPL-Reihe)
install.sh                        Neuer-Rechner-Bootstrap (idempotent)
scripts/validate.py               Validator für Kit, Template und Vertrag (`just check` + CI)
scripts/version-rule.py           Versionsregel (Pre-Commit + CI, `just version-rule`)
tests/template-sync/              Tests des Skripts und des Session-Hinweises unter dash und bash, dazu mawk/gawk (`just test`)
features/                         Aufgaben (F-NNN): je Feature eine Datei, INDEX.md als Übersicht
private/                          Gitignoriert — private Notizen/Quellen
```

## Pflege

- Regeln für neue/geänderte Skills: [docs/skill-authoring.md](docs/skill-authoring.md).
- Installierte Version aktualisieren: `claude plugin marketplace update xnyzer`, dann
  `claude plugin update coding-kit@xnyzer` (voll qualifiziert — der kurze Name wird
  nicht gefunden); Session-Neustart wendet die Änderung an.
- Jede inhaltliche Änderung an Skills, Hooks, Skripten oder Template braucht eine Version
  über dem gepushten Stand in `plugin.json` und einen Eintrag in
  `plugins/coding-kit/CHANGELOG.md` (Template-Änderungen im Abschnitt `### Template`, den
  `/update-conventions` Projekten zeigt); `just version-rule` prüft das vor jedem Commit
  und in der CI.
- Skills und Template testen: `claude --plugin-dir plugins/coding-kit` — eine normale
  Session im Repo läuft mit dem installierten Plugin, nicht mit dem Arbeitsstand.
- `just setup` installiert die Git-Hooks (gitleaks, Validator, Versionsregel; die
  Skript-Tests, wenn Skript, Template oder Tests sich ändern), `just check` ist das
  Vollgate — muss vor jedem Commit grün sein.
- Für Arbeit an `template-sync.sh` mawk installieren (`brew install mawk`), optional
  gawk: Die Skript-Tests laufen dann zusätzlich mit ihnen. mawk ist das Standard-awk auf
  Debian und Ubuntu, gawk auf Fedora und Arch, und das macOS-awk nimmt mehr hin als beide.
  Beide bleiben optionale lokale Werkzeuge (GPL), nicht Teil der Toolchain.
- Aufgaben laufen als F-Nummern in `features/` — das Kit nutzt seine eigenen Skills
  (Dogfooding). `just features-index` erzeugt die Tabelle in `features/INDEX.md`; das
  Skript kommt aus dem Template (`plugins/coding-kit/template/core/scripts/`).

## Lizenz

Apache-2.0 — siehe [LICENSE](LICENSE).
