---
id: F-065
title: Releases als Git-Tag und GitHub-Release veröffentlichen
type: feature
status: IN-PROGRESS
size: M
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-065 — Releases als Git-Tag und GitHub-Release veröffentlichen

## Erfassung

**Problem:** Ein Release besteht heute nur aus der datierten CHANGELOG-Überschrift und
dem Commit „chore: release X.Y.Z“. Das Repo hat keinen Git-Tag und kein GitHub-Release;
die Repo-Seite zeigt „Create a new release“, und von außen ist nicht zu sehen, welcher
Stand veröffentlicht ist und was er enthält. Der Ablauf selbst steht in keiner Datei.

**Ziel:** Als Nutzer des Kits möchte ich jede veröffentlichte Version als Git-Tag und
GitHub-Release mit ihrem CHANGELOG-Abschnitt sehen, damit Stand und Inhalt jeder
Version ohne Blick in den CHANGELOG zu finden sind.

**Lösungsskizze:**
- Release-Ablauf: nach dem Commit „chore: release X.Y.Z“ ein Tag `vX.Y.Z` auf genau
  diesen Commit, den Tag pushen und mit `gh release create` ein Release anlegen, dessen
  Text der CHANGELOG-Abschnitt der Version ist.
- Alte Versionen 1.0.0 bis 3.7.0 nachträglich: der Tag auf den Release-Commit; wo es
  keinen gibt (3.2.0, 3.2.1, 3.3.0, 3.3.1, 3.4.0), auf den letzten Commit, der unter
  `plugins/` etwas ändert, solange `plugin.json` die Version trägt. Jedes Release mit
  seinem CHANGELOG-Abschnitt und dem damaligen Datum; nur die neueste Version ist
  „Latest“.
- Die eingefrorenen Reihen (Kit vor 1.0.0, project-template bis 0.16.0) bekommen keine
  Tags — ihre Nummern überschneiden sich, und sie gehören zu früheren Repos.
- Den Ablauf dort festhalten, wo er gefunden wird (Kit-CLAUDE.md, README).
- Tag und Release wirken nach außen: jeder Schritt nur nach Freigabe.

**Abhängigkeiten:** keine.

**Noch zu analysieren:** Geklärt in der Spezifikation (Entscheidungen vom 2026-11-22).

## Spezifikation

### Abnahmekriterien

- [x] AC-1 — Gegeben eine datierte Version ab 1.0.0 im CHANGELOG, wenn
  `just release-notes X.Y.Z` läuft, dann gibt es den Abschnitt dieser Version aus — ohne
  Überschrift, ohne Leerzeilen am Anfang und Ende, bis vor die nächste `## `-Überschrift —
  und endet mit Exit 0; mit `--title` gibt es stattdessen den Text der Überschrift aus
  (z. B. „3.7.0 — 2026-11-22“). — belegt: `just check` (3498 Checks, 0 failed) mit den
  Fällen zu Abschnitt und Titel; am echten CHANGELOG liefern alle 21 Versionen 1.0.0 bis
  3.7.0 Titel und Text ohne fremde Überschrift.
- [x] AC-2 — Gegeben eine Version, die im CHANGELOG fehlt, noch nicht datiert ist
  („— unveröffentlicht“), nur in den eingefrorenen Reihen steht oder kein `X.Y.Z` ist,
  wenn das Skript läuft, dann schreibt es eine Fehlermeldung auf stderr, nichts auf stdout
  und endet mit einem Exit-Code ungleich 0. — belegt: Fälle für undatiert, eingefroren,
  fehlend und unlesbar (Exit 1) sowie für `3.2.0-rc`, `3x2x0`, `3.2` und falsche
  Argumente (Exit 2), jeweils ohne Ausgabe auf stdout; die Gegenprobe mit kaputten Kopien
  des Skripts schlug an.
