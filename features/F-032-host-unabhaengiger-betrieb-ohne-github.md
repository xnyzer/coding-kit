---
id: F-032
title: Git-Host je Projekt festhalten, mit Grundstufe nur Git
type: feature
status: IN-PROGRESS
size: L
created: 2026-10-19
done:
depends-on:
superseded-by:
---

# F-032 — Git-Host je Projekt festhalten, mit Grundstufe nur Git

## Erfassung

**Problem:** Das Kit setzt GitHub voraus: `gh` bzw. `gh api user` steckt im Installer,
in `new-project` (Repo-Anlage, Settings, Topics, Autor-Config), `step-done`
(Noreply-Pflicht), `update-conventions` (Topic-Discovery, Template-Issue), `go-public`,
`name-it`, `check-upstreams` und `choose-stack`; dazu das Renovate-Preset (`github>…`)
und die CI unter `.github/`. Ohne GitHub-Konto — oder mit GitLab, Forgejo/Gitea,
Bitbucket, Azure DevOps, Codeberg, einem eigenen Server oder einem Bare-Repo auf
Platte/NAS — scheitern Skills an `gh`, statt den Schritt auszuweisen. Nimmt F-023
(new-project ohne GitHub) vollständig auf; dessen offene Frage „zentral oder lokal
erkennen" ist hiermit entschieden: zentral.

**Idee:** Ein zentrales Host-Profil beschreibt, welcher Git-Server im Spiel ist und
welche Fähigkeiten er bietet (Repo anlegen, Repo-Settings, Topics/Discovery, Issues,
Noreply-Adresse, Renovate, CI). Skills fragen Fähigkeiten ab statt `gh` aufzurufen;
fehlt eine, wird der Schritt ausgewiesen übersprungen, nicht durch Fehlschlag. Die
unterste Stufe „nur Git" (Bare-Repo oder gar kein Remote) muss immer vollständig
tragen.

**Lösungsskizze:**
- Beschlossen (2026-11-03): Der Host gehört dem Projekt (`HOST` in den
  Template-Antworten), der Remote liefert nur den Vorschlag; die Personal-Config trägt
  je Host eine Commit-Adresse. Die Fähigkeiten je Host stehen im MANIFEST, die Skills
  referenzieren sie — keine `gh`-Aufrufe mehr verstreut in den Skills.
- Host-Klassen nach Recherche: gehostet (GitHub, GitLab.com, Bitbucket Cloud, Azure
  DevOps, Codeberg, SourceHut), selbst gehostet (GitLab CE/EE, Forgejo, Gitea, Gogs,
  OneDev, Bitbucket Data Center, Gerrit), minimal/lokal (Bare-Repo via `file://`/SSH,
  Gitolite, Soft Serve, `git daemon`), Peer-to-Peer (Radicle). CLIs je nach Host
  (`gh`, `glab`, `tea`, `fj`/`berg`, `az repos`) — Pflegestand zur Planungszeit prüfen.
- `new-project` lokaler Bootstrap (aus F-023): `git init` statt `gh repo create` — das
  Template kommt seit F-039 aus dem Plugin, ein Checkout ist nicht nötig; Autor-Config
  aus der Personal-Config; Repo-Settings/Topics nur, wo der Host sie kann — Discovery
  trägt sonst der `.claude/template-version`-Stempel. README-Abschnitt
  „Ohne GitHub" auf den Skill-Pfad umstellen.
- Renovate: offiziell Azure, Bitbucket (Cloud/Server), Forgejo, Gitea, GitHub, GitLab;
  Gerrit und `local` experimentell. Preset-Referenz je Host klären.
- CI: GitHub Actions, Forgejo/Gitea Actions (weitgehend kompatibel), GitLab CI,
  Woodpecker, Bitbucket Pipelines, Azure Pipelines — Template-Seite betroffen
  (im selben Commit).
- Der GitHub-Request im Übernahme-Vorschlag (`update-conventions`, seit F-039 ein Issue
  im coding-kit-Repo) braucht einen Weg ohne `gh`; der kopierfertige Prompt für eine
  Kit-Session kommt bereits ohne aus.
- Template-Seite neben CI und Renovate: die Noreply-Regel in den Vorlagen (siehe
  F-024) — gemeinsam im selben Commit.
