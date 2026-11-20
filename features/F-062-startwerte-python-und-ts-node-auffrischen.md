---
id: F-062
title: Startwerte der Module python und ts-node auffrischen
type: change
status: BACKLOG
size:
created: 2026-11-20
done:
depends-on: F-058
superseded-by:
---

# F-062 — Startwerte der Module python und ts-node auffrischen

## Erfassung

**Problem:** Die Startwerte der Module python und ts-node sind veraltet; das Dependency
Dashboard führt seit F-061 neuere Versionen zur Freigabe, darunter große Sprünge
(python, node, TypeScript, vitest, pnpm). Neue Projekte starten mit den alten Werten,
und ihr eigenes Renovate schlägt gleich zu Beginn eine Reihe großer Updates vor.

**Ziel:** Die Startwerte beider Module stehen auf aktuellen Versionen, jedes Modul ist
mit ihnen geprüft. Gleich bleiben: Rezepte und Verhalten der Module, die
Lizenzprüfung aus F-058.

**Lösungsskizze:**
- Der Weg aus F-061: Häkchen im Dashboard → PR → Modul rendern und `just check` →
  Version und CHANGELOG mit `### Template`.
- Große Sprünge einzeln, damit ein Fehler zuzuordnen ist.

**Abhängigkeiten:** F-058 — beide ändern die Module; F-058 zuerst.

**Noch zu analysieren:**
- Ist die neue Node-Hauptversion schon LTS? Die Module folgen der LTS
  (`MODULE.md` von ts-node).
- Was brauchen TypeScript 7, vitest 5 und pnpm 12 im Modul (Einstellungen, Biome,
  `pnpm licenses` aus F-058)?
- Läuft python mit der neuen Version mit pyright, ruff und uv_build?
- Gehört das Go-Update aus dem Dashboard dazu, oder bleibt es beim Modul go?
