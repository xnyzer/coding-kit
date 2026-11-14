---
id: F-059
title: Renovate hebt die mise-Tools in mise.lock an
type: fix
status: IN-PROGRESS
size: M
created: 2026-11-13
done:
depends-on:
superseded-by:
---

# F-059 — Renovate hebt die mise-Tools in mise.lock an

## Erfassung

**Problem:** Das Template trägt die Tools in `mise.toml` mit Hauptversion ein, die genaue
Version steht in `mise.lock`. Renovate hebt diese genaue Version nicht an: Die Tools
bleiben auf dem Stand, mit dem das Projekt angelegt wurde, bis jemand von Hand
`mise lock --bump` ausführt — auch gitleaks mit seinen Sicherheitsupdates. Das
widerspricht der Rahmenbedingung, dass Renovate die mise-Pins aktuell hält; F-031 ist
davon ausgegangen, dass Renovate `mise lock` ausführt.

**Ziel:**
- Ist: In einem Downstream-Projekt stehen just und lefthook Monate hinter der neuesten
  Version ihrer Hauptversion, Renovate schlägt nichts vor und hat `mise.lock` nie
  geändert. Ein lokaler Renovate-Lauf (lookup) erkennt bei `"go:…/v2" = "2"` mit
  gesperrtem 2.0.0 „nur Sperrdatei“, findet aber kein Update, obwohl 2.0.1 existiert.
- Soll: Neue Versionen innerhalb der Hauptversion kommen ohne Handarbeit an — gebündelt,
  höchstens wöchentlich, bei grüner CI automatisch gemergt. `mise.toml` behält die
  Hauptversionen.
- Reproduzieren: Projekt aus dem Template mit Renovate; ein Tool, dessen gesperrte
  Version älter ist als die neueste derselben Hauptversion → kein PR, kein Eintrag im
  Dashboard.

**Lösungsskizze:**
- Ziel: Renovates Lock File Maintenance im Preset (`mise lock --bump`, wöchentlich, ein
  PR für alle Tools, Automerge bei grüner CI). Gilt über das Preset auf jedem Host mit
  Renovate; Renovate muss dafür `mise` ausführen dürfen — auf GitHub entscheidet das der
  gehostete Dienst, auf anderen Hosts der Betreiber des Renovate-Laufs.
- Ohne Renovate (Host `git`): ein Rezept, etwa `just bump-tools`, das die Sperrdatei
  von Hand auffrischt.
- Verworfen: ein eigener CI-Job als Ausweich – der gehostete Dienst führt `mise` aus
  (siehe Spezifikation).
- Verworfen: genaue Versionen in `mise.toml` für alle Tools — ein PR je Tool und
  Version, die Sperrdatei muss trotzdem mitgehen, und das Muster aller Projekte ändert
  sich.

**Abhängigkeiten:** keine.

**Noch zu analysieren (Spike zuerst):**
- Darf der gehostete Renovate-Dienst auf GitHub `mise` ausführen (Lock File
  Maintenance)? Was muss der Betreiber auf anderen Hosts erlauben?
- Ist das fehlende Update ein Fehler in Renovate (etwa der Vergleich von „v2.0.1“ mit
  einem Filter auf „2…“)? Dann gehört ein Bericht an Renovate dazu.
- Warum bekommt ein Tool aus dem mise-Kern (node) Vorschläge für die Sperrdatei, Tools
  aus anderen Quellen (aqua, go) nicht?
- Freigabe über das Dashboard (`:dependencyDashboardApproval`) hält Updates zurück; ob
  das für Tool-Updates entfallen soll, entscheidet jedes Projekt selbst.
- `mise lock` in einem frischen Projekt legt die lokal installierte Version fest, nicht
  die neueste derselben Hauptversion (beobachtet bei just in F-057c) — gilt das auch für
  neue Projekte aus `/coding-kit:new-project`?

## Spezifikation

