---
name: define-requirements
description: Anforderungen erheben. M1-Interview aus der Short-Info (Ziele, Kern-Features, Nicht-Ziele, Constraints, Eigenschafts-Trigger des Fragment-Katalogs) → REQUIREMENTS.md als Übergangs-Artefakt → initiale PROGRESS.md mit einer F-Nummer je Anforderung. Verwaltet auch den Auflöse-Trigger der REQUIREMENTS.md. Einzeln nutzbar und von /new-project aufrufbar.
disable-model-invocation: false
---

# Anforderungen erheben

Argument: die Short-Info des Projekts. Ziel: eine belastbare `REQUIREMENTS.md`
(Übergangs-Artefakt) und eine initiale `PROGRESS.md` mit F-Nummern.

## 0. Projektkontext ermitteln

Projekt-CLAUDE.md lesen: Sprache der lebenden Doku (REQUIREMENTS + PROGRESS werden in
dieser Sprache geschrieben), Zweck/Scope, Graphiti-group_id (optional). Existiert schon
eine `REQUIREMENTS.md` (z. B. als Template-Skelett) → deren Struktur füllen statt neu
anlegen. Existiert schon substanzieller Inhalt → an `/refine-requirements` verweisen.

## 1. Interview (M1 — eine Frage pro Antwort, immer mit Default)

Aus der Short-Info Vorschläge ableiten und bestätigen lassen statt offen zu fragen:

1. **Ziele:** „Ich lese daraus diese 2–3 Ziele: … — passt das?" _(Default: ja)_
2. **Kern-Features:** vorgeschlagene Liste durchgehen; je Feature kurz bestätigen/
   schärfen. So lange nachfragen, bis die Liste stabil ist — aber keine Detailtiefe
   erzwingen, die erst die Umsetzung klärt.
3. **Nicht-Ziele (Out of scope):** explizit machen — mindestens 2 Kandidaten vorschlagen
   („kein Multi-User", „kein Hosting"). Nicht-Ziele sind so verbindlich wie Ziele.
4. **Constraints:** technisch/rechtlich/Plattform/Budget — Kandidaten aus der Short-Info
   und dem gewählten Stack vorschlagen.
5. **Eigenschafts-Trigger des Fragment-Katalogs** — nur wenn das project-template
   erreichbar ist (im /new-project-Flow ist es bereits aufgelöst; standalone ohne
   Template still überspringen): die `*characteristic:*`-Zeilen aus
   `modules/standards/README.md` zur Laufzeit lesen und je Zeile als Ja/Nein-Frage
   stellen (z. B. audit-logging → „Gibt es Nutzer-/Admin-Aktionen, die Daten
   verändern?") _(Default: nein)_. Treffer als Constraint + Decision-Log-Eintrag in
   der REQUIREMENTS.md festhalten.

## 2. REQUIREMENTS.md schreiben (M5-Struktur)

Struktur = Template-Skelett (`core/REQUIREMENTS.md` im project-template): Kopfnotiz
„Transitional artifact" mit Auflöse-Regel, **Goals**, **Core features** (nummeriert —
jedes wird eine F-Nummer), **Out of scope**, **Constraints**, **Decision log** (datiert,
Product/Technical getrennt; Historie nie umschreiben — neue Einträge ergänzen),
**Open questions** als `- [ ]`-Checkboxen.

Initiale Decision-Log-Einträge: die im Interview gefallenen Grundsatzentscheidungen
(datiert). Offene Punkte ehrlich als Open questions führen statt wegzuentscheiden.

## 3. PROGRESS.md befüllen

- Je Kern-Feature **eine F-Nummer** (F-001, F-002, … dreistellig) mit Kurzbeschreibung
  im PROGRESS-Schema des Projekts; Reihenfolge = sinnvolle Umsetzungsreihenfolge.
- `<!-- FEATURE-INDEX -->`-Block pflegen: alle Nummern + `next-feature:` auf N+1.
- Vor dem Schreiben scannen: keine Klarnamen, lokalen Pfade, IPs, Kundennamen —
  lebende Doku bleibt publishbar.
- Entwurf zeigen, **erst nach OK schreiben**.

## 4. Auflöse-Trigger (Lifecycle der REQUIREMENTS.md)

Die REQUIREMENTS.md wird aufgelöst, **sobald alle Anforderungen vollständig in
PROGRESS.md überführt sind** — geprüft (jedes Goal/Feature hat eine F-Nummer, keine
offenen Open questions mit Produktcharakter) und **vom Nutzer bestätigt**. Dann:

1. Kurzzusammenfassung (Zweck, Kernentscheidungen) in die Projekt-CLAUDE.md übernehmen/
   aktualisieren.
2. Noch relevante Decision-Log-Einträge sichern: als ADR nach `docs/adr/` (falls
   vorhanden) oder in den betroffenen PROGRESS-Eintrag.
3. `REQUIREMENTS.md` löschen (Historie bleibt in git). Nachfolgende Spec-Arbeit läuft
   über `/refine-requirements`.

Direkt nach dem Erst-Interview ist das selten schon der Fall — der Trigger wird
typischerweise von `/refine-requirements` oder `/step-done`-Läufen erreicht.

## Rückgabe an den Aufrufer

Kurzfazit: Anzahl F-Nummern, offene Fragen, ob REQUIREMENTS.md besteht oder aufgelöst
wurde — für `/new-project` als Bestätigung, dass die initiale Roadmap steht. Zusätzlich
die im Interview **bejahten Eigenschafts-Fragmente** (z. B. `audit-logging`), damit
`/new-project` sie bei der Instanziierung in den CODING-STANDARDS-Slot mitkomponiert.
