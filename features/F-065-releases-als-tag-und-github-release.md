---
id: F-065
title: Releases als Git-Tag und GitHub-Release veröffentlichen
type: feature
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-065 — Releases als Git-Tag und GitHub-Release veröffentlichen

## Erfassung

**Problem:** Ein Release besteht heute nur aus der datierten CHANGELOG-Überschrift und
dem Commit „chore: release X.Y.Z“. Das Repo hat keinen Git-Tag und kein GitHub-Release;
die Repo-Seite zeigt „Create a new release“, und von außen ist nicht zu sehen, welcher
Stand veröffentlicht ist und was er enthält. Der Ablauf selbst steht in keiner Datei.

**Ziel:** Als Nutzer des Kits möchte ich jede veröffentlichte Version als Git-Tag und
GitHub-Release mit ihrem CHANGELOG-Abschnitt sehen, damit Stand und Inhalt jeder
Version ohne Blick in den CHANGELOG zu finden sind.

**Lösungsskizze:**
- Release-Ablauf: nach dem Commit „chore: release X.Y.Z“ ein Tag `vX.Y.Z` auf genau
  diesen Commit, den Tag pushen und mit `gh release create` ein Release anlegen, dessen
  Text der CHANGELOG-Abschnitt der Version ist.
- Alte Versionen 1.0.0 bis 3.6.0 nachträglich: der Tag auf den Release-Commit; wo es
  keinen gibt (3.2.0, 3.2.1, 3.3.0, 3.3.1, 3.4.0), auf den Commit, der die Überschrift
  datiert hat, sonst den letzten mit dieser Version in `plugin.json`. Jedes Release mit
  seinem CHANGELOG-Abschnitt und dem damaligen Datum; nur die neueste Version ist
  „Latest“.
- Die eingefrorenen Reihen (Kit vor 1.0.0, project-template bis 0.16.0) bekommen keine
  Tags — ihre Nummern überschneiden sich, und sie gehören zu früheren Repos.
- Den Ablauf dort festhalten, wo er gefunden wird (Kit-CLAUDE.md, README).
- Tag und Release wirken nach außen: jeder Schritt nur nach Freigabe.

**Abhängigkeiten:** keine.

**Noch zu analysieren:**
- Rezept, Skript oder nur Doku für den Ablauf — und wer schneidet den
  CHANGELOG-Abschnitt aus?
- Wie lässt sich der Commit für die Versionen ohne Release-Commit verlässlich bestimmen?
- GitHub setzt bei nachträglichen Releases das Erstelldatum: das damalige Datum im Text
  nennen?
- Release 3.7.0 noch nach dem alten Ablauf oder erst mit diesem Feature?
