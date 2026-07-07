# coding-kit — Progress-Archiv

Abgeschlossene Aufgaben mit Detail und Begründung. Neueste oben.

---

## F-004 — Globale CLAUDE.md-Vorlage (2026-07-07)

**Was entstanden ist:** `templates/global-CLAUDE.md` — die schlanke Vorlage der globalen
House-Defaults (Sprache & Stil, Git-/Commit-Regeln inkl. Laufzeit-Auflösung der
Noreply-E-Mail, Graphiti-Regeln mit group_id-Quelle Root-CLAUDE.md + `main` für
Übergreifendes, Arbeitsweise mit Write-then-Verify, F-Nummern-Workflow, private/-
Konvention, Verweis auf die Plugin-Skills). Die Datei ist bewusst schlank (lädt in jede
Session) und identisch mit `~/.claude/CLAUDE.md` auf dem Rechner — dadurch funktioniert
der bestehende Installer-Schritt (cp bei Neueinrichtung, diff-Hinweis bei Abgleich) ohne
Code-Änderung; er war ab F-001 vorbereitet und ist jetzt aktiv.

**Migration (einmalige Nutzeraktion, erledigt):** Inhalte der Legacy-Datei
`~/.claude/instructions.md` überführt und modernisiert — group_id-Quelle ist jetzt die
Root-CLAUDE.md des Projekts (nicht mehr `.claude/instructions.md`); hartkodierte
E-Mail-Adressen durch Laufzeit-Auflösung via `gh api` ersetzt (die Vorlage ist public —
keine Identität im Text). Die Legacy-Datei wurde nach Backup in `private/` gelöscht
(sie wurde von Claude Code ohnehin nicht geladen).

**Entscheidungen:**

- Vorlage und lokale Datei bleiben byte-identisch und generisch (keine persönlichen
  Werte nötig — alles Persönliche kommt zur Laufzeit oder aus der Personal-Config).
- Kein plugin.json-Bump: `templates/` und Installer sind Repo-, nicht Plugin-Inhalt;
  die Sync-Invariante (Version + CHANGELOG) gilt nur für Skills/Hooks.

---

## F-003 — /new-project-Orchestrator (2026-07-07)

**Was entstanden ist:** `plugins/coding-kit/skills/new-project/SKILL.md` (Plugin 0.3.0) —
der Orchestrator über dem project-template, nach dem Muster des bewährten
Maschinen-Anlage-Skills (Inputs sammeln statt raten, nichts ungefragt, Templates aus
der Quelle statt inline):

- **Schritt 0 (M1):** „Was soll das Projekt können?" → Short-Info (ein Satz, publishbar),
  mehrfach wiederverwendet (Repo-Beschreibung, CLAUDE.md, README, Graphiti, Namensfindung);
  bei Projekten aus einem Quelldokument (z. B. STARTPROMPT-Datei) wird die Short-Info
  daraus vorgeschlagen.
