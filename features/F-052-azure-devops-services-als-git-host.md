---
id: F-052
title: Azure DevOps Services als Git-Host
type: feature
status: IN-PROGRESS
size: L
created: 2026-11-03
done:
depends-on: F-032
superseded-by:
---

# F-052 — Azure DevOps Services als Git-Host

## Erfassung

**Problem:** Nach F-032 läuft ein Projekt auf Azure DevOps nur als „nur Git“: Repo anlegen,
Work Items, Pipeline und Renovate fehlen. In der Firma wird Azure DevOps Services (Cloud)
gebraucht.

**Ziel:** Als Nutzer in der Firma möchte ich Projekte auf Azure DevOps Services mit dem
ganzen Zyklus führen, damit die Host-Schritte dort genauso laufen wie auf GitHub.

**Lösungsskizze:**
- Beschlossen (2026-11-04): Web-Weg ohne `az` — das Repo legt der Nutzer im Web an, der
  Skill verbindet per Clone-Adresse und prüft mit `git ls-remote`; gepusht wird per
  SSH-Schlüssel oder Git Credential Manager. Das Kit fasst keine Token an.
- Unterschiede zu GitHub: Repos haben weder Beschreibung noch Topics; die Sichtbarkeit
  gilt je Azure-Projekt, nicht je Repo; Work Items statt Issues — das Kit legt keine an.
- CI über `azure-pipelines.yml`, einmal im Web registriert; PR-Vorlage unter
  `.azuredevops/`; `renovate.json` im Projekt, den Renovate-Lauf stellt die Organisation.
- Es gibt keine Noreply-Adresse: die Commit-Adresse kommt aus der Personal-Config
  (Firmenadresse), nie aus einer Annahme.
- Test mit einer kostenlosen eigenen Organisation und einem selbst gehosteten Agenten auf
  dem Mac, ohne Firmendaten.

**Abhängigkeiten:** F-032 (Host je Projekt, Fähigkeiten an einer Stelle, Commit-Adresse
je Host).

## Spezifikation

### Stories (priorisiert)

1. Als Nutzer in der Firma will ich mit new-project ein Projekt auf Azure DevOps Services
   anlegen: Das Repo lege ich im Web in meinem Azure-Projekt an, der Skill verbindet das
   Projekt damit, prüft die Verbindung und sagt mir, wie ich die CI-Pipeline registriere.
2. Als Nutzer will ich Bestandsprojekte mit Azure-Remote ohne Umweg als Azure-Projekte
   führen; neue Dateien bestätige ich je Datei.
3. Als Nutzer will ich ein Projekt per `update-conventions host` nach Azure umziehen oder
   von dort weg, wie zwischen GitHub und `git`.
4. Als Nutzer will ich, dass die übrigen Skills auf Azure ihre Host-Schritte ausführen
   oder sauber als übersprungen ausweisen.
5. Als Nutzer will ich, dass die Renovate-Regeln mitkommen, auch wenn der Renovate-Lauf
   zentral läuft und nicht im Projekt.

### Regeln mit Beispielen

