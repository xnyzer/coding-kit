# coding-kit — Progress-Archiv

Abgeschlossene Aufgaben mit Detail und Begründung. Neueste oben.

---

## F-021 — update-conventions: Vollabdeckung aller Template-Dokumente (inkl. seed) (2026-07-20)

**Aufgabe:** update-conventions prüfte nur managed Dateien und Modul-Parts —
seed-Dateien samt ihrer Template-Struktur-Anteile (CLAUDE.md-Blöcke,
PROGRESS-Skelett, REQUIREMENTS-Kopfnotiz, README-Struktur) blieben ungeprüft, und
im Template gelöschte/umbenannte Dateien behandelte der Lauf nicht.
Template-Gegenstück: project-template F-011 (`section:NAME`-Zonen-Vertrag in
MANIFEST § Seed sections, Marker in sechs seed-Skeletten, VERSION 0.11.0) — war
bei Planungsbeginn bereits fertig; F-021 ist die rein kit-seitige Auswertung.

**Was entstanden ist (Plugin 0.15.0 + 0.16.0; 2 Substeps, 2 Commits):**

- **F-021a — seed-Abgleich abschnittsweise (0.15.0):** update-conventions liest in
  § 0 das Zonen-Inventar aus MANIFEST § Seed sections mit Feature-Detection
  (fehlt der Abschnitt — älterer Template-Stand —, entfallen seed-Abgleich und
  Marker-Migration still; `manifest-format` bleibt 1). Neuer A2-Schritt 7: die
  markierten Zonen der Template-Fassung werden instanziiert (rückaufgelöste
  Projektwerte aus A2.2) und einzeln gegen die Ist-Zone gedifft — je Zone
  übernehmen / lassen / Override, nie die ganze Datei ersetzen oder anlegen;
  gelöschtes Markerpaar = dauerhafter Opt-out (nur melden, nie ungefragt
  wiederherstellen); `claude-graphiti` fehlt legitim bei Projekten ohne
  Graphiti-Block. Neuer A3-Schritt 7: Marker-Migration für Alt-Projekte (reine
  Wrapper aus dem Inventar um wiedererkennbare Zonen, je Datei bestätigt; nicht
  Wiederauffindbares = Opt-out). Grundsatz präzisiert: seed nie als Ganzes,
  markierte Zonen abschnittsweise. new-project § 4b stellt klar, dass
  `section:NAME`-Markerpaare bei der Instanziierung erhalten bleiben.
- **F-021b — entfernte/umbenannte Template-Dateien (0.16.0):** neuer A2-Schritt 8:
  Core-Tabelle des Stempel-Stands (Stempel-Commit über die `VERSION`-Dateihistorie
  des Template-Checkouts auflösen, dann `git show <commit>:MANIFEST.md`) gegen die
  aktuelle diffen; Umbenennung → Umzug anbieten, Entfernung → Rückbau anbieten —
  je Datei bestätigt, Overrides gelten. Fallback ohne auflösbaren Stempel-Commit
  (shallow clone, zu alter Stempel): nur im CHANGELOG des Update-Fensters
  dokumentierte Fälle, nichts erraten. seed-Dateien werden nie gelöscht oder
  verschoben, nur gemeldet.
- **Entscheidungen:** Zwei Commits mit je eigenem Version-Bump (0.15.0/0.16.0),
  Historie deckungsgleich mit dem CHANGELOG (Nutzer-Wahl). Keine Heuristik für
  markerlose seed-Dateien im deterministischen Pfad — Alt-Projekte laufen über die
  bestätigte A3-Migration. LICENSE bleibt bewusst ohne Zonen (verwaltet
  `/choose-license`).
- **Begleitanpassungen:** plugin.json 0.15.0→0.16.0, CHANGELOG-Einträge,
  README-Zeile + Skill-Description um seed-Zonen und Rückbau/Umzug erweitert;
  project-template 0.11.1 (HOW-TO-Zeile zu `/update-conventions` nachgezogen,
  dortige Sync-Invariante: VERSION-Bump + CHANGELOG).
