# Changelog

Versioniert wird das Plugin (`plugins/coding-kit/.claude-plugin/plugin.json`, semver).
Jede inhaltliche Plugin-Änderung bumpt die Version und bekommt hier einen Eintrag —
im selben Commit.

## 0.5.0 — 2026-07-13

Neue Skills:

- `build-step` (Workflow) — die bisher fehlende Implementierungsphase als Skill:
  prep-step-Plan laden, Substeps mit Verifikation je Schritt abarbeiten
  (Write-then-Verify, just-Checks, Abnahmekriterien gegen Tool-Ausgaben abhaken),
  je Substep an step-done übergeben; Scope-Schutz (Entdeckungen → add-feature statt
  still mitbauen), nie pushen. Mit Argument `autonom` baut er nicht, sondern
  bereitet einen `/goal`-Lauf vor: Regeln laden, einmalige laufbezogene
  Commit-Freigabe einholen, fertige Goal-Zeile ausgeben (Varianten mit/ohne
  Commit-Freigabe, Turn-Limit als Stopp-Klausel).

- `teach-step` (Workflow) — Feature geführt selbst umsetzen: der Skill agiert als
  Coding-Lehrer, der Nutzer schreibt allen Code selbst. Sokratischer Lehr-Loop je
  Häppchen (orientieren → Arbeitsauftrag → kontrollieren via git diff/Re-Lesen →
  Tests über just → Verständnisfrage), gestufte Hilfe (Leitfrage → Tipp → Hinweis →
  Pseudocode → Musterlösung nur auf Anfrage), Lern-Interview mit Defaults, optionales
  Graphiti-Lernprofil (persönliche group_id). Schreibverbot hart via
  `disallowed-tools: Write, Edit, NotebookEdit`; Bash nur lesend/prüfend erlaubt.
  Abschluss (PROGRESS, Scans, Commit) bleibt bei `step-done`.
- `refine-prompt` (Utility) — übergebenen Prompt analysieren (Ziel, Zielgruppe,
  Format, Kontext), Schwachstellen benennen, nach Prompt-Engineering-Best-Practices
  neu formulieren und den verbesserten Prompt anschließend ausführen. Nur manuell
  aufrufbar (`disable-model-invocation`).

Geänderte Skills & Vorlagen:

- `step-done` — Ausnahme-Regel zur Commit-Frage: Bei ausdrücklicher, laufbezogener
  Commit-Freigabe des Nutzers (autonomer build-step-Lauf) wird nach grünen Checks
  und Scans ohne erneute Nachfrage committet — nie gepusht, keine History-Rewrites.
  Ohne Freigabe im autonomen Lauf: Commit-Vorschlag festhalten und weiterarbeiten
  statt blockieren.
- `templates/global-CLAUDE.md` — Halbsatz zur Commit-Regel: eine ausdrückliche,
  laufbezogene Freigabe zählt als Fragen; Push bleibt auch dann tabu.

## 0.4.0 — 2026-07-07

Pflege-Skills:

- `update-conventions` — bidirektionaler Konventions-Sync. Abwärts: Projekte via
  Marker-Topic + lokale Checkouts finden, deterministischer Abgleich über
  template-version-Stempel + MANIFEST (Soll-Fassung instanziieren, Diff + Bestätigung
  je Datei, Override-Schutz vor dem Diffen, seed nie anfassen), Altprojekt-Migrationen
  als einzeln bestätigte Schritte (heuristischer Abgleich, instructions.md→CLAUDE.md,
  Core-Skill-Kopien entfernen bei installiertem Plugin, Renovate-Onboarding,
  Tooling-Nachrüstung, Stempel setzen). Aufwärts („promote"): projektlokale Änderung
  generalisieren und mit VERSION-Bump + CHANGELOG (+ MANIFEST) in den Kern heben —
  oder als Override registrieren.
- `check-upstreams` — Watchliste externer Vorbild-Repos (`upstreams.json` im Kit-Repo):
  Neuerungen seit dem persistierten Ref zusammenfassen (gh compare/releases),
  Übernahme-Vorschläge, Ref-Update nach Bestätigung. Startliste: die Muster-Quelle
  ai-coding-starter-kit (Ref auf Analysestand) und betterleaks als
  gitleaks-Nachfolge-Kandidat (Erstprüfung offen).

## 0.3.0 — 2026-07-07

- `new-project` — der Orchestrator: Short-Info-Erhebung (M1), Abfragen mit Defaults
  (Name/Lizenz/Sichtbarkeit/Modul/Doku-Sprache/group_id/Anforderungen, Sub-Skills
  aufrufbar, Aufschieben erlaubt), Plan mit Bestätigung, dann: `gh repo create
  --template` (kein git init), Instanziierung streng nach MANIFEST (Platzhalter,
  adapt-/optional-Marker, public-only, Modul-Kontrakt, Aufräumen der Template-Dateien),
  `template-version`-Stempel, Repo-Settings inkl. Marker-Topic `coding-kit`,
  Verifikation `mise install && just setup && just check`, Personendaten-grep,
  Erst-Commit nur nach OK, Graphiti-Seeding. Trockenlauf via Argument `dry-run`;
  jeder außenwirksame Schritt einzeln bestätigt. Prüft `manifest-format` und bricht
  bei unbekannter Formatversion ab.

## 0.2.0 — 2026-07-07

Begleit-Skills (einzeln nutzbar und von `/new-project` aufrufbar):

- `name-it` — Namenskandidaten nach Kriterien, Verfügbarkeits-Checks (GitHub/npm/PyPI,
  Domain optional) zur Laufzeit.
- `choose-license` — M1-Kurzinterview → Empfehlung (Default Apache-2.0; MIT/MPL-2.0
  als Alternativen; GPL/AGPL nur bewusst; „TBD" gültig).
- `choose-stack` — Modus Neuanlage (Modul-Empfehlung, Websuche-verifiziert) und Modus
  Bestandsprojekt (EIN Modul nachrüsten/wechseln, Diff + Bestätigung je Datei,
  Override-Schutz); Grenze zu `/update-conventions` dokumentiert.
- `define-requirements` — M1-Interview → REQUIREMENTS.md (M5-Struktur) → initiale
  PROGRESS.md (eine F-Nummer je Anforderung); verwaltet den Auflöse-Trigger.
- `refine-requirements` — M2-Diagnose mit drei Pfaden (Änderung von außen /
  Implementierungs-Lücke / Grundsatz-Challenge), darf Features splitten, schreibt
  datierte Decision-Log-Einträge.

## 0.1.0 — 2026-07-07

Erstes Grundgerüst:

- Vier Core-Skills: `add-feature`, `prep-step`, `step-done` (mit Privacy-Scan der
  lebenden Doku), `audit-code` — stack-agnostisch, personendatenfrei, F-NNN-tolerant.
- Projekterkennender Stop-Hook (PROGRESS.md mit FEATURE-INDEX oder
  `.claude/template-version`; blockt höchstens einmal pro Stopp).
- Marketplace `xnyzer` mit Plugin-Quelle im selben Repo.
- Renovate-Shareable-Preset (`default.json`): `config:recommended` + Action-Digest-
  Pinning + Label `dependencies`.
- Idempotenter Installer (`install.sh`) inkl. Personal-Config `~/.claude/coding-kit.env`.