| Regel | Beispiel | Gegenbeispiel |
|---|---|---|
| R1 `azure` ist ein Host wie `github`: `HOST=azure`; ein Remote auf `dev.azure.com`, `ssh.dev.azure.com` oder `*.visualstudio.com` schlägt `azure` vor | `origin` = `<org>@vs-ssh.visualstudio.com:v3/<org>/<projekt>/<repo>` → Vorschlag `azure` | Azure DevOps Server mit eigenem Hostnamen → `other`, läuft als `git` |
| R2 Das Kit legt auf Azure nichts an und braucht kein `az`: Das Repo legt der Nutzer im Web an, der Skill verbindet per Adresse | Nutzer nennt die Clone-Adresse → `git ls-remote` gelingt, Repo leer → `origin` gesetzt | Ein Skill ruft `az` auf, verlangt einen Token oder meldet den Nutzer an |
| R3 Verbinden nur mit einem erreichbaren, leeren Repo | `git ls-remote <url>` ohne Refs → verbinden | Repo mit README aus dem Web → nicht verbinden, kein Force-Push; Hinweis: leer neu anlegen |
| R4 Keine Zugangsdaten in der Remote-Adresse | `https://<org>@dev.azure.com/…` (nur Nutzername) oder SSH → angenommen | `https://user:<token>@…` → abgelehnt, Bitte um Adresse ohne Zugangsdaten; der Token erscheint in keiner Ausgabe |
| R5 Template-Ziele für `azure`: `azure-pipelines.yml`, `.azuredevops/pull_request_template.md`, `renovate.json`; Texte: Commit-Adresse wie bei `git`, Pull Requests und CI wie bei GitHub, privater Meldeweg wie bei `git` | `HOST=azure` → keine `.github/` | Ein Azure-Projekt bekommt Issue-Vorlagen oder den Hinweis auf den Security-Tab von GitHub |
| R6 Commit-Adresse aus `CODING_KIT_EMAIL_AZURE`, sonst fragen | Adresse gesetzt → `--local` gesetzt | Die GitHub-Adresse wird genommen, weil sie zufällig gesetzt ist; eine Noreply-Adresse wird erfunden |
| R7 Die Sichtbarkeit gilt fürs ganze Azure-Projekt: Sie wird erfragt, nie umgestellt; keine Branch-Policies | go-public auf `azure` → Preflight als reine Prüfung, Hinweis auf die Sichtbarkeit des Azure-Projekts | Ein Skill setzt eine Policy auf `main` und sperrt damit direkte Pushes |
| R8 Pipeline und Renovate laufen in der Organisation: Das Projekt bringt `azure-pipelines.yml` und `renovate.json` mit, die Registrierung der Pipeline macht der Nutzer im Web | Bericht: Klickweg zum Registrieren; „Renovate braucht einen Lauf in der Organisation“ | Ein Skill legt eine Pipeline oder eine Renovate-Pipeline an oder vergibt Rechte |

### Abnahmekriterien

- [x] AC-1 — Gegeben ein Remote auf Azure DevOps (`dev.azure.com` per HTTPS mit und ohne
  `<org>@`, `ssh.dev.azure.com:v3/…`, `<org>.visualstudio.com`,
  `vs-ssh.visualstudio.com:v3/…`), wenn `template-sync.sh host` läuft, dann nennt es
  `azure` als Vorschlag; `HOST=azure` in den Antworten gilt; `HOST=git` mit
  Azure-Remote meldet einen Widerspruch. Zugangsdaten aus der URL erscheinen nie in der
  Ausgabe. — belegt: `tests/template-sync/host.sh` (alle Adressformen, `HOST=azure`,
  Widerspruch bei `HOST=git`, Token nie ausgegeben), `just check`.
- [x] AC-2 — Gegeben `HOST=azure`, wenn gerendert wird, dann entstehen
  `azure-pipelines.yml`, `.azuredevops/pull_request_template.md` und `renovate.json`,
  aber kein `.github/`; die sechs Texte tragen ihren Azure-Block; `GO_MODULE` ist der
  Projektname; `OWNER` wird nicht verlangt. Ein gerendertes Azure-Projekt besteht
  `just check`. Renders für `github` und `git` bleiben byte-gleich zum Stand vor F-052.
  — belegt: `tests/template-sync/render.sh` (Ziele, kein `.github/`, Blöcke, Go-Modul,
  ohne `OWNER`); Byte-Vergleich der Renders `github` und `git` aller Module mit dem Stand
  davor; ein gerendertes Azure-Projekt besteht `just check`.
- [x] AC-3 — Gegeben eine Template-Datei mit Host-Blöcken, wenn für einen Host aus
  `HOSTS` der Block fehlt, dann meldet `just check` das; mit allen Blöcken ist es grün.
  — belegt: Gegenprobe mit entferntem `host-azure`-Block und einem Block für einen
  unbekannten Host — `just check` meldet beides; mit allen Blöcken grün.
- [x] AC-4 — Gegeben `HOST=azure`, wenn `commit-email` läuft, dann liefert es
  `CODING_KIT_EMAIL_AZURE`; fehlt sie, meldet es `missing` und step-done fragt — nie die
  Adresse eines anderen Hosts. — belegt: `tests/template-sync/host.sh`
  (`CODING_KIT_EMAIL_AZURE`, `missing` ohne sie, nie die GitHub-Adresse).
