---
id: F-087
title: Sicherheitslücken ohne Git-Host lokal prüfen
type: feature
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-087 — Sicherheitslücken ohne Git-Host lokal prüfen

## Erfassung

**Problem:** Auf GitHub erkennt Dependabot Sicherheitslücken in Abhängigkeiten, auf Azure
DevOps übernimmt das eine selbst betriebene Renovate-Pipeline. Projekte mit dem Host `git`
haben gar keine Erkennung, und auf den anderen Hosts hängt sie an einem Dienst, der
abgeschaltet sein kann.

**Ziel:** Als Nutzer möchte ich die Abhängigkeiten auf bekannte Sicherheitslücken prüfen
können, ohne dass dafür ein Git-Host oder ein Dienst nötig ist, damit auch Projekte ohne
GitHub davon erfahren.

**Lösungsskizze:**
- Ein Rezept (etwa `just audit`), das Lücken lokal prüft, mit einem Scanner je Ökosystem
  oder einem übergreifenden.
- Für den Host `git` ersetzt es die Renovate-Prüfung aus F-074, auf den anderen Hosts
  ergänzt es sie.
- Neue Werkzeuge nur mit permissiver Lizenz (kein GPL, AGPL oder LGPL; MPL ist erlaubt;
  Ausnahmen begründet in `license-policy.txt`).

**Abhängigkeiten:** keine. Nah an F-074.

**Noch zu analysieren (Websuche):**
- Welches Werkzeug.
- Ob das Rezept in `check` gehört (es braucht Netz, und sein Ergebnis ändert sich ohne
  Codeänderung) oder eigenständig läuft.
- Wie der Host `git` an den Nutzer erinnert.
