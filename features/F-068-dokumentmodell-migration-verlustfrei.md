---
id: F-068
title: Dokumentmodell-Migration verlustfrei und nachweisbar machen
type: fix
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-068 — Dokumentmodell-Migration verlustfrei und nachweisbar machen

## Erfassung

**Problem:** `template-sync.sh migrate` (A4 in update-conventions) verliert bei
Alt-Projekten Inhalt oder ordnet ihn falsch zu. A4 verspricht dagegen „alles wird
überführt, wortgetreu“ und löscht danach die Altdateien. In fünf Migrationen von
Bestandsprojekten trat das jedes Mal auf. In einem Projekt fehlten nach `migrate` 394
Zeilen, in einem anderen ging der Absatz zum Release-Stand verloren.

**Ziel:**
- **Ist** (in den Migrationen belegt, am Code bestätigt):
  - Der Vorspann vor der ersten `##`-Überschrift jeder Quelldatei wird weder übernommen
    noch gemeldet. A4 Schritt 6 löscht ihn mit.
  - Teilschritt-Nummern mit Ziffer oder als Kombination (`F-012b1`, `F-012c3`,
    `F-012b/c`, „F-012c1 + F-012c2“) und Nummern, die nicht am Anfang der Überschrift
    stehen, werden keiner Nummer zugeordnet. Ihre Abschnitte landen als `unassigned`.
  - Eine tiefere Überschrift mit fremder Nummer innerhalb eines Abschnitts wird als
    eigener Eintrag abgetrennt. Die Unterabschnitte danach landen als `unassigned`.
  - Bei einem mehrzeiligen Status-Absatz fällt nur die erste Zeile weg, der Rest bleibt
    als Satzrest stehen. Der Infotext nach dem Status-Token geht verloren.
  - Status-Wörter außerhalb der englischen Tokens werden nicht erkannt (ERLEDIGT,
    GESCHLOSSEN, GESTRICHEN, VERWORFEN, AUFGEGANGEN, won't-fix), ebenso wenig
    vorangestellte Status-Klammern. Sie landen in Titel, H1 und Dateiname, und der Status
    wird falsch, etwa DONE statt DROPPED.
  - Index-Zeilen von Teilschritten gehen verloren. Titel entstehen aus der ganzen
    Index-Zeile, in einem Projekt waren 130 von 167 länger als 70 Zeichen. Wird ein Titel
    gekürzt, ist der Rest weg, und der Dateiname kommt aus dem langen Titel.
  - Jede Tabelle mit F-Nummern in der ersten Spalte gilt als Done-Tabelle. Done-Zeilen
    ohne F-Nummer verschwinden still.
  - Datumsquellen fehlen: `**Abgeschlossen:**`-Zeilen werden nicht gelesen, und das
    Datum einer Done-Zeile entfällt, wenn die Nummer einen Archivabschnitt hat. `created`
    stammt dann aus Git, nach einem Squash ist das der Squash-Tag.
  - Im Verlauf stehen Einträge vom selben Tag rückwärts oder durcheinander. Done-Zeilen
    ohne Archivabschnitt landen hinter dem Abschluss und haben ein anderes
    Überschriftenformat.
  - Der grep in A4 Schritt 7 trifft auch das Status-Token `IN-PROGRESS`.
- **Soll:** Jede Inhaltszeile der Altdateien landet wortgetreu in einer Feature-Datei
  oder wird gemeldet. Gelöscht wird erst, wenn keine Zeile mehr offen ist.
- **Reproduzieren:** synthetische `PROGRESS.md` und `PROGRESS-ARCHIVE.md` mit je einem
  der Fälle oben, dann `migrate`.

**Lösungsskizze:**
- *Nachweis:* `migrate` meldet jede Inhaltszeile, die im Ergebnis nicht wieder auftaucht
  (`lost`), und den Vorspann als `unassigned … (preamble)`. A4 löscht die Altdateien erst,
  wenn der Nachweis leer ist. In einem Projekt diente ein solcher Zeilen-Abgleich schon
  als Abnahmebeleg.
- *Erkennen:*
  - Teilschritt-Suffixe werden der Grundnummer zugeordnet. Steht genau eine Grundnummer
    irgendwo in der Überschrift, wird zugeordnet und gemeldet (`assigned heading`).
    Stehen mehrere darin, bleibt der Block `unassigned`, und die Meldung nennt die
    Kandidaten.
  - Tiefere Überschriften bleiben in ihrem Abschnitt.
  - Status-Wörter kommen aus einer kleinen Liste DE/EN und werden ohne Groß-/
    Kleinschreibung erkannt. Unbekannte Wörter meldet das Skript, statt zu raten.
  - Done-Zeilen zählen nur aus einer Tabelle unter einer Erledigt-Überschrift oder mit
    Datumsspalte.
  - Alle Datumsquellen werden gelesen, ihre Reihenfolge wird dokumentiert.
- *Verlustfrei:*
  - Der ganze Status-Absatz wird übernommen: das Token in den Kopfblock, der Infotext an
    den Anfang der Erfassung.
  - Alle Index-Zeilen einer Nummer stehen wörtlich als Zitat unter der H1.
  - Der Titel kommt aus der kürzesten guten Quelle, der Dateiname erst aus dem
    endgültigen Titel.
  - Der Verlauf ist nach Datum sortiert. Bei gleichem Datum stehen die Teilschritte nach
    Buchstabe, der Abschluss der Grundnummer zuletzt.
  - `unassigned`-Zeilen nennen den Eintrag davor (`follows F-…`).
  - Eine eigene Spalte sagt, woher der Status stammt.
- *Werkzeuge für den Skill:* bestätigte Zuordnungen anwenden (`--assign`, `--collect`,
  mit derselben Normalisierung wie `migrate`), Titelvorschläge (`title-suggest`) und eine
  Vorschau-Tabelle für große Migrationen (`--overview`). Heute schreibt Claude dafür eigene
  Hilfsskripte.
- *A4:*
  - Ein State-Absatz kommt nach „Status & where to start“ in der CLAUDE.md.
  - Ein Ideenblock ohne Nummern wird in schlanke BACKLOG-Dateien überführt: eine je
    Idee, wortgetreu, mit einer einzigen Freigabe. Eine eigene Ideen-Datei gibt es nicht.
  - Vor dem Schreiben läuft Privacy-Lint über die migrierten Dateien im Projektpfad.
  - Alte Verweise in zurückgestellten Zonen werden gemeldet.
  - Das grep-Muster schließt `IN-PROGRESS` aus (`PROGRESS\.md`, `PROGRESS-ARCHIVE`,
    `REQUIREMENTS\.md`), und der Skill nennt Links auf die gelöschten Dateien.
- POSIX-sh und awk wie im übrigen Skript, je Fall eine Fixture, die vor dem Fix rot ist.

**Abhängigkeiten:** keine. Der Lint-Lauf in A4 braucht den Fix des blinden Flecks aus
F-069 oder läuft im Projektpfad.

**Noch zu analysieren:**
- Zerlegung in Teilschritte. Der Nachweis soll zuerst kommen, weil gerade viele
  Migrationen laufen.
- Ob `title-suggest` nur vorschlägt oder `migrate` gleich den bereinigten Titel
  schreibt.
- Welche Struktur-Zeilen der Nachweis ausnimmt (Trenner, Tabellenköpfe, Status-Tokens).
