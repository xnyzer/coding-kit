---
id: F-016
title: Standards-Coverage-Backstop in step-done
type: feature
status: DONE
size:
created: 2026-07-17
done: 2026-07-19
depends-on:
superseded-by:
---

# F-016 — Standards-Coverage-Backstop in step-done

## Verlauf

### F-016 — step-done: Standards-Coverage-Backstop (2026-07-19)

**Aufgabe:** Auch mit der Erkennung in prep-step (F-015) konnte ein Framework ohne
zugehöriges Standards-Fragment durchrutschen — etwa wenn es erst während der
Umsetzung dazukam. Es fehlte ein Backstop am Ende des Zyklus.

**Was entstanden ist (Plugin 0.11.0):**

- **Neuer Schritt „1a. Standards-Abdeckung (Backstop)"** in step-done, zwischen
  Review (§1) und Secrets-Scan (§2). **Entscheidung — diff-basiert statt
  Projekt-Vollaudit:** Gate = der Diff des Schritts führt neue Dependencies in
  Paket-Manifesten oder neue Signal-Dateien (Dockerfile, nginx.conf, …) ein UND das
  Projekt hat einen `module:coding-standards`-Slot; sonst stilles Überspringen.
  Ein Voll-Scan je Substep wäre unverhältnismäßig; historische Lücken (Framework
  kam vor Einführung des Fragment-Systems) bleiben ein möglicher späterer
  audit-code-Erweiterungspunkt — bewusst nicht als F-Nummer aufgenommen.
- **Match** gegen das zur Laufzeit gelesene Katalog-Mapping
  (`modules/standards/README.md`, Auflösung wie choose-stack § 0);
  `*characteristic:*`-Zeilen matchen diff-basiert naturgemäß nicht (Planungsmaterie
  von prep-step 2a bzw. F-017).
- **Nicht blockierend:** Lücke wird gemeldet + Anhängen vorgeschlagen (Mechanik wie
  choose-stack, idempotent); lehnt der Nutzer ab, wird die offene Lücke im
  Archiv-Eintrag vermerkt, damit sie sichtbar bleibt.
- **Begleitanpassungen:** plugin.json 0.11.0, CHANGELOG-Eintrag,
  README-Tabellenzeile step-done, Frontmatter-`description`.
- **Geänderte Dateien:** `plugins/coding-kit/skills/step-done/SKILL.md`,
  `plugins/coding-kit/.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`.
- Damit ist der „Standards wachsen mit"-Zyklus geschlossen: prep-step schlägt vor
  (F-015), choose-stack baut ein (F-013), update-conventions pflegt (F-014),
  step-done fängt Durchrutscher (F-016).
