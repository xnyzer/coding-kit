# Changelog

Versioniert wird das Plugin (`plugins/coding-kit/.claude-plugin/plugin.json`, semver).
Jede inhaltliche Plugin-Änderung bumpt die Version und bekommt hier einen Eintrag —
im selben Commit.

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
