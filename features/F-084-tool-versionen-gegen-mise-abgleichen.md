---
id: F-084
title: Tool-Versionen des Projekts gegen mise abgleichen
type: feature
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-084 — Tool-Versionen des Projekts gegen mise abgleichen

## Erfassung

**Problem:** In einem Projekt hob der Abgleich node und pnpm in `mise.toml` um eine
Hauptversion an. `engines`, `packageManager` und `FROM` im Dockerfile blieben stehen.
Entwicklung und CI liefen danach auf einer anderen Hauptversion als die Container, pnpm
wechselte selbst auf die Version aus `packageManager`, und `lock-check` meldete trotzdem
alles als vollständig. In einem Go-Projekt hätte die CI ein anderes Go getestet als das,
was die `toolchain`-Zeile ausliefert.

**Ziel:** Als Nutzer möchte ich, dass das Kit Abweichungen zwischen den Tool-Versionen in
mise und den Versionsangaben des Projekts meldet, damit Entwicklung, CI und Auslieferung
dieselben Versionen nutzen.

**Lösungsskizze:**
- Eine Prüfung vergleicht die Hauptversion jedes mise-Tools mit den Pins des Projekts:
  - `engines` und `packageManager` in `package.json`, `.nvmrc` und `.node-version`
  - `requires-python` und `.python-version`
  - die `go`- und die `toolchain`-Zeile in `go.mod`
  - `FROM` in Dockerfiles

  Der Skill fragt, welche Seite gilt. Nichts wird automatisch angeglichen.
- Grundsatz: Die Versionen im Template sind Startwerte für neue Projekte. Hebt das
  Template eine Hauptversion an, wird das im Abgleich eine eigene Frage. Der Skill nennt
  dabei die Stellen, die mitziehen müssen, und der CHANGELOG-Abschnitt `### Template`
  nennt sie auch. Verworfen: Majors in Bestandsprojekten nie anzuheben.
- Go: Hat ein Projekt eine `toolchain`-Zeile, pinnt mise genau dieses Release. MODULE.md
  nennt die Zeile in der Wartungsnotiz.
- Lock-Format:
  - Das Kit legt fest, welches Format von `mise.lock` gilt. mise warnte in den
    Migrationen vor den Formaten 0 und 3.
  - `lock-check` meldet ein älteres Format, A2 Schritt 11 bietet das Anheben an.
  - new-project erzeugt gleich das aktuelle Format.

**Abhängigkeiten:** keine.

**Noch zu analysieren (Websuche):**
- Wie pnpm die Version aus `packageManager` verwaltet und ob pnpm dann überhaupt in mise
  gehört.
- Wie mise die Versionsdateien anderer Werkzeuge liest.
- Ob Renovate für `[tools]` in `mise.toml` PRs zu neuen Hauptversionen stellt.
- Das aktuelle Lock-Format von mise.
