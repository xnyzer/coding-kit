---
id: F-025
title: Installer läuft ohne GitHub und installiert die Toolchain über mise
type: feature
status: IN-PROGRESS
size: M
created: 2026-08-12
done:
depends-on: F-032
superseded-by:
---

# F-025 — Installer läuft ohne GitHub und installiert die Toolchain über mise

## Erfassung

**Problem:** `install.sh` setzt GitHub und macOS voraus. Fehlt `gh` oder ist es nicht
angemeldet, bricht er in der ersten Prüfung ab, statt den Login anzubieten oder ohne
GitHub weiterzumachen — obwohl die README einen GitHub-freien Weg beschreibt. Die
Toolchain-Installation kennt nur `brew`; auf Linux ohne Brew und auf Windows bleibt es
bei einer Warnung. Plattform-Erkennung gibt es im Repo nirgends.

**Idee:** Der Installer wird Bootstrap für alle drei Plattformen und auch für Rechner
ohne GitHub: Voraussetzungen werden erkannt und benannt statt zur Abbruchbedingung
gemacht, fehlender Login wird angeboten, und die Toolchain kommt über den Paketmanager
der jeweiligen Plattform.

**Lösungsskizze:**
- Drei `gh`-Zustände unterscheiden (fehlt / vorhanden ohne Login / bereit) statt eines
  harten `fail`: Login anbieten, GitHub-freien Lauf als bestätigte Alternative — dann die
  Personal-Config ohne `gh api`-Vorbefüllung abfragen.
- Toolchain über mise: nur mise selbst kommt über den Paketmanager (brew, pacman),
  just/lefthook/gitleaks per `mise use -g`; ohne passenden Paketmanager den offiziellen
  Befehl nennen.
- Windows wird nur erkannt und bekommt den Weg von Hand; die Windows-Unterstützung des
  Installers ist F-067.
- Defaults plattformgerecht wählen — das Projekte-Verzeichnis nicht auf ein englisches
  „Documents" festlegen.
- Zeilenenden sind kein Thema: `.gitattributes` erzwingt `eol=lf` für den ganzen Baum.

**Abhängigkeiten:** F-032 (zentrale Host-Erkennung — Skills und Installer nutzen
dieselbe Antwort auf „welcher Git-Server, welche Fähigkeiten").

## Spezifikation

### Abnahmekriterien

- [x] AC-1 — Gegeben `gh` ist installiert und angemeldet und es gibt noch keine
  Personal-Config, wenn der Installer läuft, dann befüllt er sie wie bisher über `gh api
  user` (Login, Name, Noreply-Adresse unter `CODING_KIT_EMAIL_GITHUB`) und fragt den
  Git-Host neuer Projekte mit dem Vorschlag `github`. Wählt man einen anderen Host, fragt
  er zusätzlich dessen Commit-Adresse. — belegt: Fälle „gh ready“ und „host azure“ in
  `tests/template-sync/install.sh` — Login, Name aus gh (quotiert), Noreply-Adresse, Host
  `github` mit Vorschlag, bei `azure` dazu dessen Adresse.
- [x] AC-2 — Gegeben `gh` ist installiert, aber nicht angemeldet, wenn der Installer
  läuft, dann bietet er `gh auth login` an (Standard: Ja). Gelingt der Login, geht es
  weiter wie in AC-1. Lehnt man ab oder scheitert der Login, fragt er, ob er ohne GitHub
  weitermachen soll (Standard: Nein). Bei Nein bricht er mit dem Hinweis „gh auth login,
  dann erneut ausführen“ und einem Exit-Code ungleich 0 ab, bevor er etwas einrichtet. —
  belegt: Fälle „login“ (Login läuft, danach mit GitHub), „declining both“ (Exit 1,
  Hinweis auf `gh auth login`, keine Config, kein Aufruf `claude plugin`) und „a failed
  login and no GitHub“.
- [x] AC-3 — Gegeben `gh` fehlt, wenn der Installer läuft, dann nennt er, wie man `gh`
  bekommt (mit brew: `brew install gh`, sonst die Seite von GitHub CLI), und fragt, ob er
  ohne GitHub weitermachen soll (Standard: Nein). Bei Nein bricht er wie in AC-2 ab. —
  belegt: Fälle „gh missing“ (Seite von GitHub CLI, Exit 1, keine Config) und „gh missing
  with brew“ (`brew install gh`).
- [x] AC-4 — Gegeben der Lauf ohne GitHub ist bestätigt, dann ruft der Installer `gh` kein
  einziges Mal auf. Er richtet Marketplace und Plugin ein und fragt für die
  Personal-Config: Autorname (Vorschlag aus `git config --global user.name`), Git-Host
  neuer Projekte (Vorschlag `git`, auch `azure`, `github` wird nicht angeboten),
  Commit-Adresse dieses Hosts (Vorschlag aus `git config --global user.email`; leer —
  neben einem Vorschlag `-` — = beim Commit fragen) und das Projekte-Verzeichnis.
  `CODING_KIT_GITHUB_LOGIN` und `CODING_KIT_EMAIL_GITHUB` schreibt er nicht. — belegt:
  Fälle „gh missing and no GitHub“ (Vorschläge aus git config, `github` nicht angeboten,
  kein Login-Schlüssel), „declined login and no GitHub“ (gh nur nach seinem Zustand
  gefragt), „- as address“ (Adresse leer).
- [x] AC-5 — Gegeben eine Eingabe, die keine einfache Adresse ist, oder ein Host außerhalb
  der Liste, dann lehnt der Installer sie mit Grund ab und fragt erneut. Gegeben ein Name
  oder Pfad mit `"`, `$`, `` ` `` oder `\`, dann steht der Wert nach dem Einlesen der
  Personal-Config (`. coding-kit.env`) unverändert da. — belegt: Fälle „rejected answers“
  (`github` und `gitlab` als Host, ungültige Adresse abgelehnt, dann übernommen) und
  „special characters“ (Name und Pfad mit `"`, `$`, `` ` ``, `\` nach dem Einlesen gleich,
  kein Befehl ausgeführt).
