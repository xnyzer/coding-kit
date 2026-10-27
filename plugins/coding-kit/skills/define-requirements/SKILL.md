---
name: define-requirements
description: Anforderungen erheben. M1-Interview aus der Short-Info (Ziele, Kern-Features, Nicht-Ziele, Rahmenbedingungen, Eigenschafts-Trigger des Fragment-Katalogs) → Ziele, Nicht-Ziele und Rahmenbedingungen im Überblick der Projekt-CLAUDE.md → je Kern-Feature eine schlanke Datei features/F-NNN-kurzname.md mit Status BACKLOG, empfohlene Reihenfolge und erzeugte Tabelle in features/INDEX.md. Einzeln nutzbar und von /new-project aufrufbar.
argument-hint: "[Short-Info]"
disable-model-invocation: false
user-invocable: true
---

# Anforderungen erheben

Argument: die Short-Info des Projekts. Ziel: belastbare Ziele, Nicht-Ziele und
Rahmenbedingungen im Überblick der Projekt-CLAUDE.md — dort lädt jede Session sie — und
eine erste Roadmap: je Kern-Feature eine Datei in `features/`, eine empfohlene
Reihenfolge und die Tabelle aller Features.

**Freigabe-Gate:** Jede neue oder geänderte Feature-Datei (`features/F-NNN-*.md`), jede
Änderung an `features/INDEX.md` und an den Ziel-Abschnitten im Überblick der
`CLAUDE.md` wird zuerst als Vorschau gezeigt und erst nach ausdrücklichem OK des Nutzers
geschrieben (ausgenommen: genau der zuvor freigegebene Text; die Tabelle erzeugt danach
das Skript). Lange Entwürfe (etwa ab 40 Zeilen) gehen als Datei nach `private/` und
werden nach dem Übernehmen gelöscht.

## 0. Projektkontext ermitteln

Projekt-CLAUDE.md lesen: Sprachen (die Ziel-Abschnitte stehen in der Sprache der
CLAUDE.md-Prosa, die Feature-Dateien in der Sprache der lebenden Doku), Zweck/Scope,
Graphiti-group_id (optional).

- **Ziel-Abschnitte** im Überblick (Ziele, Nicht-Ziele, Rahmenbedingungen — Überschriften
  in der Sprache der CLAUDE.md, im Template `### Goals`, `### Non-goals`,
  `### Constraints`): Stehen dort noch die Platzhalter der Vorlage, werden sie gefüllt.
  Fehlen die Abschnitte, legt dieser Skill sie unter dem Überblick an. Stehen dort oder
  in `features/` schon substanzielle Inhalte → an `/coding-kit:refine-requirements`
  verweisen.
- **Altes Format:** Hat das Projekt eine `PROGRESS.md` mit `FEATURE-INDEX`-Block, aber
  keine `features/INDEX.md`, arbeitet es noch mit dem Dokumentmodell vor coding-kit
  2.0.0. Dann nichts schreiben: auf die Migration per `/coding-kit:update-conventions`
  verweisen.
- **Ohne `features/`** (ein Projekt, das nicht aus dem Template kommt): `features/INDEX.md`
  aus `${CLAUDE_PLUGIN_ROOT}/template/core/features/INDEX.md` anlegen (Projektname und
  Doku-Sprache eingesetzt) — mit in der Vorschau. Fehlt `scripts/features-index.sh`, das
  Skript aus `${CLAUDE_PLUGIN_ROOT}/template/core/scripts/features-index.sh` mit `sh`
  aufrufen (in Shell-Befehlen der aufgelöste Pfad).

## 1. Interview (M1 — eine Frage pro Antwort, immer mit Default)

Aus der Short-Info Vorschläge ableiten und bestätigen lassen statt offen zu fragen:

1. **Ziele:** „Ich lese daraus diese 2–3 Ziele: … — passt das?" _(Default: ja)_
2. **Kern-Features:** vorgeschlagene Liste durchgehen; je Feature kurz bestätigen/
   schärfen — das Problem dahinter zuerst, die Lösung nur als Skizze. So lange
   nachfragen, bis die Liste stabil ist — aber keine Detailtiefe erzwingen, die erst
   `/coding-kit:prep-step` klärt.
