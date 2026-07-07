---
name: prep-step
description: Aufgabe vor der Umsetzung vorbereiten. Analysiert den Umfang, zerlegt bei Bedarf in Substeps und schreibt den Plan nach Freigabe in die PROGRESS.md.
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

## 2. Umfang analysieren

- Welche Dateien/Komponenten müssen entstehen oder geändert werden?
- Gibt es bestehenden Code/Config zum Wiederverwenden?
- Welche neue Config (Env-Vars), Endpunkte, Dependencies werden nötig? Neue Dependencies
  nur permissiv lizenziert (kein GPL/AGPL).
- Bei Security-Postur (THREAT-MODEL.md vorhanden bzw. Security-/Auth-Charakter laut
  CLAUDE.md): bleibt das Design fail-closed? Eigenbau-Krypto (verboten — nur geprüfte
  Bibliotheken)? Berührt es Auth-, Token- oder Consent-Pfade?
- Grober Umfang: wie viele Zeilen Code/Config ungefähr?

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

**Substeps:** (nur bei Mittel/Groß)
1. [Nummer]a — [Name]: [was, welche Dateien, Abnahmekriterium]
2. …

**Neue Endpunkte/Config/Dependencies:** [welche?]

**Risiken / offene Fragen:**
- …
```

**Auf OK warten — NICHT mit der Umsetzung beginnen!**

## 5. Substeps in der PROGRESS.md festhalten

Nach Freigabe (in der Sprache der lebenden Doku):

- **Klein:** nichts ändern — der bestehende Eintrag genügt.
- **Mittel/Groß:** Substeps direkt unter der Elternaufgabe einfügen, im vorhandenen Format
  (Was / Dateien / Abhängigkeiten / Abnahmekriterien als Checkboxen). Elternaufgabe als
  Überschrift/Kontext behalten. Neue Nummern immer als F-NNN mit Buchstaben-Substeps.

## 6. Fragen, ob es losgeht

- Frage: „Soll ich mit [Nummer]a starten?"
- **Erst nach explizitem OK implementieren.**