- [x] AC-6 — Gegeben eine Personal-Config existiert schon, wenn der Installer läuft, dann
  fasst er sie nicht an und stellt keine Frage zu GitHub. Den Zustand von `gh` meldet er
  nur (bereit, ohne Login, fehlt). — belegt: Fall „existing config“ — Datei unverändert
  (cksum), „nicht angemeldet“ gemeldet, keine Frage zu GitHub.
- [x] AC-7 — Gegeben der Vorschlag für das Projekte-Verzeichnis, dann ist er
  `~/Documents/Coding-Projects`, wenn `~/Documents` existiert; sonst der Ordner, den
  `xdg-user-dir DOCUMENTS` nennt (z. B. `~/Dokumente`), wenn es ihn gibt und er nicht das
  Home selbst ist; sonst `~/Coding-Projects`. — belegt: Fälle „Documents“, „xdg“, „xdg =
  home“, „xdg missing“ und „no documents folder“.
- [ ] AC-8 — Gegeben `mise` ist da, aber `just`, `lefthook` oder `gitleaks` fehlen, wenn
  der Installer läuft, dann bietet er `mise use -g <fehlende Tools>` an (Standard: Nein).
  Danach meldet `tool-check` sie als vorhanden. brew wird für diese drei nicht mehr
  angeboten.
- [ ] AC-9 — Gegeben `mise` fehlt, dann gilt:
  - mit brew (macOS oder Linux) bietet der Installer `brew install mise` an,
  - auf Arch mit pacman bietet er `sudo pacman -S mise` an,
  - nach der Installation geht es im selben Lauf mit AC-8 weiter.
  Ohne brew und pacman nennt er den offiziellen Befehl `curl https://mise.run | sh` und
  die Installationsseite von mise, bittet um einen erneuten Lauf danach und führt selbst
  nichts aus dem Netz aus. Am Ende fasst er alles Offene in einer Zeile „Offen: …“
  zusammen.
- [ ] AC-10 — Gegeben Windows (Git Bash, MSYS, Cygwin) oder ein unbekanntes System, dann
  bietet der Installer keine Installation über einen Paketmanager an. Er nennt
  `winget install jdx.mise` bzw. `scoop install mise` als Weg von Hand, verweist für
  Windows auf F-067 und richtet den Rest ein wie überall.
- [ ] AC-11 — Gegeben man liest die README, dann steht dort: Der Installer läuft auch
  ohne GitHub-Konto oder -Login. Der Satz „install.sh ist hier keine Option“ und der
  Kasten „läuft nur mit vollständig eingerichtetem GitHub“ sind weg. Die Toolchain kommt
  über mise (`mise use -g just lefthook gitleaks`), mit dem Hinweis zu Linux ohne brew.
