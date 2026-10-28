---
id: F-018
title: Konventions-Vererbung nur noch abwärts
type: feature
status: DONE
size:
created: 2026-07-19
done: 2026-07-19
depends-on:
superseded-by:
---

# F-018 — Konventions-Vererbung nur noch abwärts

## Verlauf

### F-018 — Konventions-Vererbung nur noch abwärts (2026-07-19)

**Aufgabe:** update-conventions war bidirektional — die AUFWÄRTS-Richtung („promote")
schrieb aus Projekten ins Template. Architektur-Entscheidung des Nutzers: Änderungen
immer zuerst in der Vorlage, Vererbung fließt ausschließlich Template → Projekt.

**Was entstanden ist (Plugin 0.13.0):**

- **update-conventions ist reine Abwärts-Maschine:** promote-Argument,
  Richtungsfrage und der komplette AUFWÄRTS-Abschnitt entfernt; Grundsatz
  „Vererbung fließt ausschließlich abwärts; dieser Skill schreibt nie ins Template"
  im Kopf. Entscheidungsset je Datei/Fragment dreiteilig (übernehmen / so lassen /
  Override registrieren) mit Verweis „Vorlage zuerst ändern, dann erneut syncen".
  Nebenbefund gefixt: veralteter Querverweis „Commit-Frage wie A2.6" → „A2.7"
  (seit der F-014-Umnummerierung falsch).
- **Neu: Abschnitt „Übernahme-Vorschlag"** als Ersatz für promote — projektlokale
  Fragmente bleiben erlaubt, werden aber nie automatisch ins Template gehoben.
  Stattdessen fertiges Material zum manuellen Anstoßen: kopierfertiger
  Beispiel-Prompt für eine project-template-Session (generalisieren,
  `modules/standards/<name>.md` + Katalog-Zeile, Sync-Invariante) oder ein
  GitHub-Request (`gh issue create -R OWNER/project-template`, OWNER zur Laufzeit,
  Override via `CODING_KIT_TEMPLATE_REPO`).
- **Drei Ausgabe-Stellen des Übernahme-Vorschlags:** update-conventions
  (Bestandsfälle beim Sync-Lauf), prep-step 2a Fall B (direkt nach der Anlage eines
  projektlokalen Fragments), step-done 1a (neu angelegte Fragment-Blöcke im Diff —
  fängt auch ad-hoc Angelegtes).
- **Begleitanpassungen:** plugin.json 0.13.0, CHANGELOG-Eintrag, README-Zeile
  update-conventions („nur abwärts"), Frontmatter-`description` neu; „promote"-
  Restvorkommen per grep verifiziert (nur noch CHANGELOG-Historie).
- **Geänderte Dateien:** `plugins/coding-kit/skills/update-conventions/SKILL.md`,
  `plugins/coding-kit/skills/prep-step/SKILL.md`,
  `plugins/coding-kit/skills/step-done/SKILL.md`,
  `plugins/coding-kit/.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`.
