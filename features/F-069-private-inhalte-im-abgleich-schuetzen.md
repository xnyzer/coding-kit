---
id: F-069
title: Private Inhalte beim Abgleich und im Privacy-Lint schützen
type: fix
status: IN-PROGRESS
size: L
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-069 — Private Inhalte beim Abgleich und im Privacy-Lint schützen

## Erfassung

**Problem:** Zwei Wege führen private Inhalte unbemerkt in ein öffentliches Repo:
- Das Template holt mit `!private/README.md` genau die Datei ins Git, die ein Projekt für
  private Notizen nutzen kann, und der Abgleich warnt nicht.
- Privacy-Lint überspringt jeden Pfad, der `/private/` enthält, unter macOS also alles
  unter `/private/tmp`. Ein Prüflauf über migrierte Dateien dort meldete 0 Funde, im
  Projekt waren es 17.

Dazu blockieren Fehlalarme legitime Commits.

**Ziel:**
- **Ist:**
  - `merge` meldet `private/README.md` als `two-way`, obwohl die Projektfassung
    ignoriert ist und private Daten enthält. Wer die Datei und `.gitignore` übernimmt,
    committet die Notizen.
  - `scan()` prüft `*/private/*` gegen den übergebenen Pfad statt gegen den Pfad relativ
    zum Repo.
  - Fehlalarme:
    - Vierteilige Versionen in Lock-Dateien (`uv.lock`) und Abschnittsnummern aus
      RFCs gelten als IP.
    - Browser-Versionen in Test-Strings gelten als IP: Ein User-Agent führt nach
      `Chrome/` eine vierteilige Versionsnummer.
    - Ein Pfad mitten in Fließtext gilt als lokaler Pfad, etwa eine Spaltenliste
      „Name/Users/…“ in einer Aufzählung.
    - Doku mit Sperrbereichen oder Platzhaltern blockiert jeden Commit, der die Datei
      stagt, denn eine versionierte Projekt-Allowlist gibt es nicht.
    - `.example` und `example.net` sind nicht erlaubt.
- **Soll:** Keine Datei wechselt beim Abgleich ohne Warnung von ignoriert zu sichtbar.
  Privacy-Lint prüft jede Datei, die er bekommt, und meldet nur echte Funde.
- **Reproduzieren:**
  - Projekt mit ignoriertem `private/README.md` → `merge`.
  - Privacy-Lint über eine Datei unter `/private/tmp`, die eine echte E-Mail-Adresse
    enthält → 0 Funde.

**Lösungsskizze:**
- `merge` prüft je Ziel mit `git check-ignore` gegen die aktuelle `.gitignore` des
  Projekts. Ist die Projektdatei ignoriert und weicht ab, gibt es die eigene Klasse
  `ignored`. Der Skill stoppt dann und schlägt vor, die Datei zuerst umzubenennen
  (etwa `private/notes.md`). Außerdem meldet `merge` jede heute ignorierte Datei, die
  mit dem Ergebnis der `.gitignore` sichtbar würde (`unignored`).
- Privacy-Lint nimmt `private/` nicht mehr aus. Er bekommt nur Dateien, die committet
  werden, und die Ausnahme verbarg genau das versionierte `private/README.md`.
- In Lock- und Pin-Dateien zählt eine IP nur als Host einer URL (nach `://` oder `@`).
  Pfade, E-Mails und Blocklist werden dort weiter geprüft, und `mise.lock` fällt
  darunter, statt übersprungen zu werden. Eine IP zählt nur, wenn jede Zahl höchstens
  255 ist und keine Ziffer angrenzt. Eine Zahl nach `§` ist keine IP. Reservierte
  Beispiel-Domains samt Subdomains kommen in die Allow-Liste.
