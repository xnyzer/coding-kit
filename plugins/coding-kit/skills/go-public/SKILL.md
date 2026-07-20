---
name: go-public
description: Projekt nachträglich public machen — geführter Übergang mit blockierendem Preflight-Audit (Secrets über die volle Git-Historie, Privacy-Scan des committeten Baums, Lizenz, private/-Hygiene), Datei-Nachzug VOR dem Umstellen (via /update-conventions mit Sichtbarkeits-Prämisse) und Abschluss-Check. Drei Startfälle — privates GitHub-Repo, nur lokales Projekt, schon public. Nichts passiert ohne explizite Bestätigung; online geht das Repo erst, wenn es vollständig ist.
disable-model-invocation: true
---

# Projekt public machen (geführter Übergang)

**Grundsätze:** **Fail-closed** — kein Übergang, solange ein Preflight-Gate offen
ist oder nicht geprüft werden kann; ein fehlendes Prüfwerkzeug blockiert, es wird
nie still übersprungen. **Verbindliche Reihenfolge: erst Nachzug, dann Übergang** —
das Repo wird lokal vollständig gemacht und geprüft, bevor es öffentlich wird; nie
unvollständig online. Nie automatisch committen. Der initiale Push (Fall B) braucht
eine **ausdrückliche, laufbezogene Push-Freigabe** — die einzige Ausnahme vom
Push-Tabu. Der Übergang ändert **nie** den Languages-Block der Projekt-CLAUDE.md:
Sprache ist von der Sichtbarkeit entkoppelt, public werden heißt nicht englisch
werden.

## 0. Projektkontext ermitteln

Projekt-CLAUDE.md lesen: Zweck/Scope, Sprache der lebenden Doku, Graphiti-group_id
(ohne Graphiti-Block/MCP still überspringen), Sicherheits-Postur (THREAT-MODEL.md
→ strengster Maßstab im Preflight). Template-Checkout und MANIFEST auflösen wie
`/coding-kit:update-conventions` § 0 (wird für Nachzug und private/-Regeln
gebraucht). Prüf-Infrastruktur des Projekts ermitteln: justfile
(`just check` als Gate), `scripts/privacy-lint.sh`, konfigurierter Secrets-Scanner
(lefthook.yml/mise.toml). Nichts davon hardcoden.

## Kontext-Recovery

Bei Wiederaufnahme: aus dem Verlauf übernehmen, welche Gates bereits grün sind und
welche Entscheidungen protokolliert wurden; `git status` im Projekt prüfen. Beim
nächsten offenen Punkt weitermachen — bestandene Gates nicht wiederholen, **außer**
der committete Stand hat sich seither geändert (dann die betroffenen Gates neu
laufen lassen).

## 1. Fallerkennung (zur Laufzeit)

`gh repo view --json visibility` auswerten (Fehler = kein Repo/Remote):

- **Fall A — Repo existiert und ist private:** voller Ablauf; der Übergang stellt
  später die Sichtbarkeit um.
- **Fall B — kein GitHub-Repo (Projekt nur lokal):** voller Ablauf; der Übergang
  legt später das Repo public an und pusht initial (nur mit laufbezogener
  Freigabe).
- **Fall C — Repo ist schon public:** kein Übergang nötig — aber **Preflight
  trotzdem vollständig ausführen** (nachträgliche Funde sind hier am kritischsten:
  sie sind bereits öffentlich → sofort melden und Optionen nennen), danach nur
  Nachzug-Check und Abschluss-Check.

Erkannten Fall mit Begründung nennen und vom Nutzer bestätigen lassen, bevor
irgendetwas läuft.

## 2. Preflight-Audit (blockierend, fail-closed)

Vier Gates — **alle** müssen grün sein, bevor es weitergeht. Jedes Ergebnis wird
im Lauf sichtbar protokolliert (Gate, Befund, Entscheidung). Kann ein Gate nicht
geprüft werden (Werkzeug fehlt, Kommando schlägt fehl), gilt es als **rot**.

1. **Secrets über die volle Historie** (nicht nur Working Tree): den
   Secrets-Scanner des Projekts zur Laufzeit auflösen — was lefthook.yml bzw.
   mise.toml konfigurieren, hat Vorrang; Fallback ist ein direkter
   gitleaks-Aufruf. Den Aufruf für einen **vollen Historien-Scan** der
   Scanner-Doku zur Laufzeit entnehmen (nicht raten; Scanner-CLIs ändern sich).
   **Fehlt jeder Scanner: blockieren** und die Installation anbieten — nie ohne
   Historien-Scan fortfahren.
2. **Privacy-Scan des committeten Baums** (`git ls-files`-Stand, nicht nur
   Working Tree): Klarnamen, private E-Mail-Adressen, absolute lokale Pfade
   (`/Users/…`, `/home/…`), private IPs/Hostnames, Verweise auf Inhalte, die nur
   in `private/` existieren. `scripts/privacy-lint.sh` nutzen, falls vorhanden,
   plus gezielte Greps für die genannten Muster. Erlaubt sind dokumentierte
   Platzhalter (example.com, RFC-5737-IPs, GitHub-noreply-Adressen). **Auch
   Commit-Metadaten prüfen:** Autor-/Committer-E-Mails der gesamten Historie
   (`git log --all --format='%ae%n%ce' | sort -u`) müssen noreply- oder
   unkritische Adressen sein — private Adressen in der Historie sind ein Fund
   (Behebung nur via History-Rewrite, s. u.).
