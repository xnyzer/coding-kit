---
name: explain-level
description: Antwortsprache und Erklär-Niveau festlegen. Kurzes Interview (Programmieren, Shell, Git, Frameworks, Projekt-Werkzeuge, wie viel Code der Nutzer mitliest), dann ein Vorschlag für Stufe (einsteiger, junior, fortgeschritten, senior) und Notiz mit dem Stufentext der Kit-Regeln; schreibt die Werte nach Freigabe über template-sync.sh set-global in die Personal-Config ~/.claude/coding-kit.env. Starten, wenn der Nutzer Antwortsprache oder Erklärtiefe festlegen oder neu einordnen lassen will („erklär mir mehr", „das ist mir zu ausführlich", „ich kann inzwischen Git"), und aus /coding-kit:update-conventions global, wenn die Werte fehlen. Jederzeit erneut aufrufbar; vorhandene Werte sind die Vorauswahl.
disable-model-invocation: false
---

# Antwortsprache und Erklär-Niveau

Ziel: die drei Werte der Personal-Config, aus denen die globalen Kit-Regeln
(`~/.claude/rules/coding-kit.md`) Antwortsprache und Erklär-Niveau rendern —
`CODING_KIT_REPLY_LANGUAGE`, `CODING_KIT_EXPLAIN_LEVEL` und `CODING_KIT_EXPLAIN_NOTE`.

**Grundsätze:**

- **Eine Frage pro Antwort, immer mit empfohlener Antwort.** Was schon bekannt ist (aus
  der env-Datei oder dem Gespräch), nicht noch einmal fragen.
- **Die Werte stehen nur in der env-Datei** — nicht zusätzlich in Graphiti, in
  Projektdateien oder im Gedächtnis von Claude Code. Dieser Skill ist die einzige Stelle,
  die sie abfragt.
- **Die env-Datei nie von Hand bearbeiten:** Geschrieben wird nur über das Skript, das
  alle übrigen Zeilen unverändert lässt.
- **Stufen und Stufentexte stehen nur in der Kit-Datei** — von dort lesen und zitieren,
  nie aus dem Gedächtnis beschreiben.
- **Das Niveau steuert nur, wie Claude antwortet:** Erklärungen, Rückfragen, Pläne,
  Zusammenfassungen. Code, Commits, Projekt-Doku und die Strenge von Prüfungen bleiben
  davon unberührt.

## 0. Dateien und Skript

- **Kit-Regeln:** `${CLAUDE_PLUGIN_ROOT}/global/coding-kit.md`. Jede Stufe ist dort ein
  optionaler Block `level-<Stufe>` mit ihrem Text; der HTML-Kommentar oben nennt die drei
  Schlüssel samt Optionen.
- **Skript:** `${CLAUDE_PLUGIN_ROOT}/scripts/template-sync.sh`, in Shell-Befehlen mit dem
  aufgelösten Pfad über `sh`; sein Kopf beschreibt `render-global` und `set-global`.
- **Personal-Config:** `~/.claude/coding-kit.env` (`install.sh` legt sie an). Übergibt
  der Aufrufer einen anderen Pfad — eine vorbereitete Datei oder einen Stellvertreter für
  einen Test —, gilt dieser.
- Ergebnisse in ein frisches Temp-Verzeichnis (`mktemp -d`, im Folgenden `<tmp>`).

## Kontext-Recovery

Nach Kompaktierung oder Neustart: die env-Datei neu lesen (was steht schon?), die
Antworten aus dem Verlauf übernehmen und beim ersten offenen Schritt weitermachen — nichts
zweimal fragen.

## 1. Stand lesen

- Die env-Datei lesen: welche der drei Werte gesetzt sind. Fehlt die Datei, gibt es noch
  keine Werte.
- Die Stufen und ihre Texte aus der Kit-Datei lesen.
- **Nennt der Nutzer schon, was er will** („setz mich auf senior", „Antwortsprache
  Englisch"), kein Interview: direkt zu Schritt 3 mit genau diesem Wert.

## 2. Interview

Nur die offenen Punkte, in dieser Reihenfolge. Jede Frage bietet Antworten an und
empfiehlt eine — den vorhandenen Wert oder die Antwort, die zum bisher Gesagten passt.
Antworten möglichst mit den Worten des Nutzers festhalten; sie werden zur Notiz. Ist die
Einordnung früh eindeutig (z. B. „beruflich seit Jahren, alles davon täglich"), die
übrigen Fragen auslassen.

1. **Antwortsprache:** In welcher Sprache soll Claude antworten? _(Empfehlung: die
   Sprache, in der der Nutzer gerade schreibt.)_
2. **Programmieren:** Wie viel hast du schon programmiert — Sprachen, wie lange, was für
   Projekte, beruflich oder selbst beigebracht? Kannst du objektorientiert schreiben und
   Algorithmen folgen?
3. **Shell:** nur Grundbefehle (Ordner wechseln, anlegen, kopieren, löschen) — auch
   Optionen der Befehle und Verketten mit `|` — eigene Skripte?
4. **Git:** kaum bekannt — `commit` und `push` von Hand — Branches und Merges — Konflikte
   lösen?
5. **Frameworks:** nur vom Namen — einzelne benutzt (welche) — weißt, wie sie aufgebaut
   sind und zusammenspielen?
6. **Projekt-Werkzeuge** wie Paketmanager, Lock-Dateien, CI, Task-Runner oder Hooks:
   fremd — schon gesehen — selbst eingerichtet?
7. **Code mitlesen:** Liest du den Code, den Claude schreibt, oder prüfst du vor allem, ob
   das Ergebnis funktioniert?

## 3. Vorschlag

- **Stufe:** die, deren Text aus der Kit-Datei am besten passt. Maßstab ist die
  Programmiererfahrung (Frage 2). Lücken bei Shell, Git, Frameworks oder
  Projekt-Werkzeugen gehören in die Notiz, nicht in eine niedrigere Stufe — sonst erklärt
  Claude auch, was der Nutzer längst kann.
- **Notiz:** ein bis zwei Sätze in der Antwortsprache: was sitzt, was neu ist und wo
  Claude mehr erklären soll (Antwort 7 sagt, wie viel Code-Erklärung in Pläne und
  Zusammenfassungen gehört). Ohne Namen, Arbeitgeber, Orte oder andere Personendaten.
  Sagt die Stufe schon alles, bleibt die Notiz leer.
- **Vorlegen:** Antwortsprache, Stufe mit ihrem Text aus der Kit-Datei (wörtlich), die
  Notiz und in ein bis zwei Sätzen, warum nicht eine Stufe höher oder tiefer. **Eine**
  Frage: übernehmen (empfohlen) — Stufe ändern — Notiz ändern. Bei einer Änderung den
  neuen Vorschlag zeigen und erneut fragen.
- **Bewusst ohne Wert:** Will der Nutzer Antwortsprache, Stufe oder Notiz gar nicht
  festlegen, den Wert leer schreiben (`"CODING_KIT_EXPLAIN_LEVEL="`). Leer heißt „bewusst
  ohne" — die Zeile entfällt in den Regeln, und `/coding-kit:update-conventions` fragt
  nicht erneut; ein fehlender Schlüssel dagegen gilt als noch nicht gefragt.

## 4. Schreiben

1. Die neue Datei erzeugen — jedes Argument einzeln in Anführungszeichen, nur Werte, die
   neu sind oder sich ändern:

   ```bash
   sh <skript> set-global <kit> <env> <tmp>/neu \
     "CODING_KIT_REPLY_LANGUAGE=<Sprache>" "CODING_KIT_EXPLAIN_LEVEL=<Stufe>" \
     "CODING_KIT_EXPLAIN_NOTE=<Notiz>"
   ```

   Lehnt das Skript einen Wert ab (unbekannte Stufe; Tab, Zeilenumbruch oder `{{` im
   Wert), den Wert mit dem Nutzer korrigieren und erneut aufrufen — nie die Datei selbst
   anpassen.
2. Prüfen: `sh <skript> render-global <kit> <tmp>/neu/coding-kit.env <tmp>/probe` muss
   durchlaufen; die drei `key`-Zeilen zeigen, was gesetzt ist.
3. Den Unterschied zeigen: `diff <env> <tmp>/neu/coding-kit.env` (fehlt die env-Datei,
   die neue Datei ganz). Der Diff enthält nur die Zeilen der drei Schlüssel; andere
   Zeilen der env-Datei nicht zitieren, sie können Identitätswerte enthalten.
4. Nach Freigabe übernehmen: `cp <tmp>/neu/coding-kit.env <env>` — die Datei hat Modus
   600. Schreibzugriffe unter `~/.claude/` fragt Claude Code einzeln ab; das ist
   erwartet. Ohne Freigabe den Kopierbefehl nennen und mit `<tmp>/neu/coding-kit.env`
   weiterarbeiten.

## 5. Abschluss

- **Wirksam werden die Werte erst, wenn die Regeldatei neu erzeugt ist:** Kam der Aufruf
  nicht aus `/coding-kit:update-conventions global`, darauf hinweisen, dass dieser Lauf
  sie übernimmt — eine geänderte env-Datei allein ändert nichts.
- **Rückgabe an den Aufrufer:** der Pfad der env-Datei mit den neuen Werten — die echte
  Datei oder, ohne Freigabe zum Kopieren, `<tmp>/neu/coding-kit.env`.
