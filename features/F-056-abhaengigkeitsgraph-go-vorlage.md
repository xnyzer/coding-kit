---
id: F-056
title: Fehlschlag des GitHub-Abhängigkeitsgraphen an der Go-Vorlage beheben
type: fix
status: BACKLOG
size:
created: 2026-11-04
done:
depends-on:
superseded-by:
---

# F-056 — Fehlschlag des GitHub-Abhängigkeitsgraphen an der Go-Vorlage beheben

## Erfassung

**Problem:** GitHub liest für seinen Abhängigkeitsgraphen jede `go.mod` im Repo. Die
Go-Vorlage des Templates (`modules/go/files/go.mod`) enthält Platzhalter
(`{{GO_MODULE}}`) und ist deshalb keine gültige `go.mod`. Jede Änderung an ihr lässt den
Lauf „Graph Update: go_modules“ fehlschlagen (2026-10-23 und 2026-11-04) — ein roter
Lauf in den Actions und eine mögliche Benachrichtigung, ohne Folgen für die CI oder die
Projekte. Die Python-Vorlage ist nicht betroffen.

**Ziel:**
- Ist: Nach einer Änderung an der Go-Vorlage schlägt „Graph Update: go_modules“ fehl.
- Soll: Kein Fehlschlag mehr; eine Vorlage zählt nicht als echte Abhängigkeitsdatei.
  Was Projekte aus der Vorlage bekommen, bleibt gleich.
- Reproduzieren: eine Änderung an `modules/go/files/go.mod` pushen und die Actions
  ansehen.

**Lösungsskizze:**
- Bevorzugt: den Vorlagen-Ordner vom Abhängigkeitsgraphen ausnehmen, falls GitHub einen
  Ausschluss je Pfad kennt (etwa in `.github/dependabot.yml`) — zur Planungszeit
  nachprüfen.
- Sonst: die automatische Abhängigkeitsmeldung für Go in den Repo-Einstellungen
  ausschalten; das Kit hat keinen echten Go-Code.
- Verworfen für den Anfang: die Vorlage umbenennen (`go.mod.tmpl`) und beim Rendern
  zurückbenennen — neue Regel in Renderer und MANIFEST für ein reines Anzeigeproblem.

**Abhängigkeiten:** keine.