Grundlage ist der Code-Stand vom 2026-11-14 und der Spike in prep-step. Renovates
mise-Manager kann `mise.lock` per Lock File Maintenance pflegen; er führt dann
`mise lock --bump` aus und hebt jedes Tool auf die neueste Version seiner Hauptversion.
Der gehostete Dienst auf GitHub führt `mise` aus (öffentlich beobachtet im Oktober
2026). Ein selbst betriebenes Renovate muss `mise` erst freischalten
(`allowedUnsafeExecutions`). Ein einfaches `mise lock` in einem neuen Projekt legt die
lokal installierte Version fest, nicht die neueste (lefthook 2.1.9 statt 2.2.2).

### Abnahmekriterien

- [ ] AC-1 — Gegeben ein Projekt, dessen `renovate.json` das Preset nutzt und das eine
  `mise.lock` hat, wenn Renovate im Zeitfenster der Lock File Maintenance läuft, dann
  öffnet es einen PR, der nur `mise.lock` ändert und die Tools auf die neueste Version
  ihrer Hauptversion hebt, und mergt ihn bei grüner CI selbst. Negativ: Andere
  Sperrdateien (`package-lock.json`, `uv.lock` …) und `mise.toml` bleiben unverändert.
- [x] AC-2 — Gegeben `docs/renovate-preset.md` und der Abschlussbericht von
  `/coding-kit:new-project` auf Azure, wenn man sie liest, dann nennen sie die neue Regel
  und was ein selbst betriebenes Renovate dafür braucht (`mise` freischalten, ein Image
  mit mise). Negativ: Der Text nennt keine Versionsstände. — belegt:
  `docs/renovate-preset.md` und der Abschlussbericht für Azure in new-project nennen
  Freischaltung und Image ohne Versionsstand; `just check` grün.
- [x] AC-3 — Gegeben ein neues Projekt, dessen Tools auf dem Rechner in älterer Version
  installiert sind, wenn `/coding-kit:new-project` § 4d läuft, dann steht in `mise.lock`
  die neueste Version jeder Hauptversion, `mise install` installiert genau sie, und die
  Plattform-Einträge sind vollständig (`template-sync.sh lock-check`). Negativ:
  `/choose-stack` und `/update-conventions` heben eine bestehende `mise.lock` weiter
  nicht an. — belegt: Durchlauf F-059a (just 1.59.0 und lefthook 2.2.2 statt lokal
  1.55.1 und 2.1.9, `lock-check` vollständig); choose-stack § Lock-Datei schließt
  `--bump` für bestehende Projekte aus, update-conventions unverändert.
- [x] AC-4 — Gegeben ein Projekt aus dem Template mit einem beliebigen Stack-Modul, wenn
  `just bump-tools` läuft, dann hebt es `mise.lock` an wie Renovate
  (`mise lock --bump`), `mise.toml` bleibt unverändert. Negativ: Fehlt das Rezept in
  einer justfile des Templates, meldet `just check` des Kits das. — belegt: Validator
  in `just check` mit Gegenprobe; Durchlauf F-059b (just von 1.55.1 auf 1.59.0,
  `mise.toml` unverändert, alle vier Module kennen das Rezept).
- [x] AC-5 — Gegeben ein bestehendes Projekt, wenn es `/update-conventions` holt, dann
  bekommt es das Rezept; der CHANGELOG-Eintrag 3.5.0 hat unter `### Template` das Rezept
  und sagt, dass die Preset-Regel ohne Zutun des Projekts wirkt. Negativ: `just check`
  des Kits ist grün. — belegt: Drei-Wege-Merge eines Go-Projekts vom Stand vor F-059b
  (justfile `merged` ohne Konflikt, mit `bump-tools` und eigenem Rezept); CHANGELOG
  3.5.0 `### Template`; `just check` und Versionsregel grün.

### Randfälle

- EC-1 — Projekt ohne Status-Checks → Renovate mergt nicht automatisch, der PR bleibt
  offen (Renovate wartet auf grüne Checks).
- EC-2 — Projekt mit `:dependencyDashboardApproval` → der PR kommt erst nach Freigabe
  im Dashboard; das bleibt Sache des Projekts.
- EC-3 — Selbst betriebenes Renovate ohne Freischaltung von `mise` → keine Pflege der
  `mise.lock`; die Doku nennt die Einstellung, `just bump-tools` bleibt der Handweg.
