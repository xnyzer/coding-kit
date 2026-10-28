---
name: prep-step
description: Feature vor der Umsetzung spezifizieren und planen. Schätzt die Größe aus drei Signalen (Aufwand, Unsicherheit, Reichweite), spezifiziert in der Tiefe je Größe — Abnahmekriterien, Randfälle, Nicht-Ziele, Tests, Einbettung, bei Bedarf Interview und Example Mapping, darf abraten —, prüft neu eingeführte Frameworks, Sprachen und Toolchains per Erkennungs-Skript, plant Substeps und schreibt Spezifikation, Plan und Status PLANNED nach Freigabe in die Feature-Datei.
argument-hint: "[F-Nummer]"
disable-model-invocation: true
user-invocable: true
---

# Feature vorbereiten

Bevor ein Feature umgesetzt wird: verstehen, spezifizieren, planen — so gründlich, wie es
die Größe verlangt, und nicht gründlicher. Ergebnis sind die Abschnitte Spezifikation und
Plan in `features/F-NNN-*.md` und der Status `PLANNED`.

Argument: F-Nummer (z. B. „F-004"; Alt-Formate tolerant lesen). Ohne Argument: das erste
Feature der empfohlenen Reihenfolge in `features/INDEX.md` vorschlagen und bestätigen
lassen.

**Freigabe-Gate:** Jede neue oder geänderte Feature-Datei (`features/F-NNN-*.md`), jede
Änderung an `features/INDEX.md` und an den Ziel-Abschnitten im Überblick der
`CLAUDE.md` wird zuerst als Vorschau gezeigt und erst nach ausdrücklichem OK des Nutzers
geschrieben (ausgenommen: genau der zuvor freigegebene Text; die Tabelle erzeugt danach
das Skript). Lange Entwürfe (etwa ab 40 Zeilen) gehen als Datei nach `private/` und
werden nach dem Übernehmen gelöscht.

## 0. Projektkontext ermitteln

Lies die **Projekt-CLAUDE.md**: Überblick mit Zweck, Umfang, Zielen, Nicht-Zielen und
Rahmenbedingungen; Sprache der lebenden Doku; Verweise auf `CODING-STANDARDS.md` /
`THREAT-MODEL.md`; Graphiti-group_id (Graphiti optional — ohne MCP still überspringen).
Nichts davon hardcoden.

**Altes Format:** Hat das Projekt eine `PROGRESS.md` mit `FEATURE-INDEX`-Block, aber keine
`features/INDEX.md`, arbeitet es noch mit dem Dokumentmodell vor coding-kit 2.0.0. Dann
nicht planen und nichts schreiben: auf die Migration per `/coding-kit:update-conventions`
verweisen.

## Kontext-Recovery

Nach Kompaktierung oder Session-Neustart: (1) Projekt-CLAUDE.md, `features/INDEX.md` und
die Feature-Datei neu lesen — steht die Spezifikation schon, geht es mit dem Plan weiter,
(2) `git status` + `git diff` für den tatsächlichen Arbeitsstand, (3) beim aktuellen
Schritt weitermachen — erledigte Arbeit nicht wiederholen, nichts raten.

## 1. Feature lesen & verstehen

- Die Feature-Datei lesen: Kopfblock, Erfassung (Problem, Ziel, Lösungsskizze,
  Abhängigkeiten), eine schon vorhandene Spezifikation.
- **Status prüfen:** `BACKLOG` → planen. `PLANNED` → schon geplant; nur auf Wunsch neu
  planen. `IN-PROGRESS` → läuft; Änderungen am Plan nur auf Wunsch, als datierte
  Entscheidung. `DONE`, `DROPPED`, `SUPERSEDED` → abgeschlossen; Folgearbeit bekommt eine
  neue Nummer (`/coding-kit:add-feature`).
- **Abhängigkeiten** (`depends-on`, Erfassung): erledigt (Status `DONE` in der Tabelle)
  oder in der Reihenfolge davor eingeplant? Sonst melden.
- `CODING-STANDARDS.md` lesen (falls vorhanden und noch nicht im Kontext); bei
  Security-Postur `THREAT-MODEL.md`. Grundsätzliche Entscheidungen stehen als ADR in
  `docs/adr/` — die berührten lesen.

## 2. Lösungsskizze hinterfragen & Umfang analysieren

- **Die Lösungsskizze ist ein Schnappschuss von der Erfassung — nicht der Plan.** Jede
  Annahme gegen den aktuellen Codestand verifizieren (gibt es die genannten
  Stellen/Mechanismen noch?), nichts ungeprüft übernehmen.
- **Eigene Ideen einbringen:** Siehst du einen besseren Ansatz, schlage ihn vor — mit
  Begründung, was gegenüber der Skizze anders ist und warum.
- Welche Dateien/Komponenten müssen entstehen oder geändert werden? Gibt es Bestehendes
  zum Wiederverwenden?
- Welche neue Config (Env-Vars), Endpunkte, Dependencies werden nötig? Neue Dependencies
  nur permissiv lizenziert (kein GPL/AGPL).
- Bei Security-Postur (THREAT-MODEL.md vorhanden bzw. Security-/Auth-Charakter laut
  CLAUDE.md): bleibt das Design fail-closed? Eigenbau-Krypto (verboten — nur geprüfte
  Bibliotheken)? Berührt es Auth-, Token- oder Consent-Pfade?

## 2a. Standards- und Modul-Abdeckung prüfen (Erkennung)

Nur wenn die Analyse ergibt, dass das Feature **neue Frameworks, Dependencies, Sprachen
oder Toolchains einführt** — sonst still überspringen. Template und Skript wie
`/choose-stack` § 0: `${CLAUDE_PLUGIN_ROOT}/template` und
`${CLAUDE_PLUGIN_ROOT}/scripts/template-sync.sh`, in Shell-Befehlen die aufgelösten
Pfade; Signale und Zustände beschreibt `MANIFEST.md` § Detection.

1. **Geplante Signale benennen** — typisiert, wie sie nach dem Bau im Projekt stünden:
   `npm:`, `pypi:`, `go:` für Dependencies, `tool:` für ein Tool in `mise.toml`, `file:`
   für eine geplante Datei (z. B. `npm:next`, `tool:python`, `file:Dockerfile`).
2. **Abgleich per Skript:** `sh <skript> detect <template> <projekt> <Signal…>` prüft nur
   diese Signale, ohne den Baum zu lesen. Zeilen `covered` und `declined` → nichts
   vorschlagen; eine `tool`-Zeile `unknown` heißt: Für dieses Tool hat das Template
   weder Modul noch Fragment (Punkt 6). Fehlt `.claude/template-answers` (Projekt vor
   dem Snapshot-Vertrag), prüft das Skript keine Module — dann auf die Migration per
   `/coding-kit:update-conventions` hinweisen.
3. **Eigenschafts-Trigger** (`*characteristic:*`-Zeilen in
   `modules/standards/README.md`) zeigt keine Datei: die Feature-Beschreibung selbst
   dagegen halten (z. B. „service with user/admin mutations"), Treffer wie ein Fragment
   ohne `fragment:NAME`-Marker im Slot behandeln.
4. **Fragment `missing`** → im Plan vorschlagen, das Katalog-Fragment anzuhängen
   (Mechanik wie `/choose-stack`, idempotent; ohne Fragment-Slot
   `<!-- module:coding-standards -->` in der `CODING-STANDARDS.md` nur melden). Verlangt
   das Fragment eine **Begleithandlung** am Projekt (`/choose-stack`
   § Begleithandlungen), im Vorschlag mitausweisen — sie gehört in denselben Schritt,
   nicht in einen Folgeschritt. Ebenso ausweisen (gleiche Stelle): den Eintrag des
   Fragments in `FRAGMENTS` der `.claude/template-answers` und je managed Datei, die die
   Begleithandlung ändert, eine `keep`-Zeile in der Files-Tabelle der
   `.claude/convention-overrides.md`.
5. **Modul `missing`** → im Plan ausweisen und eine Richtung empfehlen: das Modul per
   `/coding-kit:choose-stack` nachrüsten (eigener Schritt vor dem Bau) **oder** die
   Sprache als Werkzeugsprache führen — dann gehören in denselben Schritt eine Zeile
   `module:NAME` in der Rules-Tabelle der `.claude/convention-overrides.md` (was das
   Projekt stattdessen tut, mit Grund) und `keep`-Zeilen für die managed Dateien, die
   die Toolchain von Hand ändert (z. B. `mise.toml`, justfile).
6. **Tool `unknown`** oder ein Treffer-Thema ganz ohne Katalog-Fragment → im Plan
   ausweisen, dass das Template dafür keine Vorlage hat, und eine Richtung empfehlen:
   - **Von Hand im Projekt:** die Toolchain als Werkzeugsprache bauen (`keep`-Zeilen für
     die managed Dateien, die sie ändert, z. B. `mise.toml`, justfile) bzw. ein
     **projektlokales** Fragment autoren (eigener `fragment:NAME`-Block im Slot) —
     beides im selben Schritt. Dazu anbieten, es **dem Template vorzuschlagen**: den
     Hintergrund-Skill `propose-to-template` mit dem Fund starten, sobald das Material
     steht (nach dem Bau). Bis zur Aufnahme bleibt es projektlokal.
   - **Dauerhaft ablehnen**, wenn das Tool keine Konvention braucht: Rules-Zeile
     `tool:NAME` mit Grund im selben Schritt.
7. **Nur vorschlagen, nie still einbauen** — die Entscheidung fällt mit der
   Plan-Freigabe (Schritt 7). Ein Vorschlag, den der Nutzer dauerhaft ablehnt, wird zur
   Rules-Zeile `fragment:NAME`, `module:NAME` bzw. `tool:NAME` — dann meldet ihn kein
   Skill mehr.

## 3. Größe schätzen (vor dem Interview)

Drei Signale, **das höchste zählt**:

| Signal | S | M | L |
|--------|---|---|---|
| Aufwand | unter 5 Dateien und 200 Zeilen | bis 15 Dateien und 500 Zeilen | darüber |
| Unsicherheit | die Lösung liegt auf der Hand | einzelne offene Fragen | viele offene Fragen, neue Technik, ein Spike nötig |
| Reichweite | eine Stelle | mehrere Teile des Projekts | Daten- oder Projektmigration, Sicherheits- oder Auth-Pfade, Vorlage für andere Projekte |

Die Größe mit einem Satz Begründung vorschlagen; der Nutzer kann sie ändern. Sie
bestimmt die Tiefe in Schritt 4 und 5 — **nach oben begrenzt**, damit Kleines nicht
lästig wird. Nach der Spezifikation erneut prüfen: Zeigt sie mehr (oder weniger), die
Größe neu vorschlagen.

## 4. Phase 1 — Spezifikation

In der Tiefe je Größe:

- **S:** kein Interview. Claude legt eine Mini-Spezifikation vor: 1–3 Abnahmekriterien,
  Randfälle ausdrücklich „keine" oder 1–2.
- **M:** Interview nur zu offenen Punkten (etwa 3–6 Fragen). Abnahmekriterien als
  Gegeben/Wenn/Dann mit Negativfall; 3–5 Randfälle; 1–3 Nicht-Ziele; ein Testfall je
  Abnahmekriterium; kurze Einbettungsprüfung.
- **L:** volles Interview, **eine** Frage je Runde mit Empfehlung. **Example Mapping:** je
  Regel Beispiele und Gegenbeispiele, offene Fragen getrennt sammeln. Stories
  priorisiert; Randfälle systematisch (Daten, Zustände, Fehler, Sicherheit, Migration);
  Nicht-Ziele Pflicht; Teststrategie; volle Einbettungsanalyse.

Fragen aus drei Blickwinkeln — **Nutzen** (wer hat was davon, woran merkt man es?),
**Umsetzung** (was ist schwer, was bricht?), **Prüfung** (woran sieht man, dass es geht —
und dass es nicht mehr tut als gewollt?) — plus **Sicherheit** (neue Eingaben,
Berechtigungen, Secrets, Daten).

**Einbettung prüfen:** Was berührt das Feature? Was muss mitgeändert werden? Was setzt die
Anfrage stillschweigend voraus — einen Rückweg, eine Migration, eine Fehlermeldung, eine
Berechtigung? Was Bestehendes muss angepasst werden — im Feature oder als Folge-F-Nummer?
Widerspricht es Zielen, Nicht-Zielen (Überblick der CLAUDE.md) oder einem ADR?

**Alternativen und Abraten:** Ab M mindestens eine Alternative zur Skizze nennen. Spricht
mehr dagegen als dafür, abraten — mit Grund; einen Workaround planst du nicht. Die
Entscheidung bleibt beim Nutzer: weitermachen, anders lösen, `DROPPED` (Grund in die
Datei) oder `SUPERSEDED` (aufgehen in anderen Nummern, Feld `superseded-by`) — die beiden
letzten mit Vorschau wie jede Änderung, `done:` auf heute.

**Abschnitt Spezifikation** der Feature-Datei (Gerüst aus der Vorlage
`features/F-000-template.md`, Überschriften in der Sprache der lebenden Doku, Kürzel
englisch):

- **Abnahmekriterien:** `- [ ] AC-n — Gegeben …, wenn …, dann …`, Negativfälle
  eingeschlossen; jedes prüfbar.
- **Randfälle:** `EC-n — <Situation> → <erwartetes Verhalten>`.
- **Nicht-Ziele:** was das Feature ausdrücklich nicht tut (→ F-NNN, wo ein anderes es
  regelt).
- **Tests:** je Abnahmekriterium ein automatischer Test, ein Check oder „manuell: wie".
- **Einbettung:** Ergebnis der Prüfung oben, Folge-F-Nummern.
- **Offene Fragen:** `- [ ] [CLARIFY] …`; eine blockierende hält das Feature vor
  `PLANNED`.
- **Entscheidungen:** datiert mit Grund; überstimmt der Nutzer eine Empfehlung, steht das
  so da („Empfehlung war Z; entschieden X, weil …"). Eine Entscheidung, die das Projekt
  über dieses Feature hinaus prägt, als ADR in `docs/adr/` vorschlagen; die Datei
  verlinkt es.

Bei M und L die Spezifikation zuerst allein zeigen und freigeben lassen; nach dem OK darf
sie in die Datei, der Status bleibt `BACKLOG` — prep-step erkennt beim nächsten Lauf an
der Datei, dass nur der Plan fehlt. Bei S kommen Spezifikation und Plan in eine Vorschau.

## 5. Phase 2 — Plan

**Abschnitt Plan** der Feature-Datei:

- **Größe** mit der Begründung aus Schritt 3.
- **Ansatz:** der gewählte Weg; ab M mit der verworfenen Alternative und warum nicht.
- **Substeps** — S: der Plan in Stichpunkten, keine Substeps. M: 2–3 Substeps. L: 3–5,
  bei großer Unsicherheit ein Spike zuerst. Braucht es mehr, in eigene F-Nummern teilen
  (`/coding-kit:add-feature`; das Feature wird ggf. `SUPERSEDED`). Substeps heißen
  `F-NNNa`, `F-NNNb` … und haben je eine Überschrift im Plan: was, welche Teile, welche
  Abnahmekriterien er erfüllt — jeder für sich lauffähig.
- Ergebnis der Erkennung (Schritt 2a), neue Endpunkte, Config und Dependencies.

## 6. Ready prüfen

`PLANNED` nur, wenn alles erfüllt ist — sonst sagen, was fehlt:

- Problem und Ziel klar, Größe gesetzt;
- jedes Abnahmekriterium prüfbar und mit Testidee;
- Randfälle betrachtet; Nicht-Ziele ab M;
- kein blockierendes `[CLARIFY]`;
- Abhängigkeiten erledigt oder eingeplant;
- Einbettung geprüft;
- Plan steht.

## 7. Vorstellen & festhalten

Den Plan (bei S mit Spezifikation) als Vorschau zeigen: die neuen Abschnitte der
Feature-Datei, die Änderungen im Kopfblock und an `features/INDEX.md`. **Auf OK warten —
NICHT mit der Umsetzung beginnen!**

Nach Freigabe, in der Sprache der lebenden Doku:

- **Feature-Datei:** Spezifikation und Plan schreiben — nur diese beiden Abschnitte;
  einen leeren Abschnitt Verlauf aus der Vorlage nicht mitnehmen, den legt step-done an.
  Im Kopfblock `status: PLANNED`, `size`, ggf. `depends-on`. Weicht der Plan von der
  Lösungsskizze ab, die Skizze kurz auf den beschlossenen Stand bringen. Hat sich der
  Zuschnitt geändert, den `title`
  anpassen (Titelregel wie in `/coding-kit:add-feature`; der Dateiname bleibt).
- **Empfohlene Reihenfolge** in `features/INDEX.md`: verschiebt sich etwas (neue
  Abhängigkeit, neue Folge-Nummer, Feature abgeraten), eine Änderung vorschlagen — in
  derselben Vorschau, Stand-Datum auf heute.
- Tabelle erzeugen: `just features-index` (ohne das Rezept
  `sh scripts/features-index.sh write`); meldet das Skript etwas, beheben. Die Datei
  re-lesen.
- Lange Entwürfe aus `private/` nach dem Übernehmen löschen.

## 8. Fragen, ob es losgeht

- Frage: „Soll ich mit [Nummer]a starten?" (S: „Soll ich es umsetzen?")
- **Erst nach explizitem OK implementieren.**
