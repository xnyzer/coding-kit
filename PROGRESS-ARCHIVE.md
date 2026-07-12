# coding-kit — Progress-Archiv

Abgeschlossene Aufgaben mit Detail und Begründung. Neueste oben.

---

## F-009 — Repo-lokaler Pflege-Skill add-skill (2026-07-13)

**Was entstanden ist (Repo-Infrastruktur, kein Plugin-Inhalt — daher kein
Version-Bump):**

- **`.claude/skills/add-skill/SKILL.md`** — standardisiert Anlage und Änderung von
  Plugin-Skills in diesem Repo: Kontext laden (`docs/skill-authoring.md` als
  referenzierte Quelle der Wahrheit, nicht dupliziert) → M1-Kurz-Interview
  (neu/ändern, Name + Kategorie, Trigger, Frontmatter-Flags, Pflicht-Bausteine) →
  Bauen mit Write-then-Verify → **Begleit-Änderungs-Checkliste** (plugin.json-Version
  UND Description-Aufzählung, CHANGELOG, README-Tabelle UND Prosa, ggf.
  Authoring-Doku) → Verifizieren (`just check`, `/reload-plugins`) → Abschluss mit
  explizitem PROGRESS/ARCHIVE-Schritt (F-Nummer vergeben, step-done; auf
  Nutzerwunsch eigens betont).
- Modell-Aufruf bewusst erlaubt (kein `disable-model-invocation`): der Skill zieht
  automatisch, wenn der Nutzer einen Kit-Skill bauen/ändern will.
- Projekt-CLAUDE.md: Verweis auf `/add-skill` bei den Strukturregeln;
  Dogfooding-Zyklus um build-step ergänzt.
- Entscheidungen: repo-lokal statt im Plugin (Plugin-Skills werden global
  installiert — Repo-Pflege wäre dort Ballast); CLAUDE.md hält nur Invarianten,
  Prozeduren gehören in Skills (progressive disclosure). Ausbau-Ideen notiert:
  `just new-skill`-Scaffold-Rezept, validate.py-Prüfung „jeder Skill hat eine
  README-Zeile".

## F-008 — Workflow-Skill build-step + autonome Läufe (2026-07-13)

**Was entstanden ist (Plugin 0.5.0):**