- Aus F-026: `check-upstreams` leitet das Kit-Repo aus `gh api user` ab — das trägt nur
  beim Eigentümer und nie ohne `gh`. Die kanonische Quelle deklarieren (wie der
  Marketplace seine Quelle nennt), Personal-Config als Override.
- Publishing-Hygiene: Basis-URLs und Hostnamen selbst gehosteter Server sind privat —
  nur in der Personal-Config, nie im Repo oder in der lebenden Doku; Credentials
  bleiben im Store der jeweiligen CLI.

**Abhängigkeiten:** F-039 (Template-Gegenstücke entstehen im selben Commit). F-024 geht
in F-032 auf; F-025 und die Hosts F-052 (Azure DevOps), F-053 (GitLab) und F-054
(Forgejo) bauen auf F-032 auf.

**Noch zu analysieren** (beantwortet in Spezifikation und Plan):
- Welche Hosts in der ersten Ausbaustufe voll unterstützt werden (Vorschlag: GitHub,
  Forgejo/Gitea, GitLab, „nur Git"), welche nur als „nur Git" laufen.
- Liefert das Template mehrere CI-Varianten, oder wählt `new-project` je Host eine?
- Lässt sich die Arbeit sinnvoll in Substeps schneiden (Profil + Erkennung → Skills je
  Fähigkeit → Installer/Template)?

## Spezifikation

### Stories (priorisiert)

1. Als Nutzer ohne Remote oder ohne Host-Konto will ich den ganzen Zyklus nutzen — von
   new-project bis step-done —, ohne dass ein Skill an `gh` scheitert; Host-Schritte
   werden ausgewiesen übersprungen.
2. Als Nutzer mit mehreren Hosts auf einem Rechner will ich, dass jedes Projekt die
   Commit-Adresse seines Hosts bekommt und nie die eines anderen.
3. Als Nutzer bestehender GitHub-Projekte will ich, dass für mich alles bleibt, wie es
   ist.
4. Als Nutzer bestehender Projekte nur mit Git will ich beim Update gefragt werden, ob
   das Projekt auf einen Host umzieht und auf welchen — oder bei Git bleibt.
5. Als Nutzer will ich ein Projekt später auf einen anderen Host umziehen können —
   etwa von GitHub zu Azure DevOps oder zurück zu „nur Git“ —, ohne die Konventionen
   von Hand umzubauen.
6. Als Pflegender des Kits will ich die Fähigkeiten der Hosts an einer Stelle
   beschreiben, damit F-052 bis F-054 dort und in ihren Vorlagen ergänzen, statt Skills
   zu durchkämmen.

### Regeln mit Beispielen

| Regel | Beispiel | Gegenbeispiel |
|---|---|---|
| R1 Das Projekt hält seinen Host fest: `HOST` in `.claude/template-answers` (`github`, `git`; später `azure`, `gitlab`, `forgejo`) | new-project, Host GitHub gewählt → `HOST=github` | Den Host aus dem Rechner ableiten — die Personal-Config liefert nur die Vorauswahl |
| R2 Der Remote ist nur Vorschlag und Gegenprobe | `origin` = `https://github.com/o/r.git` → Vorschlag `github` | Ein Remote auf einen noch nicht unterstützten Host (`dev.azure.com`) → `git` mit Hinweis auf den erkannten Host |
| R3 Fähigkeiten stehen an einer Stelle; Skills fragen dort, statt `gh` fest einzubauen | Projekt `HOST=git`, go-public will die Sichtbarkeit umstellen → „übersprungen: Sichtbarkeit — Host git hat keine“ | Ein Skill ruft `gh` auf und scheitert mit einer Fehlermeldung |
| R4 Commit-Adresse je Host aus der Personal-Config | `HOST=github` → `CODING_KIT_EMAIL_GITHUB`; fehlt sie, `gh api user`, sonst fragen | Ein Projekt `HOST=git` bekommt die GitHub-Adresse, weil sie zufällig gesetzt ist |
| R5 Template-Ziele je Host | `HOST=git` → keine `.github/`-Dateien, keine `renovate.json` | `HOST=github` → anders als heute |
| R6 Bestandsprojekte: GitHub bleibt, Git wird gefragt | Projekt ohne `HOST` mit GitHub-Remote → update-conventions trägt `HOST=github` ein, ohne eigene Frage, und nennt es im Bericht; Projekt ohne GitHub-Remote → Frage: bei Git bleiben oder umziehen, und wohin (in F-032 nur GitHub; F-052 bis F-054 ergänzen ihre Hosts) | Bestandsprojekt bekommt ungefragt `HOST=git`; ein Umzug legt ohne Bestätigung ein Repo an oder pusht |
| R7 Der Host lässt sich jederzeit wechseln: `update-conventions host` — derselbe Weg wie der Umzug in R6 | Projekt `HOST=github`, Wechsel nach `git` → `HOST=git`, die GitHub-Dateien werden je Datei zum Entfernen angeboten, der Remote bleibt | Ein Wechsel löscht oder archiviert das alte Repo, schreibt die Historie um oder pusht ungefragt |

### Abnahmekriterien

- [x] AC-1 — Gegeben ein Projekt, wenn `template-sync.sh host <projekt>` läuft, dann
  nennt es Host und Quelle: `HOST` aus den Antworten, sonst Vorschlag aus `origin`
  (`github`), ohne Remote oder bei Bare-Repo/unbekanntem Host `git`; ein noch nicht
  unterstützter, aber erkannter Host (Azure, GitLab, Forgejo) wird als solcher genannt
  und läuft als `git` — belegt: Skript-Tests in `tests/template-sync/host.sh` (alle
  Remote-Formen und erkannten Hosts), `just check` grün.
- [x] AC-2 — Gegeben `HOST` in den Antworten und ein Remote auf einen anderen Host, wenn
  `host` läuft, dann gilt `HOST` und der Widerspruch wird gemeldet; ein ungültiger
  `HOST`-Wert bricht mit der Liste der gültigen Werte ab — belegt: Skript-Tests in
  `tests/template-sync/host.sh` (Widerspruch; ungültiger, leerer und Listen-Wert
  abgelehnt).
- [ ] AC-3 — Gegeben new-project mit Host `git`, wenn der Lauf durchgeht, dann entsteht
  das Projekt per `git init` lokal, ohne `gh`-Aufruf, ohne `.github/` und
  `renovate.json`, `just check` ist grün, der Erst-Commit hat die Adresse aus
  `CODING_KIT_EMAIL_GIT`, und der Bericht nennt die übersprungenen Schritte (Repo
  anlegen, Settings, Topics).
- [ ] AC-4 — Gegeben ein GitHub-Projekt, wenn new-project, go-public, name-it,
  check-upstreams, propose-to-template, update-conventions oder step-done laufen, dann
  verhalten sie sich wie vor F-032 (Regression).
- [ ] AC-5 — Gegeben eine Personal-Config mit Adressen für `github` und `git`, wenn
  step-done in einem Projekt committet, dann setzt es `user.email` lokal auf die Adresse
  seines Hosts; fehlt sie, fragt es, statt zu raten — nie die Adresse eines anderen
  Hosts.
- [ ] AC-6 — Gegeben ein Projekt `HOST=git`, wenn go-public, name-it, check-upstreams,
  propose-to-template oder die Projektsuche von update-conventions laufen, dann ruft
  keiner `gh` auf; jeder weist den Schritt aus (propose-to-template gibt den Text
  kopierfertig aus).
- [ ] AC-7 — Gegeben `HOST=github`, `gh` installiert, aber nicht angemeldet, wenn ein
  Skill einen Host-Schritt braucht, dann weist er ihn mit dem Hinweis `gh auth login`
  aus und läuft weiter.
- [ ] AC-8 — Gegeben ein Bestandsprojekt ohne `HOST` mit GitHub-Remote, wenn
  update-conventions läuft, dann trägt es `HOST=github` ohne eigene Frage ein, nennt das
  im Bericht und ändert am Render sonst nichts.
- [ ] AC-9 — Gegeben eine Personal-Config mit den alten Schlüsseln
  (`CODING_KIT_GIT_NOREPLY_EMAIL`, `CODING_KIT_GITHUB_LOGIN`), wenn `update-conventions
  global` läuft, dann bietet es die Umbenennung auf die Schlüssel je Host an; bis dahin
  gelten die alten Werte als GitHub-Werte.
- [ ] AC-10 — Gegeben ein Bestandsprojekt ohne `HOST` und ohne GitHub-Remote, wenn
  update-conventions läuft, dann fragt es: bei Git bleiben (`HOST=git`) oder umziehen,
  mit der Liste der unterstützten Hosts. Der Umzug läuft wie der Wechsel in AC-11.
  Bricht ein Schritt ab, bleibt `HOST` unverändert und der Bericht nennt, was schon
  geschehen ist.
- [ ] AC-11 — Gegeben ein Projekt mit `HOST`, wenn `update-conventions host` läuft, dann
  nennt es den aktuellen Host und bietet die übrigen unterstützten Hosts und `git` an.
  Nach der Wahl zeigt es die Schritte: Repo auf dem Ziel privat anlegen (nicht bei
  `git`), alten `origin` unter dem Namen des alten Hosts behalten, neuen `origin`
  setzen, `HOST` umstellen, Host-Ziele neu rendern — neue Dateien je Datei bestätigt,
  Dateien des alten Hosts je Datei zum Entfernen angeboten (Mechanik der entfernten
  Ziele, A2 Schritt 8). Erst nach Bestätigung führt es sie aus; Branches und Tags pusht
  es nur auf eigene, ausdrückliche Bitte. Ab dann gilt die Commit-Adresse des neuen
  Hosts; frühere Commits bleiben unverändert.

### Randfälle

- EC-1 — Mehrere Remotes → `origin` zählt; ohne `origin` gilt kein Remote (Vorschlag
  `git`, Hinweis).
- EC-2 — GitHub Enterprise Server oder ein anderer unbekannter Hostname → `git` mit
  Hinweis.
- EC-3 — Remote ist ein Bare-Repo auf Platte oder NAS (Pfad, `file://`, SSH ohne
  bekannten Host) → `git`; Push und Pull laufen über git wie gewohnt.
- EC-4 — Der Remote zieht auf einen anderen Host um, oder ein Projekt `HOST=git` hat
  einen Remote auf einem inzwischen unterstützten Host → `host` meldet den Widerspruch;
  update-conventions bietet den Umzug wie in AC-10 an, sonst bleibt `HOST`.
- EC-5 — `HOST=git` und ein Template-Ziel braucht `{{OWNER}}` (Issue-Vorlagen,
  Go-Modulpfad) → die Issue-Vorlagen entfallen mit `.github/`; der Go-Modulpfad wird
  ohne Host gebildet (nur der Projektname).
- EC-6 — Personal-Config fehlt ganz → Adresse wird erfragt und nur im Projekt gesetzt
  (`--local`), nicht in die Personal-Config geschrieben ohne OK.
- EC-7 — Umzug eines Projekts mit `VISIBILITY=public` → das Repo entsteht privat;
  öffentlich wird es über go-public mit dessen Prüfungen (Hinweis im Bericht).
- EC-8 — Projekt ohne `HOST` mit Remote auf einem erkannten, noch nicht unterstützten
  Host (z. B. GitLab) → die Frage empfiehlt „bei Git bleiben“ mit Hinweis auf die
  Folge-Nummer; kein Umzugsangebot weg von diesem Host ohne ausdrückliche Wahl.
- EC-9 — Das Repo-Anlegen scheitert (Name vergeben, `gh` nicht angemeldet) → nichts
  weiter geändert, `HOST` bleibt leer, die Frage kommt beim nächsten Lauf wieder.
- EC-10 — Uncommittete Änderungen im Projekt → der Wechsel startet nicht; erst
  committen oder zurückstellen.
- EC-11 — Ziel ist der aktuelle Host → nichts zu tun, Meldung.
- EC-12 — Der Name für den alten Remote ist schon belegt (es gibt schon einen Remote
  `github`) → nachfragen, wie der alte Remote heißen soll; nichts überschreiben.
- EC-13 — Eine Datei des alten Hosts ist eine registrierte Abweichung (`keep`) oder
  geändert → beim Entfernen mit Diff zeigen; Ablehnen lässt sie liegen und meldet sie.

### Nicht-Ziele

- Azure DevOps, GitLab, Forgejo (→ F-052, F-053, F-054); bis dahin laufen sie als `git`
  mit Hinweis.
- Installer (→ F-025), Windows (→ F-027).
- GitHub Enterprise Server, Bitbucket und weitere Hosts.
- Renovate und CI für `git` — ohne Plattform gibt es beides nicht.
- Kein Weg, das Plugin selbst ohne Lesezugriff auf github.com zu installieren.
- Kein Übertragen von Issues, Pull Requests, Wiki, CI-Secrets und Repo-Einstellungen
  zwischen Hosts — der Bericht nennt sie als Handarbeit.
- Das alte Repo wird beim Wechsel weder gelöscht noch archiviert — der Bericht erinnert
  daran.
- Keine Umschreibung der Historie auf die neue Commit-Adresse.

### Tests

- AC-1, AC-2, EC-1 bis EC-4: Skript-Tests (neue Datei in `tests/template-sync/`) unter
  dash und bash, System-awk und mawk — Remote-Fixtures in HTTPS-, SSH- und scp-Form,
  Pfad, `file://`, unbekannter Host, Antworten gegen Remote, ungültiger Wert.
- AC-3, EC-5: Render-Test `HOST=git` gegen `github` (Ziele); Headless-Lauf new-project
  mit `--plugin-dir` in einem Wegwerf-Ordner ohne Remote.
- AC-4: Headless-Lauf new-project `dry-run` mit GitHub; Render `HOST=github` byte-gleich
  zum Render vor F-032.
- AC-5, AC-9, EC-6: Skript-Tests für die neuen Schlüssel (`set-global`, Lesen mit
  Altschlüsseln); Headless-Lauf step-done an einem Testprojekt `HOST=git`.
- AC-6, AC-7: Check — grep: `gh` nur noch an Stellen, die vorher nach dem Host fragen;
  Headless-Lauf propose-to-template mit `HOST=git`.
- AC-8: Headless-Lauf update-conventions an einer Kopie eines Testprojekts ohne `HOST`
  mit GitHub-Remote.
- AC-10, EC-7 bis EC-9: Headless-Lauf update-conventions an einer Kopie ohne Remote —
  Antwort „bei Git bleiben“; der Umzug mit Repo-Anlage manuell an einem Wegwerf-Repo
  (privat, danach gelöscht).
- AC-11, EC-10 bis EC-13: Headless-Lauf `update-conventions host` an einer Testkopie
  `HOST=github` → `git` (Dateien entfernt, Remote bleibt, keine Netzaktion); Wechsel mit
  Repo-Anlage manuell an einem privaten Wegwerf-Repo, danach gelöscht.

### Einbettung

- Berührt: MANIFEST (Schlüssel `HOST`, Abschnitt mit den Fähigkeiten je Host, Host-Ziele
  wie die public-only-Ziele), `template-sync.sh` (Befehl `host`, Render nach `HOST`,
  neue Personal-Config-Schlüssel, Migration), Skills new-project, step-done, go-public,
  name-it, check-upstreams, propose-to-template, update-conventions; globale Regeln
  (Zone `global-git`); Template-Texte zur Commit-Adresse (CLAUDE.md, CODING-STANDARDS,
  CONTRIBUTING, HOW-TO, privacy-lint); README (Abschnitt „Ohne GitHub“ wird „Nur Git“,
  Personal-Config-Schlüssel); `install.sh` schreibt die neuen Schlüssel (der Rest bleibt
  F-025).
- Version: Minor-Release mit Abschnitt `### Template` (neuer Antworten-Schlüssel,
  Host-Ziele).
- Widerspruch zu Zielen oder Nicht-Zielen der Kit-CLAUDE.md: keiner. Die Rahmenbedingung
  „baut auf GitHub auf“ wird nach F-054 umformuliert (eigene Freigabe, Ziel-Abschnitt).
- Folge-Nummern: F-052, F-053, F-054; F-024 geht auf.

### Offene Fragen

- [x] Steht die Fähigkeiten-Tabelle im MANIFEST oder in einer eigenen Datei im Plugin?
  — Im MANIFEST, siehe Plan.

### Entscheidungen

- 2026-11-03 — Breites Host-Profil. Empfehlung war GitHub plus „nur Git“; entschieden
  breit, weil in der Firma Azure DevOps gebraucht wird.
- 2026-11-03 — Erste Ausbaustufe: GitHub, GitLab, Forgejo, Azure DevOps Services und
  „nur Git lokal“ als Grundstufe; weitere Hosts laufen als „nur Git“.
- 2026-11-03 — Azure DevOps in der Cloud-Variante (Services); getestet mit einer
  kostenlosen eigenen Organisation, ohne Firmendaten.
- 2026-11-03 — Zuschnitt nach Host statt nach Schicht: jede Nummer ist für sich nutzbar
  und an einem Host getestet.
- 2026-11-03 — Eine Commit-Adresse je Host in der Personal-Config, weil auf einem
  Rechner Projekte verschiedener Hosts nebeneinander laufen.
- 2026-11-03 — Der Host gehört dem Projekt, nicht dem Rechner (wie die Ablage in F-033).
- 2026-11-03 — Bestandsprojekte: GitHub-Projekte bekommen `HOST=github` ohne Frage;
  Projekte nur mit Git werden gefragt, ob und wohin sie umziehen (Nutzerwunsch, statt
  nur einen Vorschlag aus dem Remote zu machen).
- 2026-11-03 — Hostwechsel jederzeit über `update-conventions host` statt eines eigenen
  Skills: Render, Merge und das Entfernen alter Ziele stecken schon dort; ein eigener
  Skill müsste sie doppeln. Der Umzug von „nur Git“ (AC-10) ist derselbe Ablauf.

## Plan

**Größe:** L — 7 Skills, das Sync-Skript, Template-Ziele mit Migration der
Bestandsprojekte, globale Regeln, Installer und README; Vorlage für jedes
Downstream-Projekt.

**Ansatz:** Der Host ist ein Antworten-Schlüssel wie `VISIBILITY` und steuert die
Template-Ziele über dieselbe Mechanik wie die public-only-Ziele: eine neue Policy
`host:NAME` in der Core-Tabelle des MANIFEST. Fehlt `HOST` in den Antworten, rendert das
Skript wie `github` — Bestandsprojekte bleiben byte-gleich, bis update-conventions den
Wert einträgt. Die Fähigkeiten je Host stehen in einem neuen Abschnitt `## Hosts` im
MANIFEST (beantwortet die offene Frage): Das MANIFEST ist schon der Vertrag zwischen
Skills und Template, die Skills lesen es ohnehin, und `just check` prüft es mechanisch.
Ein neuer Skript-Befehl `host` liefert die eine Antwort „welcher Host, woher“; die
Skills fragen ihn und die Tabelle, statt `gh` fest aufzurufen.

Verworfen: eine eigene Datei für die Fähigkeiten (eine zweite Vertragsdatei, die mit dem
MANIFEST auseinanderlaufen kann); den Host in der Personal-Config statt im Projekt (ein
Rechner trägt Projekte mehrerer Hosts, siehe Entscheidungen); `.github/` auch bei `git`
rendern (tote Dateien ohne Plattform).

Erkennung (Schritt 2a): keine neuen Frameworks, Dependencies oder Toolchains — nichts zu
melden. Neue Config: Personal-Config-Schlüssel `CODING_KIT_EMAIL_<HOST>`; neuer
Antworten-Schlüssel `HOST`; keine Endpunkte, keine Dependencies. Version: 3.3.0 für alle
Substeps gemeinsam, mit Abschnitt `### Template`.

### F-032a — Host bestimmen: Befehl `host` und Fähigkeiten im MANIFEST

- `template-sync.sh host <projekt>`: `HOST` aus `.claude/template-answers`, sonst
  Vorschlag aus `origin` (HTTPS, SSH, scp-Form, Pfad, `file://`); erkannte, noch nicht
  unterstützte Hosts (Azure, GitLab, Forgejo/Codeberg) werden genannt und laufen als
  `git`; Widerspruch Antworten ↔ Remote wird gemeldet; ungültiger Wert bricht ab.
- MANIFEST: Schlüssel `HOST` unter § Answers; neuer Abschnitt `## Hosts` mit den
  Fähigkeiten je Host (Repo anlegen, Settings, Topics, Issues, Sichtbarkeit,
  Commit-Adresse, Renovate, CI) für `github` und `git`; `validate.py` prüft ihn.
- Skript-Tests (neue Datei unter `tests/template-sync/`), dash/bash, System-awk/mawk.
- Erfüllt AC-1, AC-2, EC-1 bis EC-3.

### F-032b — Template-Ziele je Host

- Policy `host:github` für `.github/**` und `renovate.json`; Render lässt sie bei
  `HOST=git` weg, ohne `HOST` gilt `github`. Module, die Jobs an `ci.yml` hängen, und
  `module_codeql` richten sich danach.
- `go.mod` ohne Host bei `HOST=git` (nur Projektname); `{{OWNER}}` wird bei `git` nicht
  verlangt.
- Template-Texte zur Commit-Adresse (CLAUDE.md, CODING-STANDARDS, CONTRIBUTING, HOW-TO,
  `privacy-lint.sh`): „die Adresse des Hosts, nie eine private“ statt GitHub-Pflicht;
  `privacy-lint.sh` erlaubt die Noreply-Form des Hosts.
- Render-Tests: `HOST=git` gegen `github`; `HOST=github` und ohne `HOST` byte-gleich zum
  Stand vor F-032.
- Erfüllt die Template-Seite von AC-3 und AC-4, EC-5.

### F-032c — Commit-Adresse je Host

- Personal-Config: `CODING_KIT_EMAIL_GITHUB`, `CODING_KIT_EMAIL_GIT` (weitere Hosts
  folgen mit ihren Nummern); `set-global` kennt sie; die alten Schlüssel gelten als
  GitHub-Werte, bis `update-conventions global` die Umbenennung anbietet.
- step-done § Commit-E-Mail und new-project § Autor-Config: Adresse des Projekt-Hosts
  aus der Personal-Config → bei GitHub `gh api user` → fragen; nur `--local`, nie die
  eines anderen Hosts.
- Globale Regeln (Zone `global-git`), `install.sh` schreibt die neuen Schlüssel, README
  (Personal-Config-Tabelle).
- Erfüllt AC-5, AC-9, EC-6.

### F-032d — Skills weisen fehlende Host-Fähigkeiten aus

- new-project: Host-Frage (Vorauswahl aus der Personal-Config), Pfad `git` mit
  `git init`, ohne `gh`; Bericht nennt übersprungene Schritte.
- go-public, name-it, check-upstreams, propose-to-template, Projektsuche in
  update-conventions: vor jedem `gh`-Aufruf Host und Fähigkeit prüfen; fehlt sie oder
  ist `gh` nicht angemeldet, Schritt ausweisen (mit Hinweis `gh auth login`) und weiter;
  propose-to-template gibt den Text kopierfertig aus.
- README: Abschnitt „Ohne GitHub (nur git)“ wird „Nur Git“ auf dem Skill-Pfad.
- Headless-Läufe mit `--plugin-dir`: new-project mit `git` in einem Wegwerf-Ordner,
  new-project dry-run mit GitHub, propose-to-template mit `HOST=git`.
- Erfüllt AC-3, AC-4, AC-6, AC-7.

### F-032e — Bestandsprojekte: Host eintragen, umziehen und wechseln

- update-conventions A2 Schritt 2 (Antworten prüfen): fehlt `HOST`, GitHub-Remote →
  `HOST=github` ohne eigene Frage, im Bericht genannt; sonst Frage bei Git bleiben oder
  umziehen (Liste aus `## Hosts`). Umzug: Schritte zeigen, nach Bestätigung Repo privat
  anlegen, `origin` setzen, Host-Ziele über den normalen Render/Merge ergänzen; Push nur
  auf eigene Bitte; Abbruch lässt `HOST` leer. Widerspruch aus `host` (EC-4) bietet den
  Umzug ebenso an.
- Argument `host` in update-conventions (argument-hint, Beschreibung, README): ein
  Ablauf für Umzug und Wechsel; alter Remote unter dem Namen des alten Hosts; Ziele des
  alten Hosts über die Klasse `removed` zum Entfernen anbieten; Bericht mit Handarbeit
  (Issues, Secrets, altes Repo).
- `update-conventions global`: Umbenennung der alten Personal-Config-Schlüssel anbieten.
- CHANGELOG 3.3.0 mit `### Template`; MANIFEST-Zeilen nachgezogen.
- Headless-Lauf an Testkopien (mit GitHub-Remote, ohne Remote); Umzug manuell an einem
  privaten Wegwerf-Repo, danach gelöscht.
- Erfüllt AC-8, AC-10, AC-11, EC-4, EC-7 bis EC-13 und den Migrationsteil von AC-9.

## Verlauf

### F-032a — fertig 2026-11-03

**Umgesetzt:**

- `template-sync.sh host [--answers FILE] PROJECT` (Funktionen `remote_kind` und `host`
  am Ende des Skripts): nennt den Host mit Quelle (`answers`, `remote`, `none`) und den
  Remote mit Art und Hostnamen; dazu Zeilen `unsupported`, `no-origin` und `mismatch`.
  Die Art kommt aus dem Hostnamen der URL (HTTPS, SSH, scp-Form); Pfade, `file://` und
  Laufwerksbuchstaben sind `local`. Zugangsdaten einer URL werden nie ausgegeben.
- MANIFEST: Schlüssel `HOST` unter § Answers; neuer Abschnitt `## Hosts` mit den
  Fähigkeiten von `github` und `git` und den erkannten, noch nicht unterstützten Hosts.
- `validate.py` prüft, dass das Skript (`HOSTS`) und § Hosts dieselben Hosts nennen und
  `git` dabei ist.
- Tests in `tests/template-sync/host.sh`; Version 3.3.0 mit CHANGELOG-Eintrag.

**Entscheidungen:**

- Ein Widerspruch zählt, wenn der Remote einen anderen Host vorschlägt als `HOST`:
  `HOST=git` auf einem noch nicht unterstützten Host (etwa GitLab) ist keiner, ein
  GitHub-Projekt ohne Remote schon.
- Selbst gehostete Server werden nicht am Namen geraten. Sie gelten als `other`, bis ein
  Host-Feature ihre Adresse kennt.
- „Noch nicht unterstützt“ wird aus der Host-Liste abgeleitet, damit F-052 bis F-054 nur
  `HOSTS` und das MANIFEST ergänzen müssen.

**Abweichung vom Plan:** `validate.py` lässt in der Datenschutz-Prüfung die SSH-Nutzer
der öffentlichen Git-Hosts zu (`git@github.com` und je erkanntem Host eine feste
Adresse). Bisher galten sie als geleakte E-Mail-Adressen, und jede SSH-Remote-URL in
Doku oder Tests war blockiert. Andere Adressen meldet die Prüfung weiter.

**Funde:** Unabhängiges Review mit 4 Befunden: 3 behoben, 1 verworfen (GitLab-Eintrag
der Erlaubnisliste — die Liste folgt den erkannten Hosts). Dabei eine Lücke gefunden und
behoben: Ein Wert mit mehreren Hosts ging durch. Keine neuen Aufgaben.

### F-032b — fertig 2026-11-04

**Umgesetzt:**

- Render nach Host (`template-sync.sh`, Funktion `render`): `HOST` aus den Antworten,
  ohne Eintrag `github`. Ziele mit der neuen Policy `host:NAME` entstehen nur auf diesem
  Host; im MANIFEST tragen `.github/**` und `renovate.json` `host:github`.
- Host-Blöcke `host-github` und `host-git`, abgeleitet wie die Lizenz-Blöcke: in
  `CLAUDE.md`, `CODING-STANDARDS.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`,
  `HOW-TO-CODE-WITH-CLAUDE.md` und `SECURITY.md`. Der GitHub-Text steht wortgleich im
  Block `host-github`.
- Abgeleiteter Platzhalter `{{GO_MODULE}}` für `go.mod`: auf GitHub
  `github.com/<owner>/<name>`, ohne Host der Projektname — so braucht bei `git` kein
  Ziel `OWNER`.
- Render-Tests für beide Hosts; Belege für AC-3 und AC-4, Template-Seite: Byte-Vergleich
  aller Module und Sichtbarkeiten mit dem Stand davor; ein gerendertes „nur Git“-Projekt
  besteht `just check`.

**Entscheidungen:**

- Der GitHub-Text bleibt wortgleich in einem eigenen Block, statt in einem gemeinsamen
  Satz für alle Hosts aufzugehen: GitHub-Projekte rendern byte-gleich, und
  `update-conventions` zeigt ihnen keine Änderung.
- Die Ableitung von `GO_MODULE` nennt jeden Host ausdrücklich; ein künftiger Host ohne
  eigenen Fall fällt als ungelöster Platzhalter auf, statt still einen GitHub-Pfad zu
  bekommen.

**Abweichung vom Plan:** Über die Texte zur Commit-Adresse hinaus haben auch die
Meldewege (`SECURITY.md`, `CODE_OF_CONDUCT.md`) und die Regeln zu Pull Requests und CI
(`CONTRIBUTING.md`, `CODING-STANDARDS.md`) Host-Blöcke bekommen. Sie verwiesen auf
GitHub-Funktionen, die es bei `git` nicht gibt.

**Funde:** Unabhängiges Review mit 2 Befunden, beide nachgeprüft und behoben (Meldeweg
im Verhaltenskodex; CI-Pflicht in CONTRIBUTING und CODING-STANDARDS). Keine neuen
Aufgaben.