- **Abfragen** mit Defaults, Sub-Skills aufrufbar, Aufschieben erlaubt: Name (/name-it),
  Sichtbarkeit (privat), Lizenz (/choose-license; TBD nur bei privat), Modul
  (/choose-stack; offen → docs-only), Doku-Sprache (Deutsch bei privat, Englisch bei
  public), group_id (= Name; „kein Graphiti" möglich), Anforderungen jetzt
  (/define-requirements) oder später.
- **Plan → Bestätigung → Ausführung**, jeder außenwirksame Schritt einzeln bestätigt:
  `gh repo create --template --clone` (kein git init) + lokale Autor-Config via gh api;
  Instanziierung streng nach den MANIFEST-Tabellen (Platzhalter-Registry,
  template:adapt konkretisieren, template:optional graphiti/security-tool,
  public-only-Dateien, LICENSE-Handling inkl. TBD); Modul-Einbau nach Modul-Kontrakt;
  Aufräumen aller Template-eigenen Dateien mit git-status-Gegenprüfung;
  `.claude/template-version`-Stempel; Repo-Settings (Beschreibung = Short-Info, Topics
  mit Marker `coding-kit`, Squash-Merge, Push-Protection mit Feature-Detection);
  Verifikation `mise trust && mise install && just setup && just check`;
  Personendaten-grep + Verschieben von Quelldokumenten nach `private/`;
  Erst-Commit nur nach OK; Graphiti-Seeding falls MCP läuft.
- **Robustheit:** Trockenlauf via Argument `dry-run` (zeigt Fragen, Plan und
  Ziel-Dateiliste, führt nichts aus), Kontext-Recovery-Block, `manifest-format`-Check
  (kann Format 1, bricht sonst mit Hinweis auf Kit-Update ab), Fehlerpfad bei belegtem
  Repo-Namen.

**Entscheidungen:**

- `disable-model-invocation: true` — Repo-Anlage darf nie spontan vom Modell ausgelöst
  werden; nur der Nutzer startet den Orchestrator.
- Instanziierung koppelt an die MANIFEST-Tabellen zur Laufzeit statt an einkopierte
  Dateilisten — Template-Änderungen brechen den Skill nicht (Kopplung nur über die
  `manifest-format`-Version).
- Quell-STARTPROMPTs wandern nach `private/` des neuen Projekts (gitignored) — die
  publishbare Essenz steckt bereits in Short-Info/REQUIREMENTS.

---

## F-002 — Begleit-Skills (2026-07-07)

**Was entstanden ist:** Fünf Skills unter `plugins/coding-kit/skills/` (Plugin 0.2.0) —
einzeln nutzbar und von `/new-project` (F-003) aufrufbar; jede SKILL.md definiert dafür
explizit ihre „Rückgabe an den Aufrufer":

- **name-it** — Kandidaten nach Kriterien (kurz, sprechend, kollisionsarm,
  lowercase-kebab-tauglich), Verfügbarkeits-Checks zur Laufzeit (GitHub via gh,
  npm-Registry, PyPI-JSON-API; Domain nur auf Wunsch via RDAP), Websuche gegen
  Namensvettern. Rückgabe: gewählter Name.
- **choose-license** — M1-Kurzinterview (Sichtbarkeit, kommerzielle Nutzung, Copyleft,
  Dependency-Lage), Empfehlung Default Apache-2.0, Alternativen MIT/MPL-2.0, GPL/AGPL
  nur als bewusste Entscheidung, „TBD" gültig (nur privat). Standalone schreibt es
  LICENSE + Paket-Metadaten nach Bestätigung. Rückgabe: SPDX-Id oder TBD.
- **choose-stack** — Modus A Neuanlage (Bedarf aus Short-Info, aktuelle Framework-Lage
  per Websuche verifiziert, Stubs klar ausgewiesen, „offen" → docs-only); Modus B
  Bestandsprojekt (EIN Modul nachrüsten/wechseln nach MANIFEST-Modul-Kontrakt, Diff +
  Bestätigung je Datei, Override-Schutz, Verifikation via mise install + just setup +
  just check). Template-Repo wird zur Laufzeit aufgelöst (lokaler Checkout, sonst
  gh clone von `<login>/project-template`; Override `CODING_KIT_TEMPLATE_REPO`).
  Grenze dokumentiert: laufende Modul-Updates = `/update-conventions`. Rückgabe:
  Modulname (+ CODEQL-Sprache, geschriebene Dateien).
- **define-requirements** — M1-Interview aus der Short-Info (Ziele, Kern-Features,
  Nicht-Ziele, Constraints; Vorschläge bestätigen lassen statt offen fragen) →
  REQUIREMENTS.md in M5-Struktur (= Template-Skelett `core/REQUIREMENTS.md`) → initiale
  PROGRESS.md mit einer F-Nummer je Anforderung + FEATURE-INDEX. Verwaltet den
  Auflöse-Trigger (vollständig überführt + Nutzer bestätigt → Kurzfassung in CLAUDE.md,
  Entscheidungen als ADR sichern, Datei löschen).
- **refine-requirements** — M2-Diagnose „Was führt dich zurück zur Spec?" mit drei
  Pfaden (Änderung von außen / Implementierungs-Lücke / Grundsatz-Challenge); darf
  Features splitten (neue Nummern via FEATURE-INDEX); immer datierte Decision-Log-
  Einträge (Product/Technical getrennt, Historie supersedieren statt umschreiben);
  arbeitet nach Auflösung der REQUIREMENTS.md auf PROGRESS + ADRs weiter.

**Entscheidungen:**

- Alle fünf mit `disable-model-invocation: false`, damit der `/new-project`-Orchestrator
  (F-003) sie als Sub-Skills aufrufen kann; präzise descriptions verhindern Spontanfeuer.
- Neuer optionaler Personal-Config-Schlüssel `CODING_KIT_TEMPLATE_REPO` (Default bleibt
  Laufzeit-Auflösung `<github-login>/project-template` — kein Hardcode).

---

## F-001 — Kit-Grundgerüst (2026-07-07)

**Was entstanden ist:**

- **Marketplace** `.claude-plugin/marketplace.json` — Name `xnyzer`, Plugin per relativem
  `source: "./plugins/coding-kit"` → `/plugin marketplace add xnyzer/coding-kit` und
  `/plugin install coding-kit@xnyzer` funktionieren direkt.
- **Plugin** `plugins/coding-kit/` — `plugin.json` (Version 0.1.0), vier Core-Skills,
  Stop-Hook.
- **Skills** (generalisiert aus erprobten projektlokalen Vorlagen, personendatenfrei,
  stack-agnostisch): `add-feature`, `prep-step`, `step-done`, `audit-code`. Gemeinsame
  Bausteine: Projektkontext aus der Projekt-CLAUDE.md (group_id, Doku-Sprache,
  Sicherheits-Postur), Checks nur über just-Standardrezepte, F-Nummern-Toleranz (alt
  lesen, F-NNN schreiben), Kontext-Recovery-Block (M4), Write-then-Verify (M3) in
  step-done, Privacy-Scan der lebenden Doku in step-done, Commit-E-Mail-Check zur
  Laufzeit via `gh api` (kein Hardcode).
- **Stop-Hook** `hooks/stop-reminder.sh` — projekterkennend (PROGRESS.md mit
  FEATURE-INDEX oder `.claude/template-version`), blockt einen Stopp höchstens einmal
  (`stop_hook_active`-Schutz) und verweist auf `/coding-kit:step-done`; in fremden Repos
  vollständig still.
- **Renovate-Preset** `default.json` (Root): `config:recommended` +
  `helpers:pinGitHubActionDigests` + Label `dependencies`; Doku in
  `docs/renovate-preset.md`. Kit und project-template extenden es selbst (Dogfooding).
- **Installer** `install.sh` — idempotent: prüft gh/claude, richtet Marketplace + Plugin
  ein, legt `~/.claude/coding-kit.env` an (via `gh api` vorbefüllt, chmod 600), bietet
  Toolchain-Installation an; globale CLAUDE.md-Einrichtung folgt mit F-004.
- **Doku:** deutsches `README.md`, `docs/skill-authoring.md` (verbindliche
  Authoring-Konvention), `CLAUDE.md` (Dogfooding), Governance auf Englisch
  (LICENSE Apache-2.0, CODE_OF_CONDUCT CC 3.0, SECURITY, CONTRIBUTING, AI-DISCLOSURE).
- **Qualität:** `scripts/validate.py` (JSON/YAML/TOML-Syntax, Plugin-/Marketplace-/
  Skill-Frontmatter-Checks, Privacy-Lint) via `just check`, lefthook (gitleaks +
  Validator), gehärtete CI (permissions minimal, Actions SHA-gepinnt, Concurrency).

**Entscheidungen:**

- Stop-Hook blockt (JSON `decision: block`) statt nur zu echoen — die Erinnerung erreicht
  das Modell zuverlässig; der `stop_hook_active`-Schutz verhindert Schleifen.
  Hook-Ausgabe auf Englisch, weil sie in beliebigen (oft öffentlichen) Projekten wirkt.
- Kit versioniert über `plugin.json` + `CHANGELOG.md` (keine separate VERSION-Datei wie
  im Template — die Skills koppeln an die MANIFEST-Formatversion des Templates, nicht an
  Kit-Versionen).
- `project-template/renovate.json` (Root) im Zuge dessen aufs Preset umgestellt
  (TODO(D3) dort erledigt; Root-Datei ist nicht manifest-verwaltet → kein VERSION-Bump).
