---
id: F-022
title: Begleithandlungen beim Fragment-Einbau
type: feature
status: DONE
size:
created: 2026-08-11
done: 2026-08-11
depends-on:
superseded-by:
---

# F-022 — Begleithandlungen beim Fragment-Einbau

## Verlauf

### F-022 — Begleithandlungen beim Fragment-Einbau (2026-08-11)

**Aufgabe:** ausgelöst von project-template 0.13.1 (dortiges TPL-016). Das `nextjs`-Fragment
verlangt seither eine Handlung, die kein Skill ausgeführt hat: Ein Projekt, das Next
adoptiert, muss eine `AGENTS.md` haben, **bevor** `next dev` das erste Mal läuft. Sonst
schreibt Nexts Agent-Rules-Generator seinen Managed-Block in die `CLAUDE.md` und erneuert
ihn dort bei jedem Lauf — und ein nachträglich angelegtes `AGENTS.md` holt ihn nicht mehr
heraus. Der Fragment-Text stand also im Projekt, ohne dass ihn jemand ausführte.

**Was gebaut wurde (5 Skills + Begleit-Änderungen):**

`choose-stack`: neuer Abschnitt **§ Begleithandlungen beim Fragment-Einbau** — die einzige
Fundstelle der Mechanik. Verlangt ein Fragment beim Einbau eine Handlung am Projekt und
nicht nur den Text im Slot, wird sie im selben Schritt ausgeführt, im Plan ausgewiesen und
einzeln bestätigt. Zwei Eigenheiten sind ausdrücklich benannt: die Prüfung ist von der
Idempotenz-Regel **entkoppelt** (Fragment schon im Slot → Text übersprungen,
Begleithandlung trotzdem geprüft), und eine Begleithandlung darf eine **Reihenfolge**
vorschreiben plus einen Zustand benennen, den späteres Nachholen allein nicht heilt. Im
Modus-B-Bullet steht der Querverweis an der Idempotenz-Regel.

Referenzen statt Duplikate an den vier Einbau-Stellen: `new-project` (Fragment-Assembly),
`prep-step` § 2a und `step-done` § 1a (Begleithandlung im Vorschlag mitausweisen),
`choose-stack` Modus B. Zusätzlich `update-conventions` Schritt 6: Prüfung je Fragment im
Slot **auch bei unverändertem Fragment-Text**, offene Fälle mit Diff angeboten.

**Notable decisions:**

- **Generisch statt fragmentspezifisch.** Kein `if nextjs then …`. Was zu tun ist, liest
  der Skill zur Laufzeit aus dem Fragment; das Kit hardcodet kein Framework-Wissen. Das
  ist dieselbe Arbeitsteilung, die schon fürs Trigger-Mapping gilt (Template = Daten,
  Kit = Logik) und die die Authoring-Konvention fordert („kein hartkodierter
  Projektzustand", „nichts hardcoden"). Künftige Fragmente mit Begleithandlung kosten
  damit **null** Skill-Änderungen.
- **Einmal formuliert, viermal referenziert.** Die Untersuchung ergab, dass alle vier
  Einbau-Stellen ohnehin schon auf `/choose-stack` verweisen („Mechanik wie
  /choose-stack"). Die Mechanik gehörte deshalb genau dorthin; die vier Stellen bekamen
  nur je einen Satz, damit die Referenz nicht überlesen wird.
- **Entkopplung von der Idempotenz-Regel war der eigentliche Fix.** Die bestehende Regel
  „`fragment:NAME` schon vorhanden → überspringen" hätte die Begleithandlung genau in den
  Projekten verschluckt, die sie am nötigsten brauchen.
- **`update-conventions` als fünfte Stelle ergänzt** — sie stand nicht in der
  Ausgangsliste, ist aber der **einzige** Pfad, der Bestandsprojekte erreicht: die
  anderen vier greifen nur beim Einbau, und ein Projekt, das `nextjs` vor 0.13.1 bekam,
  wäre sonst nie eingeholt worden.
- **Keine Versionsstände im Skill-Text** (Authoring-Konvention): die Verzweigung ist kein
  Public API, das Fragment verweist selbst auf die installierte Quelle.

**Verifikation:** die Behauptung des Auftrags wurde nicht übernommen, sondern gegen eine
frisch installierte Next-Version dreifach nachgemessen. (1) `writeAgentFiles` in
`node_modules/next/dist/server/lib/generate-agent-files.js` zeigt die Verzweigung
`agentsMdExists && (agentsMdHostsBlock || !claudeMdHostsBlock)` → `AGENTS.md`; sonst
`claudeMdExists` → `CLAUDE.md`; sonst beide anlegen. Der Aufruf sitzt in `start-server.js`
beim Dev-Boot, gated auf `agentRules !== false` (Default an) und auf erkannten Agenten
(`@vercel/detect-agent`, u. a. `CLAUDECODE`). (2) Fünf Fixtures direkt gegen
`writeAgentFiles`: nur `CLAUDE.md` → Block in `CLAUDE.md`, kein `AGENTS.md` angelegt;
`CLAUDE.md` + `AGENTS.md` → Block in `AGENTS.md`, `CLAUDE.md` übersprungen; keine von
beiden → beide angelegt; nur `AGENTS.md` → dorthin; **Block bereits in `CLAUDE.md`,
`AGENTS.md` nachträglich angelegt → weiterhin `CLAUDE.md`** (daher die Reihenfolge-Regel).
(3) Zwei echte `next dev`-Läufe mit Request: ohne `AGENTS.md` meldete Next „Generated
CLAUDE.md", der Block stand in der Governance-Datei, `git diff` zeigte sie geändert; mit
vorhandener `AGENTS.md` meldete Next „Generated AGENTS.md", `CLAUDE.md` blieb
byte-identisch. Alle drei Messungen stimmen überein und decken sich mit F-016 drüben.
`just check` grün.