- [x] AC-12 — Gegeben eine Änderung an `install.sh`, wenn `just check` läuft, dann laufen
  die Installer-Tests mit (Pfadliste in `scripts/script-tests.sh`). — belegt: `just check`
  meldet „script tests: install.sh changed — running them“.

### Randfälle

- EC-1 — Die Eingabe endet (EOF, etwa beim Start aus einem Skript) → es gelten die
  Standards. Bei einer Frage, die wiederholt würde (ungültige Adresse oder Host), bricht
  der Installer ab, statt endlos zu fragen.
- EC-2 — `git config --global` liefert keinen Namen bzw. keine Adresse → kein Vorschlag;
  ein leerer Name wird mit Warnung angenommen, eine leere Adresse heißt „beim Commit
  fragen“.
- EC-3 — `mise` ist installiert, aber nicht aktiv → `mise use -g` installiert trotzdem.
  `tool-check` zählt global installierte Tools über `mise which`, Schritt 6 bietet
  danach die Aktivierung an.
- EC-4 — Linux unter WSL → wird wie Linux behandelt, mit dem Hinweis, dass die
  Einrichtung nur für ein Claude Code innerhalb von WSL gilt.
- EC-5 — Die Tools sind schon per brew installiert → `tool-check` meldet sie als
  vorhanden, der Installer bietet nichts an und baut nichts um.
- EC-6 — macOS liefert bash 3.2 → der Installer nutzt nichts, was eine neuere bash
  verlangt.

### Nicht-Ziele

- Windows-Unterstützung des Installers (Paketmanager winget/scoop, Abbruchmeldung bleibt
  beim Start per Doppelklick sichtbar, Lauf in Git Bash geprüft) → F-067 (neu, neben
  F-027).
- Der Installer installiert `gh` nicht selbst.
- Kein Einrichten von apt- oder dnf-Repos für mise und kein Ausführen von `mise.run`.
- Eine vorhandene Personal-Config wird nicht ergänzt oder umgeschrieben — das macht
  `/coding-kit:update-conventions global`.
- GitLab und Forgejo bietet der Installer erst mit F-053 und F-054 an.

### Tests

- AC-1 bis AC-10, EC-1, EC-2, EC-4 → automatisch: neue Datei
  `tests/template-sync/install.sh`, von `run.sh` geladen. Sie startet `install.sh` mit
  bash, einem Test-HOME und eingespeisten Antworten. Auf dem PATH liegt nur ein Ordner
  mit Attrappen für `gh`, `claude`, `brew`, `pacman`, `sudo`, `mise`, `uname` und
  `xdg-user-dir`; sie schreiben ihre Aufrufe mit und täuschen Zustände vor. Daneben
  stehen Links auf die nötigen Systemwerkzeuge, damit ein echtes `gh` oder `brew` des
  Rechners nicht mitspielt. Geprüft werden Fragen, Ausgaben, Exit-Code, die
  geschriebene Personal-Config und die Aufrufe der Attrappen.
- AC-5 → im selben Test: die Config mit `.` einlesen und die Werte vergleichen.
- AC-11 → Durchsicht: README nach dem Schreiben neu lesen.
- AC-12 → `scripts/script-tests.sh` mit einer geänderten `install.sh` meldet „running
  them“.
- EC-6 → einmal von Hand mit `/bin/bash` (3.2) auf macOS.

### Einbettung

- Berührt: `install.sh` (Schritte 1, 3 und 5), `README.md` (Einrichtung, Manuell
  Schritt 4, Ohne GitHub), `tests/template-sync/run.sh` (lädt die neue Datei),
  `scripts/script-tests.sh` (Pfadliste).
- Wiederverwendet: `template-sync.sh set-global` schreibt Host und Commit-Adressen
  (prüft den Host, quotiert sicher, Kommentare aus den Kit-Regeln). Die übrigen
  Schlüssel (Login, Name, Projekte-Verzeichnis) schreibt der Installer selbst, mit
  derselben Quotierung. `tool-check` und `mise-check` bleiben, wie sie sind.