- EC-4 — Eine neue Version hat noch nicht für jede Plattform einen Download →
  `mise lock --bump` scheitert oder die CI mit `--locked` wird rot; es wird nicht
  gemergt.
- EC-5 — Projekt mit eigener justfile (`keep`) → `/update-conventions` ändert sie nicht,
  der `### Template`-Abschnitt nennt das Rezept zum Nachtragen.
- EC-6 — Host `git` ohne Renovate → nur `just bump-tools`.

### Nicht-Ziele

- Keine Lock File Maintenance für die Sperrdateien der Stack-Module (npm, uv …).
- Kein eigener CI-Job als Ausweich; der gehostete Dienst führt `mise` aus.
- Kein Fehlerbericht an Renovate zu Hauptversionen bei aqua- und go-Tools; `--bump`
  umgeht ihn.
- `/choose-stack` und `/update-conventions` erzeugen die Sperrdatei weiter ohne
  `--bump`; dort soll ein Modulwechsel nicht nebenbei alle Tools heben.
- Das Kit-Repo selbst bekommt kein Rezept; es hängt am Preset wie jedes Projekt.

### Tests

- AC-1: Check — `renovate-config-validator` auf `default.json`; manuell in F-059c: nach
  Push der PR „Lock file maintenance“ im Kit-Repo, der nur `mise.lock` ändert.
- AC-2: manuell — Doku lesen; `just check` (Privacy- und Versions-Lint).
- AC-3: manuell — Projekt aus dem Arbeitsstand mit lokal älterem lefthook, Befehl aus
  § 4d, danach `lock-check` und Versionen in `mise.lock`.
- AC-4: Check — Validator prüft `bump-tools` in allen Template-justfiles (Negativfall:
  Rezept entfernt → Meldung); manuell `just bump-tools` in einem gerenderten Projekt.
- AC-5: Check — `just check`, `just version-rule`, CHANGELOG mit `### Template`.

### Einbettung

- Berührt: `default.json` (Preset), `docs/renovate-preset.md`,
  `skills/new-project/SKILL.md` (§ 4d, Abschlussbericht Azure), die justfiles in
  `template/core` und den Modulen go, python, ts-node, MANIFEST § Standard recipe set,
  `scripts/validate.py`, Kopfkommentar von `template/core/mise.toml`, CHANGELOG 3.5.0,
  ggf. README.
- Die Preset-Regel wirkt in allen Projekten, sobald sie auf main gepusht ist —
  unabhängig von der Plugin-Version.
- Korrigiert die Annahme aus F-031, Renovate halte die Sperrdatei aktuell.
- Folgen: F-053 und F-054 — auf GitLab und Forgejo gilt EC-3, wenn Renovate dort selbst
  betrieben wird.
- Kein Widerspruch zu Zielen oder Nicht-Zielen.

### Offene Fragen

- [ ] [CLARIFY] Ist das mise im gehosteten Dienst neu genug für `--bump`? Sonst frischt
  Renovate nur auf, ohne zu heben. Nicht blockierend; zeigt F-059c.

### Entscheidungen

- 2026-11-14 — Lock File Maintenance nur für mise, nicht für alle Sperrdateien. Grund:
  Die Abhängigkeiten der Projekte sollen sich nicht ungefragt ändern. Entscheidung des
  Nutzers nach Empfehlung.
- 2026-11-14 — Kein CI-Job als Notlösung und kein Bericht an Renovate. Grund: Der
  gehostete Dienst führt `mise` aus, `--bump` umgeht den Fehler beim Lookup.
- 2026-11-14 — `/new-project` erzeugt die Sperrdatei mit `mise lock --bump`. Grund: Sonst
  startet ein Projekt mit den lokal installierten Versionen. Entscheidung des Nutzers
  nach Empfehlung.
- 2026-11-14 — `bump-tools` als Pflicht-Rezept aller Template-justfiles, geprüft von
  `just check`. Entscheidung des Nutzers nach Empfehlung.
- 2026-11-14 — Der echte PR wird in einem eigenen Schlussschritt nach Push und erstem
  Lauf belegt; bis dahin bleibt F-059 `IN-PROGRESS`. Entscheidung des Nutzers nach
  Empfehlung.

