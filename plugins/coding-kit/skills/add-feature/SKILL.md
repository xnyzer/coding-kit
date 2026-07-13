---
name: add-feature
description: Neue Aufgabe auf die Roadmap setzen. Analysiert die Idee, prüft Überschneidungen mit der PROGRESS.md, formuliert sie aus und trägt sie nach Freigabe mit Status-Marker BACKLOG ein.
disable-model-invocation: false
---

# Aufgabe aufnehmen

Der Nutzer hat eine Idee für eine neue Aufgabe: Feature, Refactoring, Audit, Doku — es wird
nicht unterschieden. Alles bekommt eine F-Nummer und landet im Backlog der `PROGRESS.md`.

Argument: Kurzbeschreibung der Aufgabe (z. B. „Rate-Limit-Middleware", „Export als CSV").

## 0. Projektkontext ermitteln

Lies die **Projekt-CLAUDE.md** (Repo-Root) — sie ist die Quelle für alle Projektspezifika:

- **Zweck/Scope** des Projekts (für die Passt-das-hierher-Prüfung).
- **Sprache der lebenden Doku** — PROGRESS-Einträge schreibst du in genau dieser Sprache.
- **Graphiti-group_id** (aus dem Graphiti-Block). Fehlt der Block oder läuft kein
  Graphiti-MCP → alle Graphiti-Schritte still überspringen.
- **Sicherheits-Postur:** öffentliches Repo oder Security-/Auth-Charakter (z. B.
  `THREAT-MODEL.md` vorhanden) → erhöhte Scan-Schärfe und Extra-Sicherheitsanalyse.

Hardcode nichts davon — jedes Projekt ist anders.

## 1. Idee verstehen

- Was genau soll getan werden?
- Bei unklarer Beschreibung: **nachfragen** — nicht raten. Eine Frage pro Antwort, immer
  mit einem empfohlenen Default.

## 2. Analyse

- **Passt es zum Projekt?** Gegen Zweck/Scope aus der CLAUDE.md prüfen.
- **Gibt es das schon?** Lies den `<!-- FEATURE-INDEX … -->`-Kommentar am Ende der
  `PROGRESS.md` — Überschneidungen oder Abhängigkeiten? Volltext einzelner Einträge nur
  bei konkretem Verdacht lesen.
- **Bestehenden Eintrag erweitern** statt neu anlegen, wo sinnvoll.
- **Machbarkeit im Stack:** Stack/Tooling aus CLAUDE.md bzw. justfile ableiten — nie
  einen Stack annehmen, der nirgends dokumentiert ist.
- **Sicherheits-/Privacy-Implikationen:** neue Angriffsflächen, externe Dienste, Secrets?
  Bei Security-Postur (siehe Schritt 0) mit besonderer Sorgfalt, ggf. gegen
  `THREAT-MODEL.md` prüfen.

## 3. Dem Nutzer vorstellen

Kurz präsentieren: Empfehlung (neuer Eintrag oder Erweiterung), Abhängigkeiten, offene
Fragen/Entscheidungen. **Auf OK warten, bevor du ausformulierst.**

## 4. Ausformulieren

**F-Nummer:** Im `<!-- FEATURE-INDEX … -->`-Block die `next-feature:`-Zeile lesen, diese
Nummer verwenden, dann: (1) `next-feature:` auf N+1 erhöhen, (2) neue Zeile im Index
ergänzen.

**F-Nummern-Toleranz:** Lies Alt-Formate anstandslos (F-001, F-9, F9, Schritt „1.2");
neue Einträge schreibst du ausschließlich als **F-NNN** (dreistellig; Substeps mit
Buchstaben: F-006a). Fehlt der FEATURE-INDEX-Block, lege ihn an und übernimm bestehende
Nummern unverändert — nichts umnummerieren.

**Status-Marker:** Jeder Eintrag trägt direkt unter der Überschrift eine
`**Status:**`-Zeile mit einem sprachinvarianten Token: `BACKLOG` = nur aufgenommen
(nächste Station `/coding-kit:prep-step`), `PLANNED` = geplant (bereit für
`/coding-kit:build-step`). Fertiges wandert in die Done-Tabelle und wird im
FEATURE-INDEX als `(DONE)` markiert. Neue Einträge bekommen immer `BACKLOG`.

**Basisformat (immer, in der Sprache der lebenden Doku; Status-Token sprachinvariant):**

```markdown
### F-NNN — [Name]

**Status:** BACKLOG

**Problem:** [1–2 Sätze — was fehlt, warum es zählt]

**Idee:** [2–3 Sätze Lösungsansatz]

**Lösungsskizze:**
- [Grobe Richtung: Ansatz, betroffene Bereiche — wenige Bullets, unverbindlich]
- [Neue Endpunkte, Config, Dependencies — Dependencies nur permissiv lizenziert, kein GPL/AGPL]

**Abhängigkeiten:** [Einträge, die vorher fertig sein müssen]
```

**Die Lösungsskizze ist unverbindlich** — eine grobe Richtung vom Zeitpunkt der
Erfassung, keine Vorwegnahme der Planung: keine Dateilisten, keine Zerlegung in
Schritte, keine Abnahmekriterien. Das macht `/coding-kit:prep-step` zur Umsetzungszeit
gegen den dann aktuellen Codestand. Optionaler Zusatzabschnitt für komplexe Aufgaben:
„Noch zu analysieren" (offene Fragen/Entscheidungen). Stil an bestehende Einträge
anpassen; Alt-Einträge nutzen ggf. die Überschrift „Mögliche Umsetzung" — nicht
umbenennen.

## 5. Festhalten

- Entwurf dem Nutzer zeigen; **erst nach explizitem OK** in die `PROGRESS.md` unter das
  Backlog eintragen.
- **Vor dem Eintragen** den Text auf Secrets/Interna scannen (keine echten Tokens, IPs,
  Hostnames, Klarnamen, lokalen Pfade — lebende Doku bleibt publishbar).
- Graphiti aktualisieren: `add_memory` mit der group_id aus der CLAUDE.md (falls
  verfügbar, sonst still überspringen).