- [x] AC-3 — Gegeben ein anstehendes Release, wenn man in der Kit-CLAUDE.md nachliest,
  dann beschreibt der Abschnitt Konventionen den Ablauf: Überschrift datieren, Commit
  „chore: release X.Y.Z“, annotierter Tag `vX.Y.Z` auf diesen Commit, main und Tag
  pushen, `gh release create` mit Titel und Text aus dem Skript — jeder Schritt nach
  außen erst nach Freigabe. Die README (Pflege) verweist darauf, der CHANGELOG-Kopf nennt
  Tag und Release. — belegt: CLAUDE.md (Konventionen), README (Pflege, Repo-Struktur) und
  CHANGELOG-Kopf nach dem Schreiben neu gelesen.
- [ ] AC-4 — Gegeben die Versionen 1.0.0 bis 3.7.0 (21 Stück), wenn das Nachtragen
  durch ist, dann hat jede einen annotierten Tag `vX.Y.Z` auf GitHub, der auf den
  festgelegten Commit zeigt (Tabelle im Plan), und ein GitHub-Release mit Titel = Text der
  Überschrift und Text = Ausgabe des Skripts; nur 3.7.0 ist „Latest“. Negativfall: Es gibt
  keinen Tag `v0.*` und keinen für eine Version der eingefrorenen Reihen.
- [ ] AC-5 — Gegeben ein neuer Tag, wenn man ihn ansieht, dann ist die Tagger-Adresse die
  GitHub-Noreply-Adresse aus der Personal-Config und das Tag-Datum das des getaggten
  Commits.

### Randfälle

- EC-1 — 1.0.0 steht direkt über „## Eingefroren: …“ → der Abschnitt endet vor dieser
  Überschrift; der Kopf-Absatz über der ersten Version wird nie ausgegeben.
- EC-2 — Ähnliche Nummern (3.2.0 neben 13.2.0, 3.2.0-rc, 3x2x0) → das Skript vergleicht
  die Nummer exakt, nicht als Muster.
- EC-3 — Ein Tag oder Release gibt es schon (lokal oder auf GitHub) → nicht überschreiben,
  sondern melden und überspringen; das Nachtragen lässt sich gefahrlos wiederholen.
- EC-4 — Im Abschnitt 2.1.0 steht „#12“ im Fließtext → GitHub verlinkt das auf Issue
  oder PR 12 und benachrichtigt niemanden; hingenommen. Ein freies `@name` außerhalb von
  Code gibt es in keinem Abschnitt ab 1.0.0 (geprüft am 2026-11-22).

### Nicht-Ziele

- Kein Release-Ablauf für Projekte aus dem Template — das Template bleibt unberührt.
- Keine Tags für die eingefrorenen Reihen (Kit vor 1.0.0, project-template bis 0.16.0).
- Keine Prüfung in `just check` oder der CI, ob jede datierte Version einen Tag hat.
- Kein Gesamt-Rezept, das datiert, committet, taggt und pusht.
- Die Plugin-Installation bleibt beim Stand von main; Marketplace und Plugin lesen keine
  Tags.

### Tests

- AC-1, AC-2, EC-1, EC-2 → automatisch: Fälle in `tests/template-sync/release-notes.sh`
  gegen einen kleinen Test-CHANGELOG (unter dash und bash, mit mawk), dazu ein Fall gegen
  den echten CHANGELOG (Titel von 3.7.0).
- AC-3 → Durchsicht: Kit-CLAUDE.md, README und CHANGELOG-Kopf nach dem Schreiben neu lesen.
- AC-4 → nach dem Nachtragen: `git ls-remote --tags origin` zeigt genau
  v1.0.0 bis v3.7.0, jeder auf dem Commit der Tabelle; `gh release list` zeigt 21
  Releases, nur 3.7.0 als Latest; für alle 21 ist der Text auf GitHub gleich der
  Skriptausgabe.
- AC-5 → `git for-each-ref refs/tags` mit Tagger-Adresse und Tagger-Datum je Tag.
- EC-3 → den Nachtrage-Lauf ein zweites Mal starten: alles wird übersprungen.

### Einbettung

- Neu: `scripts/release-notes.sh` (POSIX-Shell und awk), `tests/template-sync/release-notes.sh`
  (von `run.sh` geladen), das Rezept `release-notes` im justfile.
- `scripts/script-tests.sh`: `scripts/release-notes.sh` kommt in die Pfadliste.
- Doku: Kit-CLAUDE.md (Konventionen, ersetzt den bisher ungeschriebenen Ablauf), README
  (Repo-Struktur und Pflege), CHANGELOG-Kopf.
