---
id: F-089
title: Regeln und Vorlagen für Unit- und Integrationstests aufnehmen
type: change
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-089 — Regeln und Vorlagen für Unit- und Integrationstests aufnehmen

## Erfassung

**Problem:** Der Standards-Katalog hat kein Test-Fragment, §10 der Kernregeln hat vier
Punkte, das Fragment von ts-node anderthalb Zeilen. Ein Downstream-Projekt hat beim
Aufbau seiner Tests für jede fehlende Regel bezahlt:
- Testdateien und Test-Helfer landeten im veröffentlichten Paket.
- Integrationstests gerieten ins schnelle Gate, weil das Unit-Muster sie mitfing.
- Die Umgebungsprüfung beendete den Prozess, und der Testlauf verschwand ohne Meldung.
- Fünf von fünfzehn Sabotage-Läufen blieben grün, ohne etwas zu beweisen.
- `main` war tagelang rot, weil die Tests lokal gegen ein altes Build-Ergebnis liefen,
  das ein frischer Checkout nicht hat.

**Ziel:** Jedes Projekt bekommt die sprachneutralen Regeln für Unit- und
Integrationstests und über das passende Fragment die Mechanik seines Werkzeugs. Die
Vorlage von ts-node liefert die Konfiguration, die sie durchsetzt. Gleich bleiben
`just check` als Gate vor jedem Commit und der Fragment-Vertrag im MANIFEST.

**Lösungsskizze:**
- Kernregeln §10, sprachneutral:
  - Das schnelle Gate läuft ohne Infrastruktur. Integrationstests laufen getrennt gegen
    echte Dienste statt Mocks und haben ein eigenes Namensmuster, das der Unit-Lauf
    ausschließt.
  - Tests hängen weder voneinander noch von der Reihenfolge ab. Testdaten kommen aus
    Factories, nie mit festen IDs und nie aus der Produktion.
  - Ein Wächter-Test wird durch Sabotage bewiesen, nicht durch einen grünen Lauf. Eine
    Sabotage beweist nichts bei einem geteilten, veränderbaren Fixture, bei einer
    Fallback-Kette, deren erstes Glied die Testkonfiguration nicht trifft, bei einer
    Zusicherung auf einen Teilstring, der auch legitim vorkommt, bei einer Liste, die aus
    Umgebungsgründen leer bleibt, und bei gestaffelten Wächtern, die einander verdecken.
    Die Klammer: Eine Zusicherung braucht einen Aufbau, der sie brechen kann.
  - Der Testpfad läuft nie gegen ein Build-Ergebnis, das er nicht selbst erzeugt.
  - Testcode und Test-Helfer bleiben aus dem ausgelieferten Artefakt. Der Ausschluss sitzt
    dort, wo das Artefakt entsteht (Compiler oder Bundler). Der Nachweis: bauen, dann in
    die Ausgabe sehen.
- Ein neues Katalog-Fragment `vitest` (Signal `npm:vitest`, das Modul ts-node zieht es):
  - Integrationstests heißen `*.integration.test.ts`, jedes Unit-Projekt schließt sie
    aus. Die Auswahl läuft über eine Negation statt über eine Aufzählung.
  - Eine Setup-Datei prüft die Umgebung vor jedem Import von Anwendungscode. Sie wirft
    einen Fehler, statt den Prozess zu beenden, sonst reißt sie den Worker mit.
- Ergänzungen in den Fragmenten:
  - `react`: Komponenten über Rolle und sichtbaren Text testen, nicht über Markup oder
    Klassennamen.
  - `prisma`: Das Test-Schema entsteht per `migrate deploy`, nie per `db push`. Isolation
    über Truncation statt über eine umschließende Transaktion: die Tabellenliste zur
    Laufzeit aus der Datenbank, Zähler zurücksetzen, vor dem Test statt danach.
  - `docker`: Test-Dienste in einer eigenen Compose-Datei, nicht als Profil. Compose
    wertet alle Dienste einer Datei aus, sonst greifen die Pflichtvariablen der Anwendung
    auch im Testlauf.
  - `api-design`: Negativtests an der Auth-Grenze — ohne Token, mit abgelaufenem und mit
    fremdem Token, auf fremde Ressourcen, ohne Berechtigung.
- Modul ts-node: Die mitgelieferte vitest-Config und `tsconfig.build.json` schließen
  Integrationstests und einen Ordner für Test-Helfer aus. Fragment und MODULE.md nennen
  den Grund (Paketierung).
- Der Workspace-Teil (eine Root-Config mit einem Projekt je Paket) gehört zu F-076.
- Verworfen:
  - Ein einziges Fragment `testing` für alles. Es brächte Prisma- und Docker-Regeln in
    Projekte ohne diese Werkzeuge. Fragmente mit Signal erreichen nur, wer das Werkzeug
    nutzt.
  - Testcontainers und `services` in der CI. Das eine kostet eine Dependency und Zeit je
    Lauf, das andere beschreibt dieselben Dienste ein zweites Mal und driftet.
  - Stubs für Radix-Selects in jsdom. Das hängt an einer einzelnen Bibliothek.

**Abhängigkeiten:** keine.

**Noch zu analysieren:**
- Ob `just check` die Integrationstests einschließt (dann braucht jeder Commit Docker)
  oder nur die CI sie fährt.
- Ob die Truncation-Regel für jede SQL-Datenbank gilt und damit nach §10 gehört statt
  nach `prisma`.
- Was die Module python und go für Namensmuster und Build-Ausschluss brauchen.
- Wie sich die aktuelle vitest-Version bei Projekten und Setup-Dateien verhält.
