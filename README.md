# coding-kit

Mein persönliches Claude-Code-Kit: ein **Plugin** mit generischen Workflow-Skills, ein
**Marketplace** zum Installieren, ein **Renovate-Preset** für alle Projekte und ein
**Installer** für neue Rechner. Zusammen mit
[project-template](https://github.com/xnyzer/project-template) bildet es das
Scaffolding-System, mit dem neue Projekte entstehen und Bestandsprojekte aktuell bleiben.

> Kit-Sprache ist Deutsch (das Kit ist primär für den Eigenbedarf). Englisch ist nur, was
> in Projekte gelangt oder dort wirkt: Governance-Doku, Commit-Messages, Hook-Ausgaben.

## Einrichtung

Auf einem eingerichteten Rechner (gh + claude vorhanden):

```
/plugin marketplace add xnyzer/coding-kit
/plugin install coding-kit@xnyzer
```

Auf einem neuen Rechner: Repo klonen und den idempotenten Installer ausführen — er prüft
gh/claude, richtet Marketplace + Plugin ein, legt die Personal-Config an und bietet die
Toolchain-Installation an:

```bash
git clone https://github.com/xnyzer/coding-kit.git && cd coding-kit && ./install.sh
```

Frisch installierte Skills sind ggf. erst nach einem Session-Neustart sichtbar.

## Tägliche Nutzung

Die Skills erscheinen namespaced als `/coding-kit:<skill>`:

| Skill | Zweck |
|-------|-------|
| `/coding-kit:add-feature` | Neue Aufgabe analysieren und mit F-Nummer ins PROGRESS-Backlog aufnehmen. |
| `/coding-kit:prep-step` | Aufgabe vor der Umsetzung analysieren, ggf. in Substeps zerlegen, Plan festhalten. |
| `/coding-kit:step-done` | Abschluss-Checkliste: Review, `just check`, Secrets-Scan, Privacy-Scan der lebenden Doku, PROGRESS-Pflege, Commit-Frage. |
| `/coding-kit:audit-code` | Vollaudit (Code, Security, Deps, Deployment) → `AUDIT-RESULTS.md`, fixt nichts. |
| `/coding-kit:name-it` | Namenskandidaten nach Kriterien + Verfügbarkeits-Checks (GitHub/npm/PyPI, Domain optional). |
| `/coding-kit:choose-license` | Kurzinterview → Lizenz-Empfehlung (Default Apache-2.0, „TBD" gültig). |
| `/coding-kit:choose-stack` | Modul-Empfehlung für Neuanlage oder Nachrüsten/Wechsel EINES Moduls im Bestand (Diff + Bestätigung). |
| `/coding-kit:define-requirements` | Interview → REQUIREMENTS.md (Übergangs-Artefakt) → initiale PROGRESS.md mit F-Nummern. |
| `/coding-kit:refine-requirements` | Zurück zur Spec: Diagnose mit drei Pfaden, darf Features splitten, datiertes Decision Log. |

Der übliche Zyklus: `add-feature` → `prep-step` → implementieren → `step-done`.

Alle Skills sind **stack-agnostisch**: Sie rufen nur die just-Standardrezepte
(`just check` / `test` / `lint`) auf und lesen Projektspezifika (Graphiti-group_id,
Sprache der lebenden Doku, Sicherheits-Postur) aus der Projekt-CLAUDE.md — nichts ist
hartkodiert.

### Stop-Hook

Das Plugin bringt einen **projekterkennenden** Stop-Hook mit: Endet ein Claude-Turn,
während im Projekt uncommittete Änderungen liegen, erinnert er einmal pro Stopp an
`/coding-kit:step-done`.

- **Feuert nur in Kit-Projekten:** erkannt an einer `PROGRESS.md` mit
  `FEATURE-INDEX`-Block **oder** einer Datei `.claude/template-version`. In allen anderen
  Repos ist der Hook vollständig still.
- **Loop-Schutz:** pro Stopp maximal eine Erinnerung (`stop_hook_active`).
- Als „uncommitted" zählen geänderte und neue (nicht ignorierte) Dateien; `private/` und
  anderes Gitignoriertes lösen nichts aus.
- Abschalten: Plugin deaktivieren (`claude plugin disable coding-kit`) oder committen. 😉

### Geplant (Roadmap siehe PROGRESS.md)

- **`/new-project`:** Orchestrator, der aus dem project-template ein fertiges Repo macht.
- **Pflege-Skills:** `/update-conventions` (Template ↔ Projekte, bidirektional),
  `/check-upstreams` (Watchliste externer Repos).

## Renovate-Preset

`default.json` im Repo-Root ist ein Shareable Preset; Projekte binden es so an:

```json
{ "extends": ["github>xnyzer/coding-kit"] }
```

Inhalt: `config:recommended` + Digest-Pinning für GitHub Actions + Label `dependencies`.
Details und die (bewusst manuelle) App-Installation: [docs/renovate-preset.md](docs/renovate-preset.md).

## Personal-Config

`~/.claude/coding-kit.env` (dotenv, shell-sourcebar, **nie committen**) — legt der
Installer an. Enthält, was nicht zur Laufzeit ermittelbar ist, plus Offline-Fallbacks:

| Schlüssel | Bedeutung |
|-----------|-----------|
| `CODING_KIT_GITHUB_LOGIN` | GitHub-Login (Fallback; primär via `gh api user`) |
| `CODING_KIT_GIT_AUTHOR_NAME` | Git-Autorname |
| `CODING_KIT_GIT_NOREPLY_EMAIL` | GitHub-Noreply-Adresse für Commits |
| `CODING_KIT_PROJECTS_DIR` | Wurzelverzeichnis der Projekte |
| `CODING_KIT_TEMPLATE_REPO` | _(optional)_ Override für das Template-Repo; Default: `<github-login>/project-template` |

## Repo-Struktur

```
.claude-plugin/marketplace.json   Marketplace „xnyzer" (Quelle: dieses Repo)
plugins/coding-kit/               Das Plugin
  .claude-plugin/plugin.json      Name, Version, Beschreibung
  skills/<name>/SKILL.md          Die vier Core-Skills
  hooks/hooks.json + *.sh         Projekterkennender Stop-Hook
default.json                      Renovate-Shareable-Preset (Root = Preset-Konvention)
docs/                             Pflege-Doku (Skill-Authoring, Renovate-Preset)
install.sh                        Neuer-Rechner-Bootstrap (idempotent)
scripts/validate.py               Kit-Validator (läuft in `just check` + CI)
private/                          Gitignoriert — private Notizen/Quellen
```

## Pflege

- Regeln für neue/geänderte Skills: [docs/skill-authoring.md](docs/skill-authoring.md).
- Jede inhaltliche Plugin-Änderung bumpt die Version in `plugin.json` und bekommt einen
  `CHANGELOG.md`-Eintrag (im selben Commit).
- `just setup` installiert die Git-Hooks (gitleaks + Validator), `just check` ist das
  Vollgate — muss vor jedem Commit grün sein.
- Aufgaben laufen als F-Nummern in `PROGRESS.md` — das Kit nutzt seine eigenen Skills
  (Dogfooding).

## Lizenz

Apache-2.0 — siehe [LICENSE](LICENSE).
