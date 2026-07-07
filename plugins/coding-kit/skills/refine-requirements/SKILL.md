---
name: refine-requirements
description: Zurück zur Spec. M2-Diagnose-Einstieg („Was führt dich zurück zur Spec?") mit drei Pfaden — Umfeld geändert, Implementierung zeigte Lücken, Grundsatz-Challenge. Darf Features splitten, schreibt datierte Decision-Log-Einträge, verwaltet den Auflöse-Trigger der REQUIREMENTS.md mit.
disable-model-invocation: false
---

# Anforderungen verfeinern

Einstieg, wenn die Spec nicht mehr zur Realität passt. Arbeitet auf `REQUIREMENTS.md`,
solange sie existiert; nach deren Auflösung direkt auf den `PROGRESS.md`-Einträgen
(Entscheidungen dann als ADR in `docs/adr/`, falls vorhanden, sonst im betroffenen
PROGRESS-Eintrag).

## 0. Projektkontext ermitteln

Projekt-CLAUDE.md lesen (Sprache der lebenden Doku, Scope, Graphiti-group_id — optional).
Dann `REQUIREMENTS.md` (falls vorhanden) und `PROGRESS.md` (Done-Tabelle, offene Tasks,
FEATURE-INDEX) lesen — erst Dateien, dann Fragen.

## Kontext-Recovery

Nach Kompaktierung oder Session-Neustart: Spec + PROGRESS re-lesen, `git status` +
`git diff` prüfen, beim aktuellen Pfad weitermachen — nichts doppelt entscheiden.

## 1. Diagnose (M2 — eine Frage, drei Pfade)

Frage: **„Was führt dich zurück zur Spec?"** mit den drei Pfaden als Optionen:

1. **Etwas hat sich geändert** — Umfeld, Anforderung, Erkenntnis von außen.
2. **Die Implementierung zeigte Lücken** — die Spec war unpräzise oder unvollständig.
3. **Grundsatz-Challenge** — eine Annahme/Entscheidung soll hinterfragt werden.

Wenn die Nutzereingabe den Pfad schon klar macht: nicht erneut fragen, Pfad benennen und
loslegen.

## 2. Pfadarbeit

**Pfad 1 — Änderung von außen:**
- Was genau hat sich geändert, seit wann, was ist betroffen (Goals, Features,
  Constraints, Out of scope)?
- Betroffene Abschnitte aktualisieren; obsolet Gewordenes explizit streichen (nie
  stillschweigend). Betroffene offene F-Nummern anpassen; bereits Erledigtes bleibt
  unangetastet (ggf. neue Folge-F-Nummer statt Umschreiben der Historie).

**Pfad 2 — Lücken aus der Implementierung:**
- Die Lücke konkret benennen (was war unterspezifiziert, was wurde stattdessen gebaut/
  blockiert?).
- Spec präzisieren, sodass die Entscheidung reproduzierbar ist; betroffene F-Nummern
  schärfen (Abnahmekriterien!). Erledigte Substeps nicht rückwirkend ändern.

**Pfad 3 — Grundsatz-Challenge:**
- Annahme explizit formulieren, Für/Wider kurz aufreihen, Empfehlung mit Begründung.
- Ausgang darf sein: Feature **splitten** (aus einer F-Nummer werden zwei — neue Nummern
  via FEATURE-INDEX, alte Nummer als aufgeteilt markieren), Feature streichen (nach
  Out of scope verschieben), Constraint kippen, oder: Annahme hält (auch das ist ein
  dokumentierenswertes Ergebnis).

## 3. Decision Log (immer)

Jede Entscheidung als **datierter** Eintrag — Product- und Technical-Entscheidungen
getrennt, in der Sprache der lebenden Doku. Historie nie umschreiben: alte Einträge
bleiben, neue supersedieren („ersetzt Entscheidung vom …"). Ohne REQUIREMENTS.md →
ADR bzw. PROGRESS-Eintrag (siehe Kopf).

## 4. Abschluss

- Alle Änderungen als Entwurf zeigen, **erst nach OK schreiben**; danach Write-then-Verify.
- Vor dem Schreiben: Privacy-Kurzcheck (keine Klarnamen, Pfade, IPs, Kundennamen).
- FEATURE-INDEX konsistent halten (neue/gesplittete Nummern, `next-feature:`).
- **Auflöse-Trigger prüfen** (Regel in `/define-requirements` § 4): Sind jetzt alle
  Anforderungen in PROGRESS überführt, dem Nutzer die Auflösung der REQUIREMENTS.md
  vorschlagen.
- Graphiti: `add_memory` mit der group_id aus der CLAUDE.md (falls verfügbar) —
  Entscheidungen sind genau das, was in den Graph gehört.
