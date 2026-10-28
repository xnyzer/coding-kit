---
id: F-015
title: Framework-Erkennung mit Fragment-Vorschlag in prep-step
type: feature
status: DONE
size:
created: 2026-07-17
done: 2026-07-19
depends-on:
superseded-by:
---

# F-015 — Framework-Erkennung mit Fragment-Vorschlag in prep-step

## Verlauf

### F-015 — prep-step: Framework-Erkennung mit Fragment-Vorschlag (2026-07-19)

**Aufgabe:** Führt eine Aufgabe ein neues Framework/eine neue Dependency ein, wuchs
der Standards-Bestand des Projekts nicht mit — kein Prozessschritt bemerkte das
fehlende Fragment („Standards wachsen mit").

**Was entstanden ist (Plugin 0.10.0):**

- **Neuer Schritt „2a. Standards-Abdeckung prüfen (Fragment-Check)"** in prep-step,
  zwischen Analyse (§2) und Größenbewertung (§3). **Kosten-Gate:** läuft nur, wenn
  die Analyse neue Frameworks/Dependencies identifiziert UND das Projekt einen
  `<!-- module:coding-standards -->`-Slot hat; sonst stilles Überspringen — kein
  Template-Clone je prep-step-Lauf (das Kit-Repo selbst z. B. hat keinen Slot).
- **Match beider Signaltypen** gegen das zur Laufzeit gelesene Trigger-Mapping
  (`modules/standards/README.md` des aufgelösten Templates): Dependency-Signale
  gegen die neuen Dependencies **und** `*characteristic:*`-Eigenschafts-Trigger
  gegen die Aufgabenbeschreibung. Damit ist der prep-step-Touchpoint von **F-017
  miterledigt**; F-017 verbleibt mit define-requirements-Interview +
  choose-stack-Nachrüstpfad.
- **Vorschlags-Pfade:** Katalog-Fragment vorhanden, aber kein `fragment:NAME`-Marker
  im Projekt → Anhängen als Plan-Bestandteil vorschlagen (Mechanik wie
  `/choose-stack`, idempotent); Treffer-Thema ohne Katalog-Fragment → projektlokales
  Fragment autoren + Promote via `/update-conventions` (AUFWÄRTS) anbieten. **Nur
  vorschlagen, nie still einbauen** — Entscheidung fällt mit der Plan-Freigabe.
- **Plan-Vorlage (§4):** neue Zeile „Standards-Abdeckung" (entfällt, wenn 2a
  übersprungen wurde); Frontmatter-`description` erweitert.
- **Begleitanpassungen:** plugin.json 0.10.0, CHANGELOG-Eintrag,
  README-Tabellenzeile prep-step.
- **Geänderte Dateien:** `plugins/coding-kit/skills/prep-step/SKILL.md`,
  `plugins/coding-kit/.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`.
- **Erkennungsqualität bewusst heuristisch** (Skill-Text, kein Parser) — F-016
  fängt Durchrutscher als Backstop am Zyklusende.
