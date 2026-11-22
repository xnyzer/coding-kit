---
id: F-088
title: Regeln für TypeScript, React, API, Docker und Dependencies ergänzen
type: change
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-088 — Regeln für TypeScript, React, API, Docker und Dependencies ergänzen

## Erfassung

**Problem:** Dem Standards-Katalog und den Kernregeln fehlen allgemeine Regeln, die jedes
Projekt sonst selbst findet, oft erst nach einem Umbau. In einem Downstream-Projekt
verglich das Frontend die Fehlertexte der API. Das vertrug sich nicht mit der Übersetzung
und kostete einen eigenen Refactor. Eine `.dockerignore` mit bloßen Namen ließ sieben
Build- und Abhängigkeitsordner der Workspaces ins Image. Ein Wächter im Dockerfile blieb
grün, weil ein vom Host mitkopiertes Build-Ergebnis die Prüfung erfüllte.

**Ziel:** Die Fragmente und die Kernregeln enthalten diese Regeln, sodass jedes Projekt sie
mit dem Abgleich bekommt. Gleich bleiben der Fragment-Vertrag im MANIFEST und die
Abschnittsnummern der `CODING-STANDARDS.md` (vgl. F-083).

**Lösungsskizze:**
- `typescript-lang` (Sprachregeln, nicht das Toolchain-Fragment von ts-node):
  - kein `enum`, stattdessen ein Union-Typ oder ein `as const`-Objekt;
  - `type` für Unions und Kompositionen, `interface` für Objektformen;
  - `@ts-ignore` und `@ts-expect-error` nur mit einem Kommentar, der den Grund nennt;
  - keine Default-Exporte, außer wo ein Framework einen verlangt (Routen, Seiten).
- `react`: Event-Handler heißen `handle…`, Callback-Props `on…`. Jeder asynchrone Handler
  fängt Fehler ab und zeigt sie an (Toast oder Feldfehler), nie still verschluckt.
- `api-design`: Die Fehlerhülle trägt einen stabilen, maschinenlesbaren Code, etwa einen
  Übersetzungsschlüssel. Der Text ist für Menschen und darf sich ändern. Heute schreibt
  das Fragment nur die Hülle `{ error, details? }` vor.
- `docker`:
  - In der `.dockerignore` steht vor einem Muster, das einen Datei- oder Ordnernamen
    nennt, `**/`. Ein bloßer Name greift nur auf oberster Ebene, `dist` schließt also
    `backend/dist` nicht aus. Ein Muster mit Pfad bleibt, wie es ist.
  - Eine `.dockerignore` wird gemessen, nicht gelesen: Ein Wegwerf-Image kopiert den
    Kontext, dann die Liste ansehen.
  - Der Healthcheck nutzt ein Werkzeug, das das Basis-Image mitbringt (Alpine hat `wget`,
    kein `curl`).
- Kernregeln §8: eine kurze Prüfung vor jeder neuen Dependency — gepflegt, wie tief die
  Kette, Lizenz, bekannte Advisories, und ob ein paar eigene Zeilen reichen.
- Wo Biome eine der TypeScript-Regeln prüft, schaltet die `biome.json` des Moduls ts-node
  sie ein; das Fragment nennt dann den Grund.
- Verworfen:
  - Ein eigenes Fragment `quality-process` (Dependency-Aufnahme, Review, Änderungsklassen,
    Bugfixes, Tests). Es doppelt die Kernregeln §1, §8 und §10 und das Review in
    step-done, das jede Änderung mit denselben fünf Prüffragen und einem unabhängigen
    Reviewer prüft. Ein vereinfachtes Review für „geringe“ Änderungen wäre ein
    Rückschritt. Die tragfähigen Teile gehen nach §8 (hier) und in F-089.
  - Destructuring in der Signatur auf drei Felder begrenzen. §3 begrenzt schon die
    Parameter auf drei.
  - `pnpm deploy --prod` für Produktions-Images. Das ist pnpm-spezifisch und eine Frage
    für F-076.

**Abhängigkeiten:** keine.

**Noch zu analysieren:**
- Ob `**/name` in der `.dockerignore` auch auf oberster Ebene greift (Docker-Doku und
  Messung). Davon hängt die Regel ab.
- Ob das eingebaute Type-Stripping von Node `enum` weiterhin nicht ausführt. Das wäre der
  technische Grund für die Regel.
- Welche der TypeScript-Regeln Biome prüft.