- Eine Zahl direkt hinter einem Bezeichner mit Schrägstrich (`Chrome/`, `OPR/`) ist eine
  Produktversion, keine IP. Ein Pfad zählt nur, wenn vor seinem ersten Schrägstrich
  weder Buchstabe noch Ziffer, `.`, `_` oder `-` steht. Die Suche läuft in awk statt
  grep, weil diese Regeln auf das Zeichen vor dem Treffer schauen.
- Eine versionierte Projekt-Allowlist `privacy-allowlist.txt` mit Zeilen
  `allow <Wert> <Grund>`: ein exakter Wert je Zeile, gültig in jeder Datei, nie
  Bereiche. Projektzeilen überstehen den Merge wie in `license-policy.txt`. Bereiche wie
  10.x, 172.16.x und 192.168.x bleiben gesperrt, ein einzelner Wert daraus lässt sich
  freigeben.
- Verworfen:
  - Lock-Dateien ganz auszunehmen. Sie können private Registry-Hosts und lokale Pfade
    enthalten.
  - Nur `IP_RE` zu verschärfen. Eine vierteilige Version bleibt eine gültige IP.

**Abhängigkeiten:** keine.

**Noch zu analysieren:** geklärt in der Spezifikation.

## Spezifikation

Grundlage ist der Code-Stand vom 2026-11-22 (3.7.0). Alle Fälle der Erfassung sind
nachgestellt. Dazu kommen drei weitere Fehlalarme: Subdomains der Beispiel-Domains
(`admin@mail.example.com`) und Teiltreffer in längeren Zahlenfolgen. So gilt bei
`2024.1.1.1` alles ab der zweiten Ziffer als IP, bei einer fünfteiligen Folge die
ersten vier Teile. Vierteilige Versionen stehen in Lock-Dateien von Python
(`opencv-python`) und Ruby (Rails in `Gemfile.lock`). Composer und NuGet erlauben sie
ebenfalls, und Pin-Listen wie `requirements.txt` tragen sie genauso. `mise.lock` enthält
heute keinen Treffer, ihre Ausnahme war nur vorsorglich. Für den Privacy-Lint gibt es
keine Kit-Tests.

Stories, nach Priorität:

1. Wer ein Projekt abgleicht, verliert keine privaten Notizen und committet sie nicht.
   Das gilt auch dann, wenn eine Template-Datei oder die neue `.gitignore` sie
   sichtbar machen würde.
2. Wer committet, bekommt jeden echten Fund gemeldet, egal wo die Datei liegt.
3. Wer committet, wird nicht durch Fehlalarme blockiert. Was trotzdem legitim ist, gibt
   das Projekt einzeln und mit Grund frei.

Regeln mit Beispielen. `N` steht für eine Zahl, `<name>` für einen Namen. So meldet der
Kit-Validator die Beispiele nicht, die Tests nutzen volle Werte.