3. **Nicht-Ziele:** explizit machen — mindestens 2 Kandidaten vorschlagen („kein
   Multi-User", „kein Hosting"). Nicht-Ziele sind so verbindlich wie Ziele.
4. **Rahmenbedingungen:** technisch/rechtlich/Plattform/Budget — Kandidaten aus der
   Short-Info und dem gewählten Stack vorschlagen.
5. **Eigenschafts-Trigger des Fragment-Katalogs:** die `*characteristic:*`-Zeilen aus
   `${CLAUDE_PLUGIN_ROOT}/template/modules/standards/README.md` zur Laufzeit lesen (das
   Template kommt mit dem Plugin, siehe `/choose-stack` § 0) und je Zeile als Ja/Nein-Frage
   stellen (z. B. audit-logging → „Gibt es Nutzer-/Admin-Aktionen, die Daten
   verändern?") _(Default: nein)_. Treffer als Rahmenbedingung festhalten.
6. **Reihenfolge:** eine sinnvolle Umsetzungsreihenfolge der Kern-Features vorschlagen,
   je mit einem Halbsatz Begründung _(Default: der Vorschlag)_.

## 2. Ziel-Abschnitte im Überblick der CLAUDE.md

Drei kurze Unterabschnitte unter dem Überblick, in der Sprache der CLAUDE.md-Prosa:
**Ziele**, **Nicht-Ziele**, **Rahmenbedingungen** (mit den Eigenschafts-Treffern) — je ein
paar Stichpunkte, so knapp, dass sie jede Session mitladen kann. Keine eigene Datei; wird
es in einem Projekt deutlich mehr, darf es ausgelagert und per `@` eingebunden werden.

- **Grundsatzentscheidungen** aus dem Interview (Stack, Speicher, Protokoll …), die das
  Projekt über ein Feature hinaus prägen: als ADR in `docs/adr/` vorschlagen (Vorlage
  `0000-template.md`), nicht in die CLAUDE.md.
- **Offene Fragen** gehören in die Feature-Datei, die sie betreffen
  (`- [ ] [CLARIFY] …` unter „Noch zu analysieren"); eine projektweite als Stichpunkt mit
  `[CLARIFY]` unter den Rahmenbedingungen. Ehrlich offen lassen statt wegentscheiden.

## 3. Feature-Dateien und Index

- **Je Kern-Feature eine schlanke Datei** `features/F-NNN-kurzname.md` — Nummern ab der
  Zeile `next-feature:` in `features/INDEX.md` (F-NNN, dreistellig), danach
  `next-feature` auf die nächste freie. Kopfblock, Titelregel, Dateiname und Abschnitt
  Erfassung genau wie `/coding-kit:add-feature` § 4 (Gerüst aus
  `features/F-000-template.md`, ersatzweise
  `${CLAUDE_PLUGIN_ROOT}/template/core/features/F-000-template.md`): `status: BACKLOG`,
  `type` passend, Problem, Ziel, unverbindliche Lösungsskizze, Abhängigkeiten. Die
  Beratung von add-feature entfällt hier — das Interview hat die Liste schon bestätigt.
- **Empfohlene Reihenfolge** in `features/INDEX.md`: die Nummern aus Interview-Frage 6,
  je mit Halbsatz Begründung, Stand-Datum heute.
- Vor dem Schreiben scannen: keine Klarnamen, lokalen Pfade, IPs, Kundennamen —
  lebende Doku bleibt publishbar.
- Entwurf zeigen — Ziel-Abschnitte, Feature-Dateien, Reihenfolge, `next-feature` in einer
  Vorschau (lang: nach `private/`), **erst nach OK schreiben**. Danach die Tabelle
  erzeugen: `just features-index` (ohne das Rezept `sh scripts/features-index.sh write`,
  ohne Skript im Projekt siehe Schritt 0); meldet das Skript etwas, beheben. Alles
  re-lesen.

## Rückgabe an den Aufrufer

Kurzfazit: Anzahl Feature-Dateien, offene Fragen, vorgeschlagene ADRs — für
`/new-project` als Bestätigung, dass die initiale Roadmap steht. Zusätzlich die im
Interview **bejahten Eigenschafts-Fragmente** (z. B. `audit-logging`), damit
`/new-project` sie bei der Instanziierung in den CODING-STANDARDS-Slot mitkomponiert.
