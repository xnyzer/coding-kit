---
id: F-038
title: Freigabe-Regel für PROGRESS-Einträge kit-weit
type: feature
status: DONE
size:
created: 2026-10-23
done: 2026-10-23
depends-on:
superseded-by:
---

# F-038 — Freigabe-Regel für PROGRESS-Einträge kit-weit

## Verlauf

### F-038a — Plugin: Freigabe-Gate und add-feature-Aufruf (2026-10-23)

Teil von F-038 (Freigabe-Regel für PROGRESS-Einträge kit-weit; F-038b — Kit-CLAUDE.md
und add-skill — folgt).

**Problem:** step-done schrieb Done-Zeile, Archiv-Eintrag und `(DONE)`-Marker ohne
Vorschau („Direkt tun, ohne zu fragen"). Zugleich hielt Claude add-feature für nur vom
Nutzer startbar, obwohl der Skill seit jeher `disable-model-invocation: false` trägt —
build-step („via add-feature … vorschlagen") und add-feature („Der Nutzer hat eine
Idee …") legten das nahe.

**Was entstanden ist (Plugin 0.20.0):**

- **`step-done`:** § 4 bereitet nur noch vor (mit Standardsatz Freigabe-Gate); neuer § 5
  „Freigabe, Verbuchung und Commit" — eine Frage mit Vorschau und Commit-Message,
  Antworten verbuchen und committen / nur verbuchen / Text ändern; nach OK schreiben,
  re-lesen, `just check`, committen. Autonome Ausnahme deckt Verbuchung und Commits der
  geplanten Substeps, neue Einträge werden nur gesammelt. Graphiti jetzt § 6, erst nach
  der Verbuchung; Commit-E-Mail und Co-Authored-By jetzt § 5a/5b.
- **`build-step`:** Scope-Schutz — add-feature selbst starten, autonom nur sammeln;
  Leitplanke Freigabe-Gate; Abschluss listet gesammelte Ideen; Start-Freigabe heißt
  „verbuchen und committen" (Frage, Goal-Zeile ohne Freigabe, `claude -p`-Beispiel,
  Modus-Erkennung, Recovery, description).
- **`add-feature`:** description und Einleitung „Wer startet" (Nutzer oder Claude),
  Freigabe-Gate inkl. autonomem Fall.
- **`docs/skill-authoring.md`:** Hinweis, dass der Text eines modellaufrufbaren Skills
  dem nicht widersprechen darf; neuer Pflicht-Baustein „Freigabe-Gate" mit Standardsatz.
- **Begleit-Änderungen:** `plugin.json` 0.20.0, `CHANGELOG.md`, `README.md`
  (Tabellenzeilen add-feature und step-done, Absatz „Freigabe für die PROGRESS").

**Verifikation:** `just check` grün, `claude plugin validate` grün (einzige Warnung:
fehlendes Icon, ohne Belang). grep über alle PROGRESS-schreibenden Skills: add-feature,
step-done, build-step tragen den Standardsatz; prep-step, define-requirements,
refine-requirements waren bereits mit eigener Formulierung gegated; teach-step und
check-upstreams schreiben nur über diese. Das Laufzeitverhalten ist noch ungetestet,
installiert ist 0.19.1 — Test per `claude --plugin-dir plugins/coding-kit` möglich.

**Notable decisions:**
- Standardsatz in jedem schreibenden Skill statt einer zentral referenzierten Regel —
  `docs/` liegt nicht im Plugin-Cache, Skills können es zur Laufzeit nicht lesen.
- Verbuchung und Commit in einer Frage, damit der Abschluss nicht zweimal fragt.
- prep-step, define-requirements, refine-requirements unverändert gelassen (bereits
  gegated, „sinngemäß gleich" laut Authoring-Doku); update-conventions ohne Standardsatz,
  weil es die PROGRESS nur innerhalb einer einzeln bestätigten Migration berührt.
- Nur § 3 von step-done wird von außen referenziert (new-project) — die Umnummerierung
  ab § 4 bricht nichts.

**Geänderte Dateien:** `plugins/coding-kit/skills/{step-done,build-step,add-feature}/SKILL.md`,
`docs/skill-authoring.md`, `README.md`, `plugins/coding-kit/.claude-plugin/plugin.json`,
`CHANGELOG.md`, `PROGRESS.md`, `PROGRESS-ARCHIVE.md`.

### F-038b — Repo-lokal: CLAUDE.md und add-skill (2026-10-23)

Schließt F-038 (Freigabe-Regel für PROGRESS-Einträge kit-weit) ab; der Plugin-Teil ist
F-038a (Plugin 0.20.0).

**Was entstanden ist (repo-lokal, kein Release):**

- **`CLAUDE.md`:** neue Strukturregel „PROGRESS nur mit Freigabe" — Vorschau und
  ausdrückliches OK für jeden neuen oder geänderten Eintrag in PROGRESS, Archiv und
  Index, auch wenn ein Skill ihn anlegt; Claude darf add-feature und add-skill selbst
  starten. Der Absatz zu `/add-skill` nennt jetzt Plugin- und repo-lokale Skills.
  Zusätzlich die Regel „project-template ist bis F-039 eingefroren" — Nachzüge werden in
  F-039 vermerkt; sie entfällt mit F-039.
- **`.claude/skills/add-skill/SKILL.md`:** `disable-model-invocation: false` explizit,
  Beschreibung und Einleitung sagen, dass Claude den Skill selbst starten darf;
  Freigabe-Gate mit Standardsatz; Interview fragt „Plugin oder repo-lokal?"; Schritt 2
  und 3 mit getrennten Wegen (repo-lokal: kein Bump, kein CHANGELOG, keine
  README-Skill-Zeile); fehlende F-Nummer wird **vor** dem Bauen über add-feature angelegt
  statt „spätestens beim Abschluss vergeben"; Schritt 3 (HOW-TO im Template) vermerkt
  den Nachzug in F-039, solange project-template eingefroren ist; Kontext-Recovery
  ergänzt.
- **`PROGRESS.md`, F-039:** zwei Punkte in der Lösungsskizze — HOW-TO-Nachzug aus F-038a
  (step-done mit Vorschau und Freigabe, add-feature auch von Claude gestartet) und
  Rückbau der Einfrier-Regel samt add-skill Schritt 3.

**Verifikation:** `just check` grün; `add-skill` erscheint mit neuer Beschreibung in der
Skill-Liste der laufenden Session.

**Notable decisions:**
- Einfrier-Regel in die CLAUDE.md statt nur in add-skill: jede Session liest sie, auch
  eine, die das Template ohne add-skill anfassen würde (Nutzerentscheidung, über den
  Plan hinaus).
- Die Frage „Plugin oder repo-lokal?" betrifft nur Sessions im Kit-Repo — add-skill
  liegt nicht im Plugin, Nutzer des Plugins sehen ihn nie.

**Geänderte Dateien:** `CLAUDE.md`, `.claude/skills/add-skill/SKILL.md`, `PROGRESS.md`,
`PROGRESS-ARCHIVE.md`.