- [ ] AC-5 — Gegeben new-project mit Host `azure`, wenn der Lauf durchgeht, dann zeigt
  der Skill die Schritte zum Anlegen eines leeren Repos im Web, nimmt die Clone-Adresse
  entgegen, prüft sie mit `git ls-remote` (erreichbar, leer) und setzt `origin`;
  `HOST=azure` und die erfragte `VISIBILITY` stehen in den Antworten; der Erst-Commit
  trägt die Azure-Adresse; gepusht wird nur auf Bitte. Der Bericht nennt den Klickweg zur
  Registrierung der Pipeline, dass sie einen Agenten braucht, dass Renovate einen Lauf in
  der Organisation braucht, und die übersprungenen Schritte (Repo anlegen, Beschreibung
  und Topics, Repo-Einstellungen, Sichtbarkeit). Kein `az`-Aufruf. Negativfälle:
  `git ls-remote` scheitert, das Repo ist nicht leer oder die Adresse trägt Zugangsdaten
  → `origin` nicht gesetzt, Hinweis, Frage: neue Adresse, als `git` weiter oder
  abbrechen.
- [ ] AC-6 — Gegeben ein Testprojekt in einer eigenen kostenlosen Organisation, im Web
  registrierte Pipeline und ein selbst gehosteter Agent auf dem Mac, wenn gepusht wird,
  dann läuft die Pipeline grün (mise, `just setup`, `just check`); ein absichtlich roter
  Check macht sie rot. Agent, Organisation und Repo werden danach entfernt.
- [ ] AC-7 — Gegeben ein Bestandsprojekt ohne `HOST` mit Azure-Remote, wenn
  update-conventions läuft, dann trägt es `HOST=azure` ohne Frage ein, nennt das im
  Bericht und bietet die Azure-Dateien je Datei an; `HOST=git` mit Azure-Remote bietet
  das Angleichen an.
- [ ] AC-8 — Gegeben ein Projekt, wenn `update-conventions host` nach `azure` wechselt,
  dann läuft das Verbinden wie in AC-5 (Repo im Web, Adresse, `git ls-remote`), danach
  behält es den alten `origin` unter dem Namen des alten Hosts, stellt `HOST` um, bietet
  die Dateien je Datei an und nennt den Klickweg zur Pipeline; gepusht wird nur auf
  Bitte. Ein Wechsel weg von `azure` bietet die Azure-Dateien zum Entfernen an und behält
  den alten `origin` als `azure`.
- [ ] AC-9 — Gegeben `HOST=azure`, wenn go-public, name-it, propose-to-template oder
  check-upstreams laufen, dann: go-public stellt nichts um und bietet den Preflight als
  Prüfung an; name-it weist die Namensprüfung auf dem Host als übersprungen aus;
  propose-to-template gibt den Text kopierfertig aus, ohne `gh`; check-upstreams läuft
  unverändert. Kein Skill ruft `az` auf.
- [ ] AC-10 — Gegeben GitHub- und `git`-Projekte, wenn die Skills laufen, dann verhalten
  sie sich wie vor F-052 (Regression).

### Randfälle

- EC-1 — Azure DevOps Server mit eigenem Hostnamen → `other`, läuft als `git`.
- EC-2 — Adresse mit `<org>@` (HTTPS) oder `<org>@vs-ssh…` (SSH) → normaler Nutzername,
  angenommen; nur der Hostname wird ausgegeben.
- EC-3 — `git ls-remote` scheitert (SSH-Schlüssel nicht im Profil, keine Rechte, Tippfehler)
  → Hinweis auf die drei Ursachen, nichts gesetzt.
- EC-4 — Repo im Web mit README angelegt (nicht leer) → nicht verbinden, kein
  Force-Push; Hinweis: Repo löschen und leer neu anlegen oder andere Adresse.
- EC-5 — Die Pipeline lässt sich im Web nicht registrieren (Rechte) → das Projekt bleibt
  verbunden, `HOST=azure` bleibt; der Bericht nennt, wen man fragt (Projekt-Admin).
- EC-6 — Die Organisation hat weder gekaufte Pipeline-Jobs noch einen Agenten → der Lauf
  bricht auf Azure ab; das Kit kann das nicht prüfen, der Bericht nennt es als
  Voraussetzung.
- EC-7 — HTTPS-Adresse statt SSH (Anmeldung über den Git Credential Manager) → ebenso
  angenommen; `git ls-remote` zeigt, ob die Anmeldung trägt.

### Nicht-Ziele

- `az` oder die REST-API: Repos, Pipelines oder Sichtbarkeit per Kommandozeile — bei
  Bedarf eine eigene F-Nummer.
