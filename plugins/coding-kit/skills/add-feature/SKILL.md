---
name: add-feature
description: Neue Aufgabe auf die Roadmap setzen. Hält zuerst das Problem hinter der Idee fest, berät (stärkstes Gegenargument, Alternativen, eine von vier Empfehlungen — auch „nicht aufnehmen"), prüft Überschneidungen mit den Feature-Dateien und legt nach Freigabe eine Datei features/F-NNN-kurzname.md mit Status BACKLOG an; die Tabelle in features/INDEX.md wird erzeugt, ein Platz in der Reihenfolge vorgeschlagen. Startet der Nutzer per Slash-Command oder Claude selbst, wenn im Gespräch oder beim Bauen eine neue Aufgabe entsteht — angelegt wird immer erst nach ausdrücklichem OK.
argument-hint: "[Kurzbeschreibung]"
disable-model-invocation: false
user-invocable: true
---

# Aufgabe aufnehmen

Eine neue Aufgabe soll auf die Roadmap: neues Verhalten, ein Fehler, ein Umbau, Doku, ein
Audit. Alles bekommt eine F-Nummer und eine eigene Datei in `features/`, die über den
ganzen Lebenslauf der Aufgabe wächst. Dieser Skill legt sie an — knapp, nach Beratung.

**Wer startet:** der Nutzer per `/coding-kit:add-feature` — oder Claude selbst, wenn im
Gespräch oder beim Bauen (z. B. aus `/coding-kit:build-step` heraus) eine neue Aufgabe
entsteht. Claude muss dafür nicht den Nutzer bitten, den Skill aufzurufen.

**Freigabe-Gate:** Jede neue oder geänderte Feature-Datei (`features/F-NNN-*.md`), jede
Änderung an `features/INDEX.md` und an den Ziel-Abschnitten im Überblick der
`CLAUDE.md` wird zuerst als Vorschau gezeigt und erst nach ausdrücklichem OK des Nutzers
geschrieben (ausgenommen: genau der zuvor freigegebene Text; die Tabelle erzeugt danach
das Skript). Lange Entwürfe (etwa ab 40 Zeilen) gehen als Datei nach `private/` und
werden nach dem Übernehmen gelöscht.

Argument: Kurzbeschreibung der Aufgabe (z. B. „Rate-Limit-Middleware", „Export als CSV").

## 0. Projektkontext ermitteln

Lies die **Projekt-CLAUDE.md** (Repo-Root) — sie ist die Quelle für alle Projektspezifika:

- **Überblick** mit Zweck, Umfang und den Abschnitten Ziele, Nicht-Ziele und
  Rahmenbedingungen (für die Passt-das-hierher-Prüfung).
- **Sprache der lebenden Doku** — die Feature-Datei schreibst du in genau dieser Sprache;
  Feldnamen und Status-Token bleiben englisch.
- **Graphiti-group_id** (aus dem Graphiti-Block). Fehlt der Block oder läuft kein
  Graphiti-MCP → alle Graphiti-Schritte still überspringen.
- **Sicherheits-Postur:** öffentliches Repo oder Security-/Auth-Charakter (z. B.
  `THREAT-MODEL.md` vorhanden) → erhöhte Scan-Schärfe und Extra-Sicherheitsanalyse.

Hardcode nichts davon — jedes Projekt ist anders.

**Altes Format:** Hat das Projekt eine `PROGRESS.md` mit `FEATURE-INDEX`-Block, aber keine
`features/INDEX.md`, arbeitet es noch mit dem Dokumentmodell vor coding-kit 2.0.0. Dann
nichts anlegen und nicht raten: auf die Migration per `/coding-kit:update-conventions`
verweisen und die Idee bis dahin nur im Gespräch festhalten.

## 1. Problem verstehen

- **Problem vor Lösung:** Was fehlt oder stört, für wen, und warum zählt es? Bringt der
  Nutzer eine fertige Lösung mit („bau X"), zuerst das Problem dahinter festhalten — die
  Lösung wird eine Option unter mehreren, kein Auftrag.
- **Art bestimmen** (Feld `type`): `feature` (neues Verhalten), `fix` (falsches
  Verhalten), `change` (Umbau, Doku, Pflege, Audit).
- Bei unklarer Beschreibung: **nachfragen** — nicht raten. Eine Frage pro Antwort, immer
  mit einem empfohlenen Default.

## 2. Analyse und Beratung

- **Passt es zum Projekt?** Gegen Zweck, Ziele und Nicht-Ziele aus dem Überblick der
  CLAUDE.md prüfen; ein Widerspruch zu einem Nicht-Ziel ist ein Grund zum Abraten.
- **Gibt es das schon?** Die Tabelle aller Features in `features/INDEX.md` lesen —
  Überschneidungen oder Abhängigkeiten? Einzelne Feature-Dateien nur bei konkretem
  Verdacht öffnen; auch `DROPPED` und `SUPERSEDED` zählen (die Idee kam schon einmal,
  der Grund steht in der Datei).
- **Machbarkeit im Stack:** Stack/Tooling aus CLAUDE.md bzw. justfile ableiten — nie
  einen Stack annehmen, der nirgends dokumentiert ist.
- **Sicherheits-/Privacy-Implikationen:** neue Angriffsflächen, externe Dienste, Secrets?
  Bei Security-Postur (siehe Schritt 0) mit besonderer Sorgfalt, ggf. gegen
  `THREAT-MODEL.md` prüfen.
- **Stärkstes Gegenargument** nennen — ehrlich, nicht als Pflichtübung.
- **Alternativen** nennen, auch die unbequemen: nichts bauen, Doku statt Code, gibt es
  schon (im Projekt, in einer Bibliothek, im Werkzeug), ein kleinerer erster Schritt.

## 3. Empfehlung vorstellen

Kurz präsentieren: Problem, Gegenargument, Alternativen, Abhängigkeiten, offene Fragen —
und **genau eine** von vier Empfehlungen mit Begründung:

- **aufnehmen** — neue Feature-Datei;
- **an Bestehendes anhängen** — die Idee gehört in ein offenes Feature (dessen Datei wird
  ergänzt, Vorschau wie unten);
- **anders lösen** — eine Alternative statt der mitgebrachten Lösung aufnehmen;
- **nicht aufnehmen** — auf Wunsch trotzdem als Datei mit Status `DROPPED` und Grund;
  empfohlen, wenn die Idee wiederkommen kann, damit sie samt Begründung gefunden wird.

Die Entscheidung trifft der Nutzer. **Auf OK warten, bevor du ausformulierst.**

## 4. Ausformulieren

**Nummer:** die Zeile `next-feature: F-NNN` in `features/INDEX.md` lesen und diese Nummer
verwenden; `next-feature` steigt auf die nächste. Neue Nummern immer als **F-NNN**
(dreistellig); Alt-Formate (F-9, F9, „1.2") in Texten tolerant lesen, nie umnummerieren.

**Titel** (Feld `title`): höchstens 70 Zeichen; sagt, *was sich ändert* — nicht wie,
nicht warum, kein Ergebnisbericht; kein Status, keine Version, keine Aufzählung in
Klammern. Kein Doppelpunkt und kein `#`, am Anfang kein Anführungszeichen, keine Klammer
und kein Strich: Markdown-Vorschauen lesen den Kopfblock als YAML, und daran bricht er —
statt des Doppelpunkts einen Gedankenstrich.

**Dateiname:** `features/F-NNN-kurzname.md` — Kurzname aus dem Titel, ASCII,
Kleinbuchstaben, Ziffern und Bindestriche, Umlaute ausgeschrieben (ä → ae), etwa 40
Zeichen. Er wird beim Anlegen festgelegt und nie geändert, auch wenn der Titel sich
ändert.

**Gerüst:** aus der Vorlage `features/F-000-template.md` des Projekts (fehlt sie:
`${CLAUDE_PLUGIN_ROOT}/template/core/features/F-000-template.md`). Dieser Skill schreibt
den Kopfblock, die Überschrift und den Abschnitt **Erfassung**; Spezifikation, Plan und
Verlauf legen prep-step und step-done an, wenn sie sie füllen. Überschriften und Text in
der Sprache der lebenden Doku; die HTML-Kommentare der Vorlage fallen weg.

**Kopfblock** — nur einfache `feld: wert`-Zeilen, keine Anführungszeichen, Listen
kommagetrennt:

```
---
id: F-NNN
title: <Titel>
type: feature | fix | change
status: BACKLOG
size:
created: <heute, JJJJ-MM-TT>
done:
depends-on: <F-Nummern oder leer>
superseded-by:
---
```

Bei „nicht aufnehmen" mit Datei: `status: DROPPED`, `done:` auf heute, der Grund steht in
der Erfassung.

**Erfassung** (Überschriften übersetzt):

- **Problem:** was fehlt oder falsch ist und warum es zählt (1–3 Sätze).
- **Ziel:** je nach `type` — `feature`: „Als <Rolle> möchte ich <…>, damit <…>"; `fix`:
  Ist, Soll, wie reproduzieren; `change`: Ziel und was gleich bleiben muss.
- **Lösungsskizze:** unverbindliche Richtung in wenigen Stichpunkten; eine mitgebrachte
  Lösung steht hier als Option. Keine Dateilisten, keine Zerlegung, keine
  Abnahmekriterien — das macht `/coding-kit:prep-step` gegen den dann aktuellen
  Codestand. Neue Dependencies nur permissiv lizenziert (kein GPL/AGPL).
- **Abhängigkeiten:** F-Nummern (auch im Feld `depends-on`) oder „keine".
- **Noch zu analysieren:** optional, offene Fragen und Entscheidungen.

**Empfohlene Reihenfolge:** einen Platz in `features/INDEX.md` vorschlagen (eine Zeile mit
Nummer und Halbsatz Begründung, das Stand-Datum auf heute) — oder ausdrücklich keinen,
wenn die Aufgabe erst später dran ist. Nur offene Features gehören dorthin.

**An Bestehendes anhängen:** statt einer neuen Datei die Erfassung des offenen Features
ergänzen (Vorschau der geänderten Stelle); keine neue Nummer.

## 5. Festhalten

- Entwurf zeigen — Datei, `next-feature`-Zeile und Vorschlag zur Reihenfolge in einer
  Vorschau; **erst nach explizitem OK** schreiben.
- **Vor dem Schreiben** den Text auf Secrets/Interna scannen (keine echten Tokens, IPs,
  Hostnames, Klarnamen, lokalen Pfade — lebende Doku bleibt publishbar).
- Nach dem Schreiben die Tabelle erzeugen: `just features-index` (ohne das Rezept
  `sh scripts/features-index.sh write`). Meldet das Skript etwas, beheben und erneut
  laufen lassen; die Datei re-lesen.
- Graphiti aktualisieren: `add_memory` mit der group_id aus der CLAUDE.md (falls
  verfügbar, sonst still überspringen) — mit dem Pfad der Feature-Datei.
- Nicht committen — das macht `/coding-kit:step-done` mit dem nächsten Abschluss, oder
  der Nutzer entscheidet.
