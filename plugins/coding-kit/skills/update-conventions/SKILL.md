---
name: update-conventions
description: Konventionen vom project-template in Projekte verteilen — ausschließlich abwärts. Deterministisch via template-version + MANIFEST, Diff + Bestätigung je Datei bzw. je Standards-Fragment, Override-Schutz, Migrationen für Altprojekte. Projektlokale Fragmente ohne Template-Pendant werden nie angefasst, aber mit einem manuell anstoßbaren Übernahme-Vorschlag fürs Template gemeldet. Nichts wird ungefragt überschrieben.
disable-model-invocation: true
---

# Konventions-Sync (Template → Projekte)

**Grundsätze:** Vererbung fließt **ausschließlich abwärts** — Konventionen werden
immer zuerst in der Vorlage geändert und von dort verteilt; dieser Skill schreibt nie
ins Template. Nichts ungefragt überschreiben. Overrides sind unantastbar. Nie
automatisch committen. Seed-Dateien (lebende Doku) werden von Updates **nie** berührt.

Argument (optional): Projektpfad/-name für einen gezielten Lauf. Lokale Abweichungen
an managed Dateien werden übernommen, einmalig gelassen oder als Override registriert;
für Inhalte, die ins Template gehören, gibt es den **Übernahme-Vorschlag** (s. u.) —
angestoßen wird der immer manuell vom Nutzer.

## 0. Template & Vertrag auflösen

Wie `/choose-stack` § 0: Template-Checkout auflösen (lokal unter
`$CODING_KIT_PROJECTS_DIR/project-template`, sonst `gh repo clone`). `MANIFEST.md`
lesen; **`manifest-format` prüfen** (dieser Skill kann Format `1` — sonst abbrechen und
auf ein Kit-Update verweisen). Aktuelle Template-`VERSION` und `CHANGELOG.md` merken.
Für den Fragment-Abgleich zusätzlich MANIFEST § Standards fragments und
`modules/standards/README.md` (Fragment-Katalog) lesen.

## Kontext-Recovery

Bei Wiederaufnahme: bereits behandelte Projekte/Dateien aus dem Verlauf übernehmen,
`git status` in Projekt und Template prüfen, beim nächsten offenen Punkt weitermachen.

---

## Ablauf — Template → Projekte

### A1. Projekte finden

- GitHub-Discovery über das Marker-Topic:
  `gh search repos "user:$(gh api user --jq .login) topic:coding-kit" --json name`
- Plus lokale Ordner unter `$CODING_KIT_PROJECTS_DIR` mit `.claude/template-version`
  oder `PROGRESS.md` mit FEATURE-INDEX (Altprojekte ohne Topic).
- Liste zeigen, Auswahl bestätigen lassen. Nur lokale Checkouts bearbeiten (fehlt einer:
  klonen anbieten).

### A2. Je Projekt mit Stempel: deterministischer Abgleich

1. Stempel lesen (`.claude/template-version`). Stempel == aktuelle VERSION → „aktuell",
   fertig. Sonst die CHANGELOG-Einträge zwischen Stempel und aktueller VERSION zeigen
   (das ist das Update-Fenster).
2. **Projektwerte rückauflösen** für die Platzhalter: Name (Repo), OWNER (`gh api
   user`), Beschreibung (Repo-Beschreibung), GROUP_ID + Doku-Sprache (Projekt-CLAUDE.md),
   LICENSE_SPDX (LICENSE-Datei), CODEQL_LANGUAGES (eingebautes Modul), TEMPLATE_VERSION
   (neue VERSION).
3. **Soll-Zustand erzeugen:** jede **managed** Datei der Core-Tabelle plus die
   **module**-Parts des eingebauten Moduls (erkennbar an justfile-Kopf/mise.toml;
   im Zweifel fragen) aus dem aktuellen Template instanziieren — Platzhalter füllen,
   Marker-Logik wie `/new-project` § 4b. **Policies beachten:** `seed` nie anfassen;
   `public-only` nur bei public Repos. **Sonderfall `CODING-STANDARDS.md`:** in der
   Soll-Fassung den Slot `<!-- module:coding-standards -->` mit dem **Ist-Slot des
   Projekts** füllen — der Datei-Diff (Schritt 5) zeigt so nur Core-Änderungen; die
   Fragmente im Slot gleicht Schritt 6 einzeln ab.
4. **Override-Schutz (VOR dem Diffen):** `.claude/convention-overrides.md` lesen und
   Projekt-Dateien auf Inline-Marker `<!-- override: … -->` scannen. Registrierte
   Dateien/Abschnitte werden **nie** angefasst — nur informativ auflisten.