- Azure DevOps Server (lokal betrieben).
- Azure-Projekte anlegen, Branch-Policies, Berechtigungen vergeben.
- Eine Renovate-Pipeline je Projekt — bei Bedarf eine eigene F-Nummer.
- Work Items, Boards, Wiki.
- Secret Scanning und CodeQL auf Azure (Advanced Security kostet extra).
- Die Rahmenbedingung „baut auf GitHub auf“ umformulieren (nach F-054, wie in F-032
  geplant).
- Installer (→ F-025).

### Tests

- AC-1, EC-1, EC-2: Skript-Tests in `tests/template-sync/host.sh` (dash und bash,
  System-awk und mawk).
- AC-2, AC-10: Render-Tests `HOST=azure`; Byte-Vergleich der Renders für `github` und
  `git` mit dem Stand vor F-052; ein gerendertes Azure-Projekt besteht `just check`.
- AC-3: Validator-Test mit fehlendem Azure-Block.
- AC-4: Skript-Tests zu `commit-email`.
- AC-5, EC-3, EC-4: Headless-Lauf new-project mit `--plugin-dir` gegen ein leeres Repo
  der eigenen Test-Organisation (SSH-Schlüssel im Profil); Negativfälle mit falscher
  Adresse, nicht leerem Repo und Adresse mit Zugangsdaten.
- AC-6, EC-6: manuell — Pipeline in der Test-Organisation mit selbst gehostetem Agenten
  auf dem Mac, grün und absichtlich rot; danach alles entfernt.
- AC-7, AC-8: Headless-Läufe update-conventions an Testkopien (ohne `HOST` mit
  Azure-Remote; `HOST=git` mit Azure-Remote; Wechsel nach und von `azure`).
- AC-9: Headless-Läufe go-public und propose-to-template mit `HOST=azure`; grep — kein
  `az`-Befehl in den Skills.

### Einbettung

- Berührt: MANIFEST (§ Hosts mit der Zeile `azure`, Core-Zeilen für zwei neue Ziele,
  `renovate.json` für zwei Hosts), `template-sync.sh` (`HOSTS`, `GO_MODULE`, Host-Policy
  mit mehreren Hosts), `validate.py` (Blöcke je Host; SSH-Nutzer
  `<org>@vs-ssh.visualstudio.com` in Beispiel-URLs nicht als Mailadresse werten),
  globale Regeln (Zeile `CODING_KIT_EMAIL_AZURE` — jeder Rechner sieht die Änderung beim
  nächsten Abgleich), sechs Template-Texte, zwei neue Template-Dateien, Skills
  new-project, update-conventions, go-public, name-it, propose-to-template und
  step-done, README (Hosts, Personal-Config, Weg für Azure).
- Renovate-Preset `default.json`: Die festgelegte mise-Version in `azure-pipelines.yml`
  braucht eine Regel, damit Renovate sie aktuell hält — sie gilt dann für alle Projekte.
- Version: Minor-Release mit `### Template`.
- Publishing-Hygiene: Namen der Test-Organisation und der Firma nur in `private/`;
  Beispiel-URLs mit Platzhaltern.
- Kein Widerspruch zu Zielen, Nicht-Zielen oder ADRs.
- Folge-Nummern: keine; `az`-Weg und Renovate-Pipeline je Projekt nur bei Bedarf.

### Offene Fragen

- [x] [CLARIFY] Lädt Renovate auf Azure das Preset `github>…` ohne GitHub-Token? —
  Ja (F-052a, lokal mit `--platform=local` geprüft; der Abruf eines `github>`-Presets
  hängt nicht an der Plattform): anonym über die GitHub-API, samt der Presets, die es
  erweitert. Bei einem zentralen Lauf über viele Repos hinter einer Adresse nennt der
  Bericht einen GitHub-Token wegen des Abruflimits.
- [x] [CLARIFY] Wie wird mise in der Azure-Pipeline mit fester Version und Prüfsumme
  installiert? — Über das `install.sh` des festgelegten mise-Releases (F-052a): Es trägt
  die Prüfsummen genau dieser Version und bricht ohne passende ab.

### Entscheidungen