- Versionsregel: nichts davon ist Plugin-Inhalt, also keine neue Version.
- Sicherheit: Der Installer führt keinen Code aus dem Netz aus. `gh auth login` läuft nur
  nach Ja. Die Personal-Config behält `chmod 600`.
- Folge-Nummern: F-067 Installer unter Windows (Git Bash), über `/coding-kit:add-feature`.
  F-053 und F-054 ergänzen die Host-Liste des Installers.
- Kein Widerspruch zu Zielen, Nicht-Zielen oder Rahmenbedingungen. Die Rahmenbedingung
  „ohne GitHub läuft der Arbeitszyklus lokal weiter“ gilt damit auch für die Einrichtung.

### Offene Fragen

keine

### Entscheidungen

- 2026-11-22 — Toolchain über mise: nur mise selbst kommt über den Paketmanager, just,
  lefthook und gitleaks per `mise use -g`. Verworfen: alle vier über den Paketmanager,
  weil sich Paketnamen und Verfügbarkeit je Distribution unterscheiden.
- 2026-11-22 — Ohne brew und pacman nennt der Installer den Befehl für mise nur, statt
  `mise.run` auszuführen: kein Code aus dem Netz, und um den PATH kümmert sich der
  Nutzer selbst.
- 2026-11-22 — Windows wird eine eigene Nummer (F-067), weil es sich ohne Windows-Rechner
  nicht prüfen lässt. F-025 erkennt Windows nur und nennt den Weg von Hand.
- 2026-11-22 — Die Abzweigungen prüft ein automatischer Test mit Attrappen statt
  manueller Läufe, weil F-053 und F-054 den Installer wieder ändern.
- 2026-11-22 — Der Lauf ohne GitHub ist eine bestätigte Alternative (Standard: Nein),
  damit ein fehlender Login nicht unbemerkt zu einem Rechner ohne GitHub führt.

## Plan

**Größe:** M — vier Dateien und eine neue Testdatei, unter 500 Zeilen; mehrere
Abzweigungen (gh-Zustand, Host, Plattform), die offenen Fragen sind geklärt.

**Ansatz:** `install.sh` bleibt eine Bash-Datei mit ihren sechs Schritten. Schritt 1
unterscheidet die drei `gh`-Zustände und hält fest, ob der Lauf mit oder ohne GitHub
geht; hart abbrechen lässt ihn nur noch ein fehlendes `claude`. Schritt 3 fragt je nach
Lauf; eine Hilfsfunktion fragt mit Vorschlag und bricht bei Eingabeende ab, eine zweite
quotiert Werte wie `set-global`. Login, Name und Projekte-Verzeichnis schreibt der
Installer selbst, Host und Commit-Adressen `template-sync.sh set-global` in einen
Wegwerf-Ordner, von dem die fertige Datei an ihren Platz kommt. Schritt 5 bestimmt die
Plattform aus `uname`, holt mise über brew oder pacman bzw. nennt den Befehl und
installiert den Rest per `mise use -g`. Verworfen: neue Befehle in `template-sync.sh`
für gh-Zustand und Plattform (wie `mise-check`) — kein Skill braucht sie, sie wären
Plugin-Inhalt mit neuer Version, und testbar ist der Installer auch über die Attrappen.
Ebenso verworfen: `set-global` um Login, Name und Projekte-Verzeichnis erweitern — dafür
bräuchten die Kit-Regeln Kommentarzeilen zu Schlüsseln, die sie nicht betreffen.

**Erkennung (2a):** nichts Neues — mise, just, lefthook und gitleaks nutzt das Kit schon.
Keine neuen Endpunkte, Config-Schlüssel oder Dependencies.

### F-025a — gh-Zustände und Personal-Config

- `install.sh` Schritt 1 und 3: drei `gh`-Zustände, Login-Angebot, Lauf ohne GitHub,
  Host-Frage, Commit-Adresse je Host über `set-global`, sichere Quotierung,
  Projekte-Verzeichnis nach Plattform, vorhandene Config nur melden.
- Testgerüst `tests/template-sync/install.sh`: Ordner mit Links auf die nötigen
  Systemwerkzeuge plus Attrappen (`gh`, `claude`, `uname`, `xdg-user-dir`), Test-HOME,
  eingespeiste Antworten; von `run.sh` geladen. `install.sh` in die Pfadliste von
  `scripts/script-tests.sh`.