| Regel | Fund | Kein Fund |
|-------|------|-----------|
| R1 — Jede übergebene Datei wird geprüft, auch unter `private/` und `/private/tmp`. | echte E-Mail in `/private/tmp/x.md` oder im gestagten `private/README.md` | Template-Fassung von `private/README.md` |
| R2 — Eine IP zählt nur, wenn jede Zahl höchstens 255 ist und weder eine Ziffer noch `.Ziffer` angrenzt. | `10.1.2.N`, `10.1.2.N:8080`, `… 10.1.2.N.` am Satzende | `2024.1.1.1`, fünfteilige Folgen, `2.31.0.20240406`, ein Teil über 255 |
| R3 — In Lock- und Pin-Dateien zählt eine IP nur als Host einer URL (nach `://` oder `@`). Lock-Dateien: `*.lock`, `*-lock.json`, `*-lock.yaml`, `*.lockfile`, `packages.lock.json`, `npm-shrinkwrap.json`, `go.sum`, `Package.resolved`. Pin-Listen: `requirements*.txt`, `constraints*.txt`. Pfade, E-Mails und Blocklist gelten dort weiter. | `https://10.1.2.N/simple`, `git@10.1.2.N:repo` in `uv.lock`; `/home/<name>` in `mise.lock` | `7.1.3.N` in `Gemfile.lock`, `==4.10.0.N` in `requirements.txt`, die `mise.lock` eines neuen Projekts |
| R4 — Eine Zahl nach `§` ist keine IP. | `10.1.2.N` im Fließtext | `§ 4.1.2.N`, `§4.1.2.N` |
| R5 — Eine Zahl direkt nach einem Produktnamen mit Schrägstrich ist eine Version. Vor dem Namen steht Zeilenanfang, Leerzeichen, Klammer oder Anführungszeichen. | `/srv/10.1.2.N`, `example.com/10.1.2.N` | `Chrome/131.0.0.N`, `"Edg/131.0.0.N"` |
| R6 — Ein Pfad zählt nur, wenn vor seinem ersten `/` kein Buchstabe, keine Ziffer, kein `.`, `_` oder `-` steht. Der Fund nennt den Pfad. | `/Users/<name>`, `C:/Users/<name>`, `"/home/<name>/x"` | `Name/Users/…`, `src/home/…` |
| R7 — Reservierte Beispiel-Domains sind erlaubt: `example.com`, `example.net`, `example.org` samt Subdomains und die Endungen `.example`, `.test`, `.invalid`, `.localhost`. | `<name>@example.co`, `<name>@example.com.evil.de` | `admin@mail.example.com`, `<name>@x.example`, `<name>@example.net`, `<name>@ci.test` |
| R8 — Ein Wert aus `privacy-allowlist.txt` (`allow <Wert> <Grund>`) ist überall frei, aber nur genau dieser Wert. | eine andere Adresse desselben Bereichs, etwa die nächste | genau der eingetragene Wert, etwa `<Netzadresse>` bei `allow <Netzadresse> SSRF-Sperrliste in der Doku` |
| M1 — Eine Template-Datei, deren Projektfassung unversioniert, ignoriert und anders als das Template ist, wird `ignored` und bekommt kein Ergebnis. | ignoriertes `private/README.md` mit Notizen | versioniertes `private/README.md` mit Abweichung; ignoriertes, das dem Template gleicht |
| M2 — Jede heute ignorierte Datei, die das Merge-Ergebnis der `.gitignore` nicht mehr ignoriert, wird als `unignored` gemeldet. | `keys/server.pem`, wenn `*.pem` im Ergebnis fehlt | `node_modules/…`, das auch das Ergebnis ignoriert; eine Datei, die eine verschachtelte `.gitignore` ignoriert |

### Abnahmekriterien

- [x] AC-1 — Gegeben ein Projekt (Git-Repo), das `private/` ganz ignoriert und ein
  abweichendes `private/README.md` hat, wenn `merge` läuft, dann meldet es die Datei als
  `ignored` und legt für sie kein Ergebnis an. `/update-conventions` übernimmt sie
  nicht, sondern klärt sie vor allen anderen Entscheidungen: umbenennen (Vorschlag
  `private/notes.md`) oder als `skip` registrieren, danach neu mergen. Negativ: Eine
  versionierte oder dem Template gleiche Datei behält ihre bisherige Klasse. Ein
  Projekt ohne Git bekommt nie `ignored`.
  — belegt: Kit-Tests in `tests/template-sync/sync.sh` (abweichende ignorierte Datei
  `ignored` ohne Ergebnis; Gegenproben gleich, versioniert, ohne Git, `skip`), Ablauf in
  `/update-conventions` A2 Schritt 4; `just check` grün.