- Versionsregel: Nichts davon ist Plugin-Inhalt (Skript im Root, CHANGELOG-Kopf) — keine
  neue Version.
- Tags und Releases sind öffentlich: Die Tagger-Identität folgt derselben Regel wie die
  Commit-E-Mail; die Release-Texte sind die schon öffentlichen CHANGELOG-Abschnitte.
- Die Absprache „Ein Release heißt: datieren und committen, ohne Tags“ gilt danach nicht
  mehr.
- Keine Folge-F-Nummer nötig.

### Offene Fragen

keine

### Entscheidungen

- 2026-11-22 — 3.7.0 erschien noch ohne Tag und bekommt Tag und Release nachträglich,
  zusammen mit 1.0.0 bis 3.6.0.
- 2026-11-22 — Ohne Release-Commit (3.2.0, 3.2.1, 3.3.0, 3.3.1, 3.4.0) kommt der Tag auf
  den letzten Commit, der unter `plugins/` etwas ändert, solange `plugin.json` die
  Version trägt. Die Skizze nannte den Commit, der die Überschrift datiert hat; der ist
  bei 3.2.0, 3.3.0 und 3.4.0 der erste der Version, und späteres wie F-033b–d fehlte.
  Wo es einen Release-Commit gibt, liefert die Regel genau ihn (außer bei 1.0.0, dort
  gilt der Release-Commit).
- 2026-11-22 — Ein kleines Skript schneidet Titel und Text aus dem CHANGELOG, der Ablauf
  steht als Doku; verworfen: nur Doku (jedes Mal anders, ungetestet) und ein Rezept für
  alles (Commit und Push in einem Zug statt einzeln freigegeben).
- 2026-11-22 — Titel des Releases ist der Text der CHANGELOG-Überschrift, damit steht das
  Datum sichtbar da — GitHub setzt das Erstelldatum auf den Tag des Anlegens. Annotierte
  Tags mit dem Datum des getaggten Commits.

## Plan

**Größe:** M — rund sieben Dateien und unter 200 Zeilen, die offenen Fragen sind
geklärt; die Reichweite hebt es an: 21 Tags und Releases sind öffentlich und lassen sich
nur von Hand zurücknehmen.

**Ansatz:** `scripts/release-notes.sh [--title] X.Y.Z [CHANGELOG]` — POSIX-Shell, die
Arbeit macht ein awk-Lauf über den CHANGELOG (Standard `plugins/coding-kit/CHANGELOG.md`,
der zweite Parameter dient den Tests). awk sucht die Zeile, deren Nummer genau `X.Y.Z`
ist und hinter dem Gedankenstrich ein Datum `JJJJ-MM-TT` trägt, und hört an der
Überschrift `## Eingefroren` auf zu suchen. Ausgegeben wird der Text der Überschrift
(`--title`) oder alles bis vor die nächste `## `-Überschrift, ohne Leerzeilen an den
Rändern. Das Rezept `just release-notes *args` ruft das Skript auf. Der Ablauf steht als
nummerierte Liste in der Kit-CLAUDE.md (Konventionen):

1. Überschrift datieren, `just check`, Commit „chore: release X.Y.Z“.
2. `git tag -a vX.Y.Z -m "coding-kit X.Y.Z"` auf den Release-Commit.
3. Nach Freigabe: `git push origin main vX.Y.Z`.
4. Nach Freigabe: `gh release create vX.Y.Z --verify-tag --title "<--title>"
   --notes-file <Skriptausgabe>`.

Verworfen: den Text in die Tag-Nachricht schreiben und `gh release create
--notes-from-tag` nutzen — der Abschnitt stünde doppelt im Repo, und lange Tag-Nachrichten
liest kaum jemand.

### F-065a — Skript, Tests und Doku

- Neu `scripts/release-notes.sh`, `tests/template-sync/release-notes.sh` (in `run.sh`
  geladen und aufgerufen), Rezept `release-notes` im justfile.
