---
id: F-005
title: Pflege-Skills
type: feature
status: DONE
size:
created: 2026-07-07
done: 2026-07-07
depends-on:
superseded-by:
---

# F-005 — Pflege-Skills

## Verlauf

### F-005 — Pflege-Skills (2026-07-07)

**Was entstanden ist (Plugin 0.4.0):**

- **update-conventions** — bidirektionaler Konventions-Sync mit drei Ästen:
  - *Abwärts mit Stempel:* Projekte via Marker-Topic (`gh search repos … topic:coding-kit`)
    plus lokale Checkouts finden; CHANGELOG-Fenster zwischen Stempel und aktueller
    VERSION zeigen; Soll-Fassung jeder managed Datei (Core + Modul-Parts) mit
    rückaufgelösten Projektwerten instanziieren und gegen den Ist-Stand diffen;
    je Datei: übernehmen / so lassen / als Override registrieren / promoten.
    Override-Schutz greift vor dem Diffen (`convention-overrides.md` + Inline-Marker);
    seed-Dateien und public-only-Regeln werden respektiert; Abschluss: Stempel auf neue
    VERSION, `just check` grün, Commit-Frage.
  - *Abwärts ohne Stempel (Altprojekte):* heuristischer Abgleich + Migrationen als
    einzeln bestätigte Schritte — instructions.md→CLAUDE.md, Entfernen lokaler
    Core-Skill-Kopien (nur bei installiertem Plugin; durch den Kollisionstest aus F-001
    abgesichert, projektspezifische Skills bleiben immer), Renovate-Onboarding,
    Tooling-Nachrüstung, abschließend Stempel-Angebot.
  - *Aufwärts („promote"):* projektlokale Änderung generalisieren (Werte → Platzhalter,
    englisch, personendatenfrei) und in den Kern heben — Template-Sync-Invariante im
    selben Commit (VERSION + CHANGELOG + ggf. MANIFEST), danach optional Abwärts-Lauf;
    alternativ Registrierung als Override. Pro Änderung genau eine Entscheidung.
- **check-upstreams** — Watchliste `upstreams.json` im Kit-Repo (bewusst nicht im
  Plugin-Install-Verzeichnis: sie wird geschrieben und committed). Je Eintrag:
  Erstprüfung (Ist-Zustand) oder Folgeprüfung (`gh api compare <ref>...HEAD` +
  Releases), Bewertung gegen den hinterlegten Zweck, Übernahme-Vorschläge (Umsetzung
  via add-feature als F-Nummer), Ref-/Datums-Update nach Bestätigung. /loop-tauglich
  (dann nur berichten).
- **Watchliste initial:** `AlexPEClub/ai-coding-starter-kit` mit Ref auf Analysestand
  (HEAD `21a97bb…`, letzter Push 2026-06-03 — Analyse vom 2026-07-07 deckt ihn ab) und
  `betterleaks/betterleaks` (verifiziert: existiert, MIT, vom gitleaks-Autor;
  gitleaks erhält nur noch Security-Patches) mit `last_checked_ref: null` —
  die Erstprüfung bewertet Reifegrad und Migrationsaufwand für den Scanner-Wechsel.

**Entscheidungen:**

- update-conventions diffe **instanziierte Soll-Fassung vs. Ist** statt
  Drei-Wege-Merge über historische Template-Stände — robuster, und der Stempel
  liefert trotzdem Determinismus (Update-Fenster + CHANGELOG-Kontext).
- Beide Skills `disable-model-invocation: true` — Pflegeläufe startet nur der Nutzer.