- 2026-11-04 — Web-Weg ohne `az`: Das Repo legt der Nutzer im Web an, der Skill
  verbindet per Adresse und prüft mit `git ls-remote`; die Pipeline registriert der
  Nutzer im Web. Grund: Repos anlegen dürfen standardmäßig nur Projekt-Admins, die
  Firmen-IT sieht das Anlegen im Web vor, gepusht wird per SSH-Schlüssel, und eine
  `az`-Anmeldung auf einem Server ohne Browser ist in Firmen oft gesperrt. Der erste
  Entwurf sah `az` vor; nach der Analyse der Rechte revidiert.
- 2026-11-04 — Renovate: Das Projekt bringt nur `renovate.json` mit, der Bericht nennt den
  nötigen Lauf. Empfehlung war zuerst eine eigene Renovate-Pipeline je Projekt; nach der
  Erklärung der Pipelines revidiert, weil Firmen Renovate oft zentral betreiben.
- 2026-11-04 — Test der Pipeline nur mit einem selbst gehosteten Agenten auf dem Mac.
  Empfehlung war Antrag bei Microsoft plus Agent als Ersatz; entschieden nur Agent, ohne
  Antrag. Der Agent wird nach dem Test entfernt.
- 2026-11-04 — Bestandsprojekte mit Azure-Remote bekommen `HOST=azure` ohne Frage, wie
  GitHub-Projekte; die neuen Dateien werden je Datei bestätigt.
- 2026-11-04 — Keine Branch-Policies: Jede Policy auf `main` sperrt direkte Pushes und
  erzwingt Pull Requests.
- 2026-11-04 — Organisation und Azure-Projekt stehen nur in der `origin`-Adresse des
  Projekts, nicht in neuen Schlüsseln der Personal-Config: Firmennamen bleiben aus Kit
  und Personal-Config.
- 2026-11-04 — Go-Modulpfad wie bei `git`, nur der Projektname: Azure-Pfade
  (`…/_git/<repo>`) taugen schlecht als Modulpfad.
- 2026-11-04 — propose-to-template behandelt `azure` wie `git` (Text kopierfertig, kein
  `gh`): Wie seit F-032 entscheidet der Host des Projekts, ob `gh` ins Spiel kommt.

## Plan

**Größe:** L — 6 Skills, Sync-Skript, Validator, sechs Template-Texte, zwei neue
Template-Dateien, globale Regeln und Migration der Bestandsprojekte; dazu neue Technik
(Azure Pipelines, mise ohne fertigen Baustein), die erst ein Spike klärt.

**Ansatz:** `azure` wird ein dritter Host in derselben Mechanik, die F-032 gebaut hat:
eine Zeile in MANIFEST § Hosts, ein Name in `HOSTS`, Host-Blöcke `host-azure` in den
Texten und Ziele mit der Policy `host:azure`. Die Policy darf künftig mehrere Hosts
nennen, damit `renovate.json` auf `github` und `azure` entsteht, ohne die Datei zu
doppeln. Die PR-Vorlage hat keinen GitHub-Bezug; sie wird aus derselben Quelle an zweiter
Stelle gerendert (`.azuredevops/pull_request_template.md`). Die Prüfung einer
Clone-Adresse — Zugangsdaten abweisen, Host erkennen, mit `git ls-remote` erreichbar und
leer — wird ein Skript-Befehl: testbar unter dash und bash, und Zugangsdaten verlassen das
Skript nie. Die Skills new-project und update-conventions (A6) rufen ihn auf, statt die
Prüfung selbst zu formulieren.

Verworfen: der Weg über `az` (Repos anlegen dürfen meist nur Admins, Anmeldung auf einem
Server ohne Browser oft gesperrt, zweiter Weg mit doppelten Tests); eine Renovate-Pipeline
je Projekt (Firmen betreiben Renovate oft zentral); eine eigene Kopie der PR-Vorlage für
Azure (zwei Dateien, die auseinanderlaufen).

Erkennung (Schritt 2a): Das Kit bekommt keine neuen Frameworks, Dependencies oder
Toolchains — nichts zu melden. Neue Config: Personal-Config-Schlüssel
`CODING_KIT_EMAIL_AZURE`; Antworten-Wert `HOST=azure`; keine Endpunkte. Version 3.4.0
für alle Substeps gemeinsam, mit `### Template`; gepusht wird erst nach F-052c, weil
§ Hosts `azure` ab F-052b anbietet und die Skills den Weg erst mit F-052c kennen.

