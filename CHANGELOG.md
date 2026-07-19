# Changelog

Versioniert wird das Plugin (`plugins/coding-kit/.claude-plugin/plugin.json`, semver).
Jede inhaltliche Plugin-Änderung bumpt die Version und bekommt hier einen Eintrag —
im selben Commit.

## 0.14.0 — 2026-07-19

Sprach-Matrix: Projektsprachen sind granular wählbar und von der Sichtbarkeit
entkoppelt (Gegenstück zu project-template 0.10.0, Languages-Block + fünf
`LANG_*`-Platzhalter):

- `new-project` — die Sprachfrage ist eine Preset-Frage (Arbeitssprache + Englisch
  nach außen [Default] / alles Englisch / alles Arbeitssprache / individuell je
  Dimension mit freier Sprachwahl); der Vorschlag leitet sich aus der Short-Info ab,
  nicht mehr aus der Sichtbarkeit. §4b füllt die fünf `LANG_*`-Platzhalter. Immer
  englisch bleiben Identifier, Conventional-Tokens, Status-Tokens, Governance-Doku.
- `step-done` — liest den Languages-Block (§0), prüft die Kommentar-/
  Docstring-Sprache im Review (§1) und schlägt Commit-Prosa in der Commit-Sprache
  des Projekts vor (§6; ohne Block englisch, Format-Tokens immer englisch).
- `build-step` — schreibt Kommentare/Docstrings in der Kommentar-Sprache des
  Projekts (§2).
- `update-conventions` — löst die fünf Sprachen bei der Platzhalter-Rückauflösung
  auf (A2.2) und bietet die **Languages-Block-Migration** als bestätigten Schritt an
  (neuer A3-Schritt 6 + Hinweis in A2.7; CLAUDE.md ist `seed` und wird nie
  automatisch angefasst). Migrations-Semantik prospektiv: Bestandsinhalte werden
  nicht übersetzt, neue Einträge folgen den gewählten Sprachen,
  Struktur-Überschriften optional.
- `templates/global-CLAUDE.md` — Haus-Default bleibt Englisch; ein
  Projekt-Languages-Block gewinnt je Dimension.

## 0.13.0 — 2026-07-19