5. **Je Datei:** Soll vs. Ist diffen. Identisch → nichts. Verschieden → Diff zeigen und
   fragen: **übernehmen** / **so lassen** (einmalig) / **als Override registrieren**
   (Eintrag in `convention-overrides.md` mit Grund). Hält der Nutzer die
   Projekt-Fassung für besser als das Template: zuerst die **Vorlage** ändern
   (manuell bzw. via Übernahme-Vorschlag, s. u.), dann erneut abwärts syncen.
6. **Fragment-Abgleich (CODING-STANDARDS-Slot, je Fragment):** die
   `fragment:NAME`-Blöcke im Slot einzeln gegen ihr Template-Pendant diffen — das
   Sprachfragment gegen `CODING-STANDARDS.part.md` des Moduls, Katalog-Fragmente gegen
   `modules/standards/<name>.md`. Je Fragment dieselben Entscheidungen wie in
   Schritt 5; ein Inline-`<!-- override: … -->` im Block schützt genau dieses
   Fragment. **Ohne Template-Pendant → projektlokal: nie anfassen**; auflisten mit
   dem Hinweis, dass dieses Set im Template fehlt, und je Fragment einen
   **Übernahme-Vorschlag** ausgeben (s. u.) — Aufnahme in den Katalog wäre sinnvoll,
   anstoßen muss sie der Nutzer. Deklariert das `MODULE.md` inzwischen Fragmente, die im Projekt
   fehlen → Anhängen anbieten (Mechanik wie `/choose-stack`, idempotent). Bestehende
   Fragmente in-place ersetzen, Neues ans Slot-Ende — nie umsortieren.
7. Abschluss pro Projekt: Stempel auf die neue VERSION setzen, `just check` muss grün
   sein (Write-then-Verify), Commit-Vorschlag (z. B.
   `chore: sync template conventions <alt> -> <neu>`) — **nur nach OK**, dann Push-Frage.

### A3. Altprojekte ohne Stempel: heuristischer Abgleich + Migrationen

Erst der Abgleich, dann jede Migration als **eigener bestätigter Schritt**:

1. **Heuristik:** vorhandene Dateien, die Manifest-Zielen entsprechen, gegen die
   instanziierte Soll-Fassung diffen (je Datei bestätigen); fehlende managed Dateien
   (Governance, .github, .editorconfig …) zum Anlegen anbieten.
2. **instructions.md → CLAUDE.md:** Inhalte aus `.claude/instructions.md` (bzw.
   Legacy-Orten) in die Root-CLAUDE.md überführen (Graphiti-Block mit group_id!),
   Alt-Datei entfernen.
3. **Core-Skill-Kopien entfernen:** lokale `.claude/skills/`-Kopien von add-feature/
   prep-step/step-done/audit-code löschen — **nur wenn** das coding-kit-Plugin
   installiert ist (`claude plugin list`). Kollisionsverhalten ist geklärt: Plugin-Skills
   sind namespaced, lokale Kopien gewinnen unqualifiziert — nach dem Entfernen gilt
   `/coding-kit:<skill>`. **Projektspezifische Skills immer behalten.**
4. **Renovate-Onboarding:** `renovate.json` mit `"extends":
   ["github>OWNER/coding-kit"]` anbieten (OWNER zur Laufzeit); Hinweis: die
   Renovate-App-Freigabe ist eine manuelle Nutzeraktion.
5. **Tooling nachrüsten:** mise.toml + justfile + lefthook.yml aus dem Template-Kern
   (bzw. Modul via `/choose-stack`) anbieten; danach `mise install && just setup &&
   just check`.
6. Sind alle managed Dateien abgeglichen: **Stempel setzen** anbieten (macht künftige
   Läufe deterministisch). Commit-Frage wie A2.7.

---

## Übernahme-Vorschlag (Projekt → Template — nur manuell angestoßen)

Dieser Skill schreibt nie ins Template. Findet ein Lauf projektlokale Fragmente ohne
Template-Pendant (oder gehört eine lokale Verbesserung in die Vorlage), wird
stattdessen **fertiges Material** ausgegeben — ausführen bzw. absenden tut es der
Nutzer:

- **Kopierfertiger Beispiel-Prompt** für eine project-template-Session: das Fragment
  generalisieren (Projektwerte zu Platzhaltern, Englisch, personendatenfrei), als
  `modules/standards/<name>.md` anlegen, Katalog-Zeile mit Trigger im dortigen README
  ergänzen, Sync-Invariante des Templates beachten (VERSION-Bump + CHANGELOG im
  selben Commit) — den generalisierten Fragment-Inhalt in den Prompt beilegen.
- **Alternativ ein GitHub-Request** ins Template-Repo mit demselben Inhalt, z. B.
  `gh issue create -R "$(gh api user --jq .login)/project-template" --title
  "standards: add <name> fragment" --body <Vorschlag>` (Repo-Override via
  `CODING_KIT_TEMPLATE_REPO` aus der Personal-Config).

Nach der Aufnahme ins Template bringt ein regulärer Abwärts-Lauf das neue
Katalog-Fragment in alle Projekte.
