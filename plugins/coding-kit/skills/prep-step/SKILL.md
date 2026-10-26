---
name: prep-step
description: Aufgabe vor der Umsetzung vorbereiten. Hinterfragt die Lösungsskizze gegen den aktuellen Codestand, analysiert den Umfang, prüft neu eingeführte Frameworks, Sprachen und Toolchains per Erkennungs-Skript gegen Fragment-Katalog und Stack-Module, zerlegt bei Bedarf in Substeps und schreibt Plan + Status-Marker PLANNED nach Freigabe in die PROGRESS.md.
argument-hint: "[F-Nummer]"
disable-model-invocation: true
user-invocable: true
---

# Aufgabe vorbereiten

Bevor eine Aufgabe umgesetzt wird: gründlich analysieren, bei Bedarf zerlegen, Plan in die
`PROGRESS.md` schreiben.

Argument: Nummer aus der `PROGRESS.md` — F-Nummer (z. B. „F-004") oder Alt-Format
(„1.2", „F9" — tolerant lesen). Ohne Argument: die oberste offene Aufgabe nehmen.

## 0. Projektkontext ermitteln

Lies die **Projekt-CLAUDE.md**: Zweck/Scope, Sprache der lebenden Doku, Verweise auf
`CODING-STANDARDS.md` / `REQUIREMENTS.md` / `THREAT-MODEL.md`, Graphiti-group_id
(Graphiti optional — ohne MCP still überspringen). Nichts davon hardcoden.

## Kontext-Recovery

Nach Kompaktierung oder Session-Neustart: (1) Projekt-CLAUDE.md und PROGRESS.md neu lesen
(Done-Tabelle, offene Tasks, FEATURE-INDEX), (2) `git status` + `git diff` für den
tatsächlichen Arbeitsstand, (3) beim aktuellen Schritt weitermachen — erledigte Arbeit
nicht wiederholen, nichts raten.

## 1. Aufgabe lesen & verstehen

- Aufgabe aus der `PROGRESS.md` lesen: Beschreibung, Dateien, Abhängigkeiten,
  Abnahmekriterien.
- `CODING-STANDARDS.md` lesen (falls vorhanden und noch nicht im Kontext).
- Abhängigkeiten prüfen: sind sie erledigt (Done-Tabelle oben + FEATURE-INDEX unten)?
- Falls vorhanden: `REQUIREMENTS.md` und `THREAT-MODEL.md` für den vollen Kontext lesen.

## 2. Lösungsskizze hinterfragen & Umfang analysieren

- **Die Lösungsskizze im Eintrag ist ein Schnappschuss von der Erfassung — nicht der
  Plan** (Alt-Einträge: „Mögliche Umsetzung"). Sie war ggf. schnell notiert und kann
  veraltet sein: jede Annahme gegen den aktuellen Codestand verifizieren (gibt es die
  genannten Stellen/Mechanismen noch?), nichts ungeprüft übernehmen.
- **Eigene Ideen einbringen:** Siehst du heute einen besseren Ansatz, schlage ihn vor —
  mit Begründung, was gegenüber der Skizze anders ist und warum.
- Welche Dateien/Komponenten müssen entstehen oder geändert werden?
- Gibt es bestehenden Code/Config zum Wiederverwenden?
- Welche neue Config (Env-Vars), Endpunkte, Dependencies werden nötig? Neue Dependencies
  nur permissiv lizenziert (kein GPL/AGPL).
- Bei Security-Postur (THREAT-MODEL.md vorhanden bzw. Security-/Auth-Charakter laut
  CLAUDE.md): bleibt das Design fail-closed? Eigenbau-Krypto (verboten — nur geprüfte
  Bibliotheken)? Berührt es Auth-, Token- oder Consent-Pfade?
- Grober Umfang: wie viele Zeilen Code/Config ungefähr?

## 2a. Standards- und Modul-Abdeckung prüfen (Erkennung)

Nur wenn die Analyse ergibt, dass die Aufgabe **neue Frameworks, Dependencies, Sprachen
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
   `modules/standards/README.md`) zeigt keine Datei: die Aufgabenbeschreibung selbst
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
   Plan-Freigabe (Abschnitte 4–6 dieses Skills). Ein Vorschlag, den der Nutzer dauerhaft
   ablehnt, wird zur Rules-Zeile `fragment:NAME`, `module:NAME` bzw. `tool:NAME` — dann
   meldet ihn kein Skill mehr.

## 3. Größe bewerten & ggf. zerlegen

- **Klein** (< 200 Zeilen, < 5 Dateien): direkt machbar, keine Zerlegung — kurzer Plan.
- **Mittel** (200–500 Zeilen, 5–15 Dateien): 2–3 logische Substeps, jeder für sich
  lauffähig/sinnvoll.
- **Groß** (> 500 Zeilen, > 15 Dateien): 3–5 Substeps mit eigenen Abnahmekriterien.

Substeps erben die Nummer der Elternaufgabe mit Buchstaben (F-004 → F-004a, F-004b …).

## 4. Plan dem Nutzer vorstellen

```
### [Nummer] — [Name]

**Einschätzung:** Klein / Mittel / Groß
**Geschätzter Umfang:** ~N Zeilen, N Dateien

**Bewertung der Lösungsskizze:** [was trägt, was ist überholt, was du anders
vorschlägst — mit Begründung; entfällt, wenn der Eintrag keine Skizze hat]

**Substeps:** (nur bei Mittel/Groß)
1. [Nummer]a — [Name]: [was, welche Dateien, Abnahmekriterium]
2. …

**Neue Endpunkte/Config/Dependencies:** [welche?]

**Standards- und Modul-Abdeckung:** [ok / Fragment `<name>` fehlt → Anhängen
vorgeschlagen / Modul `<name>` fehlt → `/choose-stack` oder Werkzeugsprache / Tool
`<name>` ohne Vorlage bzw. kein Katalog-Fragment → von Hand im Projekt + Vorschlag fürs
Template, oder `tool:NAME`; Zeile entfällt, wenn Schritt 2a übersprungen wurde]

**Risiken / offene Fragen:**
- …
```

**Auf OK warten — NICHT mit der Umsetzung beginnen!**

## 5. Plan & Status in der PROGRESS.md festhalten

Nach Freigabe (in der Sprache der lebenden Doku; Status-Token sprachinvariant):

- **Immer — Status-Marker setzen:** die `**Status:**`-Zeile des Eintrags auf `PLANNED`
  setzen (fehlt sie — Alt-Eintrag —, direkt unter der Überschrift anlegen) und die
  Zeile der F-Nummer im `<!-- FEATURE-INDEX … -->` mit `(PLANNED)` markieren. Der
  Marker zeigt, wo die Aufgabe steht: `BACKLOG` → prep-step, `PLANNED` → build-step.
- **Immer — Skizze nachziehen:** Weicht der freigegebene Plan von der Lösungsskizze ab,
  die Skizze im Eintrag kurz auf den beschlossenen Stand bringen.
- **Klein:** sonst nichts ändern — der bestehende Eintrag genügt.
- **Mittel/Groß:** Substeps direkt unter der Elternaufgabe einfügen, im vorhandenen Format
  (Was / Dateien / Abhängigkeiten / Abnahmekriterien als Checkboxen). Elternaufgabe als
  Überschrift/Kontext behalten. Neue Nummern immer als F-NNN mit Buchstaben-Substeps.

## 6. Fragen, ob es losgeht

- Frage: „Soll ich mit [Nummer]a starten?"
- **Erst nach explizitem OK implementieren.**