Konventions-Vererbung fließt nur noch **abwärts** (Template → Projekt) — die
AUFWÄRTS-Richtung („promote") ist gestrichen:

- `update-conventions` — promote-Argument, Richtungsfrage und der komplette
  AUFWÄRTS-Abschnitt entfallen; das Entscheidungsset je Datei/Fragment ist
  dreiteilig (übernehmen / so lassen / Override registrieren). Wer die
  Projekt-Fassung für besser hält, ändert zuerst die Vorlage und synct dann
  herunter. Veralteter Querverweis „wie A2.6" auf „wie A2.7" korrigiert.
- **Neu: Übernahme-Vorschlag** (Ersatz für promote) — projektlokale Fragmente
  bleiben erlaubt, werden aber nie ins Template geschrieben. Stattdessen gibt es
  fertiges Material zum manuellen Anstoßen: kopierfertiger Prompt für eine
  Template-Session (generalisieren, Katalog-Datei + README-Zeile, Sync-Invariante)
  oder ein GitHub-Request ins Template-Repo (`gh issue create`, OWNER zur
  Laufzeit). Ausgegeben an drei Stellen: `update-conventions` (Bestandsfälle beim
  Sync), `prep-step` 2a Fall B (direkt nach der Anlage) und `step-done` 1a (neu
  angelegte Fragment-Blöcke im Diff, auch ad-hoc entstandene).

## 0.12.0 — 2026-07-19

Eigenschafts-Trigger des Fragment-Katalogs werden ausgewertet — Fragmente wie
`audit-logging`, deren Trigger eine Projekteigenschaft statt einer Dependency ist,
finden jetzt ihren Weg ins Projekt:

- `define-requirements` — neuer Interview-Punkt 5: die `*characteristic:*`-Zeilen
  des Katalogs werden zur Laufzeit gelesen und als Ja/Nein-Fragen gestellt
  (Default nein; ohne erreichbares Template stilles Überspringen). Treffer landen
  als Constraint + Decision-Log-Eintrag in der REQUIREMENTS.md und in der Rückgabe
  an den Aufrufer.
- `new-project` — komponiert die im Interview bejahten Eigenschafts-Fragmente bei
  der Instanziierung in den CODING-STANDARDS-Slot mit.
- `choose-stack` (Modus B) — Eigenschafts-Fragmente sind nachrüstbar: sie sind in
  keinem `MODULE.md` deklariert; je Trigger wird gefragt, ob die Eigenschaft
  zutrifft (Projektentscheidung, Default nein), angehängt wird nur nach
  Bestätigung (gleiche idempotente Mechanik).
- Der prep-step-Teil (Trigger-Match in der Feature-Analyse) kam bereits mit 0.10.0.

## 0.11.0 — 2026-07-19

`step-done` bekommt den Standards-Abdeckungs-Backstop — Frameworks, die erst
während der Umsetzung dazukamen, rutschen nicht mehr ohne ihr Fragment durch:

- Neuer Schritt „1a. Standards-Abdeckung (Backstop)", **diff-basiert**: läuft nur,
  wenn der Diff des Schritts neue Dependencies in Paket-Manifesten oder neue
  Signal-Dateien (Dockerfile, nginx.conf, …) einführt und das Projekt einen
  `module:coding-standards`-Slot hat; sonst stilles Überspringen. Ein
  Projekt-Vollaudit je Substep wäre unverhältnismäßig und bleibt `/audit-code`.
- Match gegen das zur Laufzeit gelesene Katalog-Mapping (wie prep-step 2a);
  `*characteristic:*`-Zeilen matchen diff-basiert naturgemäß nicht.
- Lücke → melden + Anhängen vorschlagen (Mechanik wie `/choose-stack`,
  idempotent). Der Abschluss wird nicht blockiert; eine abgelehnte Ergänzung wird
  im Archiv-Eintrag vermerkt.

## 0.10.0 — 2026-07-19

`prep-step` prüft die Standards-Abdeckung — „Standards wachsen mit":

- Neuer Schritt „2a. Standards-Abdeckung prüfen" mit Kosten-Gate: nur wenn die
  Aufgabe neue Frameworks/Dependencies einführt und das Projekt einen
  `module:coding-standards`-Slot hat; sonst stilles Überspringen (kein
  Template-Clone je Lauf).
- Gematcht werden **beide** Signaltypen des Fragment-Katalogs
  (`modules/standards/README.md`, zur Laufzeit gelesen): Dependency-Signale gegen
  die neuen Dependencies und `*characteristic:*`-Eigenschafts-Trigger gegen die
  Aufgabenbeschreibung (prep-step-Touchpoint von F-017).
- Vorschlags-Pfade: vorhandenes Katalog-Fragment → Anhängen als Plan-Bestandteil
  (Mechanik wie `/choose-stack`, idempotent); kein Katalog-Fragment → Autoring
  eines projektlokalen Fragments + Promote via `/update-conventions` anbieten.
  Nie still einbauen — Entscheidung fällt mit der Plan-Freigabe. Die Plan-Vorlage
  hat dafür eine neue Zeile „Standards-Abdeckung".

## 0.9.0 — 2026-07-19

`update-conventions` gleicht CODING-STANDARDS fragment-granular ab (Gegenstück zum
choose-stack-Einbau aus 0.8.0):

- **Zwei Diff-Ebenen abwärts:** Der Datei-Diff der `CODING-STANDARDS.md` hält den
  §13-Slot konstant (Ist-Slot wird in die Soll-Fassung injiziert) und zeigt nur
  Core-Änderungen; die `fragment:NAME`-Blöcke im Slot werden einzeln gegen ihr
  Template-Pendant gedifft — Entscheidung je Fragment (übernehmen / lassen /
  Override / promoten). Projektlokale Fragmente ohne Template-Pendant werden nie
  angefasst, nur aufgelistet; Inline-Override-Marker schützen einzelne Fragmente.
- **Neu deklarierte Fragmente:** Fehlt im Projekt ein inzwischen vom `MODULE.md`
  deklariertes Katalog-Fragment, bietet der Abwärts-Lauf das Anhängen an (Mechanik
  wie `/choose-stack`, idempotent; Bestehendes in-place, Neues ans Slot-Ende, nie
  umsortieren).
- **Promote:** Ein bewährtes projektlokales Fragment kann generalisiert in den
  Katalog wandern (`modules/standards/<name>.md` + Katalog-Zeile im README).

## 0.8.0 — 2026-07-19

`choose-stack` baut Standards-Fragmente komponierbar ein (Vertrag: project-template
MANIFEST § Standards fragments):

- Statt EINEN `CODING-STANDARDS.part.md` in den §13-Slot einzufügen, hängt Modus B
  jetzt die Fragmentliste des Moduls an: eigenes Sprachfragment plus die im
  `MODULE.md` deklarierten Katalog-Fragmente (`Standards fragments:`-Zeile, tolerant
  gelesen — fett/plain, `(none)`/leer/fehlend = keine). Idempotent je
  `fragment:NAME`-Marker: Vorhandenes wird nie doppelt eingebaut und nie erneuert
  (Erneuern bleibt `/update-conventions`); der Platzhaltertext im Slot fällt beim
  Erst-Einbau weg.
- Modulwechsel: das Sprachfragment wird getauscht, Katalog-Fragmente bleiben stehen
  und werden nur zur Prüfung aufgelistet — Entfernen ist Projektentscheidung.
- `new-project` referenziert den Modul-Einbau entsprechend (Standards-Fragmente
  anhängen statt „Slot füllen").

## 0.7.0 — 2026-07-14

`build-step` entkoppelt den step-done-Handoff vom Bauen:

- **Interaktiv (Normalfall):** build-step baut und verifiziert den Substep, startet
  step-done aber **nicht mehr automatisch** — es empfiehlt `/coding-kit:step-done`,
  damit du prüfen und ggf. anpassen kannst, bevor der Schritt fertig ist. Der nächste
  Substep folgt erst nach deinem Abschluss bzw. ausdrücklichem „weiter".
- **Autonomer `/goal`-Lauf:** unverändert — step-done läuft je Substep automatisch
  durch (die `/goal`-Abschlussbedingung verlangt genau das). Modus-Signal: ein aktiver
  `/goal`-Lauf mit erteilter Commit-Freigabe = autonom, jede andere Nutzung = interaktiv.

## 0.6.0 — 2026-07-13

Status-Marker-Konvention + schärfere Grenze zwischen add-feature und prep-step:

- PROGRESS-Einträge tragen jetzt eine sprachinvariante `**Status:**`-Zeile:
  `BACKLOG` (nur aufgenommen → prep-step) → `PLANNED` (geplant → build-step);
  fertig bleibt Done-Tabelle + `(DONE)` im FEATURE-INDEX. prep-step markiert
  zusätzlich die Index-Zeile mit `(PLANNED)`. Alt-Einträge ohne Status-Zeile
  werden tolerant gelesen (Substeps vorhanden ≈ geplant) und beim nächsten
  Kontakt nachgezogen.
- `add-feature` — „Mögliche Umsetzung" heißt jetzt „Lösungsskizze" und ist
  explizit eine grobe, unverbindliche Richtung: keine Dateilisten, keine
  Zerlegung in Schritte, keine Abnahmekriterien (das bleibt prep-step);
  optionale Ablauf-/Ansatz-Zusatzabschnitte gestrichen. Neue Einträge starten
  mit `Status: BACKLOG`.
- `prep-step` — hinterfragt die Lösungsskizze, statt sie blind zu übernehmen:
  jede Annahme gegen den aktuellen Codestand verifizieren, eigene/bessere
  Ansätze mit Begründung vorschlagen; Plan-Vorlage um „Bewertung der
  Lösungsskizze" ergänzt. Setzt nach Freigabe `Status: PLANNED` (auch bei
  kleinen Aufgaben) und zieht die Skizze auf den beschlossenen Stand nach.
- `build-step` — prüft beim Plan-Laden den Status-Marker: `BACKLOG` → erst
  prep-step empfehlen statt ungeplant zu bauen.
- `step-done` — `(DONE)` ersetzt ein `(PLANNED)`-Suffix im FEATURE-INDEX; die
  Status-Zeile wandert nicht mit ins Archiv.
- `docs/skill-authoring.md` — Status-Marker-Konvention als Pflicht-Baustein.

## 0.5.0 — 2026-07-13

Neue Skills:

- `build-step` (Workflow) — die bisher fehlende Implementierungsphase als Skill:
  prep-step-Plan laden, Substeps mit Verifikation je Schritt abarbeiten
  (Write-then-Verify, just-Checks, Abnahmekriterien gegen Tool-Ausgaben abhaken),
  je Substep an step-done übergeben; Scope-Schutz (Entdeckungen → add-feature statt
  still mitbauen), nie pushen. Mit Argument `autonom` baut er nicht, sondern
  bereitet einen `/goal`-Lauf vor: Regeln laden, einmalige laufbezogene
  Commit-Freigabe einholen, fertige Goal-Zeile ausgeben (Varianten mit/ohne
  Commit-Freigabe, Turn-Limit als Stopp-Klausel).

- `teach-step` (Workflow) — Feature geführt selbst umsetzen: der Skill agiert als
  Coding-Lehrer, der Nutzer schreibt allen Code selbst. Sokratischer Lehr-Loop je
  Häppchen (orientieren → Arbeitsauftrag → kontrollieren via git diff/Re-Lesen →
  Tests über just → Verständnisfrage), gestufte Hilfe (Leitfrage → Tipp → Hinweis →
  Pseudocode → Musterlösung nur auf Anfrage), Lern-Interview mit Defaults, optionales
  Graphiti-Lernprofil (persönliche group_id). Schreibverbot hart via
  `disallowed-tools: Write, Edit, NotebookEdit`; Bash nur lesend/prüfend erlaubt.
  Abschluss (PROGRESS, Scans, Commit) bleibt bei `step-done`.
- `refine-prompt` (Utility) — übergebenen Prompt analysieren (Ziel, Zielgruppe,
  Format, Kontext), Schwachstellen benennen, nach Prompt-Engineering-Best-Practices
  neu formulieren und den verbesserten Prompt anschließend ausführen. Nur manuell
  aufrufbar (`disable-model-invocation`).

Geänderte Skills & Vorlagen:

- `step-done` — Ausnahme-Regel zur Commit-Frage: Bei ausdrücklicher, laufbezogener
  Commit-Freigabe des Nutzers (autonomer build-step-Lauf) wird nach grünen Checks
  und Scans ohne erneute Nachfrage committet — nie gepusht, keine History-Rewrites.
  Ohne Freigabe im autonomen Lauf: Commit-Vorschlag festhalten und weiterarbeiten
  statt blockieren.
- `templates/global-CLAUDE.md` — Halbsatz zur Commit-Regel: eine ausdrückliche,
  laufbezogene Freigabe zählt als Fragen; Push bleibt auch dann tabu.

## 0.4.0 — 2026-07-07

Pflege-Skills:

- `update-conventions` — bidirektionaler Konventions-Sync. Abwärts: Projekte via
  Marker-Topic + lokale Checkouts finden, deterministischer Abgleich über
  template-version-Stempel + MANIFEST (Soll-Fassung instanziieren, Diff + Bestätigung
  je Datei, Override-Schutz vor dem Diffen, seed nie anfassen), Altprojekt-Migrationen
  als einzeln bestätigte Schritte (heuristischer Abgleich, instructions.md→CLAUDE.md,
  Core-Skill-Kopien entfernen bei installiertem Plugin, Renovate-Onboarding,
  Tooling-Nachrüstung, Stempel setzen). Aufwärts („promote"): projektlokale Änderung
  generalisieren und mit VERSION-Bump + CHANGELOG (+ MANIFEST) in den Kern heben —
  oder als Override registrieren.
- `check-upstreams` — Watchliste externer Vorbild-Repos (`upstreams.json` im Kit-Repo):
  Neuerungen seit dem persistierten Ref zusammenfassen (gh compare/releases),
  Übernahme-Vorschläge, Ref-Update nach Bestätigung. Startliste: die Muster-Quelle
  ai-coding-starter-kit (Ref auf Analysestand) und betterleaks als
  gitleaks-Nachfolge-Kandidat (Erstprüfung offen).

## 0.3.0 — 2026-07-07

- `new-project` — der Orchestrator: Short-Info-Erhebung (M1), Abfragen mit Defaults
  (Name/Lizenz/Sichtbarkeit/Modul/Doku-Sprache/group_id/Anforderungen, Sub-Skills
  aufrufbar, Aufschieben erlaubt), Plan mit Bestätigung, dann: `gh repo create
  --template` (kein git init), Instanziierung streng nach MANIFEST (Platzhalter,
  adapt-/optional-Marker, public-only, Modul-Kontrakt, Aufräumen der Template-Dateien),
  `template-version`-Stempel, Repo-Settings inkl. Marker-Topic `coding-kit`,
  Verifikation `mise install && just setup && just check`, Personendaten-grep,
  Erst-Commit nur nach OK, Graphiti-Seeding. Trockenlauf via Argument `dry-run`;
  jeder außenwirksame Schritt einzeln bestätigt. Prüft `manifest-format` und bricht
  bei unbekannter Formatversion ab.

## 0.2.0 — 2026-07-07

Begleit-Skills (einzeln nutzbar und von `/new-project` aufrufbar):

- `name-it` — Namenskandidaten nach Kriterien, Verfügbarkeits-Checks (GitHub/npm/PyPI,
  Domain optional) zur Laufzeit.
- `choose-license` — M1-Kurzinterview → Empfehlung (Default Apache-2.0; MIT/MPL-2.0
  als Alternativen; GPL/AGPL nur bewusst; „TBD" gültig).
- `choose-stack` — Modus Neuanlage (Modul-Empfehlung, Websuche-verifiziert) und Modus
  Bestandsprojekt (EIN Modul nachrüsten/wechseln, Diff + Bestätigung je Datei,
  Override-Schutz); Grenze zu `/update-conventions` dokumentiert.
- `define-requirements` — M1-Interview → REQUIREMENTS.md (M5-Struktur) → initiale
  PROGRESS.md (eine F-Nummer je Anforderung); verwaltet den Auflöse-Trigger.
- `refine-requirements` — M2-Diagnose mit drei Pfaden (Änderung von außen /
  Implementierungs-Lücke / Grundsatz-Challenge), darf Features splitten, schreibt
  datierte Decision-Log-Einträge.

## 0.1.0 — 2026-07-07

Erstes Grundgerüst:

- Vier Core-Skills: `add-feature`, `prep-step`, `step-done` (mit Privacy-Scan der
  lebenden Doku), `audit-code` — stack-agnostisch, personendatenfrei, F-NNN-tolerant.
- Projekterkennender Stop-Hook (PROGRESS.md mit FEATURE-INDEX oder
  `.claude/template-version`; blockt höchstens einmal pro Stopp).
- Marketplace `xnyzer` mit Plugin-Quelle im selben Repo.
- Renovate-Shareable-Preset (`default.json`): `config:recommended` + Action-Digest-
  Pinning + Label `dependencies`.
- Idempotenter Installer (`install.sh`) inkl. Personal-Config `~/.claude/coding-kit.env`.