- **build-step** — schließt die Lücke der Implementierungsphase (bisher formloses
  „setze F-xxx um"): prep-step-Plan laden, Substeps mit Verifikation je Schritt
  abarbeiten (Write-then-Verify, just-Checks, Abnahmekriterien einzeln gegen
  Tool-Ausgaben abhaken), je Substep Übergabe an step-done. Leitplanken: Plan-Treue,
  Scope-Schutz (Entdeckungen → add-feature statt still mitbauen), nie pushen, keine
  History-Rewrites, PROGRESS-Pflege nur via step-done.
- **Modus `autonom`:** baut nicht, sondern richtet einen `/goal`-Lauf ein (verifiziert
  gegen die Claude-Code-Doku: /goal hält die Session Turn für Turn am Arbeiten, bis
  ein Prüfmodell die Bedingung als erfüllt bewertet; Skills können /goal nicht selbst
  absetzen). Ablauf: Kontext + Plan laden → Voraussetzungen nennen (Trust-Dialog,
  Hooks, Auto-Modus für unbeaufsichtigte Läufe) → einmalige laufbezogene
  Commit-Freigabe einholen → fertige Goal-Zeile ausgeben (Varianten mit/ohne
  Freigabe, Turn-Limit als Stopp-Klausel, ~5 Turns je Substep) → enden; der Lauf
  startet mit dem Absenden der Goal-Zeile durch den Nutzer.
- **Commit-Granularität entschieden:** step-done + Commit je Substep (prep-step
  zerlegt in einzeln lauffähige Substeps = natürliche Commit-Grenzen; Commits sind
  im autonomen Lauf die Checkpoints gegen Entgleisung).
- **step-done erweitert:** Ausnahme-Regel zur Commit-Frage — bei dokumentierter
  laufbezogener Freigabe committen ohne Nachfrage (nach grünen Checks/Scans, nie
  Push); ohne Freigabe im autonomen Lauf Commit-Vorschlag festhalten und
  weiterarbeiten statt auf Antwort blockieren (schließt die Grauzone, in der ein
  Goal-Lauf sonst raten würde).
- **Vorlagen-Sync:** Halbsatz in `templates/global-CLAUDE.md` und (per
  Übernahme-Regel der Vorlage) in der live `~/.claude/CLAUDE.md`: laufbezogene
  Freigabe zählt als Fragen, Push bleibt tabu.
- README: build-step-Zeile, Zyklus-Satz mit drei Implementierungswegen
  (build-step / teach-step / frei + step-done), neue Anleitung „Autonomer Lauf
  (build-step + /goal)".

## F-007 — Workflow-Skill teach-step (2026-07-13)

**Was entstanden ist (Plugin 0.5.0):**

- **teach-step** — Lehrer-Modus für die Implementierungsphase: der Nutzer setzt eine
  Aufgabe (F-Nummer) selbst um, der Skill leitet sokratisch an, gibt gestufte Hilfe
  (Leitfrage → Tipp → Hinweis mit Datei:Zeile → Pseudocode → Musterlösung nur auf
  ausdrückliche Anfrage, erklärt statt zum Kopieren), kontrolliert per `git diff` +
  Re-Lesen und lässt Tests über die just-Rezepte laufen.
- **Schreibverbot zweistufig:** hart via `disallowed-tools: Write, Edit, NotebookEdit`
  im Frontmatter; für Bash per Anweisung (nur lesend/prüfend — keine Redirects, kein
  `sed -i`/`rm`/`mv`, kein `git add`/`commit`). Bitten um Selbst-Implementierung lehnt
  der Skill ab und bietet stattdessen das Beenden des Lehrer-Modus an.
- **Lern-Interview (M1), gemeinsam mit dem Nutzer designt:** (1) Vertrautheit mit
  drei verhaltensverankerten Stufen (Neuland/Grundlagen/Routiniert — jede Option
  nennt, was sie bewirkt), (2) Lernziel mit vier Optionen (Default „Struktur &
  Verdrahtung" — welche Datei wohin, wie Teile verbunden werden; dazu Sprache &
  Syntax, Konzept & Design, Diese Codebase). Der Führungsgrad wird nicht abgefragt,
  sondern abgeleitet (Trittsteine/Wegweiser/Kompass, per Zuruf änderbar);
  Nachkalibrierungs-Regel: Antworten sind Startpunkt, kein Vertrag.
- **Graphiti-Lernprofil (optional):** Level/Themen des Nutzers in der persönlichen
  group_id (Konvention `main`) nachschlagen und fortschreiben — bekannte Antworten
  überspringen das Interview.
- Abgrenzung: PROGRESS-Pflege, Scans und Commit bleiben bei `step-done`; teach-step
  schreibt keine Doku und committet nie.
- Entscheidungen: Platzierung im coding-kit statt eigenem Trainer-Plugin (an
  prep-step/step-done-Workflow gekoppelt; Extraktion später billig). Bash bewusst
  erlaubt, damit der Lehrer Tests laufen lassen kann — Nutzer entschied sich gegen
  das strengere Bash-Verbot.

## F-006 — Utility-Skill refine-prompt (2026-07-13)

**Was entstanden ist (Plugin 0.5.0):**

- **refine-prompt** — übergebenen Prompt analysieren (Ziel, Zielgruppe, Ausgabeformat,
  impliziter Kontext), Schwachstellen benennen (Unklarheiten, fehlende Rollen-/
  Kontextangaben, fehlende Erfolgskriterien), nach Prompt-Engineering-Best-Practices
  neu formulieren und den verbesserten Prompt anschließend ausführen. Ausgabe:
  Schwachstellen → verbesserter Prompt (kopierbar) → Ergebnis.
- Nur manuell aufrufbar (`disable-model-invocation: true`); bei leerem `$ARGUMENTS`
  wird nach dem Prompt gefragt (M1). Kein Projektkontext-/M4-Baustein nötig — der
  Skill fasst nichts im Projekt an.
- Erster Skill der neuen Kategorie **Utility-Skills** (Plugin-Description entsprechend
  erweitert); Skill-Text vom Nutzer ausformuliert, bei der Aufnahme gegen
  `docs/skill-authoring.md` geprüft (Korrekturen: Namespacing `/coding-kit:refine-prompt`,
  M1-Fallback ergänzt).

---

## F-005 — Pflege-Skills (2026-07-07)

**Was entstanden ist (Plugin 0.4.0):**

- **update-conventions** — bidirektionaler Konventions-Sync mit drei Ästen:
  - *Abwärts mit Stempel:* Projekte via Marker-Topic (`gh search repos … topic:coding-kit`)
    plus lokale Checkouts finden; CHANGELOG-Fenster zwischen Stempel und aktueller
    VERSION zeigen; Soll-Fassung jeder managed Datei (Core + Modul-Parts) mit
    rückaufgelösten Projektwerten instanziieren und gegen den Ist-Stand diffen;
    je Datei: übernehmen / so lassen / als Override registrieren / promoten.
    Override-Schutz greift vor dem Diffen (`convention-overrides.md` + Inline-Marker);
    seed-Dateien und public-only-Regeln werden respektiert; Abschluss: Stempel auf neue
    VERSION, `just check` grün, Commit-Frage.
  - *Abwärts ohne Stempel (Altprojekte):* heuristischer Abgleich + Migrationen als
    einzeln bestätigte Schritte — instructions.md→CLAUDE.md, Entfernen lokaler
    Core-Skill-Kopien (nur bei installiertem Plugin; durch den Kollisionstest aus F-001
    abgesichert, projektspezifische Skills bleiben immer), Renovate-Onboarding,
    Tooling-Nachrüstung, abschließend Stempel-Angebot.
  - *Aufwärts („promote"):* projektlokale Änderung generalisieren (Werte → Platzhalter,
    englisch, personendatenfrei) und in den Kern heben — Template-Sync-Invariante im
    selben Commit (VERSION + CHANGELOG + ggf. MANIFEST), danach optional Abwärts-Lauf;
    alternativ Registrierung als Override. Pro Änderung genau eine Entscheidung.
- **check-upstreams** — Watchliste `upstreams.json` im Kit-Repo (bewusst nicht im
  Plugin-Install-Verzeichnis: sie wird geschrieben und committed). Je Eintrag:
  Erstprüfung (Ist-Zustand) oder Folgeprüfung (`gh api compare <ref>...HEAD` +
  Releases), Bewertung gegen den hinterlegten Zweck, Übernahme-Vorschläge (Umsetzung
  via add-feature als F-Nummer), Ref-/Datums-Update nach Bestätigung. /loop-tauglich
  (dann nur berichten).
- **Watchliste initial:** `AlexPEClub/ai-coding-starter-kit` mit Ref auf Analysestand
  (HEAD `21a97bb…`, letzter Push 2026-06-03 — Analyse vom 2026-07-07 deckt ihn ab) und
  `betterleaks/betterleaks` (verifiziert: existiert, MIT, vom gitleaks-Autor;
  gitleaks erhält nur noch Security-Patches) mit `last_checked_ref: null` —
  die Erstprüfung bewertet Reifegrad und Migrationsaufwand für den Scanner-Wechsel.

**Entscheidungen:**

- update-conventions diffe **instanziierte Soll-Fassung vs. Ist** statt
  Drei-Wege-Merge über historische Template-Stände — robuster, und der Stempel
  liefert trotzdem Determinismus (Update-Fenster + CHANGELOG-Kontext).
- Beide Skills `disable-model-invocation: true` — Pflegeläufe startet nur der Nutzer.

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