- `scripts/script-tests.sh`: `scripts/release-notes.sh` in die Pfadliste.
- Kit-CLAUDE.md (Konventionen: der Ablauf), README (Repo-Struktur, Pflege: ein Satz mit
  Verweis), CHANGELOG-Kopf (ein Satz: jede Version ab 1.0.0 hat Tag und Release).
- Erfüllt AC-1, AC-2, AC-3, EC-1, EC-2. Keine neue Version (kein Plugin-Inhalt).
- Commit lokal; gepusht wird auf deine Bitte, das braucht F-065b.

### F-065b — Tags und Releases für 1.0.0 bis 3.7.0 nachtragen

- Voraussetzung: F-065a ist gepusht.
- Commit-E-Mail prüfen (Tagger = Noreply-Adresse aus der Personal-Config).
- Annotierte Tags lokal anlegen, je mit `GIT_COMMITTER_DATE` = Datum des getaggten
  Commits; einen vorhandenen Tag überspringen und melden.
- Vorschau: Liste Tag → Commit → Titel; nach Freigabe die 21 Tags pushen.
- Nach Freigabe die Releases in aufsteigender Reihenfolge anlegen, alle mit
  `--latest=false`, zuletzt 3.7.0 mit `--latest`; ein vorhandenes Release überspringen.
- Prüfen nach AC-4, AC-5, EC-3 (zweiter Lauf überspringt alles), EC-4.
- Erfüllt AC-4, AC-5, EC-3, EC-4. Danach Verbuchung und Abschluss-Commit.

| Version | Commit | | Version | Commit | | Version | Commit |
|---------|--------|-|---------|--------|-|---------|--------|
| 1.0.0 | `b09549f` | | 1.7.0 | `c095e66` | | 3.3.0 | `3727646` |
| 1.1.0 | `8a67f22` | | 2.0.0 | `2a47334` | | 3.3.1 | `9c0f02a` |
| 1.2.0 | `46ef30b` | | 2.1.0 | `5d354ec` | | 3.4.0 | `b8a0afc` |
| 1.2.1 | `0601a57` | | 3.0.0 | `0a89504` | | 3.5.0 | `5d40326` |
| 1.3.0 | `3cecdd4` | | 3.1.0 | `de24bed` | | 3.6.0 | `d459e17` |
| 1.4.0 | `8c0ac24` | | 3.2.0 | `6c204de` | | 3.7.0 | `e58979d` |
| 1.5.0 | `ba9246d` | | 3.2.1 | `edac2ab` | | | |
| 1.6.0 | `516cb90` | | | | | | |

**Erkennung:** keine neuen Frameworks, Dependencies oder Toolchains (`gh` und `git` sind
schon da).

## Verlauf

### F-065a — fertig 2026-11-22

**Umgesetzt:** `scripts/release-notes.sh` liest den Plugin-CHANGELOG mit einem awk-Lauf.
Es sucht die Überschrift, die mit genau der Versionsnummer beginnt und danach ein Datum
trägt, und hört an „## Eingefroren“ auf zu suchen. Ausgegeben wird der Abschnitt bis vor
die nächste `## `-Überschrift ohne Leerzeilen an den Rändern, mit `--title` der Text der
Überschrift. Ist die Version kein Release (fehlend, undatiert, eingefroren) oder die
Datei unlesbar, endet es mit Exit 1; bei falschen Argumenten oder einer Nummer, die nicht
`X.Y.Z` ist, mit Exit 2 — jeweils nur mit Meldung auf stderr. Dazu das Rezept
`just release-notes` und 22 Fälle in `tests/template-sync/release-notes.sh`; das Skript
steht in der Pfadliste der Skript-Tests. Den Ablauf in vier Schritten beschreibt die
CLAUDE.md (Konventionen), README und CHANGELOG-Kopf verweisen darauf.

**Entscheidungen:** Exit 1 heißt „kein Release“, Exit 2 „falscher Aufruf“ — so
unterscheidet ein Aufrufer einen Tippfehler von einer noch nicht datierten Version.

**Abweichung vom Plan:** Fälle für eine unlesbare Datei und für `--title` an falscher
Stelle sind dazugekommen; das Zweite war ein Befund des unabhängigen Reviews (Meldung
„cannot read --title“ statt der Usage-Meldung).

**Funde:** keine.