- **Geänderte Dateien:** `plugins/coding-kit/skills/update-conventions/SKILL.md`,
  `plugins/coding-kit/skills/new-project/SKILL.md`,
  `plugins/coding-kit/.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`;
  im project-template: `core/HOW-TO-CODE-WITH-CLAUDE.md`, `VERSION`,
  `CHANGELOG.md`.

## F-020 — Sprach-Matrix: granulare Sprachwahl je Projekt (2026-07-19)

**Aufgabe:** Die Projektsprache war eine einzige Dimension („Sprache der lebenden
Doku") mit sichtbarkeitsgekoppeltem Default (Deutsch privat / Englisch public).
Sprache hängt aber am Thema/Publikum, nicht an der Sichtbarkeit — ein privates
Projekt kann public werden (F-019), ohne dass die Sprache wechseln soll.
Template-Gegenstück: project-template F-010 (Languages-Block, fünf
`LANG_*`-Platzhalter, VERSION 0.10.0) — im Pairing direkt miterledigt.

**Was entstanden ist (Plugin 0.14.0; 2 Substeps, ein Release):**

- **F-020a — Erhebung & Instanziierung:** new-project Schritt 5 ist die
  Preset-Frage (A Arbeitssprache + Englisch nach außen [Default] / B alles Englisch /
  C alles Arbeitssprache / D individuell je Dimension, freie Sprachwahl), Vorschlag
  aus der Short-Info — die Sichtbarkeits-Frage sagt explizit, dass sie die
  Sprachwahl nicht beeinflusst. §4b füllt die fünf `LANG_*`-Platzhalter. Globale
  CLAUDE.md-Vorlage: Haus-Default Englisch bleibt, ein Projekt-Languages-Block
  gewinnt je Dimension; Alt-Konvention wird weiter gelesen. Immer englisch:
  Identifier, Conventional-Tokens, Status-Tokens, Governance-Doku.
- **F-020b — Betrieb & Migration:** step-done liest den Languages-Block (§0), prüft
  die Kommentar-/Docstring-Sprache im Review (§1) und schlägt Commit-Prosa in der
  Commit-Sprache vor (§6; ohne Block englisch, Tokens immer englisch); build-step
  schreibt Kommentare in der Kommentar-Sprache (§2); update-conventions löst die
  fünf Werte rück (A2.2, mit Alt-Projekt-Fallback) und bietet die
  Languages-Block-Migration als bestätigten Schritt an (neuer A3-Schritt 6 +
  Hinweis in A2.7) — nötig, weil CLAUDE.md `seed` ist und nie automatisch
  angefasst wird.
- **Entscheidung (Nutzer) — prospektive Migration:** Beim Sprachwechsel wird nichts
  rückwirkend übersetzt; neue Einträge folgen ab sofort den gewählten Sprachen,
  Struktur-Überschriften (z. B. PROGRESS-Skelett) dürfen übersetzt werden, die
  Historie bleibt unverändert. Gemischte Tabellen sind akzeptiert — sie
  dokumentieren den Wechselzeitpunkt.
- **Bewusst nicht angefasst:** die generische Phrase „Sprache der lebenden Doku" in
  ~10 Skills — sie bleibt gültig und zeigt auf die Block-Zeile (Diff-Minimierung).
- **Begleitanpassungen:** plugin.json 0.14.0, CHANGELOG, new-project-description;
  README-new-project-Zeile brauchte keine Änderung.
- **Geänderte Dateien:** `plugins/coding-kit/skills/new-project/SKILL.md`,
  `plugins/coding-kit/skills/step-done/SKILL.md`,
  `plugins/coding-kit/skills/build-step/SKILL.md`,
  `plugins/coding-kit/skills/update-conventions/SKILL.md`,
  `templates/global-CLAUDE.md`, `plugins/coding-kit/.claude-plugin/plugin.json`,
  `CHANGELOG.md`.

## F-018 — Konventions-Vererbung nur noch abwärts (2026-07-19)

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

## F-017 — Eigenschafts-Trigger für Standards-Fragmente auswerten (2026-07-19)

**Aufgabe:** Der Fragment-Katalog des project-template kennt Mapping-Zeilen mit
Projekteigenschafts-Triggern (`*characteristic:*`; erster Fall: `audit-logging` mit
„service with user/admin mutations"). Solche Trigger sind über Paket-Manifeste nicht
erkennbar — ohne Kit-Unterstützung würde ein Eigenschafts-Fragment nie gezogen.

**Was entstanden ist (Plugin 0.12.0; der prep-step-Teil kam bereits mit F-015/0.10.0):**

- **define-requirements — Interview-Punkt 5:** die `*characteristic:*`-Zeilen aus
  `modules/standards/README.md` werden zur Laufzeit gelesen und je Zeile als
  Ja/Nein-Frage gestellt (z. B. audit-logging → „Gibt es Nutzer-/Admin-Aktionen, die
  Daten verändern?"), Default nein. **Gate:** nur bei erreichbarem Template (im
  /new-project-Flow ohnehin aufgelöst), sonst stilles Überspringen. Treffer →
  Constraint + Decision-Log-Eintrag in der REQUIREMENTS.md **und** Bestandteil der
  „Rückgabe an den Aufrufer" (Liste bejahter Eigenschafts-Fragmente).
- **new-project § 4b:** komponiert die im Interview bejahten Eigenschafts-Fragmente
  in die anzuhängende Fragmentliste mit — ohne diese Zeile wäre die
  Interview-Antwort verpufft.
- **choose-stack Modus B:** Eigenschafts-Fragmente sind nachrüstbar — sie sind in
  keinem `MODULE.md` deklariert; je Trigger wird gefragt, ob die Eigenschaft aufs
  Projekt zutrifft (Projektentscheidung, Default nein), angehängt nur nach
  Bestätigung mit derselben idempotenten Mechanik.
- **Skalierungs-Einschätzung:** aktuell eine characteristic-Zeile im Katalog → eine
  Interview-Frage; wächst linear, Ja/Nein mit Default nein — bewusst keine
  Extra-Mechanik.
- **Begleitanpassungen:** plugin.json 0.12.0, CHANGELOG-Eintrag, README-Zeilen
  (choose-stack, define-requirements), define-requirements-`description`.
- **Geänderte Dateien:** `plugins/coding-kit/skills/define-requirements/SKILL.md`,
  `plugins/coding-kit/skills/new-project/SKILL.md`,
  `plugins/coding-kit/skills/choose-stack/SKILL.md`,
  `plugins/coding-kit/.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`.
- **Strang komplett:** Mit F-017 ist die Composable-CODING-STANDARDS-Arbeit auf
  Kit-Seite abgeschlossen (F-012–F-017); beide Signaltypen des Katalogs werden an
  allen Lebenszyklus-Punkten ausgewertet.

## F-016 — step-done: Standards-Coverage-Backstop (2026-07-19)

**Aufgabe:** Auch mit der Erkennung in prep-step (F-015) konnte ein Framework ohne
zugehöriges Standards-Fragment durchrutschen — etwa wenn es erst während der
Umsetzung dazukam. Es fehlte ein Backstop am Ende des Zyklus.

**Was entstanden ist (Plugin 0.11.0):**

- **Neuer Schritt „1a. Standards-Abdeckung (Backstop)"** in step-done, zwischen
  Review (§1) und Secrets-Scan (§2). **Entscheidung — diff-basiert statt
  Projekt-Vollaudit:** Gate = der Diff des Schritts führt neue Dependencies in
  Paket-Manifesten oder neue Signal-Dateien (Dockerfile, nginx.conf, …) ein UND das
  Projekt hat einen `module:coding-standards`-Slot; sonst stilles Überspringen.
  Ein Voll-Scan je Substep wäre unverhältnismäßig; historische Lücken (Framework
  kam vor Einführung des Fragment-Systems) bleiben ein möglicher späterer
  audit-code-Erweiterungspunkt — bewusst nicht als F-Nummer aufgenommen.
- **Match** gegen das zur Laufzeit gelesene Katalog-Mapping
  (`modules/standards/README.md`, Auflösung wie choose-stack § 0);
  `*characteristic:*`-Zeilen matchen diff-basiert naturgemäß nicht (Planungsmaterie
  von prep-step 2a bzw. F-017).
- **Nicht blockierend:** Lücke wird gemeldet + Anhängen vorgeschlagen (Mechanik wie
  choose-stack, idempotent); lehnt der Nutzer ab, wird die offene Lücke im
  Archiv-Eintrag vermerkt, damit sie sichtbar bleibt.
- **Begleitanpassungen:** plugin.json 0.11.0, CHANGELOG-Eintrag,
  README-Tabellenzeile step-done, Frontmatter-`description`.
- **Geänderte Dateien:** `plugins/coding-kit/skills/step-done/SKILL.md`,
  `plugins/coding-kit/.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`.
- Damit ist der „Standards wachsen mit"-Zyklus geschlossen: prep-step schlägt vor
  (F-015), choose-stack baut ein (F-013), update-conventions pflegt (F-014),
  step-done fängt Durchrutscher (F-016).

## F-012 — add-skill: Template-HOW-TO synchron halten (2026-07-19)

**Aufgabe:** Die Skill-Übersicht in project-templates `core/HOW-TO-CODE-WITH-CLAUDE.md`
fiel hinter den Skill-Bestand des coding-kit zurück — kein Prozessschritt erinnerte
beim Anlegen/Ändern von Skills an die Pflege der Template-Übersicht.

**Was entstanden ist (repo-lokal, kein Plugin-Release):**

- **Neuer Haken in der Vollständigkeits-Checkliste** (Schritt 3) von
  `.claude/skills/add-skill/SKILL.md`: Gehört der neue/geänderte Skill zum
  Projekt-Alltag (Dev-Loop) oder zur Projekt-Pflege, wird die Skill-Übersicht in
  project-templates `core/HOW-TO-CODE-WITH-CLAUDE.md` mitgepflegt — Template zur
  Laufzeit auflösen (wie `/coding-kit:choose-stack` § 0), die passende der beiden
  Tabellen treffen (Dev-Loop mit „What happens"-Spalte, Pflege nur „When to use"),
  Sync-Invariante jenes Repos einhalten (VERSION-Bump + CHANGELOG im selben Commit).
  Rein kit-interne Skills (wie add-skill selbst) bleiben draußen.
- **Entscheidung:** keine Plugin-Begleitänderungen — add-skill ist repo-lokal
  (`.claude/skills/`), kein Plugin-Inhalt; die Kit-Sync-Invariante greift nicht
  (konsistent mit der F-009-Verbuchung).
- **Vermerk für die nächste project-template-Session:** Die HOW-TO-Zeilen für
  prep-step/choose-stack/update-conventions sind durch F-013–F-015 bereits leicht
  veraltet (u. a. fehlt der Standards-Abdeckungs-Check) — Drift dort beheben; der
  neue Checklisten-Haken verhindert künftige.
- **Geänderte Dateien:** `.claude/skills/add-skill/SKILL.md`.

## F-015 — prep-step: Framework-Erkennung mit Fragment-Vorschlag (2026-07-19)

**Aufgabe:** Führt eine Aufgabe ein neues Framework/eine neue Dependency ein, wuchs
der Standards-Bestand des Projekts nicht mit — kein Prozessschritt bemerkte das
fehlende Fragment („Standards wachsen mit").

**Was entstanden ist (Plugin 0.10.0):**

- **Neuer Schritt „2a. Standards-Abdeckung prüfen (Fragment-Check)"** in prep-step,
  zwischen Analyse (§2) und Größenbewertung (§3). **Kosten-Gate:** läuft nur, wenn
  die Analyse neue Frameworks/Dependencies identifiziert UND das Projekt einen
  `<!-- module:coding-standards -->`-Slot hat; sonst stilles Überspringen — kein
  Template-Clone je prep-step-Lauf (das Kit-Repo selbst z. B. hat keinen Slot).
- **Match beider Signaltypen** gegen das zur Laufzeit gelesene Trigger-Mapping
  (`modules/standards/README.md` des aufgelösten Templates): Dependency-Signale
  gegen die neuen Dependencies **und** `*characteristic:*`-Eigenschafts-Trigger
  gegen die Aufgabenbeschreibung. Damit ist der prep-step-Touchpoint von **F-017
  miterledigt**; F-017 verbleibt mit define-requirements-Interview +
  choose-stack-Nachrüstpfad.
- **Vorschlags-Pfade:** Katalog-Fragment vorhanden, aber kein `fragment:NAME`-Marker
  im Projekt → Anhängen als Plan-Bestandteil vorschlagen (Mechanik wie
  `/choose-stack`, idempotent); Treffer-Thema ohne Katalog-Fragment → projektlokales
  Fragment autoren + Promote via `/update-conventions` (AUFWÄRTS) anbieten. **Nur
  vorschlagen, nie still einbauen** — Entscheidung fällt mit der Plan-Freigabe.
- **Plan-Vorlage (§4):** neue Zeile „Standards-Abdeckung" (entfällt, wenn 2a
  übersprungen wurde); Frontmatter-`description` erweitert.
- **Begleitanpassungen:** plugin.json 0.10.0, CHANGELOG-Eintrag,
  README-Tabellenzeile prep-step.
- **Geänderte Dateien:** `plugins/coding-kit/skills/prep-step/SKILL.md`,
  `plugins/coding-kit/.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`.
- **Erkennungsqualität bewusst heuristisch** (Skill-Text, kein Parser) — F-016
  fängt Durchrutscher als Backstop am Zyklusende.

## F-014 — update-conventions: Pro-Fragment-Refresh (2026-07-19)

**Aufgabe:** update-conventions aktualisierte CODING-STANDARDS als einen Modul-Part.
Mit Append-Slot und Pro-Fragment-Markern (F-013) musste der Abwärts-Abgleich
fragment-granular werden — ohne projektlokal ergänzte Fragmente zu überschreiben.

**Was entstanden ist (Plugin 0.9.0):**

- **Zwei Diff-Ebenen abwärts:** A2.3 Sonderfall `CODING-STANDARDS.md` — die
  Soll-Fassung wird mit dem **Ist-Slot des Projekts** befüllt, der Datei-Diff zeigt
  damit nur Core-Änderungen (§1–12). Neuer A2-Schritt 6 „Fragment-Abgleich": die
  `fragment:NAME`-Blöcke im Slot einzeln gegen ihr Template-Pendant diffen
  (Sprachfragment ↔ `CODING-STANDARDS.part.md` des Moduls, Katalog-Fragmente ↔
  `modules/standards/<name>.md`) mit denselben Entscheidungen wie je Datei
  (übernehmen / lassen / Override / promoten). Ohne Template-Pendant → projektlokal:
  nie anfassen, nur auflisten; Inline-`<!-- override: … -->` im Block schützt genau
  dieses Fragment.
- **Neu deklarierte Fragmente:** fehlt im Projekt ein inzwischen vom `MODULE.md`
  deklariertes Katalog-Fragment → Anhängen anbieten (Mechanik wie `/choose-stack`,
  idempotent). Reihenfolge-Regel: Bestehendes in-place ersetzen, Neues ans
  Slot-Ende — nie umsortieren (kosmetische Diffs vermeiden).
- **AUFWÄRTS:** projektlokales Fragment kann generalisiert in den Katalog promotet
  werden (`modules/standards/<name>.md` + Katalog-Zeile mit Trigger-Mapping im
  dortigen README); Frontmatter-`description` erweitert.
- **Entscheidung:** keine `manifest-format`-Erhöhung — das Template hat den
  Fragment-Vertrag innerhalb von Format 1 ergänzt, das bestehende Gate in §0 genügt;
  §0 liest zusätzlich MANIFEST § Standards fragments + `modules/standards/README.md`.
  Der A3-Heuristik-Pfad erbt die Fragment-Logik über die gemeinsame Soll-Erzeugung.
- **Begleitanpassungen:** plugin.json 0.9.0, CHANGELOG-Eintrag, README-Tabellenzeile
  update-conventions.
- **Geänderte Dateien:** `plugins/coding-kit/skills/update-conventions/SKILL.md`,
  `plugins/coding-kit/.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`.

## F-013 — choose-stack: Multi-Fragment-Einbau (2026-07-19)

**Aufgabe:** choose-stack installierte den EINEN `CODING-STANDARDS.part.md` eines
Stack-Moduls in den §13-Slot. Das project-template komponiert CODING-STANDARDS
inzwischen aus framework-granularen Fragmenten (Vertrag: MANIFEST § Standards
fragments; umgesetzt dort seit Template-VERSION 0.7.0, verifiziert gegen 0.8.0) —
ein Modul deklariert MEHRERE Fragmente, der Ein-Part-Einbau griff nicht mehr.

**Was entstanden ist (Plugin 0.8.0):**

- **choose-stack §0:** liest zusätzlich MANIFEST § Standards fragments und
  `modules/standards/README.md` (Fragment-Katalog).
- **choose-stack Modus B — Append-Prozedur:** Standards-Fragmente werden im Slot
  `<!-- module:coding-standards -->` **angehängt**, nie ersetzt. Fragmentliste in
  Reihenfolge: eigenes Sprachfragment (`CODING-STANDARDS.part.md`) + Katalog-Fragmente
  laut `Standards fragments:`-Zeile des `MODULE.md`, tolerant gelesen (fett/plain;
  `(none)`/leer/fehlend = keine). Die Quell-Dateien tragen ihre
  `<!-- fragment:NAME -->`-Marker bereits — nichts wird gewrappt. **Idempotent** je
  Marker: Vorhandenes nie doppelt einbauen, nie erneuern (Erneuern =
  `/update-conventions`); der docs-only-Platzhalter im Slot fällt beim Erst-Einbau weg.
- **Modulwechsel:** Sprachfragment wird gegen das neue getauscht; Katalog-Fragmente
  bleiben stehen und werden nur aufgelistet („noch aktuell?"). **Entscheidung
  (Nutzer):** kein automatisches Entfernen — Katalog-Fragmente sind cross-cutting und
  können den Sprachwechsel überleben; Entfernen ist Projektentscheidung.
- **new-project:** Referenz des Modul-Einbaus nachgezogen — „Standards-Fragmente
  anhängen" statt „CODING-STANDARDS-Slot füllen".
- **Begleitanpassungen:** plugin.json 0.8.0, CHANGELOG-Eintrag, README-Tabellenzeile
  choose-stack.
- **Geänderte Dateien:** `plugins/coding-kit/skills/choose-stack/SKILL.md`,
  `plugins/coding-kit/skills/new-project/SKILL.md`,
  `plugins/coding-kit/.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`.
- **Abgrenzung:** Fragment-Refresh downstream bleibt F-014 (update-conventions);
  Erkennungs-/Backstop-Logik bleibt F-015/F-016; Eigenschafts-Trigger bleibt F-017.

## F-011 — build-step vom step-done-Handoff entkoppeln (2026-07-14)

**Was entstanden ist (Plugin 0.7.0):**

- **Anlass (Nutzer-Beobachtung, aus einem update-conventions-Lauf in webstack):**
  build-step ließ je Substep *immer* step-done laufen. Unerwünscht bei interaktiver
  Einzelarbeit — der Nutzer will vor dem Abschluss selbst prüfen und ggf. anpassen; das
  automatische Durchlaufen soll nur im autonomen `/goal`-Lauf über mehrere Subfeatures
  gelten.
- **Modus-Split in build-step:** Neuer expliziter Erkennungssatz im Kopf von „2.
  Umsetzung" — aktiver `/goal`-Lauf mit erteilter Commit-Freigabe = **autonom**, jede
  andere Nutzung = **interaktiv**. Schritt 5 verzweigt: interaktiv wird step-done nur
  **empfohlen** (nächster Substep erst nach Nutzer-Abschluss bzw. „weiter"), autonom
  läuft step-done je Substep automatisch wie bisher (die `/goal`-Abschlussbedingung
  verlangt es). Description, Loop-Satz und Abschluss-/DONE-Markierung entsprechend
  nachgezogen.
- **Begleitanpassungen:** plugin.json 0.7.0, CHANGELOG-Eintrag, README (build-step-
  Tabellenzeile + Zyklus-Prosa: step-done ist interaktiv ein bewusster eigener Schritt).
- **Entscheidung:** Unterscheidungssignal ist der laufende `/goal`-Kontext + die
  laufbezogene Commit-Freigabe, nicht ein neues Argument — kein Bruch am `/goal`-Flow,
  dessen Abschlussbedingung step-done ohnehin explizit nennt.
- **Nicht hierher (in project-template notiert):** MANIFEST listet `core/private/README.md`
  ohne existierende Datei (Template-Bug); webstacks reichere AI-DISCLOSURE ist noch nicht
  als promote/override entschieden.

## F-010 — Status-Marker-Konvention + Grenze add-feature/prep-step (2026-07-13)

**Was entstanden ist (Plugin 0.6.0):**

- **Anlass (Nutzer-Beobachtung):** add-feature-Einträge waren oft schon fast fertige
  Pläne, prep-step legte noch einmal nach; außerdem war einem Eintrag nicht anzusehen,
  ob er nur aufgenommen (→ prep-step) oder schon geplant (→ build-step) ist.
- **Status-Marker-Konvention:** `**Status:**`-Zeile direkt unter der
  Eintrags-Überschrift mit sprachinvarianten Tokens — `BACKLOG` (setzt add-feature) →
  `PLANNED` (setzt prep-step, zusätzlich `(PLANNED)` an der Index-Zeile); fertig
  bleibt Done-Tabelle + `(DONE)` im FEATURE-INDEX. Toleranz für Alt-Einträge ohne
  Status-Zeile (Substeps vorhanden ≈ geplant; Zeile bei nächster Berührung nachziehen).
- **add-feature geschärft:** „Mögliche Umsetzung" → „Lösungsskizze", explizit
  unverbindlich: keine Dateilisten, keine Zerlegung in Schritte, keine
  Abnahmekriterien (bleibt prep-step); optionale Ablauf-/Ansatz-Zusatzabschnitte
  gestrichen; Alt-Überschriften werden nicht umbenannt.
- **prep-step geschärft:** hinterfragt die Skizze statt sie zu übernehmen (jede
  Annahme gegen den aktuellen Codestand verifizieren, eigene Alternativen mit
  Begründung); Plan-Vorlage um „Bewertung der Lösungsskizze" ergänzt; setzt `PLANNED`
  auch bei kleinen Aufgaben; zieht die Skizze bei Abweichung auf den beschlossenen
  Stand nach.
- **Begleitanpassungen:** build-step prüft den Marker beim Plan-Laden (`BACKLOG` →
  erst prep-step empfehlen); step-done ersetzt `(PLANNED)` durch `(DONE)` und nimmt
  die Status-Zeile nicht mit ins Archiv; `docs/skill-authoring.md` führt die
  Konvention als Pflicht-Baustein; README (Tabellenzeilen, Zyklus-Satz), CHANGELOG,
  plugin.json 0.6.0.
- **Entscheidung:** Trennung add-feature/prep-step bleibt bestehen (Erfassungs- ≠
  Umsetzungszeitpunkt; build-step hängt am prep-step-Output; add-feature muss als
  billiges Scope-Schutz-Ventil erhalten bleiben) — statt eines Merges wurde die
  Grenze geschärft und per Marker sichtbar gemacht.

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