- [x] AC-2 — Gegeben ein Projekt mit heute ignorierten Dateien, wenn das
  Merge-Ergebnis der `.gitignore` eine davon nicht mehr ignoriert, dann meldet `merge`
  sie je Zeile als `unignored`. `/update-conventions` zeigt die Liste, bevor es die
  `.gitignore` anbietet. Wahl je Datei: verschieben (etwa nach `private/`), bewusst
  sichtbar machen oder die `.gitignore` diesmal nicht übernehmen. Negativ: Eine Datei,
  die ignoriert bleibt, erscheint nicht. Das gilt, ob das Ergebnis selbst, eine
  verschachtelte `.gitignore`, `.git/info/exclude` oder die globale Ausschlussdatei sie
  ignoriert. Bei unveränderter `.gitignore` gibt es keine Zeile.
  — belegt: Kit-Tests in `sync.sh` (Schlüssel, Name mit Leerzeichen und Umlaut,
  `private/README.md`, Konflikt, fehlende und gelöschte `.gitignore`; nicht gemeldet bei
  Ausschluss durch das Ergebnis, eine verschachtelte `.gitignore`, `.git/info/exclude`
  oder `core.excludesFile`; unveränderte `.gitignore` ohne Zeile), Ablauf in
  `/update-conventions` A2 Schritt 5; `just check` grün.
- [ ] AC-3 — Gegeben eine Datei mit einer echten E-Mail-Adresse, wenn der Lint sie
  prüft, dann meldet er den Fund (R1). Das gilt auch unter `/private/tmp`, als
  gestagtes `private/README.md` und als `mise.lock`. Negativ: Die Template-Fassung von
  `private/README.md` ergibt keinen Fund.
- [ ] AC-4 — Gegeben die Werte der Spalte „Kein Fund“ zu R2 bis R7, wenn der Lint sie
  prüft, dann meldet er nichts. Negativ: Jeder Wert der Spalte „Fund“ bleibt ein Fund,
  vor allem eine IP als URL-Host und ein lokaler Pfad in einer Lock-Datei.
- [ ] AC-5 — Gegeben eine `privacy-allowlist.txt` mit
  `allow <Netzadresse> SSRF-Sperrliste in der Doku` für die Netzadresse eines privaten
  Bereichs, wenn eine Datei diese Adresse mit Präfixlänge enthält (etwa `/8`), dann gibt
  es keinen Fund, die nächste Adresse desselben Bereichs bleibt einer. Negativ: Eine
  Zeile ohne Grund, mit `*` oder mit einer Präfixlänge ist ein Fehler. Er macht den Lint
  rot und nennt die Zeile. Fehlt die Datei, gelten nur die eingebauten Ausnahmen.
- [ ] AC-6 — Gegeben ein Projekt mit eigenen Zeilen in `privacy-allowlist.txt`, wenn
  `/update-conventions` eine geänderte Template-Fassung mergt, dann bleiben die
  Projektzeilen erhalten (`merged`). Negativ: Das Template selbst bringt keine
  `allow`-Zeile mit.
- [ ] AC-7 — Gegeben das Kit, wenn `just check` läuft und man die Doku liest, dann gilt:
  - Das MANIFEST führt `privacy-allowlist.txt`.
  - Der Kopf des Lints, `private/README.md` und `CONTRIBUTING.md` beschreiben die
    Regeln und die Allowlist.
  - `private/README.md` sagt, dass die Datei versioniert ist und keine Notizen
    aufnimmt.
  - Der Kopf von `template-sync.sh` und `/update-conventions` beschreiben `ignored` und
    `unignored`.
  - Der CHANGELOG-Eintrag hat `### Template`.

  Negativ: Im Text stehen keine Versionsstände.

### Randfälle

- EC-1 — Projekt ohne Git → weder `ignored` noch `unignored`, die Klassen bleiben wie
  bisher.
- EC-2 — Das Projekt ist ein Unterordner seines Repos (Monorepo) → `ignored` wirkt.
  `unignored` wird nicht berechnet, `merge` sagt das in einer Warnung, und der Skill
  zeigt sie. Volle Unterstützung kommt mit F-076.
