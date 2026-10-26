---
name: choose-license
description: Lizenz für ein Projekt wählen. Wenige Fragen (Sichtbarkeit, Copyleft-Toleranz, kommerzielle Nutzung, Dependency-Lizenzen), dann Empfehlung mit Begründung — Default Apache-2.0, „TBD" ist gültig. Einzeln nutzbar und von /new-project aufrufbar.
disable-model-invocation: false
user-invocable: true
---

# Lizenz wählen

Ziel: eine bewusste Lizenzentscheidung mit minimalem Frageaufwand. **Eine Frage pro
Antwort, immer mit empfohlenem Default.** Bekannte Antworten (z. B. Sichtbarkeit aus dem
/new-project-Kontext oder der Projekt-CLAUDE.md) nicht erneut abfragen.

## 1. Fragen (nur die noch offenen)

1. **Sichtbarkeit:** public oder privat? _(Default: privat)_ — bei privat ist „TBD"
   meist die pragmatische Wahl; bei public ist eine LICENSE-Datei Pflicht.
2. **Dürfen Dritte kommerziell nutzen/einbetten?** _(Default: ja — permissiv)_
3. **Copyleft gewollt?** Sollen Ableitungen quelloffen bleiben müssen?
   _(Default: nein)_
4. **Dependency-Lage:** Gibt es Dependencies mit Copyleft-Lizenzen (GPL/AGPL/LGPL)?
   Bei bestehendem Projekt zur Laufzeit prüfen (Lockfiles/Manifeste bzw. `just`-Rezepte
   des Stacks), nicht raten. _(Haus-Default: Dependencies nur permissiv)_

## 2. Empfehlung

| Situation | Empfehlung |
|-----------|------------|
| Standard (permissiv, professionell) | **Apache-2.0** — expliziter Patent-Grant, klare Contribution-Regeln (Haus-Default) |
| Maximal schlank, kleine Utilities | MIT |
| Datei-Copyleft als Mittelweg | MPL-2.0 |
| Starkes Copyleft gewünscht | GPL-3.0 / AGPL-3.0 — **nur als bewusste, begründete Entscheidung** (weicht vom Haus-Default ab) |
| Entscheidung vertagen (nur privat) | **TBD** — gültiges Ergebnis; vor einem Public-Schalten nachholen |

Empfehlung mit 1–2 Sätzen Begründung vorlegen; **eine** Frage: „Passt Apache-2.0?"
(Default: ja). Warnung aussprechen, wenn Copyleft-Dependencies gefunden wurden und eine
permissive Lizenz gewählt werden soll.

## 3. Umsetzen (nur bei Bestandsprojekt)

Im /new-project-Flow schreibt der Orchestrator die Dateien. Standalone in einem
bestehenden Projekt nach Bestätigung:

- `LICENSE` mit dem kanonischen Lizenztext anlegen/ersetzen (aktuellen Text von der
  offiziellen Quelle bzw. für Apache-2.0 aus `${CLAUDE_PLUGIN_ROOT}/template/core/LICENSE`
  übernehmen, nicht aus dem Gedächtnis).
- Paket-Metadaten angleichen, falls vorhanden (`license`-Feld in `pyproject.toml` /
  `package.json` — gültiger SPDX-Ausdruck; bei „TBD" das Feld weglassen statt einen
  ungültigen Wert zu schreiben).
- README-Lizenzabschnitt aktualisieren.
- **Antworten und managed Dateien** — hat das Projekt eine `.claude/template-answers`:
  Die Lizenz steckt auch in managed Dateien (z. B. `CONTRIBUTING.md`). Mit
  `${CLAUDE_PLUGIN_ROOT}/scripts/template-sync.sh` (in Shell-Befehlen der aufgelöste Pfad,
  Aufruf über `sh`; Ergebnisse in ein Temp-Verzeichnis `<tmp>`):
  1. mit den bisherigen Antworten rendern: `sh <skript> render <template>
     <projekt>/.claude/template-answers <tmp>/alt` (`<template>` wie
     `/coding-kit:choose-stack` § 0);
  2. `LICENSE_SPDX` in `.claude/template-answers` setzen und genauso nach `<tmp>/neu`
     rendern — die Ziele, die sich zwischen `<tmp>/alt` und `<tmp>/neu` unterscheiden,
     hängen an der Lizenz;
  3. `sh <skript> merge <projekt> <tmp>/neu <tmp>/out`, für genau diese Ziele den Diff
     Projekt → Ergebnis zeigen, nach Bestätigung das Ergebnis übernehmen und
     `sh <skript> snapshot <projekt> <tmp>/neu <diese Ziele>` setzen. Andere
     Template-Unterschiede gehören zu `/coding-kit:update-conventions`, nicht hierher.

  Ohne Antworten-Datei (Projekt vor dem Snapshot-Vertrag) nur melden, dass
  `/coding-kit:update-conventions` die managed Dateien nachzieht.

## Rückgabe an den Aufrufer

Die SPDX-Id (z. B. `Apache-2.0`) oder `TBD` — für `/new-project` als
`{{LICENSE_SPDX}}`.
