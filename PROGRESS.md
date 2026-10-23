# coding-kit — Progress

Lebende Aufgabenliste. **Done-Tabelle** oben, **offene Aufgaben in Ausführungsreihenfolge**
darunter, **Feature-Index** ganz am Ende.

So funktioniert's: `/coding-kit:add-feature` nimmt neue Aufgaben auf (F-Nummer),
`/coding-kit:prep-step` bereitet vor und zerlegt, `/coding-kit:step-done` schließt ab.

---

## Done

| Step | Beschreibung | Fertig |
|------|--------------|--------|
| F-001 | Kit-Grundgerüst → **Plugin (4 Core-Skills, projekterkennender Stop-Hook), Marketplace „xnyzer", Renovate-Preset, Installer, Doku, Validator + CI.** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-07 |
| F-002 | Begleit-Skills → **name-it, choose-license, choose-stack, define-requirements, refine-requirements (Plugin 0.2.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-07 |
| F-003 | /new-project-Orchestrator → **Short-Info → Abfragen → Plan → Instanziierung nach MANIFEST, Trockenlauf-Modus (Plugin 0.3.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-07 |
| F-004 | Globale CLAUDE.md-Vorlage → **templates/global-CLAUDE.md (aktiviert den Installer-Schritt), Legacy-Migration abgeschlossen.** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-07 |
| F-005 | Pflege-Skills → **update-conventions (bidirektional, Override-Schutz, Migrationen) + check-upstreams mit upstreams.json (Plugin 0.4.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-07 |
| F-006 | Utility-Skill refine-prompt → **Prompt analysieren, Schwachstellen benennen, neu formulieren, ausführen (Plugin 0.5.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-13 |
| F-007 | Workflow-Skill teach-step → **Lehrer-Modus: sokratisch angeleitete Eigenumsetzung, hartes Schreibverbot, Lern-Interview + Graphiti-Lernprofil (Plugin 0.5.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-13 |
| F-008 | Workflow-Skill build-step + autonome Läufe → **Implementierungsphase als Skill (plan-treu, Verifikation je Substep, step-done je Substep); Modus `autonom` bereitet /goal-Läufe vor; laufbezogene Commit-Freigabe in step-done + globaler Vorlage (Plugin 0.5.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-13 |
| F-009 | Repo-lokaler Pflege-Skill add-skill → **Prozedur für Anlage/Änderung von Plugin-Skills (`.claude/skills/`, kein Plugin-Inhalt): Authoring-Konvention, Begleit-Änderungs-Checkliste, Abschluss inkl. PROGRESS-Pflege.** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-13 |
| F-010 | Status-Marker-Konvention + schärfere Grenze add-feature/prep-step → **`Status:`-Zeile mit Tokens BACKLOG/PLANNED in PROGRESS-Einträgen, „Lösungsskizze" statt Vorab-Plan in add-feature, prep-step hinterfragt die Skizze gegen den Codestand; Begleitanpassungen in build-step/step-done (Plugin 0.6.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-13 |
| F-011 | build-step vom step-done-Handoff entkoppeln → **interaktiv wird step-done nur empfohlen (Nutzer prüft/schließt selbst ab), nur im autonomen `/goal`-Lauf läuft es je Substep automatisch; Modus-Signal = aktiver /goal-Lauf mit Commit-Freigabe (Plugin 0.7.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-14 |
| F-013 | choose-stack: Multi-Fragment-Einbau → **Modus B hängt Sprachfragment + deklarierte Katalog-Fragmente idempotent an den §13-Slot an (Vertrag: project-template MANIFEST § Standards fragments); Modulwechsel tauscht nur das Sprachfragment, Katalog-Fragmente bleiben; new-project-Referenz nachgezogen (Plugin 0.8.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-19 |
| F-014 | update-conventions: Pro-Fragment-Refresh → **zwei Diff-Ebenen (Core-Datei-Diff mit injiziertem Ist-Slot + Fragment-Abgleich je `fragment:NAME`), fehlende deklarierte Fragmente werden zum Anhängen angeboten, Fragment-Promote in den Katalog (Plugin 0.9.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-19 |
| F-015 | prep-step: Framework-Erkennung mit Fragment-Vorschlag → **Schritt 2a „Standards-Abdeckung" mit Kosten-Gate; matcht Dependency-Signale UND Eigenschafts-Trigger (F-017-Touchpoint miterledigt); Vorschlags-Pfade Anhängen bzw. Autoring + Promote (Plugin 0.10.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-19 |
| F-012 | add-skill: Template-HOW-TO synchron halten → **neuer Checklisten-Haken in Schritt 3: Dev-Loop-/Pflege-Skills pflegen die Skill-Übersicht in project-templates HOW-TO mit (Sync-Invariante jenes Repos); repo-lokal, kein Plugin-Release.** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-19 |
| F-016 | step-done: Standards-Coverage-Backstop → **Schritt 1a, diff-basiert (neue Manifest-Dependencies/Signal-Dateien) mit Katalog-Match zur Laufzeit; Lücke melden + Anhängen vorschlagen, nicht blockierend (Plugin 0.11.0). Zyklus F-013/014/015/016 damit geschlossen.** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-19 |
| F-017 | Eigenschafts-Trigger für Standards-Fragmente → **define-requirements fragt characteristic-Zeilen im Interview ab, new-project komponiert bejahte Fragmente mit, choose-stack rüstet sie auf Bestätigung nach (Plugin 0.12.0). Composable-Standards-Strang komplett.** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-19 |
| F-018 | Konventions-Vererbung nur noch abwärts → **AUFWÄRTS/promote aus update-conventions gestrichen; Ersatz: manuell anstoßbarer Übernahme-Vorschlag (Template-Session-Prompt oder GitHub-Request) an drei Stellen — Sync-Lauf, Fragment-Anlage, step-done-Diff (Plugin 0.13.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-19 |
| F-020 | Sprach-Matrix: granulare Sprachwahl je Projekt → **new-project-Preset-Frage (entkoppelt von Sichtbarkeit), fünf `LANG_*`-Platzhalter, Commit-/Kommentar-Sprache in step-done/build-step, Languages-Block-Migration in update-conventions (prospektiv, nichts rückwirkend übersetzen); Pairing: project-template F-010 (Plugin 0.14.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-19 |
| F-021 | update-conventions: Vollabdeckung aller Template-Dokumente → **seed-Abgleich abschnittsweise je `section:NAME`-Zone (Opt-out, Override, Feature-Detection) + A3-Marker-Migration + Marker-Erhalt in new-project (0.15.0); entfernte/umbenannte Template-Dateien via Stempel-Commit-Auflösung, Rückbau/Umzug je Datei bestätigt (0.16.0). Pairing: project-template F-011.** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-20 |
| F-019 | Pflege-Skill go-public → **geführter, fail-closed Übergang private/lokal → public: vier blockierende Preflight-Gates (Historie-Secrets, Privacy inkl. Commit-Metadaten, Lizenz, private/-Hygiene), Nachzug vor Übergang via update-conventions-Sichtbarkeits-Prämisse, Push nur mit laufbezogener Freigabe (Plugin 0.17.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-07-20 |
| F-022 | Begleithandlungen beim Fragment-Einbau → **`/choose-stack` § Begleithandlungen als einzige Fundstelle (generisch, Fragment-Wissen bleibt im Template), von new-project/prep-step/step-done referenziert; entkoppelt von der Idempotenz-Regel; `update-conventions` prüft zusätzlich bei unverändertem Fragment-Text und erreicht damit als einziger Pfad Bestandsprojekte. Anlass/Pairing: project-template 0.13.1 (F-016), `nextjs`-Fragment (Plugin 0.18.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-08-11 |
| F-028 | Utility-Skill handoff → **kopierfertiger Handoff-Prompt am Kontextlimit: Orientierung zuerst (zuletzt, Stand, als Nächstes inkl. Reihenfolge-Vorgabe der Aufgabenliste), sonst nur Undokumentiertes (Maßstab je Zeile) mit Verweisen auf Quellen; kontextsparsam (keine Rückfrage, max. ein Shell-Aufruf), Schreibverbot inkl. Memory, Ausgabe als ein Codeblock (Plugin 0.19.0).** Details in `PROGRESS-ARCHIVE.md`. | 2026-09-16 |
| F-031 | mise.lock mit Plattform-Einträgen erzeugen → **`/choose-stack` § Lock-Datei erzeugen und prüfen als gemeinsame Mechanik: `mise lock` nach `mise install`, ohne `--platform` (Liste allein aus `lockfile_platforms`), Lücke auf der CI-Runner-Plattform blockiert den Commit; new-project/choose-stack erzeugen und prüfen, `update-conventions` gleicht auch bei aktuellem Stempel ab. Pairing: project-template 0.13.3 (F-020) (Plugin 0.19.1).** Details in `PROGRESS-ARCHIVE.md`. | 2026-10-23 |

---

## Offene Aufgaben — von oben nach unten abarbeiten

### F-038 — Freigabe-Regel für PROGRESS-Einträge kit-weit; add-feature als von Claude aufrufbar klarstellen

**Status:** PLANNED

**Problem:** Ob Claude PROGRESS-Einträge ohne ausdrückliche Freigabe schreiben darf, regelt
jeder Skill für sich: add-feature und prep-step warten auf OK, andere Pfade (add-skill
„spätestens beim Abschluss", step-done) sagen dazu nichts. Gleichzeitig hält Claude
add-feature für nur vom Nutzer startbar, obwohl der Skill seit jeher
`disable-model-invocation: false` trägt — die Texte legen das nahe (build-step: „via
add-feature … vorschlagen", add-feature: „Der Nutzer hat eine Idee …").

**Idee:** Eine kit-weite Regel, die für alle gilt: Claude darf add-feature (und andere
PROGRESS-schreibende Skills) selbst starten, aber jeder neue oder geänderte PROGRESS-Eintrag
wird erst als Vorschau gezeigt und nach ausdrücklichem OK geschrieben. Die Regel ist an
einer Stelle definiert (Authoring-Doku); die Skills tragen sie als einheitlichen Standardsatz.

**Lösungsskizze** (Stand Planung 2026-10-23):
- Konvention in `docs/skill-authoring.md` als Pflicht-Baustein „Freigabe-Gate" mit
  Standardsatz; jeder PROGRESS-schreibende Skill trägt den Satz an seiner Schreibstelle
  (die Doku liegt nicht im Plugin-Cache, Skills können sie zur Laufzeit nicht lesen).
- Geltung: alles, was in `PROGRESS.md`, `PROGRESS-ARCHIVE.md` oder den FEATURE-INDEX
  geschrieben wird — ausgenommen das Schreiben genau des zuvor freigegebenen Texts.
- Bereits gegated (bleiben, wie sie sind): add-feature, prep-step, define-requirements,
  refine-requirements; teach-step, check-upstreams, new-project gehen über diese.
- `step-done`: § 4 zeigt Done-Zeile, Archiv-Eintrag und `(DONE)`-Marker als Vorschau,
  gebündelt mit der Commit-Frage (ein OK für beides, „nur verbuchen" möglich); „Direkt
  tun, ohne zu fragen" entfällt. Reihenfolge: Vorschau → OK → schreiben → Checks → Commit.
- `build-step`: Claude startet add-feature selbst (Entwurf, Freigabe); im autonomen Lauf
  werden neue Ideen nur gesammelt und am Ende vorgeschlagen. Start-Freigabe des Laufs =
  „verbuchen und committen"; ohne sie bleiben PROGRESS- und Commit-Änderungen Vorschläge.
- `add-feature`: Beschreibung und Einleitung sagen, dass Claude ihn selbst starten darf.
- prep-step/build-step bleiben nur manuell startbar (gewollt).
- `templates/global-CLAUDE.md` bleibt unverändert (gilt auch für Projekte ohne Kit).
- Repo-lokaler Teil: Freigabe-Regel in die Kit-CLAUDE.md; `add-skill` ausdrücklich von
  Claude aufrufbar, deckt repo-lokale Skills ab, Freigabe-Pflicht vor PROGRESS-Einträgen;
  Schritt 3 (HOW-TO im Template) vermerkt den Nachzug in F-039, solange project-template
  eingefroren ist.
- Plugin 0.20.0 (Verhaltensänderung), CHANGELOG.

**Abhängigkeiten:** keine. Vor F-039 und F-036 umsetzen (beide laufen dann schon nach der
Regel; F-036 und F-034 bauen auf denselben Skills auf).

#### F-038a — Plugin: Freigabe-Gate und add-feature-Aufruf

**Was:** step-done § 4/§ 6 (Vorschau + Freigabe, gebündelt mit der Commit-Frage),
build-step (add-feature selbst starten, autonom sammeln, Start-Freigabe „verbuchen und
committen"), add-feature (Aufruf durch Claude), `docs/skill-authoring.md`
(Pflicht-Baustein), README (Satz zum Zyklus), plugin.json 0.20.0, CHANGELOG.

**Dateien:** `plugins/coding-kit/skills/{step-done,build-step,add-feature}/SKILL.md`,
`docs/skill-authoring.md`, `README.md`, `plugins/coding-kit/.claude-plugin/plugin.json`,
`CHANGELOG.md`.

**Abnahmekriterien:**
- [ ] `just check` grün.
- [ ] Kein PROGRESS-schreibender Skill schreibt ohne Vorschau (grep über alle
      Schreibstellen belegt).
- [ ] Version-Bump und CHANGELOG im selben Commit.

#### F-038b — Repo-lokal: CLAUDE.md und add-skill

**Was:** Freigabe-Regel in die Kit-CLAUDE.md (Verweis auf die Skills); `add-skill`
ausdrücklich von Claude aufrufbar, repo-lokale Skills mit eigener kurzer Checkliste,
Freigabe-Pflicht in Schritt 0 und 5, Schritt 3 vermerkt HOW-TO-Nachzug in F-039.

**Dateien:** `CLAUDE.md`, `.claude/skills/add-skill/SKILL.md`, `PROGRESS.md` (Vermerk in
F-039).

**Abhängigkeiten:** F-038a.

**Abnahmekriterien:**
- [ ] `just check` grün.
- [ ] `add-skill` erscheint weiter in der Skill-Liste.
- [ ] F-039 trägt den Template-Nachzug (HOW-TO § step-done: Vorschau + Freigabe) —
      nach Freigabe.

---

## Feature-Ideen (Backlog)

_Neue Ideen via `/coding-kit:add-feature` — sie bekommen die nächste F-Nummer._

**Empfohlene Reihenfolge** (Stand 2026-10-23; die Einträge darunter bleiben nach Nummer
sortiert):

1. **F-038** — klein; Freigabe-Regel kit-weit (inkl. `add-skill` und Kit-CLAUDE.md), damit
   die folgenden Sessions schon danach laufen (in Arbeit, siehe „Offene Aufgaben").
2. **F-039** — ein Repo: Template ins Plugin, Version 1.0.0; vor F-036, damit dessen Umbau
   Skills und Vorlage in einem Commit trifft.
3. **F-036** — großer Umbau; alle folgenden Features werden schon mit Spec-Phase und
   Feature-Datei geplant.
4. **F-034 + F-037** — Qualitätsstrang auf dem neuen prep-step/step-done.
5. **F-029 → F-033 → F-030** — Graphiti-Strang (F-030 ohne den `install.sh`-Teil).
6. **F-032 → F-024 → F-026 → F-025** — Host-Strang; F-025 nimmt den `install.sh`-Teil
   von F-030 mit. F-039 nimmt die Template-Teile von F-026/F-032 weitgehend vorweg.
7. **F-027** — sobald ein Windows-Rechner zur Verifikation verfügbar ist, gern mit F-025.

Strang 5 und 6 sind tauschbar: Graphiti-Kosten zuerst oder Betrieb auf anderen Rechnern
bzw. ohne GitHub zuerst.

### F-024 — Commit-Adresse aus der Personal-Config statt hart aus gh

**Status:** BACKLOG

**Problem:** `/step-done` § Autor-Config setzt `git config user.email` unbedingt auf die
GitHub-Noreply-Adresse und ermittelt sie über `gh api user`. Ohne GitHub schlägt die
Ermittlung fehl — und die Regel ist dort auch inhaltlich falsch, weil die Adresse des
eigenen Hosts in die Commits gehört. Das widerspricht der eigenen Kit-Regel, Identität
nicht zu hardcoden.

**Idee:** `CODING_KIT_GIT_NOREPLY_EMAIL` aus der Personal-Config wird zur Quelle der
Wahrheit, `gh api user` nur noch einer von zwei Ermittlungswegen. Fehlt beides, fragt der
Skill statt zu raten.

**Lösungsskizze:**
- Reihenfolge in step-done § Autor-Config: Personal-Config → `gh api user` → fragen; kein
  GitHub-Format mehr erzwingen.
- Gleiche Härte in `templates/global-CLAUDE.md` entschärfen: GitHub-Noreply als Default
  für GitHub-Projekte, Kernaussage bleibt „keine private Adresse".
- Weitere Fundstellen desselben Musters prüfen (u. a. `new-project` 4a) und die
  README-Zeile zum Schlüssel an die neue Rolle anpassen.
- Template-Seite: Die Noreply-Regel steht auch in project-template (`core/CLAUDE.md`,
  `CODING-STANDARDS.md`, `CONTRIBUTING.md`, HOW-TO, `scripts/privacy-lint.sh`) —
  Übergabe nach F-035, gemeinsam mit F-032.

**Abhängigkeiten:** F-032 (Host-Profil bestimmt, welche Noreply-Adresse gilt) — sinnvoll
im selben Zug umzusetzen

### F-025 — install.sh: fehlender gh-Login und Plattform-Abdeckung

**Status:** BACKLOG

**Problem:** `install.sh` setzt GitHub und macOS voraus. Fehlt `gh` oder ist es nicht
angemeldet, bricht er in der ersten Prüfung ab, statt den Login anzubieten oder ohne
GitHub weiterzumachen — obwohl die README einen GitHub-freien Weg beschreibt. Die
Toolchain-Installation kennt nur `brew`; auf Linux ohne Brew und auf Windows bleibt es
bei einer Warnung. Plattform-Erkennung gibt es im Repo nirgends.

**Idee:** Der Installer wird Bootstrap für alle drei Plattformen und auch für Rechner
ohne GitHub: Voraussetzungen werden erkannt und benannt statt zur Abbruchbedingung
gemacht, fehlender Login wird angeboten, und die Toolchain kommt über den Paketmanager
der jeweiligen Plattform.

**Lösungsskizze:**
- Drei `gh`-Zustände unterscheiden (fehlt / vorhanden ohne Login / bereit) statt eines
  harten `fail`: Login anbieten, GitHub-freien Lauf als bestätigte Alternative — dann die
  Personal-Config ohne `gh api`-Vorbefüllung abfragen.
- Lokalen Template-Checkout mit anlegen — `git clone` der öffentlichen URL, braucht kein
  `gh`; für den GitHub-freien Weg der Hebel. Aktualität ist Sache von F-026.
- Plattform bestimmen und Paketmanager wählen: brew auf macOS, apt/dnf/pacman auf Linux,
  winget/scoop auf Windows; prüfen, ob `mise` der plattformneutrale Weg für
  just/lefthook/gitleaks ist und nur mise selbst plattformspezifisch installiert wird.
  Wird kein Paketmanager gefunden: Abbruch mit Hinweis auf die manuelle Installation
  statt stiller Warnung (Toolchain ist der letzte Schritt, alles Übrige ist dann bereits
  eingerichtet).
- Windows: Lauf in einer Bash prüfen und benennen (der Stop-Hook verlangt sie ohnehin);
  Abbruchmeldungen so ausgeben, dass sie beim Start per Dateizuordnung nicht mit dem
  Fenster verschwinden.
- Defaults plattformgerecht wählen — das Projekte-Verzeichnis nicht auf ein englisches
  „Documents" festlegen.
- Zeilenenden sind kein Thema: `.gitattributes` erzwingt `eol=lf` für den ganzen Baum.

**Abhängigkeiten:** F-032 (zentrale Host-Erkennung — Skills und Installer nutzen
dieselbe Antwort auf „welcher Git-Server, welche Fähigkeiten"). Berührung mit
F-026 (F-025 legt den Checkout an, F-026 hält ihn aktuell).

### F-026 — Template-Auflösung: Aktualität, Herkunft und Klontiefe

**Status:** BACKLOG

**Problem:** Die gemeinsame Template-Auflösung (`/choose-stack` § 0, referenziert von
`new-project` und `update-conventions`) hat drei Defekte. **Erstens Aktualität:** sie nimmt
den lokalen Checkout unter `$CODING_KIT_PROJECTS_DIR/project-template`, sobald er
existiert — und kein Skill aktualisiert ihn. `update-conventions` liest dessen `VERSION`
aber als aktuellen Template-Stand und entscheidet daran, ob ein Projekt aktuell ist; ein
veralteter Checkout lässt Projekte fälschlich als aktuell gelten oder verteilt alte
Dateistände, ohne dass es auffällt. **Zweitens Herkunft:** das Template-Repo wird aus dem
aufrufenden GitHub-Konto abgeleitet (`gh api user`). Das trägt nur beim Eigentümer der
Vorlage — fremde Nutzer landen bei einem Repo, das ihnen nicht gehört, und Rechner ohne
`gh` können den Owner überhaupt nicht ermitteln. `CODING_KIT_TEMPLATE_REPO` gibt es, ist
aber ein Override, den man kennen muss. Dasselbe Muster steckt in `check-upstreams` beim
Kit-Repo. **Drittens Klontiefe:** der Ersatzpfad klont mit `--depth 1`, während die
Stempel-Auflösung die `VERSION`-Historie durchgeht — mit Shallow-Klon nicht möglich.

**Idee:** Der Live-Stand ist die Regel, der lokale Checkout die Ausnahme für Offline-
Betrieb und für die Arbeit am Template selbst. Die Herkunft steht fest, statt aus dem
Konto des Aufrufers zu folgen, und der benutzte Stand wird im Lauf immer benannt.

**Lösungsskizze:**
- Live zuerst: bei erreichbarem Netz gegen den aktuellen Stand arbeiten; der lokale
  Checkout greift, wenn offline oder wenn ausdrücklich der lokale Stand gemeint ist.
- Herkunft ohne Account-Ableitung: Kette `CODING_KIT_TEMPLATE_REPO` → kanonische
  Upstream-Quelle → optional eigener Fork. Die kanonische Quelle gehört deklariert (der
  Marketplace nennt seine Quelle ebenso), nicht aus `gh api user` erraten — analog für das
  Kit-Repo in `check-upstreams`.
- Ohne `gh` nutzbar: für ein öffentliches Repo genügen `git clone`/`git fetch` der URL.
- Aufgelöste `VERSION` und Herkunft (live oder offline mit Datum) im Lauf benennen.
- Lokale Änderungen oder divergierte Historie im Checkout nicht still übergehen — melden
  und bestätigen lassen.
- Klontiefe am Bedarf ausrichten: die Stempel-Auflösung braucht `VERSION`-Historie.

**Abhängigkeiten:** F-032 (Herkunft und Clone-Weg hängen am Host-Profil) — sinnvoll
zusammen mit F-025. Berührung mit F-035 (Übergaben gehen in den lokalen
Arbeits-Checkout, nicht an den Live-Stand).

**Noch zu analysieren:**
- Wie erkennt ein Lauf „ich arbeite gerade am Template" — expliziter Schalter oder
  Folgerung aus einem dirty bzw. abweichenden Checkout? F-035 braucht genau diesen
  Fall — Lösung abstimmen.
- Bleibt die Personal-Config der Ort für den Override, oder gehört die kanonische Quelle
  in eine Plugin-Datei?

### F-027 — Stop-Hook plattformfähig machen (Windows greift ins WSL)

**Status:** BACKLOG

**Problem:** `hooks.json` startet den Stop-Hook als
`bash "${CLAUDE_PLUGIN_ROOT}/hooks/stop-reminder.sh"`. Unter Windows wurde beobachtet,
dass der Hook nicht funktioniert; wahrscheinliche Ursache ist das `bash.exe` in
`System32`, das den WSL-Start auslöst — der Hook landet damit in einer Umgebung, in der
der übergebene Windows-Pfad nicht auflösbar ist. Auf Windows fällt damit die einzige
Erinnerung an `/step-done` aus, und ein fehlschlagender Hook erzeugt womöglich bei jedem
Stopp Lärm, statt still zu bleiben.

**Idee:** Der Einstiegspunkt darf sich nicht auf ein nacktes `bash` aus dem PATH
verlassen. Auf Windows wird die Bash der Git-Installation gezielt aufgelöst — git ist für
den Hook ohnehin Voraussetzung. Schlägt die Auflösung fehl, bleibt der Hook stumm statt
zu scheitern.

**Lösungsskizze:**
- Ursache auf einem Windows-Rechner bestätigen, bevor gebaut wird (WSL-Treffer oder
  anderer Grund).
- Prüfen, welche Plattformweichen `hooks.json` erlaubt (Doku zur Laufzeit lesen); sonst
  muss der Einstiegspunkt selbst die Shell bestimmen.
- Auf Windows die Git-Bash auflösen statt `System32\bash.exe` zu treffen.
- Das Skript bleibt inhaltlich unverändert — es ist bereits POSIX-kompatibel, das Problem
  ist der Interpreter.
- Stillschweigen im Fehlerfall wahren: keine Ausgabe, wenn keine passende Shell gefunden
  wird.
- Verifikation gehört auf einen echten Windows-Rechner; auf macOS und Linux ist nur
  Nicht-Regression prüfbar.

**Abhängigkeiten:** keine. Thematische Nähe zu F-025 (Plattform-Abdeckung), aber anderer
Gegenstand: Plugin-Inhalt statt Installer.

---

### F-029 — Graphiti-Schreibzugriffe auf Server-LLM-Kosten optimieren

**Status:** BACKLOG

**Problem:** Die Skills schreiben häufig und ohne gemeinsame Regel in Graphiti — dasselbe
Feature landet bei Aufnahme, Abschluss und Spec-Änderung jeweils als eigene Episode, oft
als ausführliche Prosa mit vielen beiläufigen Nennungen. Jede Episode löst auf dem
Graphiti-Server eine Kette von Extraktions-, Dedup- und Auflösungsschritten im
angebundenen LLM aus; der Verbrauch dort ist entsprechend hoch. Der Informationsgehalt
im Graph soll dabei nicht sinken — er dient als schnelle Alternative zur Repo-Suche und
spart so Entwicklungs-Tokens.

**Idee:** Eine zentrale Graphiti-Konvention, auf die alle Skills verweisen: weniger, dafür
gezielt geschnittene Episoden mit gesteuerter Extraktion, sodass der Server pro
gespeichertem Fakt weniger LLM-Arbeit leistet. Überholtes regelt der Graph selbst über
seine Zeitstempel — kein manuelles Löschen.

**Lösungsskizze:**
- Erst auswerten, dann ändern: Die Messung pro LLM-Call und Pipeline-Schritt läuft
  serverseitig; nach ein bis zwei Wochen Daten entscheiden — bis dahin keine
  Skill-Änderungen auf Verdacht. Die Vergleichsbasis beginnt erst mit einem
  serverseitigen Fix am 09.10.2026; ältere Werte stammen aus einer anderen
  Kostenstruktur und sind nicht vergleichbar.
- Arbeitshypothese: Stärkster Hebel ist die Zahl der Entitäten, die eine Episode
  erwähnt — jede kostet einen eigenen Attribut-Call plus Abgleich gegen den Graph.
  Die Episodenlänge wirkt nur indirekt (mehr Text → mehr Entitäten).
- Entitäten-Rauschen senken: Dateipfade, Funktionsnamen, Test-IDs und F-Nummern, die
  nicht Thema der Episode sind, nicht als eigene Entitäten entstehen lassen — im Text
  dürfen sie für die Suche stehen bleiben, wenn die Extraktion sie überspringt.
- Extraktion steuern: kurze `custom_extraction_instructions` (z. B. „einzelne
  Dateipfade und Test-IDs nicht als eigene Entitäten, außer sie sind das Thema") und
  `excluded_entity_types` testen; für einzelne, klar umrissene Fakten `add_triplet`
  statt freier Extraktion. Wirkung jeweils vorher/nachher messen.
- Episoden pro Arbeitsschritt zählen: mehrere Episoden eines Schritts zusammenfassen,
  dabei etwa 2.000–3.000 Zeichen pro Episode nicht deutlich überschreiten (sonst
  droht Abbruch der Extraktion).
- Ein Schreibanlass pro Feature statt mehrerer (z. B. nur beim Abschluss); andere Skills
  schreiben nur bei echten Entscheidungen. Mit F-036 liegt das Detail in der
  Feature-Datei — der Graph bekommt eine knappe Zusammenfassung mit Verweis statt
  ausführlicher Prosa, also weniger Entitäten.
- `reference_time` setzen, wo vergangene Ereignisse beschrieben werden, damit die
  zeitliche Auflösung ohne Nacharbeit stimmt; `update_communities` bleibt aus.
- Globale CLAUDE.md-Vorlage anpassen: Löschanweisung streichen, Splitting-Regel
  überdenken, auf die zentrale Konvention verweisen.
- Betroffen: alle Skills mit Graphiti-Schreibzugriff, `docs/skill-authoring.md`,
  Vorlage der globalen CLAUDE.md.

**Noch zu analysieren:**
- Welchen Anteil die Kit-Skills am Gesamtverbrauch haben, verglichen mit Schreibern
  außerhalb des Kits — bestimmt, wie viel F-029 überhaupt bewirken kann.
- Ob die Entitäten-Hypothese hält und was daraus folgt (weniger Entitäten, weniger
  Episoden, kürzer).
- Wie viele Entitäten die Kit-Skills heute pro Episode erzeugen und welcher Anteil
  davon Rauschen ist.
- Ob übersprungene Entitäten die Auffindbarkeit im Graph spürbar verschlechtern —
  der Graph soll die Repo-Suche weiterhin ersetzen können.
- Wo die zentrale Konvention liegt, damit Plugin-Skills sie zur Laufzeit erreichen.

**Abhängigkeiten:** Auswertung der serverseitigen Kostenmessung (extern, ein bis zwei
Wochen Daten). F-036 — erst danach umsetzen, sonst werden Skills optimiert, die F-036
ohnehin umschreibt.

---

### F-030 — Graphiti-Episodenverlust erkennen und wiederherstellbar halten

**Status:** BACKLOG

**Problem:** `add_memory` meldet nur „queued" — ob eine Episode wirklich im Graph
ankommt, sieht der Skill nicht. Episoden, die der Graphiti-Server verliert, werden nie
erneut verarbeitet; wiederherstellen lassen sie sich nur aus den lokalen
Claude-Code-Transkripten. Die löscht Claude Code standardmäßig nach 30 Tagen — danach
ist ein Verlust endgültig.

**Idee:** Zwei Teile: Das Kit setzt die Aufbewahrungsdauer der Transkripte auf jedem
Rechner hoch (Empfehlung: 365 Tage), und ein Skill prüft an passender Stelle, ob die
zuletzt geschriebenen eigenen Episoden angekommen sind.

**Lösungsskizze:**
- Erfolgskontrolle: z. B. zu Sessionbeginn oder in `step-done` die letzten Episoden der
  Gruppe abrufen und mit den zuletzt geschriebenen abgleichen; Fehlendes melden (nicht
  automatisch nachschreiben). Leseaufrufe kosten keine Extraktion.
- `cleanupPeriodDays` in den Nutzer-Settings von Claude Code setzen — über `install.sh`,
  ohne bestehende Settings zu überschreiben (vorhandenen Wert respektieren oder
  nachfragen).
- Schlüssel und Default zur Laufzeit gegen die aktuelle Claude-Code-Doku prüfen.
- In der globalen CLAUDE.md-Vorlage bzw. README kurz begründen, warum der Wert gesetzt
  wird.
- Speicherbedarf der Transkripte bei längerer Aufbewahrung im Blick behalten.

**Abhängigkeiten:** keine. Thematische Nähe zu F-029 (Graphiti). Den
`install.sh`-Teil (`cleanupPeriodDays`) zusammen mit F-025 bauen.

### F-032 — Host-unabhängiger Betrieb (ohne GitHub, andere Git-Server, nur Git)

**Status:** BACKLOG

**Problem:** Das Kit setzt GitHub voraus: `gh` bzw. `gh api user` steckt im Installer,
in `new-project` (Repo-Anlage, Settings, Topics, Autor-Config), `step-done`
(Noreply-Pflicht), `update-conventions` (Topic-Discovery, Template-Issue), `go-public`,
`name-it`, `check-upstreams` und `choose-stack`; dazu das Renovate-Preset (`github>…`)
und die CI unter `.github/`. Ohne GitHub-Konto — oder mit GitLab, Forgejo/Gitea,
Bitbucket, Azure DevOps, Codeberg, einem eigenen Server oder einem Bare-Repo auf
Platte/NAS — scheitern Skills an `gh`, statt den Schritt auszuweisen. Nimmt F-023
(new-project ohne GitHub) vollständig auf; dessen offene Frage „zentral oder lokal
erkennen" ist hiermit entschieden: zentral.

**Idee:** Ein zentrales Host-Profil beschreibt, welcher Git-Server im Spiel ist und
welche Fähigkeiten er bietet (Repo anlegen, Repo-Settings, Topics/Discovery, Issues,
Noreply-Adresse, Renovate, CI). Skills fragen Fähigkeiten ab statt `gh` aufzurufen;
fehlt eine, wird der Schritt ausgewiesen übersprungen, nicht durch Fehlschlag. Die
unterste Stufe „nur Git" (Bare-Repo oder gar kein Remote) muss immer vollständig
tragen.

**Lösungsskizze:**
- Host-Profil in der Personal-Config (Typ, CLI, Basis-URL) mit Erkennung aus dem
  Remote als Vorschlag; eine Stelle beschreibt die Fähigkeiten je Host, die Skills
  referenzieren sie — keine `gh`-Aufrufe mehr verstreut in den Skills.
- Host-Klassen nach Recherche: gehostet (GitHub, GitLab.com, Bitbucket Cloud, Azure
  DevOps, Codeberg, SourceHut), selbst gehostet (GitLab CE/EE, Forgejo, Gitea, Gogs,
  OneDev, Bitbucket Data Center, Gerrit), minimal/lokal (Bare-Repo via `file://`/SSH,
  Gitolite, Soft Serve, `git daemon`), Peer-to-Peer (Radicle). CLIs je nach Host
  (`gh`, `glab`, `tea`, `fj`/`berg`, `az repos`) — Pflegestand zur Planungszeit prüfen.
- `new-project` lokaler Bootstrap (aus F-023): Template-Checkout kopieren, `git init`,
  Autor-Config aus der Personal-Config; Repo-Settings/Topics nur, wo der Host sie kann
  — Discovery trägt sonst der `.claude/template-version`-Stempel. README-Abschnitt
  „Ohne GitHub" auf den Skill-Pfad umstellen.
- Renovate: offiziell Azure, Bitbucket (Cloud/Server), Forgejo, Gitea, GitHub, GitLab;
  Gerrit und `local` experimentell. Preset-Referenz je Host klären.
- CI: GitHub Actions, Forgejo/Gitea Actions (weitgehend kompatibel), GitLab CI,
  Woodpecker, Bitbucket Pipelines, Azure Pipelines — Template-Seite betroffen
  (Übergabe nach F-035).
- Der GitHub-Request im Übernahme-Vorschlag (`update-conventions`) entfällt ggf. durch
  das Inbox-Format aus F-035 — eine `gh`-Abhängigkeit weniger.
- Template-Seite neben CI und Renovate: die Noreply-Regel in den Vorlagen (siehe
  F-024) — eine gemeinsame Übergabe.
- Publishing-Hygiene: Basis-URLs und Hostnamen selbst gehosteter Server sind privat —
  nur in der Personal-Config, nie im Repo oder in der lebenden Doku; Credentials
  bleiben im Store der jeweiligen CLI.

**Abhängigkeiten:** F-035 (Template-Gegenstücke laufen als Übergabe). F-024, F-025 und
F-026 bauen auf der Host-Erkennung auf.

**Noch zu analysieren:**
- Welche Hosts in der ersten Ausbaustufe voll unterstützt werden (Vorschlag: GitHub,
  Forgejo/Gitea, GitLab, „nur Git"), welche nur als „nur Git" laufen.
- Liefert das Template mehrere CI-Varianten, oder wählt `new-project` je Host eine?
- Lässt sich die Arbeit sinnvoll in Substeps schneiden (Profil + Erkennung → Skills je
  Fähigkeit → Installer/Template)?

### F-033 — Betrieb ohne Graphiti absichern

**Status:** BACKLOG

**Problem:** Graphiti ist in den Skills bereits weitgehend optional („ohne MCP still
überspringen"), aber nie systematisch geprüft. Zudem geht Wissen, das sonst in den Graph
gegangen wäre (Entscheidungen, gelöste Probleme, Lernprofil), ohne Graphiti ersatzlos
verloren.

**Idee:** Ein Audit stellt sicher, dass jeder Skill, der Installer und die Vorlagen ohne
Graphiti vollständig laufen. Optional bekommt das Kit einen Ersatzweg für das Wissen,
das sonst im Graph landet.

**Lösungsskizze:**
- Alle Graphiti-Stellen (Skills, globale Vorlage, Template-Block, README) auf harte
  Kopplung prüfen — auch impliziten Text wie „erst den Graph fragen".
- Ersatz nur für Wissen ohne eigenen Ort: Entscheidungen, Nicht-Ziele und offene Fragen
  tragen nach F-036 Feature-Dateien und ADRs. Übrig bleiben u. a. das Lernprofil von
  `teach-step` (lebt heute nur im Graph) und Infra-Fakten — dafür
  Claude-Code-Auto-Memory, eine Datei unter `private/` oder bewusst kein Ersatz, dann
  dokumentiert.
- Der Graphiti-Block der CLAUDE.md-Vorlage in project-template ist mitbetroffen —
  Übergabe nach F-035.

**Abhängigkeiten:** F-036 (übernimmt den Großteil des Ersatzwegs). Thematische Nähe zu
F-029/F-030 (Graphiti) und F-032 (gleicher Grundsatz: optionale Infrastruktur wird
ausgewiesen übersprungen).

---

### F-034 — Senior-Maßstab in den Bau-Skills (Lesbarkeit, keine Workarounds, Secure Coding)

**Status:** BACKLOG

**Problem:** Der inhaltliche Maßstab steht in der `CODING-STANDARDS.md` des Templates,
die Bau-Skills wenden ihn aber nicht aktiv an: `build-step` liest die Datei nur
(„falls vorhanden"). Qualität wird erst nachträglich in `step-done` geprüft, ohne
CODING-STANDARDS gibt es gar keine Messlatte, und im autonomen `/goal`-Lauf fehlt eine
Regel für den Fall, dass die saubere Lösung nicht im Plan liegt.

**Idee:** Die Bau-Skills arbeiten durchgängig wie ein Senior-Entwickler. Sie wählen die
einfachste tragfähige Lösung, schreiben Code, den der Nächste beim Ändern versteht
(keine verschachtelten Schleifen oder cleveren Ketten), bauen keine Workarounds und
sichern jeden Substep auch auf Secure Coding ab. Die Skills regeln den Prozess, den
Inhalt regelt die `CODING-STANDARDS.md`.

**Lösungsskizze:**
- `build-step`: aktive Qualitäts-Leitplanke. Selbst-Review je Substep, bevor er als
  fertig gemeldet wird: verständlich, einfach, sicher. Workaround-Stopp: Ist die saubere
  Lösung im Plan nicht machbar, anhalten und melden statt Hack (autonom: Lauf stoppen).
- Knapper Ersatz-Maßstab für Projekte ohne `CODING-STANDARDS.md` (Kernprinzipien,
  kein Duplikat der Vorlage).
- `teach-step`, `prep-step` (einfachstes Design planen, Security-Punkte je Substep
  benennen) und `step-done` (Review-Kriterien Verständlichkeit und Secure Coding)
  konsistent nachziehen.
- Inhaltliche Lücken der Vorlage (Lesbarkeit vor Cleverness, Secure Coding über Secrets
  hinaus) laufen als eigener Eintrag in project-template; Bestandsprojekte erhalten sie
  über `/update-conventions`.

**Abhängigkeiten:** F-036 — schreibt prep-step und step-done grundlegend um, deshalb
erst danach (sonst doppelte Arbeit); zusammen mit F-037 umsetzen. Gegenstück:
project-template F-021 (Inhalte der CODING-STANDARDS-Vorlage) — Paarungsprüfung nach
F-035.

---

### F-036 — Dokumentmodell neu: Feature-Dateien statt Übergangs-Artefakt

**Status:** BACKLOG

**Problem:** Anforderungen leben doppelt und laufen auseinander. `define-requirements`
schreibt die Kern-Features in die `REQUIREMENTS.md` und zugleich als F-Nummern in die
`PROGRESS.md`; die Auflösung der REQUIREMENTS.md (alles überführt, keine offene
Produktfrage, Nutzer bestätigt) wird praktisch nie erreicht, die Überführung in
CLAUDE.md, ADRs und PROGRESS bleibt Handarbeit. Zugleich fehlt je Feature eine
gründliche Spezifikation: Edge-Cases, prüfbare Abnahmekriterien, Testfälle,
Nicht-Ziele und offene Fragen werden nirgends verlangt, und die PROGRESS.md wächst
mit jedem Eintrag weiter.

**Idee:** Jede Information wird sofort an ihren endgültigen Ort geschrieben, ein
Übergangs-Dokument entfällt. Projektweites (Ziele, Nicht-Ziele, Constraints) landet in
der Projekt-CLAUDE.md, Grundsatzentscheidungen als ADR, jedes Feature in einer eigenen
Datei `features/F-NNN-….md`, die über seinen ganzen Lebenszyklus wächst: Erfassung,
Spezifikation, Plan, Abweichungen beim Bau, Abnahme. Die `PROGRESS.md` wird zur reinen
Übersicht. Vorbild: der Spec-Workflow aus AlexPEClub/ai-coding-starter-kit (Interview
eine Frage je Runde mit Empfehlung, Abnahmekriterien im Given/When/Then-Muster,
Out of Scope mit Verweisen, Entscheidungsprotokoll, offene Fragen als Checkboxen).

**Lösungsskizze:**
- `REQUIREMENTS.md` entfällt. `define-requirements` legt nur die Feature-Landkarte an
  (je Feature eine schlanke Datei mit Status BACKLOG + Übersichtszeile) und schreibt
  Projektweites direkt in CLAUDE.md bzw. ADRs; die Detail-Spec entsteht erst kurz vor
  dem Bau.
- `add-feature` legt die Feature-Datei an (Problem, Idee, Skizze), `prep-step` baut sie
  in zwei Phasen aus: Spezifikation per Interview (Edge-Cases, Abnahmekriterien,
  Testfälle, Nicht-Ziele, offene Fragen, Entscheidungen), dann Technik-Plan; Tiefe
  skaliert mit Klein/Mittel/Groß. `build-step` ergänzt Abweichungen, `step-done` hängt
  die Abnahme an und schließt ab — die Feature-Datei ersetzt den Archiv-Eintrag.
- Die Vorlage der Feature-Datei liegt in project-template (entschieden 2026-10-23:
  Inhalt im Template, Prozess im Kit), kommt per `update-conventions` in die Projekte
  und wird von den Skills zur Laufzeit gelesen — kein Duplikat im Kit.
- Übersicht bleibt knapp: Erledigtes ist dort nur ein Haken (F-Nummer, Titel, Datum),
  höchstens mit kurzem Kommentar, wenn ihn jemand beim Überfliegen braucht (offene
  Lücke, Folge-F-Nummer, Release-Version) — keine Zusammenfassungen; die stehen in der
  Feature-Datei. Anlass: Done-Tabellen in Projekten wachsen heute je Aufgabe um einen
  Absatz. Die Migration bietet an, bestehende lange Done-Zeilen zu kürzen.
- `refine-requirements` arbeitet auf CLAUDE.md, Feature-Dateien und ADRs; der
  Auflöse-Mechanismus fällt weg. Nicht-Ziele der Spec speisen den Scope-Schutz in
  `build-step`.
- Übrige Skills mit PROGRESS-/REQUIREMENTS-Bezug nachziehen (u. a. new-project,
  handoff, teach-step, audit-code); Konsistenzprüfung Übersicht ↔ Feature-Dateien als
  Check-Kandidat für `just check`.
- Bestandsprojekte: `update-conventions` bietet eine einmalige Migration an
  (REQUIREMENTS.md und offene PROGRESS-Einträge auf die Zielorte verteilen, Diff und
  Bestätigung je Datei); bestehende `PROGRESS-ARCHIVE.md` bleibt eingefroren.
- Eigene PROGRESS beider Repos (coding-kit, project-template) erst in der Release-Phase
  umstellen — nach Push und Plugin-Update, mit der neuen Migration (zugleich erster
  Praxistest). Vorher arbeiten alle Sessions mit dem installierten alten Plugin, das die
  neue Struktur nicht kennt (entschieden 2026-10-23).

**Noch zu analysieren:**
- Name und Ort der Übersicht (`PROGRESS.md` behalten spart Migration) und ob der
  FEATURE-INDEX-Kommentar in der Übersichtstabelle aufgeht.
- Projektweite Inhalte in CLAUDE.md oder eigener Produktdatei — Schwelle, ab der
  ausgelagert wird.
- Status an einer Stelle oder an zweien (Datei-Kopf + Übersicht).

**Abhängigkeiten:** F-035 — das Template-Gegenstück (Vorlage der Feature-Datei,
Vorlagen PROGRESS/REQUIREMENTS/CLAUDE/HOW-TO/README, ADR-README, MANIFEST inkl.
Seed-Sections) läuft als Übergabe in die Inbox von
project-template, DONE erst nach grüner Paarungsprüfung. Berührt dieselben Skills wie
F-034 (prep-step, step-done) — F-034 folgt danach. Entlastet F-029 und F-033.

---

### F-037 — Unabhängiges Review in step-done (Reviewer mit frischem Kontext)

**Status:** BACKLOG

**Problem:** Das Review in `step-done` macht derselbe Kontext, der den Code geschrieben
hat. Er kennt jede Begründung und neigt dazu, seine eigenen Entscheidungen zu
bestätigen. Im autonomen `/goal`-Lauf prüft zwischen den Substeps zudem kein Mensch.

**Idee:** Nach grünen Checks prüft ein separater Agent ohne Schreibrechte den Diff mit
frischem Kontext. Er bekommt bewusst nur F-Nummer, Diff, Feature-Spec und
CODING-STANDARDS, keine Zusammenfassung vom Bauen. Er prüft gegen die Spezifikation:
Abnahmekriterien erfüllt, Edge-Cases behandelt, nichts aus „Out of Scope" berührt;
dazu Security und Lesbarkeit.

**Lösungsskizze:**
- Eigene Agent-Definition im Plugin mit gesperrten Schreib-Tools (analog teach-step);
  ob Plugins Agents mitliefern können, zur Umsetzungszeit gegen die aktuelle Doku
  prüfen. Der eingebaute `/code-review` reicht nicht, weil er die Spec nicht kennt.
- Neuer Schritt in `step-done` nach den grünen Checks, vor Secrets-Scan und Commit;
  Haupt-Agent bewertet jeden Befund (beheben oder mit Begründung verwerfen), der
  Nutzer sieht die Liste.
- Nach Größe staffeln: Klein ein oder kein Reviewer, Mittel/Groß zwei parallel
  (Korrektheit gegen Spec; Security + Lesbarkeit). Token-Kosten im Blick behalten.
- Gleiches Muster wie der Paarungs-Prüfer aus F-035 (frischer Kontext, ohne
  Schreibrechte) — Wiederverwendung bei der Planung prüfen.

**Abhängigkeiten:** F-036 (Feature-Spec als Prüfgrundlage; ohne sie nur Prüfung gegen
den PROGRESS-Eintrag). Zusammen mit F-034 umsetzen — dessen Review-Kriterien
(verständlich, einfach, Secure Coding) sind der Prüfmaßstab des Reviewers.
Template-Seite: HOW-TO-Abschnitt „What `/step-done` does in detail" um den Review-Schritt
ergänzen — Übergabe nach F-035.

---

### F-039 — Ein Repo: project-template ins Plugin, gemeinsame Version 1.0.0

**Status:** BACKLOG

**Problem:** Kit-Skills und Template hängen über einen textuellen Vertrag zusammen
(MANIFEST-Abschnitte, Marker, Platzhalter, Pfade), leben aber in zwei Repos mit eigener
PROGRESS, eigener Version und eigenem CHANGELOG. Gepaarte Änderungen brauchen zwei Commits,
Einträge vermischten sich, und der Vertrag driftete unbemerkt (der Kit-Validator führt noch
`LIVING_DOC_LANGUAGE`, das das Template in 0.10.0 gestrichen hat, und kennt die
`LANG_*`-Platzhalter nicht). Zudem legt `new-project` Repos aus dem GitHub-Stand des
Templates an, liest MANIFEST aber aus dem lokalen Checkout.

**Idee:** Das Template wird Teil des Plugins (`plugins/coding-kit/template/`), kommt mit
`claude plugin update` zum Nutzer und wird über `${CLAUDE_PLUGIN_ROOT}/template` gelesen.
Ein Repo, eine PROGRESS, ein Archiv, ein CHANGELOG, eine Version, ein Commit je Änderung;
ein Validator prüft den Vertrag zwischen Skills und Template mechanisch. project-template
wird danach archiviert.

**Entschieden (2026-10-23):**
- Unabhängige Architektur-Prüfung (Status quo, Übergabe, Kit führt, Monorepo) → Monorepo
  mit Template im Plugin-Ordner; ersetzt F-035.
- Cache-Test bestanden: Plugin-Cache byte-identisch zur Quelle inkl. Punkt-Dateien
  (`core/.github`, `core/.claude`, `.gitignore`, `.editorconfig` …) und Ausführungsrechten;
  Template-Dateien werden nicht als Plugin-Komponenten geladen; ein Update legt je Version
  einen frischen Ordner an.
- Repo bleibt `coding-kit` mit Historie (Marketplace `coding-kit@xnyzer` und Renovate-Preset
  `github>xnyzer/coding-kit` hängen am Namen). Template-Historie wird mit Pfad-Umschreibung
  importiert, damit `update-conventions` alte Stempel weiter auflöst.
- Eine Version für alles, Start bei 1.0.0 (über Plugin 0.19.1 und Template 0.16.0).
  Stempel unter 1.0.0 gehören zur alten Template-Reihe. Bestehende Projekte brauchen keine
  Migration. Ohne Template-Änderung seit dem Stempel setzt `update-conventions` nur den
  Stempel neu.
- Dokumente zusammenführen, kein Archivordner:
  - eine `PROGRESS.md`: Done-Tabelle leer (jede alte Done-Zeile hat einen Archiv-Eintrag),
    offene Einträge behalten ihre Nummer und werden auf das neue Modell umgeschrieben,
    `next-feature` läuft weiter.
  - ein `PROGRESS-ARCHIVE.md`: beide Archive chronologisch gemischt; Kit-Einträge ohne
    Kennzeichen, Template-Einträge als `TPL-NNN` (kein „F-", damit Suchen eindeutig
    bleiben); Kopf erklärt das Schema. Verweise umschreiben (Template-Archiv ~90,
    Kit-Archiv 4, Kit-PROGRESS 7), ebenso in den importierten Template-Commit-Messages.
    TPL-Einträge nicht in den FEATURE-INDEX.
  - ein `CHANGELOG.md` unter `plugins/coding-kit/` (muss im Cache liegen): ab 1.0.0,
    darunter eingefroren „coding-kit-Plugin bis 0.19.1" und „project-template bis 0.16.0";
    alte Stempel lesen nur den Template-Abschnitt.
- `new-project` legt ein leeres Repo an und schreibt nur die MANIFEST-Ziele hinein
  (kein `--template`, kein Aufräumen).
- project-template: letzter Push vor dem Kit-Push (Kit 0.19.1 braucht Template 0.13.3 auf
  GitHub), danach eingefroren; Archivierung erst nach Release 1.0.0 und Gegenprüfung, mit
  README-Hinweis; lokaler Checkout bleibt bis dahin.

**Lösungsskizze:**
- Template-Inhalt (`core/`, `modules/`, `MANIFEST.md`, `VERSION`) nach
  `plugins/coding-kit/template/`; Repo-eigene Template-Dateien entfallen bzw. gehen im
  Kit auf.
- `choose-stack` § 0: Template = `${CLAUDE_PLUGIN_ROOT}/template` plus Override für die
  Arbeit am Template; Template-Klon über `gh` entfällt. Folgen in allen Skills, die § 0
  referenzieren; `new-project`, `update-conventions` (Stempel-Auflösung, Update-Fenster,
  Übernahme-Vorschlag an eine Kit-Session), `check-upstreams`, `go-public` prüfen.
- Validatoren zusammenführen: Template-Checks plus Vertrags-Checks (Platzhalter-Registry
  aus MANIFEST, in Skills genannte Marker/Abschnitte/Pfade existieren, `manifest-format`
  stimmt); Sync-Invariante als Pre-Commit-Check.
- CLAUDE.md, README, CONTRIBUTING, `docs/` auf ein Repo umstellen (`template/**` Englisch);
  `add-skill` Schritt 3 (HOW-TO-Pflege) wird zur Änderung im selben Commit; Renovate darf
  Template-Pins nicht ohne Versions-Bump ändern.
- Vor dem Release lokal mit `claude --plugin-dir plugins/coding-kit` testen.
- Abschluss: Release 1.0.0, ein Projekt per `/update-conventions` gegenprüfen,
  project-template archivieren (README-Hinweis), lokalen Checkout danach entfernen.

**Noch zu analysieren:**
- Form des Overrides für die Arbeit am Template (Env-Variable oder `--plugin-dir`).
- Stempel-Auflösung ohne Git-Historie im Plugin-Cache: Marketplace-Klon nutzen oder eine
  deklarierte Tabelle entfernter/umbenannter Dateien im MANIFEST.
- Funktioniert `gh repo create --template` mit einem archivierten Repo noch (Plugins bis
  0.19.1)? Zum Zeitpunkt prüfen.
- Schnitt in Substeps.

**Abhängigkeiten:** F-038 (klein, vorher). Ersetzt F-035. Vor F-036 umsetzen. Berührt F-026
und F-032 — deren Template-Teile entfallen weitgehend, bei der Planung abgleichen.

---

<!-- FEATURE-INDEX
next-feature: F-040
F-001 Kit-Grundgerüst (DONE)
F-002 Begleit-Skills (DONE)
F-003 /new-project-Orchestrator (DONE)
F-004 Globale CLAUDE.md-Vorlage (DONE)
F-005 Pflege-Skills (DONE)
F-006 Utility-Skill refine-prompt (DONE)
F-007 Workflow-Skill teach-step (DONE)
F-008 Workflow-Skill build-step + autonome Läufe (DONE)
F-009 Repo-lokaler Pflege-Skill add-skill (DONE)
F-010 Status-Marker + Grenze add-feature/prep-step (DONE)
F-011 build-step vom step-done-Handoff entkoppeln (DONE)
F-012 add-skill: Template-HOW-TO synchron halten (DONE)
F-013 choose-stack: Multi-Fragment-Einbau (DONE)
F-014 update-conventions: Pro-Fragment-Refresh (DONE)
F-015 prep-step: Framework-Erkennung mit Fragment-Vorschlag (DONE)
F-016 step-done: Standards-Coverage-Backstop (DONE)
F-017 Eigenschafts-Trigger für Standards-Fragmente auswerten (DONE)
F-018 Konventions-Vererbung nur noch abwärts (DONE)
F-019 Pflege-Skill go-public (Projekt nachträglich public-ready) (DONE)
F-020 Sprach-Matrix: granulare Sprachwahl je Projekt (DONE)
F-021 update-conventions: Vollabdeckung aller Template-Dokumente (inkl. seed) (DONE)
F-022 Begleithandlungen beim Fragment-Einbau (DONE)
F-023 new-project ohne GitHub (lokaler Bootstrap-Pfad) (→ aufgegangen in F-032)
F-024 Commit-Adresse aus der Personal-Config statt hart aus gh
F-025 install.sh: fehlender gh-Login und Plattform-Abdeckung
F-026 Template-Auflösung: Aktualität, Herkunft und Klontiefe
F-027 Stop-Hook plattformfähig machen (Windows greift ins WSL)
F-028 Utility-Skill handoff (DONE)
F-029 Graphiti-Schreibzugriffe auf Server-LLM-Kosten optimieren
F-030 Graphiti-Episodenverlust erkennen und wiederherstellbar halten
F-031 mise.lock mit Plattform-Einträgen erzeugen (CI im --locked-Modus) (DONE)
F-032 Host-unabhängiger Betrieb (ohne GitHub, andere Git-Server, nur Git)
F-033 Betrieb ohne Graphiti absichern
F-034 Senior-Maßstab in den Bau-Skills (Lesbarkeit, keine Workarounds, Secure Coding)
F-035 Repo-übergreifende Übergabe statt Parallelarbeit (coding-kit ↔ project-template) (→ aufgegangen in F-039)
F-036 Dokumentmodell neu: Feature-Dateien statt Übergangs-Artefakt
F-037 Unabhängiges Review in step-done (Reviewer mit frischem Kontext)
F-038 Freigabe-Regel für PROGRESS-Einträge kit-weit; add-feature von Claude aufrufbar (PLANNED)
F-039 Ein Repo: project-template ins Plugin, gemeinsame Version 1.0.0
-->
