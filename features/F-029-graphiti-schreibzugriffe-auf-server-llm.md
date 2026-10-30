---
id: F-029
title: Graphiti-Schreibzugriffe auf Server-LLM-Kosten optimieren
type: feature
status: IN-PROGRESS
size: L
created: 2026-10-09
done:
depends-on: F-036
superseded-by:
---

# F-029 — Graphiti-Schreibzugriffe auf Server-LLM-Kosten optimieren

## Erfassung

**Problem:** Die Skills schreiben häufig und ohne gemeinsame Regel in Graphiti — dasselbe
Feature landet bei Aufnahme, Abschluss und Spec-Änderung jeweils als eigene Episode, oft
als ausführliche Prosa mit vielen beiläufigen Nennungen. Jede Episode löst auf dem
Graphiti-Server eine Kette von Extraktions-, Dedup- und Auflösungsschritten im
angebundenen LLM aus; der Verbrauch dort ist entsprechend hoch. Der Informationsgehalt
im Graph soll dabei nicht sinken — er dient als schnelle Alternative zur Repo-Suche und
spart so Entwicklungs-Tokens.

**Idee:** Eine zentrale Graphiti-Konvention, auf die alle Skills verweisen: weniger, dafür
gezielt geschnittene Episoden mit gesteuerter Extraktion, sodass der Server pro
gespeichertem Fakt weniger LLM-Arbeit leistet. Überholtes regelt der Graph selbst über
seine Zeitstempel — kein manuelles Löschen.

**Lösungsskizze:**
- Erst auswerten, dann ändern: Die Messung pro LLM-Call und Pipeline-Schritt läuft
  serverseitig; nach ein bis zwei Wochen Daten entscheiden — bis dahin keine
  Skill-Änderungen auf Verdacht. Die Vergleichsbasis beginnt erst mit einem
  serverseitigen Fix am 09.10.2026; ältere Werte stammen aus einer anderen
  Kostenstruktur und sind nicht vergleichbar.
- Arbeitshypothese: Stärkster Hebel ist die Zahl der Entitäten, die eine Episode
  erwähnt — jede kostet einen eigenen Attribut-Call plus Abgleich gegen den Graph.
  Die Episodenlänge wirkt nur indirekt (mehr Text → mehr Entitäten).
- Entitäten-Rauschen senken: Dateipfade, Funktionsnamen, Test-IDs und F-Nummern, die
  nicht Thema der Episode sind, nicht als eigene Entitäten entstehen lassen — im Text
  dürfen sie für die Suche stehen bleiben, wenn die Extraktion sie überspringt.
