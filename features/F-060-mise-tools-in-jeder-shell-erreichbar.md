---
id: F-060
title: mise-Tools in jeder Shell erreichbar machen
type: fix
status: BACKLOG
size:
created: 2026-11-13
done:
depends-on:
superseded-by:
---

# F-060 — mise-Tools in jeder Shell erreichbar machen

## Erfassung

**Problem:** Das Kit sagt nur `mise install`, nie, wie mise aktiviert wird. Auf einem
Rechner ohne Aktivierung stehen die von mise installierten Tools nicht im `PATH`:
Werkzeuge, die nur über mise kommen (im Go-Modul golangci-lint und seit F-057
go-licenses), fehlen, und wo Homebrew dasselbe Werkzeug liefert, läuft dessen Version
statt der im Projekt festgelegten. `just check` scheitert dann im Terminal wie in der
Shell von Claude, oder es prüft mit falschen Versionen. In der CI fällt das nicht auf,
weil sie mise selbst aufruft.

**Ziel:**
- Ist: `mise doctor` meldet `activated: no` und `shims_on_path: no`; in einem
  Go-Projekt aus dem Template findet `just check` golangci-lint nur über `mise exec`.
- Soll: Nach der Einrichtung laut Kit stehen die mise-Tools in jeder Shell vorn im
  `PATH` — interaktiv, in Skripten und in der Shell von Claude —, und `just check`
  läuft ohne `mise exec`.
- Reproduzieren: Rechner ohne mise-Aktivierung, Go-Projekt aus dem Template,
  `just check`.

**Lösungsskizze:**
- Einrichtung dokumentieren: README des Kits, Installer und Template-Doku nennen die
  Aktivierung; für Shells ohne Eingabe (Claude, Skripte) die Shims, etwa
  `mise activate zsh --shims` in der `.zprofile`.
- Option: Der Installer prüft `mise doctor` und bietet die Zeile an.
- Option: Skills prüfen vor `just check`, ob mise aktiv ist, und weisen darauf hin.
- Verworfen vorab: alle `just`-Aufrufe in den Skills auf `mise exec -- just …`
  umstellen — wirkt nur in Skills, nicht im Terminal und nicht in Git-Hooks.

**Abhängigkeiten:** keine.

**Noch zu analysieren:**
- Reicht `mise activate zsh` in der `.zshrc` für die Shell von Claude, oder braucht es
  die Shims? (Spike)
- Wie verhalten sich Git-Hooks (lefthook), die `just` aufrufen?
- Was gilt unter bash und auf Linux/WSL (Bezug F-027)?
