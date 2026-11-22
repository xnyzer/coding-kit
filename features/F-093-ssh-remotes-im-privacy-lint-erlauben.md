---
id: F-093
title: Privacy-Lint erlaubt SSH-Remotes öffentlicher Git-Hosts
type: fix
status: BACKLOG
size:
created: 2026-11-23
done:
depends-on: F-069
superseded-by:
---

# F-093 — Privacy-Lint erlaubt SSH-Remotes öffentlicher Git-Hosts

## Erfassung

**Problem:** Zieht ein Projekt eine Abhängigkeit direkt aus einem Git-Repo, steht in
der Lock-Datei eine SSH-Adresse wie `git+ssh://git@<host>/org/repo`. Der Privacy-Lint
des Templates liest `git@<host>` als E-Mail-Adresse und blockiert den Commit, obwohl
darin keine Personendaten stehen. Der Kit-eigene Validator erlaubt solche Adressen schon.

**Ziel:**
- **Ist:** `scripts/privacy-lint.sh` meldet den SSH-Benutzer eines öffentlichen
  Git-Hosts als E-Mail, in Lock-Dateien wie in jeder anderen Datei. Ein Projekt kann
  sich nur mit einer Zeile in der Allowlist aus F-069c helfen.
- **Soll:** Die SSH-Benutzer der öffentlichen Git-Hosts gelten nicht als E-Mail, mit
  derselben Liste wie im Kit-Validator. Andere `git@`-Adressen, etwa die selbst
  betriebener Hosts, bleiben ein Fund, bis das Projekt sie in der Allowlist freigibt.
- **Reproduzieren:** eine `package-lock.json` mit einer Abhängigkeit über
  `git+ssh://git@<host>` bei einem öffentlichen Host → Privacy-Lint meldet eine E-Mail.

**Lösungsskizze:**
- Eine feste Liste im Lint wie `ALLOWED_SSH_REMOTES` im Kit-Validator: die
  SSH-Benutzer von GitHub, GitLab, Codeberg und Azure DevOps. Sie gilt in jeder Datei,
  nicht nur in Lock-Dateien, denn dieselben Adressen stehen auch in Doku und
  Konfiguration.
- Selbst betriebene Hosts gibt das Projekt in `privacy-allowlist.txt` frei. Deren Kopf
  nennt das als Beispiel.
- Verworfen:
  - Den Benutzer jeder URL (`://git@<host>`) nicht als E-Mail werten. Dann meldet der
    Lint auch interne Git-Hosts nicht mehr, die er heute nebenbei fängt.
  - Nichts bauen und nur auf die Allowlist verweisen. Dann braucht jedes Projekt mit
    einer Git-Abhängigkeit dieselbe Zeile, und Template und Kit-Validator bleiben uneins.

**Abhängigkeiten:** F-069 (neuer Lint, Allowlist als Rückfall). Die Host-Liste berührt
F-053 und F-054, die weitere Git-Hosts bringen.

**Noch zu analysieren:**
- Ob Template-Lint und Kit-Validator die Liste aus einer gemeinsamen Quelle beziehen
  oder je eine eigene führen.
- Welche Schreibweisen vorkommen: `git+ssh://`, `ssh://` und die SCP-Form
  `git@<host>:org/repo`.
