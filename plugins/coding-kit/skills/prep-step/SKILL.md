---
name: prep-step
description: Aufgabe vor der Umsetzung vorbereiten. Hinterfragt die Lösungsskizze gegen den aktuellen Codestand, analysiert den Umfang, prüft die Standards-Abdeckung neu eingeführter Frameworks gegen den Fragment-Katalog, zerlegt bei Bedarf in Substeps und schreibt Plan + Status-Marker PLANNED nach Freigabe in die PROGRESS.md.
disable-model-invocation: true
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

## 2a. Standards-Abdeckung prüfen (Fragment-Check)

Nur wenn die Analyse ergibt, dass die Aufgabe **neue Frameworks/Dependencies
einführt**, und das Projekt einen Fragment-Slot hat (`<!-- module:coding-standards -->`
in der `CODING-STANDARDS.md`) — sonst still überspringen:

1. Template auflösen (wie `/choose-stack` § 0) und das Trigger-Mapping aus
   `modules/standards/README.md` lesen — zur Laufzeit, nichts hardcoden.
2. **Beide Signaltypen matchen:** die neu eingeführten Frameworks/Dependencies gegen
   die Dependency-Signale des Katalogs **und** die Aufgabenbeschreibung gegen die
   `*characteristic:*`-Eigenschafts-Trigger (z. B. „service with user/admin
   mutations").
3. Treffer, aber kein `<!-- fragment:NAME -->`-Marker im Projekt → im Plan
   vorschlagen, das Katalog-Fragment anzuhängen (Mechanik wie `/choose-stack`,
   idempotent).
4. Treffer-Thema ganz ohne Katalog-Fragment → vorschlagen, ein **projektlokales**
   Fragment zu autoren (eigener `fragment:NAME`-Block im Slot). Direkt nach der
   Anlage den **Übernahme-Vorschlag** fürs Template ausgeben (kopierfertiger Prompt
   bzw. GitHub-Request — siehe `/coding-kit:update-conventions`
   § Übernahme-Vorschlag); die Aufnahme in den Katalog stößt der Nutzer manuell an,
   bis dahin bleibt das Fragment projektlokal.
5. **Nur vorschlagen, nie still einbauen** — die Entscheidung fällt mit der
   Plan-Freigabe (Schritte 4–6).

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

**Standards-Abdeckung:** [ok / Fragment `<name>` fehlt → Anhängen vorgeschlagen /
kein Katalog-Fragment → Autoring + Promote vorgeschlagen; Zeile entfällt, wenn
Schritt 2a übersprungen wurde]

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