### F-052a — Spike in einer eigenen Test-Organisation

- Mit dem Nutzer: kostenlose Organisation, Projekt, SSH-Schlüssel im Profil, leeres Repo;
  selbst gehosteter Agent auf dem Mac.
- `azure-pipelines.yml` entwerfen und dort laufen lassen: mise mit fester Version und
  Prüfsumme installieren, `just setup`, `just check`; grün und absichtlich rot.
- Renovate lokal (`--platform=local`) an einem gerenderten Projekt ohne GitHub-Token:
  lädt es das Preset `github>…`?
- Prüfen, was `git ls-remote` bei leerem, nicht leerem und nicht erreichbarem Repo
  liefert (Grundlage für den Skript-Befehl).
- Ergebnis im Verlauf; die beiden `[CLARIFY]` werden beantwortet. Kein Kit-Code; die
  Test-Organisation bleibt bis F-052d bestehen.
- Klärt die offenen Fragen; Vorarbeit für AC-2 und AC-6.

### F-052b — Host `azure` in Skript, MANIFEST und Template

- `template-sync.sh`: `HOSTS='github azure git'`, `GO_MODULE` bei `azure` der
  Projektname, Policy `host:` mit mehreren Hosts, neuer Befehl zur Prüfung einer
  Clone-Adresse (Zugangsdaten, Host, `git ls-remote`).
- MANIFEST: Zeile `azure` in § Hosts, Core-Zeilen für `azure-pipelines.yml` und die
  PR-Vorlage, `renovate.json` für `github` und `azure`, Marker-Liste.
- Template: Blöcke `host-azure` in den sechs Texten, `core/azure-pipelines.yml` aus dem
  Spike.
- `validate.py`: jede Datei mit Host-Blöcken hat einen Block je Host; der SSH-Nutzer von
  `vs-ssh.visualstudio.com` gilt in Beispiel-URLs nicht als Mailadresse.
- Globale Regeln: Zeile `CODING_KIT_EMAIL_AZURE`. Renovate-Preset `default.json`: Regel
  für die mise-Version in `azure-pipelines.yml`.
- Tests: `host.sh` (alle Azure-Adressformen), Render `HOST=azure`, Byte-Vergleich
  `github` und `git` mit dem Stand davor, `commit-email`, Validator, Adress-Prüfung; ein
  gerendertes Azure-Projekt besteht `just check`. Version 3.4.0 mit CHANGELOG.
- Erfüllt AC-1 bis AC-4, die Template-Seite von AC-10, EC-1, EC-2.

### F-052c — Skills auf Azure

- new-project: Host `azure` mit Web-Schritten, Adress-Prüfung über das Skript,
  `origin`, erfragter Sichtbarkeit, Bericht mit Klickweg zur Pipeline, Agent und
  Renovate-Lauf; Negativfälle mit der Wahl neue Adresse, als `git` weiter oder abbrechen.
- update-conventions: A2 Schritt 2 trägt `HOST=azure` bei Azure-Remote ohne Frage ein;
  A6 Umzug nach und weg von `azure` mit derselben Prüfung.
- go-public, name-it, propose-to-template und step-done für `azure`; MANIFEST § Hosts,
  Absatz „Host steps in a skill“ um den Weg ohne CLI ergänzt.
- README (Hosts, Personal-Config, Weg für Azure); CHANGELOG ergänzt.
- Headless-Läufe mit `--plugin-dir`: new-project gegen ein leeres Repo der
  Test-Organisation samt Negativfällen; update-conventions an Testkopien; go-public und
  propose-to-template mit `HOST=azure`; grep auf `az`.
- Erfüllt AC-5, AC-7 bis AC-10, EC-3, EC-4, EC-7.

### F-052d — Ende-zu-Ende und Aufräumen

- Das mit new-project angelegte Testprojekt pushen, die Pipeline im Web nach dem Klickweg
  aus dem Bericht registrieren, mit dem Agenten auf dem Mac grün und absichtlich rot
  laufen lassen.
- Danach Agent vom Mac entfernen, Repo und Test-Organisation löschen.
- Erfüllt AC-6, EC-5 (am Text des Klickwegs), EC-6.

## Verlauf

### F-052a — fertig 2026-11-09

**Umgesetzt:**

