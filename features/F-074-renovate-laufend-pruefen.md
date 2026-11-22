---
id: F-074
title: Renovate beim Anlegen und im Abgleich als laufend prüfen
type: feature
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-074 — Renovate beim Anlegen und im Abgleich als laufend prüfen

## Erfassung

**Problem:** Dass eine `renovate.json` im Repo liegt, heißt nicht, dass Renovate läuft.
Eine Bestandsaufnahme über zehn GitHub-Repos fand Renovate nur in zwei Repos aktiv. Drei
hatten die Datei, aber die App war für sie nie freigegeben, und sie hatten 10 bis 18
offene Sicherheitswarnungen. Kein Skill prüft das nach dem Anlegen.

**Ziel:** Als Nutzer möchte ich, dass ein neues Projekt erst dann als eingerichtet gilt,
wenn Renovate nachweislich läuft, und dass der Abgleich bei Bestandsprojekten meldet, wenn
es nicht läuft, damit Abhängigkeits- und Sicherheitsupdates nicht unbemerkt ausbleiben.

**Lösungsskizze:**
- *Aktivität erkennen* (Host github): ein Issue „Dependency Dashboard“ oder ein PR von
  `renovate[bot]`. `gh api /user/installations` geht mit einem normalen Token nicht.
  Zusätzlich melden, wie viele Updates im Dashboard auf Freigabe warten. In einem aktiven
  Projekt warteten 15, und nur die Sicherheits-PRs kamen durch.
- *new-project:*
  - Nach dem ersten Push wartet der Skill eine begrenzte Zeit, bis das Dashboard
    erscheint. Kommt es nicht, meldet er „Renovate läuft nicht“ mit dem Weg zur
    Freigabe der App und prüft danach erneut.
  - Fertig ist das Projekt erst dann, außer der Nutzer stellt die Prüfung ausdrücklich
    zurück. In dem Fall prüft der nächste Abgleich.
  - Beim ersten Mal erklärt der Skill, was „All repositories“ gegenüber „Only select
    repositories“ bewirkt: Neue Repos sind dann automatisch dabei, und Repos ohne Config
    bekommen einen Onboarding-PR.
- *update-conventions:* dieselbe Prüfung in `status` und in A2 Schritt 11. Optional
  meldet er die Zahl offener Dependabot-Warnungen, wenn der Token sie lesen darf.
- *Dependabot:*
  - Die Warnungen bleiben an, denn Renovates Sicherheits-PRs brauchen sie.
  - Die Sicherheitsupdates sind an, solange kein aktives Renovate gefunden wird.
  - Versionsupdates sind die bewusste Alternative zu Renovate, nie beides zugleich.
  - `detect` erkennt `.github/dependabot.yml` und bietet die Entscheidung an. Bei
    Dependabot pflegt mise dann nur `just bump-tools`.
  - Der `skip`-Weg für `renovate.json` wird dokumentiert.
- *Erzeugte Dateien:* Hängt eine erzeugte Datei vom Stand der Abhängigkeiten ab und
  prüft `just check` sie, wird jeder Bot-PR rot. Das Kit legt dafür eine Regel fest:
  beim Build erzeugen oder auf Bot-Branches per CI neu erzeugen.
- *Azure DevOps:* prüfen, ob die Renovate-Pipeline der Organisation das Repo erfasst.
  Beleg ist ein Renovate-PR. Für den Host `git` gilt F-087.

**Abhängigkeiten:** keine. F-053 und F-054 bringen Renovate für ihre Hosts mit, die
Prüfung wird so gebaut, dass sie dort andocken.

**Noch zu analysieren (Websuche):**
- Ob die gehostete Renovate-App `postUpgradeTasks` ausführt.
- Welcher Token-Umfang die Dependabot-Warnungen lesen darf.
- Wie lange new-project auf das Dashboard wartet.