## Plan

**Größe:** M. Rund zehn Dateien mit wenigen Zeilen; die Spike-Fragen hat prep-step
geklärt. Die Preset-Regel wirkt in allen Projekten, ändert dort aber nur `mise.lock`.

**Ansatz:** Das Preset schaltet Renovates Lock File Maintenance im Manager `mise` ein, mit
Automerge; Zeitplan bleibt Renovates Vorgabe (wöchentlich, montags früh). Für Wege ohne
Renovate kommt `just bump-tools` (`mise lock --bump`) in alle Template-justfiles, und
`/new-project` erzeugt die Sperrdatei gleich mit `--bump`. Verworfen: ein eigener
wöchentlicher CI-Job (je Host verschieden, unnötig, weil der gehostete Dienst `mise`
ausführt) und genaue Versionen in `mise.toml` (ein PR je Tool, Muster aller Projekte
ändert sich).

### F-059a — Preset, Doku und new-project

- `default.json`: `"mise": { "lockFileMaintenance": { "enabled": true, "automerge": true } }`,
  dazu eine Zeile in `description`.
- `docs/renovate-preset.md`: Abschnitt zur Regel — was sie tut, dass sie mit dem Push
  wirkt, was ein selbst betriebenes Renovate braucht (`allowedUnsafeExecutions: ["mise"]`,
  ein Image mit mise), dass Projekte mit Freigabe über das Dashboard den PR erst
  freigeben.
- `skills/new-project/SKILL.md`: § 4d `mise trust && mise lock --bump && mise install &&
  just setup && just check`, Erklärsatz angepasst; Abschlussbericht Azure (Punkt
  Renovate) nennt die Freischaltung von `mise`.
- MANIFEST § Version stamp: `mise.lock` entsteht mit `mise lock --bump`.
- Prüfen: `renovate-config-validator` auf `default.json` (per npx, nichts ins Repo);
  manuell der Befehl aus § 4d in einem Projekt aus dem Arbeitsstand mit lokal älterem
  lefthook, danach `template-sync.sh lock-check`.
- Version 3.5.0 (schon unveröffentlicht), CHANGELOG-Eintrag.
- Erfüllt AC-2 und AC-3; AC-1 bis auf den echten Lauf.

### F-059b — Rezept bump-tools

- `bump-tools` mit Kommentar in den justfiles von `template/core` und den Modulen go,
  python, ts-node; Kopfkommentar der Core-justfile nennt das Rezept im Rezeptsatz.
- MANIFEST § Standard recipe set um `bump-tools` ergänzt.
- `scripts/validate.py`: prüft, dass jede Template-justfile `bump-tools` mit
  `mise lock --bump` hat (wie die Rezepte für den Feature-Index); Negativfall von Hand.
- Kopfkommentar von `template/core/mise.toml`: Renovate hebt die Sperrdatei wöchentlich,
  von Hand `just bump-tools`.
- CHANGELOG 3.5.0 `### Template`: das neue Rezept, bei eigener justfile (`keep`) die
  Zeilen zum Nachtragen; die Preset-Regel wirkt ohne Zutun.
- Manuell `just bump-tools` in einem gerenderten Projekt; `just check` grün.
- Erfüllt AC-4 und AC-5.

### F-059c — Echter Lauf nach dem Push

- Nach dem Release-Push von 3.5.0 und dem nächsten Montag: im Kit-Repo der PR „Lock file
  maintenance“ — ändert nur `mise.lock`, hebt die Versionen (`--bump`), mergt bei grüner
  CI. Zeigt er nur Auffrischen ohne Heben, Befund und Folge-F-Nummer.
- Ändert keine Kit-Dateien außer der Feature-Datei, also keine neue Version.
- Erfüllt AC-1 und klärt die offene Frage.

**Erkennung (Schritt 2a):** entfällt; kein neues Framework, keine neue Sprache, kein
neues Tool. Neue Config nur im Preset; keine Endpunkte, keine Dependencies.

## Verlauf

### F-059a — fertig 2026-11-14