- Spike in einer eigenen Test-Organisation auf Azure DevOps Services: Azure-Probeabo mit
  Ausgabenlimit, privates Projekt, SSH-Schlüssel im Profil, selbst gehosteter Agent auf
  einem Mac. Kein Kit-Code.
- Verbinden per SSH: Ein neues Azure-Projekt bringt ein leeres Repo mit dem Projektnamen
  mit. `git ls-remote` liefert für ein leeres Repo Exit 0 ohne Zeile auf stdout, für ein
  Repo mit Inhalt Exit 0 und eine Zeile je Ref; für ein fehlendes Repo oder fehlende
  Rechte einen Fehler mit `TF401019` auf stderr — Azure unterscheidet beides nicht.
  Zeitüberschreitungen enden ebenfalls mit einem Fehler („Operation timed out“ auf
  stderr); ein zweiter Versuch nach kurzer Pause klappt.
- Pipeline: Ein mit dem Kit gerendertes Projekt (`HOST=git`, Modul docs-only) mit einem
  Entwurf von `azure-pipelines.yml` lief, im Web registriert, auf dem Agenten grün —
  mise installieren, `mise install --locked`, `just setup`, `just check`. Ein Push auf
  einen Branch mit absichtlich rotem Check startete die Pipeline von selbst; sie endete
  rot bei `just check`.
- mise mit fester Version: Jedes Release von jdx/mise hat ein eigenes `install.sh` mit
  den Prüfsummen genau dieser Version. `MISE_VERSION` muss gesetzt sein und zur
  Download-Adresse passen, sonst wählt das Skript selbst ein Release.
- Renovate lokal (`--platform=local`, ohne GitHub-Token): Es lädt das Preset
  `github>xnyzer/coding-kit` anonym über die GitHub-API, löst `config:recommended` auf
  und erkennt `mise.toml`.

**Entscheidungen:**

- Test-Organisation mit Azure-Probeabo: Neue Organisationen verlangen ein Azure-Abo.
  Empfehlung war zuerst Pay-as-you-go mit Budget-Alarm; entschieden das Probeabo, weil
  es dank Ausgabenlimit nichts abbuchen kann, ohne dass der Nutzer umstellt.
- Für die Pipeline-Vorlage (F-052b): mise über das `install.sh` des festgelegten
  Releases, Renovate hält `MISE_VERSION` aktuell. `trigger` auf alle Branches und
  `pr: none`, weil Azure Repos `pr:` ignoriert und Läufe für Pull Requests nur über eine
  Branch-Policy gäbe.

**Abweichung vom Plan:** Die Test-Organisation braucht ein Azure-Abo; die Spezifikation
ging von einer Organisation ohne Abo aus. Renovate lief nicht gegen Azure selbst — die
Preset-Frage hängt nicht an der Plattform und ist lokal geklärt.

**Funde:** Keine neuen Aufgaben. Für F-052b und F-052c:

- Azure DevOps nimmt nur RSA-Schlüssel an, `ssh-keygen` erzeugt heute ED25519 — der
  erste Hinweis, wenn die Verbindung scheitert; die README nennt es.
- Neue OpenSSH-Versionen warnen bei jeder Verbindung zu Azure auf stderr, auch bei
  Erfolg. Die Prüfung der Adresse liest Erfolg sowie „leer“ oder „nicht leer“ allein aus
  Exit-Code und stdout; stderr dient nur dazu, die Art eines Fehlers zu bestimmen
  (`TF401019`: gibt es nicht oder keine Rechte; Zeitüberschreitung: erneut versuchen) —
  die Warnung zählt nie als Fehler.
- Beim ersten Kontakt kennt SSH den Host-Schlüssel nicht, und `git ls-remote` scheitert
  ohne Terminal mit „Host key verification failed“ — Hinweis: einmal
  `ssh -T git@ssh.dev.azure.com` im Terminal ausführen und den Fingerabdruck mit dem in
  Azure (User settings → SSH public keys) vergleichen. Dieser Befehl endet auch bei
  erfolgreicher Anmeldung mit einem Fehlercode und „Shell access is not supported“; der
  Hinweis muss das sagen.
- Der anonyme Preset-Abruf unterliegt dem Abruflimit von GitHub je Adresse; der Bericht
  nennt einen GitHub-Token für einen zentralen Renovate-Lauf.
- Offen für F-052b: der Standard-Pool der Vorlage (Microsoft-gehostet oder ein benannter
  Pool der Organisation).
