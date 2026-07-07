---
name: update-conventions
description: Konventionen zwischen project-template und Projekten synchron halten — bidirektional. Abwärts verteilt Template-Updates in Projekte (deterministisch via template-version + MANIFEST, Diff + Bestätigung je Datei, Override-Schutz, Migrationen für Altprojekte). Aufwärts („promote") hebt eine bewährte projektlokale Änderung in den Template-Kern (mit VERSION-Bump + CHANGELOG). Nichts wird ungefragt überschrieben.
disable-model-invocation: true
---

# Konventions-Sync (Template ⇄ Projekte)

**Grundsätze:** Nichts ungefragt überschreiben. Overrides sind unantastbar. Nie
automatisch committen. Seed-Dateien (lebende Doku) werden von Updates **nie** berührt.

Argument (optional): Projektpfad/-name für einen gezielten Abwärts-Lauf, oder `promote`
für die Aufwärts-Richtung. Ohne Argument: **eine** Frage — „Abwärts (Template →
Projekte) oder Aufwärts (Projekt → Template)?" _(Default: abwärts)_. Wird der Skill in
einem Projekt mit lokalen Abweichungen an managed Dateien aufgerufen, `promote` aktiv
anbieten.

## 0. Template & Vertrag auflösen

Wie `/choose-stack` § 0: Template-Checkout auflösen (lokal unter
`$CODING_KIT_PROJECTS_DIR/project-template`, sonst `gh repo clone`). `MANIFEST.md`
lesen; **`manifest-format` prüfen** (dieser Skill kann Format `1` — sonst abbrechen und
auf ein Kit-Update verweisen). Aktuelle Template-`VERSION` und `CHANGELOG.md` merken.

## Kontext-Recovery

Bei Wiederaufnahme: bereits behandelte Projekte/Dateien aus dem Verlauf übernehmen,
`git status` in Projekt und Template prüfen, beim nächsten offenen Punkt weitermachen.

---

## Richtung ABWÄRTS — Template → Projekte

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
   `public-only` nur bei public Repos.
4. **Override-Schutz (VOR dem Diffen):** `.claude/convention-overrides.md` lesen und
   Projekt-Dateien auf Inline-Marker `<!-- override: … -->` scannen. Registrierte
   Dateien/Abschnitte werden **nie** angefasst — nur informativ auflisten.
5. **Je Datei:** Soll vs. Ist diffen. Identisch → nichts. Verschieden → Diff zeigen und
   fragen: **übernehmen** / **so lassen** (einmalig) / **als Override registrieren**
   (Eintrag in `convention-overrides.md` mit Grund) / **promoten** (Änderung ist
   besser als das Template → Richtung AUFWÄRTS für diese Datei).
6. Abschluss pro Projekt: Stempel auf die neue VERSION setzen, `just check` muss grün
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
   Läufe deterministisch). Commit-Frage wie A2.6.

---

## Richtung AUFWÄRTS — „promote" (Projekt → Template)

1. **Projekt erkennen** (cwd bzw. Argument; Stempel/CLAUDE.md lesen).
2. **Kandidaten:** Diff der managed Dateien gegen die instanziierte Soll-Fassung
   (wie A2.3–A2.5) — oder der Nutzer benennt die Änderung direkt.
3. **Pro Änderung genau eine Entscheidung einholen:** „in den Kern" **oder** „bleibt
   projektlokale Abweichung"?
   - **In den Kern:** Änderung **generalisieren** (Projektwerte zurück zu Platzhaltern,
     Projektspezifika raus, Englisch, personendatenfrei) und im Template-Checkout
     einpflegen. **Sync-Invariante des Templates gilt:** VERSION-Bump + CHANGELOG-Eintrag
     (+ MANIFEST bei neuen/entfernten/umpolicten Dateien) **im selben Commit**;
     `just check` im Template muss grün sein. Commit-/Push-Frage. Danach anbieten:
     Abwärts-Lauf, um die Änderung in die anderen Projekte zu tragen.
   - **Bleibt lokal:** automatisch als Override registrieren —
     `.claude/convention-overrides.md`-Eintrag (Datei/Regel, Abweichung, Grund, Datum)
     bzw. Inline-Marker `<!-- override: Grund -->` bei Abschnitts-Abweichung. Damit ist
     die Abweichung vor künftigen Abwärts-Läufen geschützt.
4. Begründungen gehören in den Commit-Body (`Decision: X over Y because …`).