- EC-3 — Projekt ohne eigene `.gitignore` → `unignored` vergleicht mit dem, was heute
  nur `.git/info/exclude` und die globale Ausschlussdatei ignorieren.
- EC-4 — Ignorierte Template-Datei mit `skip`-Zeile → `skipped`, keine Warnung.
- EC-5 — Viele ignorierte Dateien (`node_modules`, `.venv`) → Gemeldet werden nur
  Dateien, die wechseln. Die Laufzeit bleibt bei wenigen Sekunden.
- EC-6 — Dateinamen mit Leerzeichen oder Umlauten → Lint und `unignored` melden sie
  korrekt.
- EC-7 — Allowlist mit Kommentar- und Leerzeilen, E-Mail-Werte in anderer
  Schreibweise → Kommentare und Leerzeilen zählen nicht. E-Mails vergleicht der Lint
  ohne Rücksicht auf Groß- und Kleinschreibung.
- EC-8 — Git scheitert bei der Prüfung auf „ignoriert“ in einem Git-Projekt → `merge`
  bricht mit Meldung ab, statt still weiterzumachen.

### Nicht-Ziele

- Keine neuen Muster (Windows-Pfade mit `\`, IPv6, Hostnamen) und keine Änderung an der
  Blocklist.
- Kein verlustfreier Erstabgleich und keine Vereinigung für `.gitignore` (→ F-071),
  keine weiteren Merge-Klassen (→ F-070).
- Kein Umbau des Kit-eigenen Validators `scripts/validate.py`, denn er prüft nur das
  Kit-Repo.
- Kein Bereinigen der Historie für schon committete Funde (→ `/coding-kit:go-public`).

### Tests

- AC-1: automatisch, in `tests/template-sync/sync.sh`. Ein Projekt als Git-Repo mit
  `private/` in der `.gitignore` ergibt `ignored` ohne Ergebnis. Gegenproben:
  versioniert, gleich, ohne Git, mit `skip`.
- AC-2: automatisch, in `sync.sh`. Fehlt `*.pem` im Ergebnis, kommt `unignored`.
  Gegenproben: verschachtelte `.gitignore`, `.git/info/exclude`, unveränderte
  `.gitignore`, Projekt als Unterordner (Warnung).
- AC-3, AC-4: automatisch, in der neuen Suite `tests/template-sync/privacy.sh` mit
  den Beispielen der Regeltabelle (beide Spalten), unter dash und bash, mit mawk und
  gawk.
- AC-5: automatisch, in `privacy.sh`. Der Eintrag wirkt genau für seinen Wert. Ohne
  Grund, mit `*` oder mit `/8` wird der Lint rot und nennt die Zeile. Ohne Datei gelten
  die eingebauten Ausnahmen.
- AC-6: automatisch, in `sync.sh`. Basis ist der alte Kopf, das Projekt hat Kopf plus
  Zeile, das Template einen neuen Kopf. Erwartet: `merged`, die Zeile bleibt.
- AC-7: Check mit `just check` (MANIFEST-Vertrag) und `just version-rule`. Manuell:
  Lint mit `--all` über ein frisch gerendertes Projekt aus dem Arbeitsstand ergibt 0
  Funde; die Doku lesen.

### Einbettung

- Berührt werden:
  - `template/core/scripts/privacy-lint.sh` und die neue
    `template/core/privacy-allowlist.txt`
  - `template/core/private/README.md` und `template/core/CONTRIBUTING.md`
  - das MANIFEST und `merge` in `scripts/template-sync.sh`
  - der Skill update-conventions
  - die Kit-Tests (`run.sh`, `sync.sh`, neu `privacy.sh`)
  - CHANGELOG und Version
- Der Lint braucht künftig awk neben grep, weil die Regeln auf das Zeichen vor dem
  Treffer schauen. awk ist POSIX und in Git Bash enthalten, der Kopf des Skripts sagt
  das.
- Bestehende Projekte bekommen Lint und Allowlist über `/update-conventions`. Danach
  prüft der Lint `private/README.md` und `mise.lock` mit, und Funde dort sind echt.
- Der Kit-Validator (`scripts/validate.py`) prüft auch Feature-Dateien, Tests und
  CHANGELOG des Kits. Beispielwerte stehen dort mit Platzhaltern wie oben, die Tests
  setzen volle Werte erst zur Laufzeit zusammen.
- `/coding-kit:go-public` nutzt den Lint und profitiert ohne eigene Änderung. Seine
  Liste erlaubter Platzhalter zieht im selben Schritt nach (R7).
- F-071 baut auf `unignored` auf: Mit der Vereinigung für `.gitignore` sollte der
  Erstabgleich keine solchen Zeilen mehr erzeugen. F-070 ändert die Klassen der
  Inhalte, `ignored` wird vor ihnen vergeben und kommt ihnen nicht in die Quere.
- Kein Widerspruch zu Zielen, Nicht-Zielen oder einem ADR.

### Offene Fragen

Keine.

### Entscheidungen

- 2026-11-22 — Größe L: eine Sicherheitsprüfung, die in jedes Projekt geht, und etwa
  zehn Dateien. Entscheidung des Nutzers nach Empfehlung.
- 2026-11-22 — Die Ausnahme für `private/` entfällt ganz, statt nur relativ zur Wurzel
  zu gelten. Grund: Der Lint bekommt nur Dateien, die committet werden. Die Ausnahme
  verbarg genau das versionierte `private/README.md`. Empfehlung war, von der Skizze
  abzuweichen. Entscheidung des Nutzers nach Empfehlung.
- 2026-11-22 — `merge` meldet neben `ignored` auch jede Datei, die durch das Ergebnis
  der `.gitignore` sichtbar würde (`unignored`). Grund: Der Erstabgleich ohne Basis
  verliert Projektzeilen der `.gitignore`, bis F-071 das behebt. Entscheidung des
  Nutzers nach Empfehlung.
- 2026-11-22 — Die Projekt-Allowlist heißt `privacy-allowlist.txt`, liegt im Root und
  hat Zeilen der Form `allow <Wert> <Grund>`. Ein Wert gilt genau so in jeder Datei,
  auch eine einzelne private IP. Bereiche sind nie erlaubt. Entscheidung des Nutzers
  nach Empfehlung.
- 2026-11-22 — Zwei Ergänzungen zu den Regeln nach Umgebung, kein Ersatz für sie:
  - Eine IP zählt nur, wenn jede Zahl höchstens 255 ist und keine weitere Ziffer
    angrenzt (R2). Die Skizze verwarf nur, allein `IP_RE` zu verschärfen.
  - Lock- und Pin-Dateien erkennt der Lint am Dateinamen, nach Muster statt nach einer
    Liste je Sprache. `mise.lock` fällt darunter (R3).

## Plan

**Größe:** L. Es geht um eine Sicherheitsprüfung, die in jedes Projekt geht, und um den
Abgleich, den jede Migration nutzt. Dazu kommen etwa zehn Dateien.

**Ansatz:**

- **Abgleich:**
  - `merge` fragt Git, bevor es eine Inhaltsklasse vergibt. Ist die Projektfassung eines
    Ziels unversioniert und ignoriert und weicht sie vom Template ab, heißt sie
    `ignored`, und es entsteht kein Ergebnis.
  - Weicht das Ergebnis der `.gitignore` von der Projektfassung ab, baut `merge` in
    seinem Arbeitsordner ein leeres Hilfs-Repo. Es trägt das Ergebnis als `.gitignore`
    und dazu die übrigen Ausschlussquellen des Projekts: verschachtelte
    `.gitignore`-Dateien, `.git/info/exclude` und ein im Projekt gesetztes
    `core.excludesFile`. Die heute ignorierten Dateien laufen durch `git check-ignore`
    dieses Hilfs-Repos. Jede, die dort nicht mehr ignoriert ist, wird eine Zeile
    `unignored`.
  - Ohne Git entfallen beide Prüfungen. Ist das Projekt ein Unterordner seines Repos,
    entfällt `unignored` mit einer Warnung. Scheitert Git, bricht `merge` ab.
- **Skill:** `/update-conventions` klärt `ignored`-Zeilen vor allen anderen
  (umbenennen nach OK oder `skip`, dann neu mergen). Die `unignored`-Zeilen zeigt er bei
  der Entscheidung über die `.gitignore`.
- **Lint:**
  - Die Suche nach Pfaden, IPs und E-Mails wandert von grep in ein awk-Programm je Datei.
    Es findet jeden Kandidaten und prüft die Zeichen davor und danach (R2 bis R7), dann
    die eingebauten Ausnahmen und die Allowlist.
  - Die Blocklist bleibt bei `grep -F`.
  - Ob eine Datei eine Lock- oder Pin-Datei ist, entscheidet ihr Name. Die Ausnahmen für
    `private/` und `mise.lock` entfallen.
  - Das awk-Programm kommt ohne Wiederholungs-Klammern wie `{3}` aus, weil ältere
    mawk-Versionen sie nicht kennen.
- **Allowlist:** `core/privacy-allowlist.txt` ist eine managed Datei mit erklärendem Kopf
  und ohne Einträge, wie `license-policy.txt`. Der Lint liest sie wie die Blocklist aus
  dem Arbeitsordner, also der Wurzel des Repos. Eine fehlerhafte Zeile ist ein Fund mit
  Zeilennummer, der Lint wird rot.
- **Verworfen:**
  - Für `unignored` nur die neuen `!`-Zeilen der `.gitignore` auswerten. Das übersieht
    weggefallene Zeilen wie `*.pem`.
  - Erst nach dem Kopieren der `.gitignore` mit `git status` prüfen. Dann ist die Datei
    schon sichtbar, und der Skill müsste zurückdrehen.
  - Den Lint bei grep lassen und nachfiltern. grep kann das Zeichen vor einem Treffer nur
    prüfen, indem es dieses Zeichen mit in den Treffer nimmt. Dann fehlt es dem nächsten
    Treffer direkt dahinter, und der geht verloren.

**Erkennung:** entfällt. Es kommen keine neue Sprache, kein Framework und keine
Dependency dazu, und awk nutzt das Kit schon.

**Neu:** die Datei `privacy-allowlist.txt` in jedem Projekt und die Merge-Klassen
`ignored` und `unignored`. Keine Env-Vars, keine Endpunkte, keine Dependencies.

**Version:** eine Version über dem gepushten Stand, gemeinsam für alle drei
Teilschritte. Der CHANGELOG-Eintrag bekommt mit F-069b einen Abschnitt `### Template`.

### F-069a — Abgleich schützt ignorierte Dateien

- `merge` in `template-sync.sh` vergibt `ignored` und meldet `unignored`, und der Kopf
  des Skripts beschreibt beide.
- `/update-conventions` behandelt sie in Schritt 4 und 5 und in der Migration (A3).
- Kit-Tests in `sync.sh` mit einem Projekt als Git-Repo.

Erfüllt AC-1, AC-2 und den Teil von AC-7 zu Skript-Kopf und Skill.

### F-069b — Privacy-Lint prüft jede Datei und meldet nur echte Funde

- `core/scripts/privacy-lint.sh` bekommt die awk-Suche mit R1 bis R7, und sein Kopf
  nennt awk als Voraussetzung.
- `core/private/README.md` sagt, dass die Datei versioniert ist und keine Notizen
  aufnimmt.
- Die Platzhalterliste von `/coding-kit:go-public` zieht nach (R7).
- Neue Suite `tests/template-sync/privacy.sh`, eingebunden in `run.sh`. Die Testwerte
  entstehen zur Laufzeit, damit der Kit-Validator sie nicht meldet.

Erfüllt AC-3, AC-4 und den Teil von AC-7 zu Lint-Kopf und `private/README.md`.

### F-069c — Projekt-Allowlist für den Privacy-Lint

- Neue managed Datei `core/privacy-allowlist.txt` mit MANIFEST-Zeile.
- Der Lint liest sie (R8) und meldet fehlerhafte Zeilen.
- `CONTRIBUTING.md` und `private/README.md` nennen sie.
- Tests in `privacy.sh` für die Einträge und in `sync.sh` dafür, dass Projektzeilen den
  Merge überstehen.

Erfüllt AC-5, AC-6 und den Rest von AC-7.

## Verlauf

### F-069a — fertig 2026-11-22

**Umgesetzt:**

- `merge` in `plugins/coding-kit/scripts/template-sync.sh` fragt Git, bevor es eine
  Inhaltsklasse vergibt. Eine Template-Datei, deren Projektfassung unversioniert und
  ignoriert ist und vom Template abweicht, wird `ignored` und bekommt kein Ergebnis.
- Ändert sich die `.gitignore` (auch bei `new`, `missing` und `conflict`), baut `merge`
  ein Hilfs-Repo mit der neuen Fassung und den übrigen Ausschlussquellen des Projekts
  (`exclude_repo`). Jede heute ignorierte Datei, die dort nicht mehr ignoriert ist,
  meldet es als `unignored` (`report_unignored`).
  - Ohne Git entfällt beides.
  - Unterhalb der Repo-Wurzel kommt eine Warnung.
  - Ein unlesbares `.git` bricht ab.
- `/update-conventions`:
  - klärt `ignored` in A2 Schritt 4 vor allem anderen;
  - zeigt `unignored` in Schritt 5, bevor es die `.gitignore` anbietet;
  - nimmt `ignored` in Schritt 9 vom Snapshot aus;
  - nennt in A3 Schritt 2 (b) den zweiwegigen Erstabgleich.
- 35 neue Prüfungen je Durchlauf in `tests/template-sync/sync.sh`. 30 006 ignorierte
  Dateien prüft `merge` in etwa 0,4 Sekunden.

**Entscheidungen:**

- 2026-11-22 — Bei einem Konflikt in der `.gitignore` gilt die `unignored`-Liste für
  die Auflösung zugunsten des Templates, bei einer gelöschten `.gitignore` für die
  wiederhergestellte Template-Fassung. Grund: Diese Fassungen verlieren die meisten
  Projektzeilen bzw. kommen beim Wiederherstellen ins Projekt.
- 2026-11-22 — Nach `skip` für eine `ignored`-Datei wird nicht neu gemergt, nur nach dem
  Umbenennen. Grund: Die Registry-Zeile entsteht erst in Schritt 10, ein neuer Merge
  ergäbe dasselbe.

**Abweichung vom Plan:**

- Der Abschnitt `### Template` im CHANGELOG kommt schon mit F-069a statt erst mit
  F-069b, weil `/add-skill` verlangt, die Skill-Übersicht in
  `HOW-TO-CODE-WITH-CLAUDE.md` mitzuziehen.
- Dazu kamen die README-Zeile von `/update-conventions` und Schritt 9 des Skills.

**Funde:**

- Die neuen Testordner kollidierten mit Namen aus anderen Test-Dateien, weil sich alle
  Fälle eines Durchlaufs ein `$TMP` teilen. Im Gesamtlauf scheiterten dadurch 60
  fremde Prüfungen. Behoben mit dem Präfix `ig-`.
- Unabhängiges Review: Eine gelöschte `.gitignore` wurde nicht geprüft (behoben, Test
  ergänzt). In Schritt 9 fehlte `ignored` bei den Ausnahmen (behoben). Der Hinweis,
  nach `skip` neu zu mergen, ist verworfen (siehe Entscheidungen).