- Extraktion steuern: kurze `custom_extraction_instructions` (z. B. „einzelne
  Dateipfade und Test-IDs nicht als eigene Entitäten, außer sie sind das Thema") und
  `excluded_entity_types` testen; für einzelne, klar umrissene Fakten `add_triplet`
  statt freier Extraktion. Wirkung jeweils vorher/nachher messen.
- Episoden pro Arbeitsschritt zählen: mehrere Episoden eines Schritts zusammenfassen,
  dabei etwa 2.000–3.000 Zeichen pro Episode nicht deutlich überschreiten (sonst
  droht Abbruch der Extraktion).
- Ein Schreibanlass pro Feature statt mehrerer (z. B. nur beim Abschluss); andere Skills
  schreiben nur bei echten Entscheidungen. Mit F-036 liegt das Detail in der
  Feature-Datei — der Graph bekommt eine knappe Zusammenfassung mit Verweis statt
  ausführlicher Prosa, also weniger Entitäten.
- `reference_time` setzen, wo vergangene Ereignisse beschrieben werden, damit die
  zeitliche Auflösung ohne Nacharbeit stimmt; `update_communities` bleibt aus.
- Globale Kit-Regeln anpassen (Zone `global-graphiti`): Löschanweisung streichen,
  Splitting-Regel überdenken, auf die zentrale Konvention verweisen.
- Betroffen: alle Skills mit Graphiti-Schreibzugriff, `docs/skill-authoring.md`,
  die globalen Kit-Regeln.

**Noch zu analysieren:**
- Welchen Anteil die Kit-Skills am Gesamtverbrauch haben, verglichen mit Schreibern
  außerhalb des Kits — bestimmt, wie viel F-029 überhaupt bewirken kann.
- Ob die Entitäten-Hypothese hält und was daraus folgt (weniger Entitäten, weniger
  Episoden, kürzer).
- Wie viele Entitäten die Kit-Skills heute pro Episode erzeugen und welcher Anteil
  davon Rauschen ist.
- Ob übersprungene Entitäten die Auffindbarkeit im Graph spürbar verschlechtern —
  der Graph soll die Repo-Suche weiterhin ersetzen können.
- Wo die zentrale Konvention liegt, damit Plugin-Skills sie zur Laufzeit erreichen.

→ beantwortet durch die Auswertung vom 2026-10-30, siehe Spezifikation.

**Abhängigkeiten:** Auswertung der serverseitigen Kostenmessung (extern, ein bis zwei
Wochen Daten) — erledigt 2026-10-30. F-036 — erst danach umsetzen, sonst werden Skills optimiert, die F-036
ohnehin umschreibt.

## Spezifikation

Grundlage ist die Auswertung der Serverdaten vom 19.10. bis 30.10.2026: 271 Episoden,
5,26 €. Rund 60 % der Kosten entstehen im Attribut-Schritt, der je Entität einmal läuft.
Die Kosten einer Episode folgen der Zahl ihrer Entitäten (Korrelation 0,88), eine Entität
kostet etwa 0,002 €. Etwa 87 % der Kosten fallen in Gruppen, in denen die Kit-Regeln
gelten. Je Feature entstehen heute 3–11 Episoden.

### Abnahmekriterien

- [x] AC-1 — Gegeben vier echte coding-kit-Episoden aus dem Messzeitraum, wenn sie in
  einer Testgruppe in vier Varianten eingespielt werden (wie heute; neue Form; neue Form
  mit Extraktionsanweisung; zusätzlich ohne Typ `Document`), dann liegt je Variante eine
  Tabelle mit Entitäten, Beziehungen und Kosten aus dem Ledger vor. Dazu kommt das
  Ergebnis von fünf festgelegten Suchfragen je Variante. Die Feature-Datei hält die
  gewählte Variante als Entscheidung fest. Negativ: Erreicht keine Variante mindestens
  40 % weniger Entitäten als „wie heute“ bei mindestens 4 von 5 gleich gut beantworteten
  Suchfragen, gilt nur die Episoden-Form ohne Extraktionsparameter, und die
  Entscheidung nennt den Grund. — belegt: Testlauf 2026-10-30, Ergebnis im Verlauf
  F-029a: v2 mit 48 % weniger Entitäten und 5 von 5 Suchfragen mindestens so gut wie die
  Originale.
- [ ] AC-2 — Gegeben die globalen Kit-Regeln (Zone `global-graphiti`), wenn man sie
  liest, dann regeln sie in höchstens 15 Zeilen:
  - Was in den Graph gehört: Wissen ohne Ort im Repo, also Stolperfallen,
    Infra-Fakten, Präferenzen und Projektübergreifendes, dazu je abgeschlossenem
    Feature ein kurzer Wegweiser.
  - Was nicht hineingehört: Projektentscheidungen und Feature-Details. Die stehen in
    der Feature-Datei bzw. im ADR.
  - Die Form einer Episode: ein Thema, Richtwert für die Länge aus AC-1, keine
    Commit-Hashes, Testzahlen, Funktions- oder Konstantennamen und Versionsstände,
    außer sie sind das Thema.
  - Die Extraktionsparameter aus AC-1.
  - `reference_time` bei vergangenen Ereignissen.

  Negativ: Die Anweisungen „dichte Inhalte in mehrere Episoden splitten“ und
  „Veraltetes per `delete_entity_edge` ersetzen“ stehen nicht mehr darin.
- [ ] AC-3 — Gegeben ein Feature-Abschluss, wenn step-done das Feature auf `DONE`
  setzt, dann schreibt es genau eine Wegweiser-Episode nach der Konvention: F-Nummer,
  Titel, Pfad der Feature-Datei und das Ergebnis in wenigen Sätzen. Negativ: Bei einem
  Substep, nach dem das Feature `IN-PROGRESS` bleibt, schreibt step-done nichts. Ein
  Fund von allgemeinem Wert, etwa eine Stolperfalle, darf als eigene Episode nach der
  Konvention dazukommen.
- [ ] AC-4 — Gegeben add-feature, refine-requirements, new-project und go-public, wenn
  man ihre Graphiti-Schritte liest, dann gilt:
  - add-feature und refine-requirements schreiben nicht mehr automatisch.
  - new-project schreibt die Gründungs-Episode nach der Konvention.
  - go-public schreibt höchstens eine kurze Episode nach der Konvention.

  Alle verweisen auf die Konvention der Kit-Regeln, statt eigene Inhaltslisten zu
  führen. Negativ: Ein grep nach `add_memory` in den Skills findet keine Stelle ohne
  diesen Verweis.
- [ ] AC-5 — Gegeben ein Projekt aus dem Template, wenn es per `/update-conventions`
  den Block `claude-graphiti` holt, dann verweist der Block für das Schreiben auf die
  Konvention der Kit-Regeln. Die Abfrage-Hinweise bleiben, die Split-Regel fehlt. Die
  HOW-TO sagt in Schritt 6 von step-done „nur beim Feature-Abschluss“. Die
  CLAUDE.md des Kits folgt derselben Regel. Negativ: `just check` ist grün, und der
  CHANGELOG-Eintrag hat einen Abschnitt `### Template`.
- [ ] AC-6 — Gegeben mindestens 7 Tage Arbeit nach dem Release, wenn die Ledger-Daten
  wie in der Auswertung ausgewertet werden, dann haben Episoden aus Kit-Projektgruppen
  im Schnitt mindestens 40 % weniger Entitäten als in der Basis (coding-kit: 12,6), und
  je abgeschlossenem Feature gibt es höchstens 2 Episoden. Negativ: Wird das Ziel
  verfehlt, hält die Feature-Datei die Ursache fest, und eine Folge-Nummer wird
  vorgeschlagen.

### Regeln mit Beispielen

| Regel | Beispiel: schreiben | Gegenbeispiel: nicht schreiben |
|---|---|---|
| Wissen ohne Ort im Repo | „mawk lehnt ein Array namens NF ab; vor dem Commit unter mawk testen“ | „F-045a: neuer Befehl zones mit 11 Zuständen“ (steht in der Feature-Datei) |
| Ein Wegweiser je Feature | Abschluss F-037: was es kann, Pfad der Feature-Datei | Abschluss F-037a, F-037b einzeln |
| Keine Rausch-Entitäten | „Reviewer-Agent prüft nur lesend“ | „commit 8bb3583, AGENT_TOOLS, 1170 checks“ |
| Infra und Präferenzen | „Graphiti-Logs je LLM-Aufruf liegen in Graylog“ | Zwischenstände beim Debuggen |

### Randfälle

- EC-1 — MCP oder Client kennt `custom_extraction_instructions` bzw.
  `excluded_entity_types` nicht → ohne die Parameter schreiben; die Form-Regeln gelten
  weiter.
- EC-2 — Ein Feature endet als `DROPPED` oder `SUPERSEDED` → eine Wegweiser-Episode mit
  Grund bzw. Nachfolger, wie bei `DONE`.
- EC-3 — Graphiti läuft nicht → still überspringen wie bisher (Ersatzweg → F-033).
- EC-4 — Die Testgruppe beginnt leer, deshalb ist der Abgleich-Schritt dort billiger
  als im echten Graph → Verglichen werden Entitäten und Beziehungen; Kosten nur
  zwischen den Varianten, nicht gegen die Basis.
- EC-5 — Ein Nutzer bittet ausdrücklich, etwas zu speichern → es wird gespeichert, in
  der Form der Konvention; die Konvention steuert nur, was ohne Bitte geschrieben wird.

### Nicht-Ziele

- Kein Aufräumen oder Löschen alter Episoden und Entitäten; Überholtes regelt der Graph
  über seine Zeitstempel.
- Keine Änderung am Graphiti-Server: Modelle, Entitätstypen, Prompts. Das ist
  Server-Sache außerhalb des Kits.
- Keine Regeln für Schreibvorgänge aus claude.ai (Graphiti Remote); dort gelten die
  Kit-Regeln nicht.
- Kein Ersatzweg ohne Graphiti (→ F-033), keine Erkennung verlorener Episoden
  (→ F-030).

### Tests

- AC-1: manuell — Testlauf in der Gruppe `zz-test-f029`, Ledger-Export aus Graylog,
  Auswertung mit denselben Skripten wie in der Basis; Suchfragen über
  `search_memory_facts` und `search_nodes`.
- AC-2: Check — `just check` (Zonen der Kit-Datei); grep: keine Split- und keine
  Löschanweisung; Zeilen der Zone gezählt.
- AC-3: manuell — Lesen von step-done § 6; Testlauf `claude -p` mit `--plugin-dir` an
  einem Testprojekt mit einem Substep (`IN-PROGRESS`) und einem Abschluss (`DONE`):
  genau ein `add_memory`, beim Abschluss.
- AC-4: Check — grep nach `add_memory` und `Graphiti` in `plugins/coding-kit/skills/`;
  jede Stelle verweist auf die Konvention.
- AC-5: Check — `just check`, grep im Template-Block und in der HOW-TO; Render der
  Projektdateien mit `template-sync.sh render`.
- AC-6: manuell — Graylog-Export nach mindestens 7 Tagen, Auswertung wie in der Basis.

### Einbettung

- Berührt:
  - `plugins/coding-kit/global/coding-kit.md`, Zone `global-graphiti`
  - die Skills step-done, add-feature, refine-requirements, new-project und go-public
  - im Template `core/CLAUDE.md` (Zone `claude-graphiti`) und `core/HOW-TO-CODE-WITH-CLAUDE.md`
  - die CLAUDE.md des Kits (Graphiti-Block, nicht die Ziel-Abschnitte)
  - `docs/skill-authoring.md`, falls dort Graphiti-Bausteine stehen
  - README, CHANGELOG und plugin.json mit Version 3.1.0
- Kommt in Projekten so an: die Kit-Regeln per `/coding-kit:update-conventions global`,
  der Template-Block per normalem Sync. Beides sind Zonen-Änderungen ohne neue Datei,
  das MANIFEST bleibt unverändert.
- Kein Widerspruch zu Zielen oder Nicht-Zielen.
- Folgen: Die Nachmessung (AC-6) liefert zugleich eine Datenbasis für F-046.

### Offene Fragen

keine

### Entscheidungen

- 2026-10-30 — Graph als Wegweiser plus Wissen ohne Ort im Repo; Projektdetails nur in
  Feature-Datei und ADR. Grund: Feature-Dateien halten die Details seit F-036, und je
  Feature entstanden bis zu 11 Episoden.
- 2026-10-30 — Konvention in den globalen Kit-Regeln statt in einer Plugin-Datei oder
  im Template-Block. Grund: 28 der 108 coding-kit-Episoden entstanden ohne Skill-Schritt
  über die globale Regel, und auch `main` soll erfasst sein.
- 2026-10-30 — Extraktionsparameter erst nach einem Testlauf festlegen. Grund: Der Typ
  `Document` macht 38 % der Attribut-Aufrufe aus, trägt aber auch nützliche Knoten.
- 2026-10-30 — Die Vermutung, lange Zusammenfassungen machten die Prompts teuer, ist
  verworfen: Die Attribut-Prompts liegen eng beieinander (p50 5.000, max 7.000
  Tokens).

## Plan

**Größe:** L. Die Reichweite gibt den Ausschlag: globale Kit-Regeln und Template-Block
wirken auf alle Projekte. Aufwand und Unsicherheit allein wären M, seit die Auswertung
vorliegt.

**Ansatz:** Die Konvention ersetzt die Zone `global-graphiti` der Kit-Regeln. Skills und
Template-Block verweisen nur noch darauf. Code entsteht keiner, es ändern sich Regel- und
Skill-Texte. Die Extraktionsparameter legt ein Testlauf fest, bevor ein Text sich ändert.

Verworfen:
- **Eine eigene Konventionsdatei im Plugin:** Sie erreicht Schreibvorgänge ohne Skill
  nicht.
- **`add_triplet` als Hauptweg:** Claude müsste Entitätsnamen exakt treffen, der
  Zusammenhang einer Episode ginge verloren. Außerdem sparen weniger Episoden nur den
  festen Anteil je Episode (rund 25 %), die Entitäten bleiben.

### F-029a — Testlauf Extraktion und Episoden-Form

- Vier coding-kit-Episoden aus dem Messzeitraum auswählen: ein Abschluss, eine
  Planung, eine Aufnahme, eine Stolperfalle.
- Jede in die neue Form umschreiben und fünf Suchfragen festlegen, die die Originale
  beantworten.
- Je Variante eine eigene Testgruppe, `zz-test-f029-v1` bis `-v4`, damit sich die
  Varianten nicht gegenseitig beim Abgleich beeinflussen.
- Je Gruppe die vier Episoden in gleicher Reihenfolge schreiben und die Verarbeitung
  abwarten.
- Ledger-Export aus Graylog für die Testgruppen.
- Auswertung mit denselben Skripten wie in der Basis.
- Suchfragen je Gruppe stellen.
- Ergebnis-Tabelle nach `private/f029-testlauf.md` schreiben: Entitäten, Beziehungen,
  Kosten, Treffer.
- Die gewählte Variante samt Richtwert für die Länge wird Entscheidung in der
  Feature-Datei.
- Testgruppen danach per `clear_graph` löschen, nur nach Bestätigung.
- Ändert keine Kit-Dateien außer der Feature-Datei, also keine neue Version.
- Erfüllt AC-1.

### F-029b — Konvention in Kit-Regeln und Template

- Zone `global-graphiti` in `plugins/coding-kit/global/coding-kit.md` neu schreiben,
  höchstens 15 Zeilen: was hinein gehört, was nicht, Form, Parameter aus F-029a,
  `reference_time`. Split- und Löschanweisung entfallen.
- Template:
  - Zone `claude-graphiti` in `core/CLAUDE.md`: Abfrage-Hinweise bleiben, Schreiben
    verweist auf die Kit-Regeln, Split-Regel fällt weg.
  - `core/HOW-TO-CODE-WITH-CLAUDE.md`, Schritt 6 von step-done: „nur beim
    Feature-Abschluss“.
- CLAUDE.md des Kits: Graphiti-Block wie der Template-Block.
- README, wo es die Graphiti-Konventionen beschreibt.
- Version 3.1.0 in `plugin.json`, CHANGELOG-Eintrag mit `### Template`.
- Prüfen mit `just check` und `template-sync.sh render-global`.
- Erfüllt AC-2 und AC-5.

### F-029c — Skills auf die Konvention umstellen

- step-done § 6: schreibt nur, wenn das Feature `DONE`, `DROPPED` oder `SUPERSEDED`
  wird. Inhalt ist ein Wegweiser, ein Fund von allgemeinem Wert darf als eigene
  Episode dazukommen. Die Beschreibung im Frontmatter zieht nach.
- add-feature und refine-requirements: den Schreibschritt streichen.
- new-project § 4g und go-public: auf die Konvention verweisen.
- `docs/skill-authoring.md`: Baustein „Graphiti schreiben nur nach der Konvention der
  Kit-Regeln“.
- `plugin.json`-Beschreibung, falls sie das Graphiti-Update nennt. Die Version bleibt
  bei 3.1.0, weil sie unveröffentlicht ist.
- Testlauf: `claude -p` mit `--plugin-dir plugins/coding-kit` an einem Testprojekt.
  Zuerst ein Substep, der das Feature `IN-PROGRESS` lässt; dann ein Abschluss. Genau
  ein `add_memory`, beim Abschluss.
- Danach Release 3.1.0; der Push erfolgt nur auf Bitte.
- Erfüllt AC-3 und AC-4.

### F-029d — Nachmessung im Betrieb

- Frühestens 7 Tage nach dem Release.
- Graylog-Export wie in der Basis, Auswertung mit denselben Skripten.
- Vergleich: Entitäten je Episode in Kit-Projektgruppen, Episoden je abgeschlossenem
  Feature, Kosten je Tag.
- Ergebnis in die Feature-Datei. Bei verfehltem Ziel Ursache und Vorschlag für eine
  Folge-Nummer.
- Feature `DONE`.
- Erfüllt AC-6.

**Erkennung (Schritt 2a):** entfällt, keine neuen Frameworks, Dependencies oder Sprachen.
Neue Config, Endpunkte oder Dependencies gibt es nicht. Die Parameter
`custom_extraction_instructions` und `excluded_entity_types` bieten beide
Graphiti-Verbindungen schon an.

## Verlauf

### F-029a — fertig 2026-10-30

**Umgesetzt:** Testlauf in vier leeren Testgruppen, eine je Variante, nacheinander
verarbeitet. Getestet wurden vier coding-kit-Episoden aus dem Messzeitraum: ein
Abschluss (F-037a), eine Planung (F-034), eine Aufnahme (F-050) und eine Stolperfalle
(mawk). Die Varianten:

- v1: die Originale
- v2: neue Form, also ein Thema, Verweis auf die Feature-Datei, ohne Hashes, Testzahlen
  und Konstantennamen
- v3: wie v2 mit `custom_extraction_instructions`
- v4: wie v3, zusätzlich `excluded_entity_types: ["Document"]`

Entitäten und Beziehungen kommen aus dem Graph, die Kosten aus dem Ledger-Export, dazu
fünf Suchfragen.

| Variante | Entitäten | Beziehungen | Kosten | LLM-Aufrufe | Suchfragen mind. so gut wie v1 |
|---|---|---|---|---|---|
| v1 | 48 | 49 | 0,0450 € | 114 | — |
| v2 | 25 (−48 %) | 21 | 0,0147 € (−67 %) | 42 | 5/5 |
| v3 | 25 (−48 %) | 18 | 0,0135 € (−70 %) | 40 | 4/5 |
| v4 | 15 (−69 %) | 12 | 0,0091 € (−80 %) | 27 | 2/5 |

Die Testgruppen wurden nach Bestätigung gelöscht.

**Entscheidungen:**

- Gewählt ist Variante v2: die neue Form ohne Extraktionsparameter.
- Die Anweisung (v3) spart keine Entität, Dateipfade werden trotzdem Entitäten, und die
  Aussage „mawk lehnt NF ab“ fehlt.
- Der Ausschluss von `Document` (v4) entfernt auch die Werkzeuge des Reviewers, die Pfade
  der Feature-Dateien und den mawk-Fakt.
- Richtwert für die Konvention (AC-2): ein Thema, 2–4 Sätze, höchstens etwa 450 Zeichen.
  Extraktionsparameter entfallen.

**Abweichung vom Plan:**

- v3 und v4 wurden nicht per Suche abgefragt, sondern über ihre vorhandenen Fakten
  bewertet. `search_nodes` kam in keiner Variante zum Einsatz.
- Ein ✗ wegen eines fehlenden Fakts ist sicher, ein ✓ nur eine Obergrenze. Die
  Entscheidung stützt sich auf die sicheren ✗ und auf die fehlende Ersparnis von v3.
- Kosten sind nur zwischen den Varianten verglichen, nicht gegen die Basis. In einer
  leeren Gruppe entfällt der Abgleich der ersten Episode (EC-4).

**Funde:**

- Vergangenheitsformen wie „hing am“ oder „war Teil von“ legt Graphiti als ungültig
  gewordene Fakten ab. F-029b bekommt deshalb die Regel: Zustände, die weiter gelten, im
  Präsens.
- Attribut-Aufrufe entstehen nur für Entitäten mit Typ.