**Umgesetzt:**

- `default.json`: Lock File Maintenance im Manager `mise`, mit Automerge; der Zeitplan
  bleibt Renovates Vorgabe. `renovate-config-validator` meldet das Preset gültig; mit
  einem Tippfehler im neuen Schlüssel meldet er „Invalid configuration option“.
- `docs/renovate-preset.md` und README beschreiben die Regel, wann der PR offen bleibt,
  und was ein selbst betriebenes Renovate braucht (`allowedUnsafeExecutions: ["mise"]`,
  ein Image mit mise).
- `/coding-kit:new-project` § 4d: `mise trust && mise lock --bump && mise install &&
  just setup && just check`; der Abschlussbericht für Azure nennt die Freischaltung.
  MANIFEST § Version stamp und CHANGELOG 3.5.0 nachgezogen.
- Durchlauf mit einem Projekt aus dem Arbeitsstand (docs-only), lokal just 1.55.1 und
  lefthook 2.1.9 installiert: `mise.lock` legt just 1.59.0 und lefthook 2.2.2 fest, die
  neuesten ihrer Hauptversion; `mise install` installiert genau sie, `lock-check` meldet
  alle sieben Plattformen `complete`, `just check` grün.

**Entscheidungen:** siehe Spezifikation.

**Abweichung vom Plan:**

- `/coding-kit:choose-stack` § Lock-Datei geändert: Die Regel dort galt ausdrücklich auch
  für new-project („nach `mise install` schlicht `mise lock`“) und hätte § 4d
  widersprochen. Sie nennt jetzt die Ausnahme; bestehende Projekte bleiben ohne `--bump`.
- README ergänzt (Renovate-Preset, Renovate auf Azure).

**Funde:** Unabhängiges Review mit einem Befund, behoben: Der neue Satz in choose-stack
nannte Renovate als einzigen Weg zum Anheben; jetzt auch den Handweg (EC-3, EC-6).

### F-059b — fertig 2026-11-14

**Umgesetzt:**

- Rezept `bump-tools` (`mise lock --bump`) in den justfiles von `template/core` und den
  Modulen go, python, ts-node; MANIFEST § Standard recipe set nimmt es auf. Der
  Validator prüft es wie die Rezepte für den Feature-Index (`REQUIRED_RECIPES` in
  `scripts/validate.py`); ohne `--bump` in der python-justfile meldet er genau diese
  Datei.
- Kopfkommentare: Die Core-justfile nennt den ganzen Rezeptsatz, `core/mise.toml` das
  wöchentliche Anheben durch Renovate und `just bump-tools`. `docs/renovate-preset.md`
  nennt `just bump-tools` als Handweg.
- CHANGELOG 3.5.0 `### Template`: das Rezept mit Text zum Nachtragen bei eigener
  justfile (`keep`); die Preset-Regel wirkt ohne Zutun des Projekts.
- Durchlauf: Alle vier Module gerendert, jedes kennt `bump-tools`. Im docs-only-Projekt
  hebt `just bump-tools` just von gesperrt 1.55.1 auf 1.59.0; `mise.toml` unverändert,
  `lock-check` vollständig. Update eines Go-Projekts vom Stand vor F-059b mit eigenem
  Rezept: Der Drei-Wege-Merge bringt `bump-tools`, das eigene Rezept bleibt, ohne
  Konflikt.

**Entscheidungen:** keine neuen.

**Abweichung vom Plan:**

- Entwurfs-Module java und swift-ios: `MODULE.md` nennt `bump-tools` im geplanten
  Rezeptsatz.
- CHANGELOG: Der Go-Hinweis aus F-057 heißt jetzt „Modul go — eigene `justfile`
  (`keep`)“, weil es zwei solche Hinweise gibt.

**Funde:**

- Der Kopfkommentar der Core-justfile ließ `features-index` im Rezeptsatz aus;
  mitbehoben.
- Unabhängiges Review mit einem Befund, behoben: Die Kommentare nannten Renovate ohne
  die Bedingung, dass es `mise` ausführen darf (EC-3); an allen gleichartigen Stellen
  korrigiert.