- README: Einrichtung und „Ohne GitHub“ — der Installer ist auch dort ein Weg.
- Erfüllt AC-1 bis AC-7, AC-11 (GitHub-Teil), AC-12; EC-1, EC-2, EC-6.

### F-025b — Plattform und Toolchain über mise

- `install.sh` Schritt 5: Plattform, mise über brew bzw. pacman (mit `sudo`) oder der
  genannte Befehl, Windows und Unbekanntes nur mit Weg von Hand, WSL-Hinweis, danach
  `mise use -g` für die fehlenden Tools, Schlusszeile „Offen: …“.
- Tests: Fälle für macOS mit brew, Linux mit brew, Arch, Linux ohne beides, Windows,
  WSL, Tools schon vorhanden; Attrappen `brew`, `pacman`, `sudo`, `mise`.
- README: Manuell Schritt 4 (Toolchain über mise statt brew für alle vier), Hinweis zu
  Linux ohne brew.
- Erfüllt AC-8 bis AC-10, AC-11 (Toolchain-Teil); EC-3 bis EC-5.

## Verlauf

### F-025a — fertig 2026-11-22

**Umgesetzt:** `install.sh` prüft zuerst `claude`, dann `gh` in drei Zuständen: bereit,
nicht angemeldet (bietet `gh auth login` an) oder fehlt (nennt `brew install gh` bzw. die
Seite von GitHub CLI). Ohne GitHub geht der Lauf nur nach „Ohne GitHub weitermachen?“
(Standard: Nein) weiter; bei Nein bricht er ab, bevor er etwas einrichtet. Gibt es die
Personal-Config schon, meldet er `gh` nur. Schritt 3 fragt mit GitHub den Host
(`github | azure | git`), ohne GitHub Autorname, Host (`git | azure`) und Commit-Adresse
mit Vorschlägen aus `git config --global`, dazu das Projekte-Verzeichnis
(`~/Documents`, sonst `xdg-user-dir DOCUMENTS`, sonst Home; ein führendes `~` wird
aufgelöst). Die Hilfsfunktion `ask_value` fragt bis zu einer gültigen Antwort und bricht
am Eingabeende ab, statt endlos zu fragen. Login, Name und Projekte-Verzeichnis schreibt
der Installer quotiert in eine Basisdatei; Host und Adressen setzt
`template-sync.sh set-global`, die fertige Datei kommt mit `umask 077` und `chmod 600`
an ihren Platz. `tests/template-sync/install.sh` startet `install.sh` mit bash in einer
leeren Umgebung (`env -i`) und Attrappen für `claude`, `gh`, `brew` und `xdg-user-dir`
(79 Checks je Durchlauf); `just check` lässt sie laufen, sobald sich `install.sh`
ändert. README: Einrichtung und „Ohne GitHub“ beschreiben den Lauf mit und ohne GitHub.

**Entscheidungen:** Neben einem Vorschlag heißt `-` „beim Commit fragen“, weil eine leere
Antwort den Vorschlag übernimmt (AC-4 entsprechend präzisiert). Fragen stehen mit
`printf` statt `read -p` auf der Standardausgabe — `read -p` zeigt sie nur am Terminal,
die Tests sähen sie sonst nicht. `claude` wird vor `gh` geprüft, damit niemand sich
anmeldet und dann am fehlenden `claude` scheitert.

**Abweichung vom Plan:** Die Attrappe für `uname` braucht erst F-025b. Der Test-HOME heißt
`test-home` und die Beispieladressen enden auf `example.com`/`example.org`, weil der
Validator `/home/…` als lokalen Pfad und andere Domains als echte Adressen meldet.

**Funde:** Vorhandene Fehler, behoben und getestet: Werte mit `"` oder `$` machten die
Personal-Config kaputt (keine Quotierung), und ein `~/…` als Projekte-Verzeichnis blieb
wörtlich stehen. Befunde des unabhängigen Reviews, behoben: Ein Tab oder `{{` in Name
oder Pfad hätte eine Config ergeben, die `template-sync.sh` ganz ablehnt (jetzt
abgelehnt und neu gefragt; ein solcher Name aus `gh api` weicht dem Login); der Hinweis
„leer lassen“ stimmte neben einem Vorschlag nicht (jetzt `-`); der README-Kasten nannte
mit GitHub nur die Host-Frage. Gegenprobe: sechs kaputte Kopien des Installers fielen
durch die Tests.