- Die ersten Läufe scheiterten am macOS-Gatekeeper des Test-Agenten; das betrifft nur den
  Testaufbau, nicht das Kit.

### F-052b — fertig 2026-11-10

**Umgesetzt:**

- `template-sync.sh`: `HOSTS='github azure git'`; ein Azure-Remote schlägt `azure` vor
  statt „nicht unterstützt“; `GO_MODULE` ist auf `azure` der Projektname; die Policy
  `host:` nennt mehrere Hosts mit `/` (`host:github/azure`).
- Neuer Befehl `remote-check URL`: weist Zugangsdaten in der Adresse ab, ohne den
  Server zu fragen; sonst `git ls-remote` ohne Rückfrage (kein Terminal-Prompt, ssh im
  Batch-Modus, nur übliche Transporte) mit dem Ergebnis `empty`, `refs`, `not-found`,
  `host-key`, `timeout`, `denied` oder `failed`. Ausgegeben werden nur Hostname und
  Ergebnis. Live gegen die Test-Organisation geprüft (Repo mit Inhalt, fehlendes Repo).
- MANIFEST: Zeile `azure` in § Hosts, Core-Zeilen für `azure-pipelines.yml` und die
  PR-Vorlage (dieselbe Quelle wie auf GitHub, Ziel `.azuredevops/`), `renovate.json` auf
  `github/azure`, Marker-Liste.
- Template: `core/azure-pipelines.yml` aus dem Spike; Blöcke `host-azure` in den sechs
  Texten — Commit-Adresse und Meldeweg wie bei `git`, Pull Requests und CI wie bei
  GitHub.
- `validate.py`: Block je Host in jeder Datei mit Host-Blöcken; der Kontoname in
  `<org>@vs-ssh.visualstudio.com` und `https://<org>@dev.azure.com` gilt nicht als
  Mailadresse. Globale Regeln: `CODING_KIT_EMAIL_AZURE`, `azure` als Standard-Host
  möglich. `default.json`: Regel für `MISE_VERSION` (Releases von jdx/mise), lokal mit
  Renovate geprüft. Version 3.4.0.

**Entscheidungen:**

- Pool der Pipeline-Vorlage: `Default`, der Pool eigener Agenten, den jede Organisation
  hat. Microsoft-gehostete Agenten wären die Alternative gewesen; entschieden `Default`,
  weil er ohne gekaufte Laufzeit läuft und F-052d die Vorlage unverändert mit dem
  Agenten auf dem Mac testet.
- Der fehlende CI-Job des Go-Moduls (Lizenzprüfung) auf Azure wird eine eigene Aufgabe
  (F-057), nicht Teil von F-052.

**Abweichung vom Plan:**

- `remote-check` braucht eine Zeitgrenze: Azure meldet `TF401019` sofort, hält die
  Verbindung aber rund 4½ Minuten offen, und git wartet darauf (bei allen
  Protokollversionen). Die Prüfung endet daher bei `TF401019`, sonst nach 60 Sekunden
  (`REMOTE_CHECK_SECONDS`); git wird hart beendet, weil es sonst noch auf ssh wartet.
  Folge: jeder Aufruf dauert mindestens eine Sekunde, die Skript-Tests rund 45 Sekunden
  länger.
- Der Validator lässt neben `<org>@vs-ssh.visualstudio.com` auch `<org>@dev.azure.com`
  zu — dieselbe Lage in der HTTPS-Adresse.
- Kein eigener Test für den Validator: das Repo hat keine Test-Suite dafür; AC-3 ist
  per Gegenprobe belegt.

**Funde:**

- Vorhandener Fehler behoben (aus F-032): `host` gab den Hostnamen der Remote-Adresse
  ungefiltert aus; ein Zeilenumbruch darin fälschte eine Zeile der Ausgabe. Hostnamen
  werden nur noch ausgegeben, wenn sie aus Buchstaben, Ziffern, `.`, `_` und `-`
  bestehen — gilt für `host` und `remote-check`, belegt mit Tests.
- F-057 (CI-Jobs der Stack-Module auch in der Azure-Pipeline) angelegt.
- Ohne eine Pause zwischen vielen neuen SSH-Verbindungen drosselt Azure sie
  (Zeitüberschreitung beim Verbinden); `remote-check` meldet das als `timeout`.
