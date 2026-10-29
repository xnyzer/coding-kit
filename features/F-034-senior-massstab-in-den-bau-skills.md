---
id: F-034
title: Senior-Maßstab in den Bau-Skills
type: feature
status: IN-PROGRESS
size: M
created: 2026-10-20
done:
depends-on: F-050
superseded-by:
---

# F-034 — Senior-Maßstab in den Bau-Skills

## Erfassung

**Problem:** Der inhaltliche Maßstab steht in der `CODING-STANDARDS.md` des Templates,
die Bau-Skills wenden ihn aber nicht aktiv an: `build-step` liest die Datei nur
(„falls vorhanden"). Qualität wird erst nachträglich in `step-done` geprüft, ohne
CODING-STANDARDS gibt es gar keine Messlatte, und im autonomen `/goal`-Lauf fehlt eine
Regel für den Fall, dass die saubere Lösung nicht im Plan liegt.

**Idee:** Die Bau-Skills arbeiten durchgängig wie ein Senior-Entwickler. Sie wählen die
einfachste tragfähige Lösung, schreiben Code, den der Nächste beim Ändern versteht
(keine verschachtelten Schleifen oder cleveren Ketten) und den ein Senior-Entwickler im
Diff prüfen kann — immer menschenlesbar, nie minifiziert —, bauen keine Workarounds und
sichern jeden Substep auch auf Secure Coding ab. Die Skills regeln den Prozess, den
Inhalt regelt die `CODING-STANDARDS.md`.

**Lösungsskizze:**
- `build-step`: aktive Qualitäts-Leitplanke. Selbst-Review je Substep, bevor er als
  fertig gemeldet wird: verständlich, einfach, sicher. Workaround-Stopp: Ist die saubere
  Lösung im Plan nicht machbar, anhalten und melden statt Hack. Vorhandene Fehler im
  berührten Code gleich mitbeheben, bei großen Korrekturen erst fragen.
- **Menschenlesbarer Code:** Was die Skills schreiben, ist lesbarer Quelltext — nie
  minifiziert, komprimiert oder auf eine Zeile gepresst, auch nicht JSON, CSS oder
  Konfiguration —, damit ein Senior-Entwickler jede Änderung prüfen kann. Minifiziertes
  entsteht nur als Build-Ausgabe des Build-Werkzeugs und wird nie von Hand geschrieben
  oder bearbeitet. `build-step` prüft das im Selbst-Review, `step-done` im Review.
- Ersatz-Maßstab für Projekte ohne `CODING-STANDARDS.md`: die Abschnitte Mindset,
  Control flow und Secure coding der Vorlage aus dem Plugin — kein Duplikat.
- `teach-step`, `prep-step` (einfachstes Design planen; Security-Punkte je Substep
  deckt mit F-036 der Sicherheits-Blick der Spezifikation ab) und `step-done`
  (Review-Kriterien Verständlichkeit und Secure Coding) konsistent nachziehen.
- Inhaltliche Lücken der Vorlage (Lesbarkeit vor Cleverness, Secure Coding über Secrets
  hinaus) sind mit TPL-021 (project-template 0.14.0) bereits im Template;
  Bestandsprojekte erhalten sie über `/update-conventions`. Neu dazu: eine Regel in der
  `CODING-STANDARDS.md` der Vorlage (bei „Readable over clever", § 6): Quelltext ist
  menschenlesbar und nie minifiziert, Minifiziertes nur als Build-Ausgabe. Das ist
  Template-Inhalt und braucht deshalb einen CHANGELOG-Abschnitt `### Template`.

**Abhängigkeiten:** F-036 (erledigt) und F-050 — ohne autonomen Lauf braucht der
Workaround-Stopp keine Sonderregel; zusammen mit F-037 umsetzen. Gegenstück:
TPL-021 (Inhalte der CODING-STANDARDS-Vorlage, erledigt) — die Skill-Kriterien darauf
abstimmen.

## Spezifikation

### Abnahmekriterien

- [ ] AC-1 — Gegeben ein Substep in build-step, wenn er umgesetzt ist und die Checks
  grün sind, dann folgt vor der Fertig-Meldung ein Selbst-Review des Diffs nach fünf
  Prüffragen — verständlich, einfach, sicher, lesbar (nie minifiziert), kein Workaround —
  gegen den Maßstab aus AC-4; Funde werden behoben, der Bericht nennt das Ergebnis in
  einer Zeile. Negativ: Ein Substep mit offenem Fund wird nicht als fertig gemeldet.
- [ ] AC-2 — Gegeben die saubere Lösung ist im Plan nicht machbar (sie bräuchte mehr
  Umfang oder eine andere Architektur, oder sie bricht ein Nicht-Ziel), dann hält
  build-step an, nennt Grund und Wege (Plan per datierter Entscheidung anpassen, neue
  F-Nummer, anders lösen) und wartet auf den Nutzer. Negativ: kein Hack, kein
  `HACK`/`TODO: fix later`, kein stilles Umgehen.
- [ ] AC-3 — Gegeben build-step findet im berührten Code einen vorhandenen Fehler
  (falsches Verhalten, Sicherheitslücke, roter Check, Warnung), dann behebt er ihn im
  selben Substep, belegt die Korrektur mit einem Test und nennt sie als Fund für den
  Verlauf. Ist die Korrektur groß, ändert sie Verhalten, auf das sich anderes verlässt,
  oder liegt sie in einem anderen Teil des Projekts, fragt er vorher — auf Wunsch wird
  daraus eine eigene F-Nummer vom Typ `fix`. Negativ: Verbesserungen ohne Fehler werden
  nicht mitgebaut (weiter über `/coding-kit:add-feature`).
- [ ] AC-4 — Gegeben ein Projekt ohne `CODING-STANDARDS.md`, wenn build-step, step-done,
  teach-step oder prep-step den Maßstab brauchen, dann lesen sie die Abschnitte
  Mindset, Control flow und Secure coding der Vorlage aus dem Plugin
  (`${CLAUDE_PLUGIN_ROOT}/template/core/CODING-STANDARDS.md`) und sagen einmal, dass
  dieser Ersatz gilt. Negativ: Mit vorhandener `CODING-STANDARDS.md` wird die Vorlage
  nicht zusätzlich herangezogen.
- [x] AC-5 — Gegeben die CODING-STANDARDS-Vorlage, dann steht in § 6 bei „Readable over
  clever" die Regel: Quelltext bleibt menschenlesbar — nie minifiziert, komprimiert oder
  auf eine Zeile gepresst, auch nicht JSON, CSS oder Konfiguration; Minifiziertes
  entsteht nur als Ausgabe des Build-Werkzeugs und wird nie von Hand geschrieben oder
  bearbeitet. Der CHANGELOG-Eintrag hat einen Abschnitt `### Template` — belegt: Regel in
  § 6 der Vorlage (`CODING-STANDARDS.md`, „Human-readable source, never minified");
  CHANGELOG 3.0.0 mit `### Template`; `version-rule.py --since origin/main` OK;
  `just check` grün.
- [ ] AC-6 — Gegeben step-done reviewt einen Schritt, dann prüft es ausdrücklich dieselben
  fünf Prüffragen gegen denselben Maßstab und behebt vorhandene Fehler nach der Regel aus
  AC-3; teach-step kontrolliert die Änderung des Nutzers nach denselben Fragen und zeigt
  vorhandene Fehler (als Hinweis oder Frage, nie als Fix); prep-step plant die
  einfachste tragfähige Lösung gegen denselben Maßstab. Negativ: Kein Skill führt eigene
  Inhaltsregeln neben der `CODING-STANDARDS.md` bzw. dem Ersatz.
- [ ] AC-7 — Gegeben die Doku, dann nennen README (Skill-Tabelle) und die Template-HOW-TO
  (build-step-Zeile, „What `/step-done` does in detail") Selbst-Review,
  Workaround-Stopp und das Mitbeheben vorhandener Fehler; `just check` ist grün.

### Randfälle

- EC-1 — Die Projekt-`CODING-STANDARDS.md` weicht ab (erlaubt z. B. längere Funktionen)
  → die Projektdatei gilt; die fünf Prüffragen sind Fragen, keine zusätzlichen Regeln.
- EC-2 — Der Diff enthält Minifiziertes aus einem Werkzeug (Build-Ausgabe, Lockfile,
  vendorter Code) → kein Fund, solange es aus dem Werkzeug stammt; von Hand bearbeitet →
  Fund. Im Zweifel melden statt umformatieren.
- EC-3 — Die saubere Lösung ist im Plan machbar, nur aufwendiger als gedacht → kein
  Stopp; als Abweichung sammeln wie bisher.
- EC-4 — Reiner Doku- oder Konfig-Substep → das Selbst-Review läuft trotzdem; Fragen ohne
  Bezug (etwa „sicher" bei einem Tippfehler) entfallen, „lesbar" gilt immer.
- EC-5 — Der vorhandene Fehler liegt in vendortem oder erzeugtem Code (Fremdbibliothek,
  Build-Ausgabe) → nicht dort beheben, sondern melden; die Korrektur gehört an die Quelle.

### Nicht-Ziele

- Kein Reviewer mit frischem Kontext → F-037.
- Keine neuen Inhaltsregeln in der Vorlage außer der Minifizier-Regel — Lesbarkeit und
  Secure Coding kamen mit TPL-021.
- Keine mechanische Prüfung auf Minifiziertes (Linter, Skript); audit-code bleibt
  unverändert.

### Tests

- AC-1, AC-2, AC-3, AC-4 → manuell: ein Testlauf mit
  `claude --plugin-dir plugins/coding-kit` in einem Wegwerf-Projekt ohne
  `CODING-STANDARDS.md` — eine Mini-Aufgabe mit einer einzeiligen JSON-Datei
  (Selbst-Review meldet und behebt), ein eingebauter Altfehler im berührten Code (wird
  mit Test behoben und als Fund genannt) und eine Aufgabe, deren Plan nur mit Hack
  aufgeht (Stopp mit Wegen); der Ersatz-Maßstab wird genannt. Kosten vorher schätzen,
  danach nennen. `just check` prüft, dass der Plugin-Pfad existiert.
- AC-5 → Sichtprüfung der Regel; `just version-rule` verlangt den Abschnitt `### Template`.
- AC-6 → Textprüfung: die fünf Prüffragen heißen in build-step, step-done und teach-step
  gleich (grep), prep-step verweist auf denselben Maßstab.
- AC-7 → `just check`.

### Einbettung

- Berührt: build-step (Leitplanken, Umsetzung je Substep), step-done (Review), teach-step
  (Kontrolle im Lehr-Loop), prep-step (Kontext und Ansatz), Template-`CODING-STANDARDS.md`
  § 6 und `HOW-TO-CODE-WITH-CLAUDE.md`, README, `plugin.json` und CHANGELOG.
- Setzt F-050 voraus: Ohne autonomen Lauf braucht der Workaround-Stopp keine
  Ausstiegsbedingung für `/goal` — F-034 bekommt `depends-on: F-050` und teilt sich
  dessen unveröffentlichte Hauptversion.
- Die Scope-Regel in build-step („nichts nebenbei bauen") bekommt die Ausnahme für
  vorhandene Fehler; das deckt sich mit § 1 der Vorlage („don't dismiss as
  pre-existing").
- Bestandsprojekte erhalten § 6 und die HOW-TO über `/coding-kit:update-conventions`
  (managed Dateien, Drei-Wege-Merge); keine Migration nötig.
- Die Skill-Änderungen laufen über `/add-skill` (Begleit-Änderungen).
- F-037 baut darauf auf: sein Reviewer prüft dieselben fünf Fragen gegen denselben
  Maßstab und meldet vorhandene Fehler, die der Haupt-Agent nach AC-3 behebt — F-037
  bekommt `depends-on: F-034` und einen Hinweis in der Erfassung.
- Kein Widerspruch zu Zielen, Nicht-Zielen oder ADRs (das Kit hat keine ADRs).

### Offene Fragen

- keine

### Entscheidungen

- 2026-10-29 — Größe M statt L: Die Reichweite allein träfe L (Template-Inhalt wirkt auf
  alle Projekte), die Template-Änderung ist aber eine einzelne zusätzliche Regel.
- 2026-10-29 — Ersatz-Maßstab sind die Abschnitte Mindset, Control flow und Secure coding
  der Vorlage aus dem Plugin, statt einer eigenen Datei (doppelte Pflege) oder der ganzen
  Vorlage (Dateilängen und Commit-Regeln passen oft nicht zu fremden Projekten).
- 2026-10-29 — Vorhandene Fehler werden beim Bauen mitbehoben, mit Grenze: große
  Korrekturen, geändertes Verhalten oder ein anderer Projektteil erst nach Rückfrage —
  statt alles sofort zu beheben, damit der Diff prüfbar und der Plan aussagekräftig
  bleibt. Gilt ebenso für das Review in F-037.
- 2026-10-29 — Der autonome `/goal`-Lauf entfällt (F-050); damit entfällt die geplante
  Ausstiegsbedingung für den Workaround-Stopp.
- 2026-10-29 — F-034 und F-037 bleiben getrennte Nummern: F-037 braucht eine eigene
  Prüfung (Agents im Plugin, `context: fork`) und eine eigene Kosten-Abwägung.

## Plan

**Größe:** M — neun Dateien (vier Skills, README, HOW-TO, Vorlage, CHANGELOG,
`plugin.json`), unter 500 Zeilen, die offenen Fragen sind entschieden; die Reichweite
(Template-Inhalt) allein träfe L, betrifft aber nur eine zusätzliche Regel.

**Ansatz:** Die Skills regeln den Prozess, die `CODING-STANDARDS.md` den Inhalt. Jeder
Bau-Skill nennt die fünf Prüffragen (verständlich, einfach, sicher, lesbar, kein
Workaround) mit denselben Wörtern und prüft sie gegen die Projektdatei oder, ohne sie,
gegen die Abschnitte Mindset, Control flow und Secure coding der Vorlage aus dem Plugin.
Inhaltlich neu ist nur die Minifizier-Regel in § 6 der Vorlage. Verworfen: die
Prüffragen als eigener Abschnitt in der Vorlage — dann wären sie Projektinhalt und
fehlten in Projekten mit eigener `CODING-STANDARDS.md` oder ohne Kit. Alle Skill-Änderungen
laufen über `/add-skill`. Erkennung (prep-step 2a): keine neuen Frameworks, Dependencies
oder Tools. Keine neue Config, keine Endpunkte. Version: teilt sich die unveröffentlichte
Hauptversion von F-050; ist die schon veröffentlicht, die nächste Minor-Version.

### F-034a — Vorlage und build-step

- Template-`CODING-STANDARDS.md` § 6: die Minifizier-Regel bei „Readable over clever"
  (AC-5).
- build-step: Maßstab samt Ersatz (AC-4), Selbst-Review mit den fünf Prüffragen vor der
  Fertig-Meldung (AC-1), Workaround-Stopp mit Grund und Wegen (AC-2), Ausnahme vom
  Scope-Schutz für vorhandene Fehler mit Grenze (AC-3).
- Begleit-Änderungen: README- und HOW-TO-Zeile zu build-step (AC-7, Teil), CHANGELOG mit
  `### Template`, Version.
- Erfüllt AC-1, AC-2, AC-3, AC-5; AC-4 für build-step.

### F-034b — step-done, teach-step, prep-step

- step-done (Review): die fünf Prüffragen gegen denselben Maßstab, vorhandene Fehler
  nach der Regel aus AC-3.
- teach-step (Kontrolle im Lehr-Loop): dieselben Fragen und vorhandene Fehler als
  Hinweis oder Frage, nie als Fix.
- prep-step (Kontext und Ansatz): einfachste tragfähige Lösung gegen denselben Maßstab,
  Ersatz ohne `CODING-STANDARDS.md`.
- HOW-TO „What `/step-done` does in detail" und README-Zeile zu step-done (AC-7, Rest).
- Erfüllt AC-6, AC-7; AC-4 für die übrigen Skills.

### F-034c — Testlauf

- Ein Testlauf mit `claude --plugin-dir plugins/coding-kit` in einem Wegwerf-Projekt
  ohne `CODING-STANDARDS.md` (Aufbau wie unter Tests); Kosten vorher schätzen, danach
  nennen; Funde zeigen, der Nutzer entscheidet.
- Belegt AC-1 bis AC-4 im echten Lauf; Feinschliff an den Skill-Texten aus den Funden.

## Verlauf

### F-034a — fertig 2026-10-30

**Umgesetzt:** Die CODING-STANDARDS-Vorlage hat in § 6 die Regel „Human-readable
source, never minified". build-step lädt den Maßstab (Abschnitt 1): die
`CODING-STANDARDS.md` des Projekts, ohne sie die Abschnitte Mindset, Control flow und
Secure coding der Vorlage aus dem Plugin, mit einmaligem Hinweis. Zwei neue Leitplanken:
vorhandene Fehler im berührten Code mitbeheben (Test, Vermerk; vorher fragen bei großen
Korrekturen, geändertem Verhalten oder anderem Projektteil; vendorten oder erzeugten
Code nur melden) und „Kein Workaround" (anhalten, Grund und Wege nennen). Neuer Schritt
2.4 Selbst-Review mit den fünf Prüffragen verständlich, einfach, sicher, lesbar, kein
Workaround; Funde beheben, Ergebnis in einer Zeile. README- und HOW-TO-Zeile zu
build-step nachgezogen, CHANGELOG 3.0.0 mit F-034-Teil und `### Template`.

**Entscheidungen:** keine neuen.

**Abweichung vom Plan:** Die Einleitung des CHANGELOG-Eintrags 3.0.0 gliedert jetzt
zwei Themen (F-050, F-034); der Satz „Projekte müssen nichts tun" stimmte nicht mehr,
weil sich die Vorlage ändert. AC-1 bis AC-4 sind geschrieben, belegt werden sie wie
geplant erst im Testlauf (F-034c).

**Funde:** keine.