3. **Lizenz:** LICENSE-Datei vorhanden und nicht TBD. Sonst stoppen und
   `/coding-kit:choose-license` anbieten; ohne gewählte Lizenz kein Übergang
   (auch der README-Vermerk „License: TBD" muss danach aufgelöst sein).
4. **private/-Hygiene:** `private/` ist gitignored und — mit Ausnahme des
   managed `private/README.md` — **nie committet worden**, auch nicht in der
   Historie (`git log --all -- private/` prüfen, README ausnehmen).

**Befund → Stopp mit Optionen** (je Befund entscheiden, nichts pauschal):

- **Bereinigen:** Inhalt entfernen/maskieren bzw. nach `private/` verschieben,
  Commit nach Freigabe; betrifft nur den aktuellen Baum.
- **History-Rewrite (nur Anleitung):** Steckt der Fund in der Historie, die
  konkreten Schritte dokumentieren (`git filter-repo`-Aufruf für die betroffenen
  Pfade/Muster, anschließender Force-Push, Auswirkungen auf Clones) — **nie
  selbst ausführen**; das ist eine destruktive, bewusste Nutzeraktion. Danach
  Preflight neu laufen lassen.
- **Begründete Einstufung als unkritisch:** Der Nutzer kann einen Befund als
  False Positive einstufen (z. B. dokumentierter Beispiel-Token) — Entscheidung
  **mit Begründung** im Lauf protokollieren. Das Gate bleibt für alles
  Unentschiedene hart.
- **Abbruch:** jederzeit; nichts wurde verändert.

Erst wenn alle vier Gates grün sind (bzw. jeder Befund eine protokollierte
Entscheidung hat), weiter zum Nachzug.

## 3. Nachzug — lokal vollständig machen (als-ob-public, VOR dem Übergang)

`/coding-kit:update-conventions` für dieses Projekt ausführen und dabei die
**Sichtbarkeits-Prämisse `public`** übergeben: die public-only-Policy behandelt
das Projekt schon jetzt als öffentlich, obwohl es noch privat/lokal ist. Dadurch
erscheinen CODE_OF_CONDUCT, codeql.yml & Co. zusammen mit allen ausstehenden
Template-Updates als regulärer Diff — je Datei bestätigt, Override-Schutz gilt,
Platzhalter (inkl. CODEQL_LANGUAGES) löst der Lauf selbst rück.

Danach: `just check` muss grün sein; Secrets- und Privacy-Scan über die neu
entstandenen Dateien (Preflight-Maßstab). Dann **Commit nach Freigabe**
(Conventional, englisch; Commit-E-Mail muss die GitHub-noreply-Adresse sein —
vor dem Commit `git config user.email` prüfen).

**Hartes Gate: kein Übergang, solange der Nachzug nicht committet ist.** Das Repo
geht erst online, wenn es vollständig ist. (Fall C: der Lauf zeigt nur noch
tatsächliche Lücken — meist public-only-Dateien, die beim manuellen
Public-Stellen nie nachgezogen wurden.)

## 4. Übergang (je Fall, nur nach expliziter Bestätigung)

Unmittelbar vor der Ausführung noch einmal bestätigen lassen — mit Klartext, was
gleich passiert („Repo <name> wird öffentlich; die gesamte Historie wird
sichtbar").

- **Fall A — Sichtbarkeit umstellen:** `gh repo edit --visibility public`.
  Neuere gh-Versionen verlangen zusätzlich
  `--accept-visibility-change-consequences` — per `gh repo edit --help`
  feature-detecten, nicht raten.
- **Fall B — Repo anlegen + initial pushen:** `gh repo create` (public, Source =
  Projektverzeichnis). Der initiale Push läuft **nur** mit der ausdrücklichen,
  laufbezogenen Push-Freigabe des Nutzers — sie muss in diesem Lauf erteilt
  worden sein, eine frühere oder allgemeine Freigabe zählt nicht.
- **Fall C:** entfällt — das Repo ist schon public.

Direkt danach **Repo-Settings** setzen/prüfen (wie `/coding-kit:new-project`
§ 4c): Beschreibung, Topics lowercase-kebab inkl. Marker-Topic `coding-kit`,
Issues an, Wiki/Projects aus, Squash-Merge + delete-branch-on-merge,
Push-Protection/Secret-Scanning via `gh api` mit Feature-Detection.

Der Übergang stellt **keine Sprachen um**: der Languages-Block der
Projekt-CLAUDE.md bleibt exakt wie er ist. Wünscht der Nutzer anlässlich des
Public-Gehens eine andere Sprachaufteilung, ist das ein separater, bewusster
Schritt (Languages-Block editieren; prospektive Semantik wie bei
`/coding-kit:update-conventions`).

## 5. Abschluss-Check (Verifikation, Write-then-Verify)

- **CodeQL:** `codeql.yml` liegt im Repo und der Workflow läuft nach dem
  Push/Umstellen an (`gh run list --workflow codeql.yml`); Fehlschläge melden.
- **Vollständigkeit:** keine offenen public-only-Lücken mehr (kurzer
  `/update-conventions`-Gegencheck bzw. Manifest-Abgleich), Template-Stempel
  aktuell.
- **Settings:** Sichtbarkeit tatsächlich public, Topics/Beschreibung gesetzt,
  Push-Protection aktiv (soweit vom Plan unterstützt).
- **Checks:** `just check` grün.
- Ergebnis als kurze Zusammenfassung ausgeben (Fall, Gates, Befund-Entscheidungen,
  Commits, Settings). Graphiti-Update mit der group_id des Projekts (falls
  verfügbar): Projekt ist public, wesentliche Entscheidungen des Laufs.
