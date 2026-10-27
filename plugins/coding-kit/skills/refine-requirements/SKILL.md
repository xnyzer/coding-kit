---
name: refine-requirements
description: Zurück zur Spec. M2-Diagnose-Einstieg („Was führt dich zurück zur Spec?") mit drei Pfaden — Umfeld geändert, Implementierung zeigte Lücken, Grundsatz-Challenge. Arbeitet auf den Zielen, Nicht-Zielen und Rahmenbedingungen im Überblick der Projekt-CLAUDE.md, den Feature-Dateien und den ADRs; teilt Features (SUPERSEDED), streicht sie (DROPPED), schreibt datierte Entscheidungen und plant die empfohlene Reihenfolge um.
disable-model-invocation: false
user-invocable: true
---

# Anforderungen verfeinern

Einstieg, wenn die Spec nicht mehr zur Realität passt. Arbeitet auf drei Orten:

- **Ziel-Abschnitte** im Überblick der Projekt-CLAUDE.md — Ziele, Nicht-Ziele,
  Rahmenbedingungen;
- **Feature-Dateien** `features/F-NNN-*.md` und der Übersicht `features/INDEX.md`
  (empfohlene Reihenfolge, erzeugte Tabelle);
- **ADRs** in `docs/adr/` für Entscheidungen, die das Projekt über ein Feature hinaus
  prägen.

**Freigabe-Gate:** Jede neue oder geänderte Feature-Datei (`features/F-NNN-*.md`), jede
Änderung an `features/INDEX.md` und an den Ziel-Abschnitten im Überblick der
`CLAUDE.md` wird zuerst als Vorschau gezeigt und erst nach ausdrücklichem OK des Nutzers
geschrieben (ausgenommen: genau der zuvor freigegebene Text; die Tabelle erzeugt danach
das Skript). Lange Entwürfe (etwa ab 40 Zeilen) gehen als Datei nach `private/` und
werden nach dem Übernehmen gelöscht.

## 0. Projektkontext ermitteln

Projekt-CLAUDE.md lesen (Sprachen, Überblick mit den Ziel-Abschnitten, Scope,
Graphiti-group_id — optional). Dann `features/INDEX.md` (Reihenfolge, Tabelle) und die
berührten Feature-Dateien und ADRs lesen — erst Dateien, dann Fragen.

**Altes Format:** Hat das Projekt eine `PROGRESS.md` mit `FEATURE-INDEX`-Block, aber keine
`features/INDEX.md`, arbeitet es noch mit dem Dokumentmodell vor coding-kit 2.0.0. Dann
nichts schreiben: auf die Migration per `/coding-kit:update-conventions` verweisen.

## Kontext-Recovery

Nach Kompaktierung oder Session-Neustart: CLAUDE.md-Überblick, `features/INDEX.md` und die
berührten Feature-Dateien re-lesen, `git status` + `git diff` prüfen, beim aktuellen Pfad
weitermachen — nichts doppelt entscheiden.

## 1. Diagnose (M2 — eine Frage, drei Pfade)

Frage: **„Was führt dich zurück zur Spec?"** mit den drei Pfaden als Optionen:

1. **Etwas hat sich geändert** — Umfeld, Anforderung, Erkenntnis von außen.
2. **Die Implementierung zeigte Lücken** — die Spec war unpräzise oder unvollständig.
3. **Grundsatz-Challenge** — eine Annahme/Entscheidung soll hinterfragt werden.

Wenn die Nutzereingabe den Pfad schon klar macht: nicht erneut fragen, Pfad benennen und
loslegen.

## 2. Pfadarbeit

**Pfad 1 — Änderung von außen:**
- Was genau hat sich geändert, seit wann, was ist betroffen (Ziele, Nicht-Ziele,
  Rahmenbedingungen, einzelne Features)?
- Betroffene Abschnitte aktualisieren; obsolet Gewordenes explizit streichen (nie
  stillschweigend). Offene Features anpassen; `DONE` bleibt unangetastet — Folgearbeit
  bekommt eine neue Nummer (`/coding-kit:add-feature`).

**Pfad 2 — Lücken aus der Implementierung:**
- Die Lücke konkret benennen (was war unterspezifiziert, was wurde stattdessen gebaut/
  blockiert?).
- Die Spezifikation des Features präzisieren, sodass die Entscheidung reproduzierbar ist
  (Abnahmekriterien `AC-n`, Randfälle `EC-n`, Nicht-Ziele). Verbuchte Substeps im
  Verlauf nicht rückwirkend ändern.

**Pfad 3 — Grundsatz-Challenge:**
- Annahme explizit formulieren, Für/Wider kurz aufreihen, Empfehlung mit Begründung.
- Ausgang darf sein:
  - Feature **teilen** — neue Dateien mit den nächsten Nummern ab `next-feature`
    (Kopfblock und Erfassung wie `/coding-kit:add-feature` § 4), das alte Feature wird
    `SUPERSEDED` mit `superseded-by` auf die neuen Nummern;
  - Feature **zusammenlegen** — das aufgehende wird `SUPERSEDED` mit Verweis auf das
    bleibende;
  - Feature **streichen** — `DROPPED`, der Grund in der Datei; gehört es grundsätzlich
    nicht ins Projekt, auch als Nicht-Ziel in die CLAUDE.md;
  - Rahmenbedingung kippen — oder: Annahme hält (auch das ist ein dokumentierenswertes
    Ergebnis).
  DROPPED und SUPERSEDED behalten Datei und Nummer; `done:` auf heute.

**Umplanung der Reihenfolge:** Verschiebt die Pfadarbeit Prioritäten oder Abhängigkeiten,
die empfohlene Reihenfolge in `features/INDEX.md` neu vorschlagen — nur offene Features,
je mit Halbsatz Begründung, Stand-Datum heute.

## 3. Entscheidungen (immer)

Jede Entscheidung **datiert** mit Grund, in der Sprache der lebenden Doku. Historie nie
umschreiben: alte Einträge bleiben, neue supersedieren („ersetzt Entscheidung vom …").

- Betrifft sie ein Feature → Abschnitt Entscheidungen seiner Datei (überstimmt der Nutzer
  eine Empfehlung, steht das so da).
- Prägt sie das Projekt über ein Feature hinaus → neues ADR in `docs/adr/` (ein
  angenommenes ADR wird nie umgeschrieben, sondern durch ein neues ersetzt); die
  berührten Feature-Dateien verlinken es.

## 4. Abschluss

- Alle Änderungen als Entwurf zeigen, **erst nach OK schreiben**; danach Write-then-Verify.
- Vor dem Schreiben: Privacy-Kurzcheck (keine Klarnamen, Pfade, IPs, Kundennamen).
- Nach dem Schreiben die Tabelle erzeugen: `just features-index` (ohne das Rezept
  `sh scripts/features-index.sh write`); meldet das Skript etwas, beheben.
- Graphiti: `add_memory` mit der group_id aus der CLAUDE.md (falls verfügbar) —
  Entscheidungen sind genau das, was in den Graph gehört.
