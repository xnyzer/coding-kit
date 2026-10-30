---
name: step-done
description: Nach Abschluss einer Aufgabe ausführen. Review gegen CODING-STANDARDS (ohne sie gegen drei Abschnitte der Vorlage) nach fünf Prüffragen — verständlich, einfach, sicher, lesbar, kein Workaround — samt Behebung vorhandener Fehler im berührten Code, Checks über just, Erkennungs-Backstop (neu eingeführte Frameworks ohne Fragment, Sprachen ohne Stack-Modul), Backstop für geänderte managed Dateien ohne Registry-Eintrag, Secrets-Scan, Privacy-Scan der lebenden Doku, Verbuchung in der Feature-Datei (Verlauf-Eintrag, Abnahmekriterien mit Beleg, Status IN-PROGRESS bzw. DONE, erzeugte Index-Tabelle, Vorschlag zur Reihenfolge) und Commit nach einer gemeinsamen Freigabe (Vorschau vor dem Schreiben), Graphiti-Update.
disable-model-invocation: false
user-invocable: true
---

# Abschluss-Checkliste

Eine Aufgabe oder ein Substep ist fertig — ein Feature (F-001) oder einer seiner Substeps
(F-001a); Alt-Formate (Schritt „1.2") in Texten tolerant lesen. Arbeite die Checkliste systematisch ab und
erledige jeden Punkt selbst — **außer wo ausdrücklich eine Nutzerfrage verlangt ist**.
Fasse am Ende zusammen, was du getan hast.

## 0. Projektkontext ermitteln

Lies die **Projekt-CLAUDE.md**: Sprachen (Languages-Block; Alt-Projekte: einzeilige
Doku-Sprach-Angabe), Graphiti-group_id (ohne
Graphiti-Block/MCP → Graphiti still überspringen), Sicherheits-Postur (öffentliches Repo
oder Security-/Auth-Charakter, z. B. `THREAT-MODEL.md` vorhanden → strengster Maßstab
bei Secrets/Privacy). Nichts davon hardcoden.

**Altes Format:** Hat das Projekt eine `PROGRESS.md` mit `FEATURE-INDEX`-Block, aber keine
`features/INDEX.md`, arbeitet es noch mit dem Dokumentmodell vor coding-kit 2.0.0. Dann
nichts verbuchen und nicht raten: auf die Migration per `/coding-kit:update-conventions`
verweisen. Review, Checks und Scans (Schritte 1–3) laufen trotzdem; committen nur, wenn
der Nutzer es ohne Verbuchung will.

## Kontext-Recovery

Nach Kompaktierung oder Session-Neustart: (1) Projekt-CLAUDE.md, `features/INDEX.md` und
die Feature-Datei neu lesen,
(2) `git status` + `git diff` für den tatsächlichen Arbeitsstand, (3) beim aktuellen
Punkt der Checkliste weitermachen — erledigte Arbeit nicht wiederholen.

## 1. Code-Review & Checks

- **Maßstab laden:** die `CODING-STANDARDS.md` des Projekts lesen (falls noch nicht im
  Kontext); sie gilt, auch wo sie von der Vorlage abweicht. Fehlt sie, gelten als Ersatz
  die Abschnitte Mindset, Control flow und Secure coding der Vorlage
  `${CLAUDE_PLUGIN_ROOT}/template/core/CODING-STANDARDS.md` — einmal sagen, dass dieser
  Ersatz gilt. Mit Projektdatei wird die Vorlage nicht zusätzlich herangezogen.
- **Alle in diesem Schritt geänderten/neuen Dateien** gegen den Maßstab prüfen,
  ausdrücklich nach fünf Prüffragen:
  - **verständlich:** Versteht jemand, der neu im Code ist, die Änderung ohne Erklärung?
  - **einfach:** Ist es die einfachste tragfähige Lösung, ohne Abstraktion auf Vorrat?
  - **sicher:** Eingaben an Vertrauensgrenzen geprüft, keine Injection, Zugriffe
    berechtigt, keine Secrets?
  - **lesbar:** menschenlesbarer Quelltext, nie minifiziert oder auf eine Zeile gepresst
    (auch JSON, CSS, Konfiguration)? Minifiziertes aus einem Build-Werkzeug ist kein
    Fund, von Hand bearbeitetes schon — im Zweifel melden statt umformatieren.
  - **kein Workaround:** keine Umgehung, kein `HACK`, kein „später richtig"?

  Fragen ohne Bezug entfallen (etwa „sicher" bei einem Tippfehler), „lesbar" gilt immer.
  In der Zusammenfassung das Review in einer Zeile nennen, mit dem Maßstab darin:
  „Review gegen die `CODING-STANDARDS.md`: …" bzw. „Review gegen den Ersatz aus der
  Vorlage (Mindset, Control flow, Secure coding): …".
- **Kommentar-/Docstring-Sprache** gegen den Languages-Block prüfen (ohne Block:
  englisch).
- **Verstöße direkt beheben** — nicht als Frage an den Nutzer zurückspielen.
- **Vorhandene Fehler:** Stößt das Review im berührten Code auf einen Fehler, der schon
  vorher da war (falsches Verhalten, Sicherheitslücke, roter Check, Warnung), gleich
  beheben, mit einem Test belegen und im Verlauf-Eintrag unter Funde nennen. Vorher
  fragen, wenn die Korrektur groß ist, Verhalten ändert, auf das sich anderes verlässt,
  oder in einem anderen Teil des Projekts liegt; auf Wunsch wird daraus eine F-Nummer
  vom Typ `fix`. Fehler in vendortem oder erzeugtem Code (Fremdbibliothek,
  Build-Ausgabe) nur melden — die Korrektur gehört an die Quelle.
- Checks stack-agnostisch über die just-Standardrezepte ausführen: **`just check`** ist
  das Vollgate; bei Bedarf gezielt `just test` / `just lint`. Gibt es kein justfile:
  projektübliche Checks aus CLAUDE.md/README ermitteln — nie einen Stack raten. Bei
  reinen Doku-Änderungen: interne Links und Formatierung prüfen.
- Rote Ergebnisse sofort fixen. **Nie mit roten Checks committen.** Vorbestehende rote
  Tests trotzdem fixen oder explizit melden.
- **Write-then-Verify:** Nach jedem Edit die Datei re-lesen; nichts als erledigt melden,
  was nicht per Tool-Ausgabe belegt ist.

## 1a. Standards- und Modul-Abdeckung (Backstop)

Nur in Kit-Projekten (`.claude/template-answers` oder ein Fragment-Slot
`<!-- module:coding-standards -->` in der `CODING-STANDARDS.md`), die ein Git-Repo sind —
sonst still überspringen. Ein Schritt, der eine neue Sprache, ein Framework oder eine
Signal-Datei (z. B. `Dockerfile`) einführt, soll das nicht ohne passende Vorlage tun.

- `sh <skript> detect --changed <template> <projekt>` ausführen — `<skript>` und
  `<template>` sind `${CLAUDE_PLUGIN_ROOT}/scripts/template-sync.sh` und
  `${CLAUDE_PLUGIN_ROOT}/template` (wie `/coding-kit:choose-stack` § 0), in
  Shell-Befehlen die aufgelösten Pfade. Es meldet nur Signale, die der Arbeitsbaum
  gegenüber HEAD neu hat — vor dem Commit also die dieses Schritts — und je Treffer
  `covered`, `declined` oder `missing`, für Tools ohne Vorlage `unknown` oder `declined`
  (`MANIFEST.md` § Detection). Keine Zeile oder nur `covered`/`declined` → still weiter.
  Ohne `.claude/template-answers` prüft das Skript keine Module; dann auf die Migration
  per `/coding-kit:update-conventions` hinweisen.
- **Fragment `missing`** → **Lücke melden** und das Anhängen vorschlagen (Mechanik wie
  `/coding-kit:choose-stack`, idempotent; ohne Fragment-Slot nur melden) — inklusive
  einer **Begleithandlung**, die das Fragment verlangt, dem Eintrag in `FRAGMENTS` der
  `.claude/template-answers` und den `keep`-Zeilen für managed Dateien, die die
  Begleithandlung ändert (alles `/coding-kit:choose-stack` § Begleithandlungen); das
  gehört in denselben Schritt.
- **Modul `missing`** → melden und anbieten: das Modul nach diesem Abschluss per
  `/coding-kit:choose-stack` nachrüsten **oder** die Sprache als Werkzeugsprache
  dauerhaft ablehnen — eine Zeile `module:NAME` in der Rules-Tabelle der
  `.claude/convention-overrides.md` (was das Projekt stattdessen tut, mit Grund) und
  `keep`-Zeilen für die managed Dateien, die die Toolchain von Hand ändert; beides gehört
  in diesen Commit (sonst meldet 1b die Dateien).
- **Tool `unknown`** (eine `tool`-Zeile: das Template hat für ein neues Tool weder Modul
  noch Fragment) → melden und anbieten: **dem Template vorschlagen** — den
  Hintergrund-Skill `propose-to-template` mit dem Fund starten (Art Tool, Name,
  mise-Datei) — **oder** dauerhaft ablehnen, weil das Tool keine Konvention braucht
  (Rules-Zeile `tool:NAME` mit Grund, in diesen Commit).
- **Dauerhaft ablehnen** geht auch für ein Fragment (Rules-Zeile `fragment:NAME`); danach
  meldet kein Skill den Vorschlag mehr. `*characteristic:*`-Trigger erkennt kein Skript —
  sie sind Planungsmaterie von prep-step 2a.
- Der Abschluss wird dadurch **nicht blockiert**; lehnt der Nutzer nur für diesmal ab,
  die offene Lücke im Verlauf-Eintrag (Schritt 4) vermerken, damit sie sichtbar bleibt.
- Enthält der Diff einen **neu angelegten projektlokalen Fragment-Block**
  (`fragment:NAME` ohne Katalog-Pendant) → anbieten, ihn dem Template vorzuschlagen
  (`propose-to-template` mit dem Fund starten); rein informativ, abschicken tut der
  Nutzer.

## 1b. Managed Dateien (Backstop)

Nur wenn das Projekt einen Basis-Snapshot hat (`.claude/template-base/`) — sonst still
überspringen. Ein Schritt, der eine Datei aus dem Template ändert, soll das bewusst tun
und mit Grund festhalten, nicht erst beim nächsten Template-Update auffallen.

- `sh <skript> changed <projekt>` ausführen — `<skript>` ist
  `${CLAUDE_PLUGIN_ROOT}/scripts/template-sync.sh`, in Shell-Befehlen der aufgelöste Pfad.
  Es listet die managed Dateien, die der Arbeitsbaum gegenüber HEAD berührt, mit Zustand
  und Registry-Art (Files-Tabelle der `.claude/convention-overrides.md`).
- Je Zeile `deviates` mit Registry `none`: die Abweichung zeigen
  (`git diff --no-index .claude/template-base/<Datei>.base <Datei>`) und anbieten:
  **(a)** eine Zeile mit Grund in die Files-Tabelle (Art leer, `keep` oder `adapt`),
  **(b)** die Änderung zurücknehmen, **(c)** sie dem Template vorschlagen
  (`propose-to-template` mit dem Fund starten: Datei, Diff), wenn sie allen Projekten
  nützt. Zeilen mit einer Art sind registriert — nichts melden.
- `snapshot-edited`: Den Snapshot setzen nur `/coding-kit:update-conventions`,
  `/coding-kit:new-project`, `/coding-kit:choose-stack` und `/coding-kit:choose-license`.
  War dieser Schritt ein solcher Lauf, ist die Änderung erwartet; sonst wurde der
  Snapshot von Hand geändert — als Fehler melden und das Zurücknehmen anbieten
  (`git checkout -- <Pfad>`).
- **Nicht blockierend:** Lehnt der Nutzer alles ab, geht der Abschluss weiter; die
  unregistrierte Abweichung im Verlauf-Eintrag (Schritt 4) vermerken.

## 2. Secrets-Scan (KRITISCH)

Vor jedem Commit-Vorschlag die Working-Tree-Änderungen **und** den Commit-Message-Entwurf
scannen — bei Security-Postur mit maximaler Schärfe:

- Echte Tokens/Bearer/Passwörter/API-Keys/private Schlüssel (PEM/JWK), private
  E-Mail-Adressen.
- Deployment-Interna: konkrete IPs, SSH-Key-Namen, Hostnames, Domains.
- Inhalte, die nach `private/` (gitignored) gehören, aber im öffentlichen Baum liegen.

**Funde sofort entfernen/maskieren** und erneut prüfen. **Kein Commit-Vorschlag, solange
etwas offen ist.**

## 3. Privacy-Scan der lebenden Doku

Zusätzlich zum Secrets-Scan: die in diesem Schritt geänderte **lebende Doku**
(Feature-Datei, `features/INDEX.md`, CLAUDE.md, README …) auf Privatinfos prüfen —
jedes Projekt muss jederzeit publishbar bleiben:

- Klarnamen, Kunden-/Arbeitgebernamen, private E-Mail-Adressen.
- Absolute lokale Pfade (`/Users/…`, `/home/…`), Rechner-/Gerätenamen, WLAN-/Share-Namen.
- Private IPs/Hostnames aus der eigenen Infrastruktur.
- Verweise auf Inhalte, die nur in `private/` existieren.

Erlaubt sind dokumentierte Platzhalter (example.com, RFC-5737-IPs wie 192.0.2.x,
GitHub-noreply-Adressen). Befunde **vor** dem Commit-Vorschlag beheben: Inhalt nach
`private/` verschieben **oder** neutral umformulieren (generische Platzhalter) — im
Zweifel den Nutzer fragen, welche Variante er will.

## 4. Verbuchung vorbereiten (Vorschau)

**Freigabe-Gate:** Jede neue oder geänderte Feature-Datei (`features/F-NNN-*.md`), jede
Änderung an `features/INDEX.md` und an den Ziel-Abschnitten im Überblick der
`CLAUDE.md` wird zuerst als Vorschau gezeigt und erst nach ausdrücklichem OK des Nutzers
geschrieben (ausgenommen: genau der zuvor freigegebene Text; die Tabelle erzeugt danach
das Skript). Lange Entwürfe (etwa ab 40 Zeilen) gehen als Datei nach `private/` und
werden nach dem Übernehmen gelöscht. In diesem Schritt also **nur vorbereiten, noch
nicht schreiben** — die Vorschau geht in Schritt 5 zusammen mit der Commit-Message an
den Nutzer.

Vorzubereiten in der Feature-Datei, in der Sprache der lebenden Doku (siehe Schritt 0);
Feldnamen, Status-Token und Kürzel bleiben englisch:

- **Verlauf-Eintrag** — je Substep einer, unter der Überschrift „F-NNNa — fertig
  JJJJ-MM-TT" (ein Feature ohne Substeps: „F-NNN — fertig JJJJ-MM-TT") im Abschnitt
  Verlauf (fehlt er, aus der Vorlage `features/F-000-template.md` anlegen), ältester
  oben:
  - **Umgesetzt:** was entstanden ist und wie es funktioniert, mit den wichtigen Dateien
    und Stellen — keine vollständige Dateiliste, die hat der Commit.
  - **Entscheidungen:** was entschieden wurde und warum, auch Nutzerentscheidungen;
    Planungsentscheidungen stehen schon unter Spezifikation und werden nicht wiederholt.
  - **Abweichung vom Plan:** was und warum (aus build-step gesammelt), oder „keine".
  - **Funde:** neue Aufgaben (→ `/coding-kit:add-feature`, eigene Freigabe), offene
    Lücken aus 1a/1b.
  Das Problem steht nur oben in der Datei — der Verlauf wiederholt es nicht.
- **Abnahmekriterien:** die des Substeps abhaken, mit Beleg in derselben Zeile
  („— belegt: Test …", „— belegt: `just check`"). Ein Kriterium ohne Beleg bleibt offen
  und wird gemeldet.
- **Status** im Kopfblock: nach dem ersten verbuchten Substep `IN-PROGRESS`; nach dem
  letzten — alle Substeps im Verlauf, **alle** Abnahmekriterien belegt — `DONE` mit
  `done:` auf heute. Ein Feature ohne Substeps (S) geht von `PLANNED` direkt nach
  `DONE`. `DONE` ist endgültig; Folgearbeit bekommt eine neue Nummer.
- **Empfohlene Reihenfolge** in `features/INDEX.md`: ist das Feature fertig, fällt es
  dort heraus; verschiebt sich sonst etwas (neue Abhängigkeit, ein Fund), eine Änderung
  vorschlagen, Stand-Datum auf heute.
- **Tabelle:** wird nach dem Schreiben per Skript erzeugt (Schritt 5) — nie von Hand.

**Done-Prüfung** vor der Vorschau: Schritte 1–3 grün, die Abnahmekriterien des Substeps
belegt, der Verlauf-Eintrag vorbereitet, die Index-Änderungen vorbereitet. Fehlt etwas,
melden statt verbuchen.

## 5. Freigabe, Verbuchung und Commit

- **Eine Frage für beides:** die Vorschau aus Schritt 4 (Verlauf-Eintrag, abgehakte
  Abnahmekriterien, Status, Änderung der Reihenfolge) und eine aussagekräftige
  Conventional-Commits-Message zeigen — Prosa in der Commit-Sprache des Projekts
  (Languages-Block; ohne Block englisch), Format-Tokens immer englisch.
  Antwortmöglichkeiten: verbuchen und committen / nur verbuchen / Änderungen am Text.
- **Nach OK:** Feature-Datei und `features/INDEX.md` schreiben, die Tabelle erzeugen
  (`just features-index`, ohne das Rezept `sh scripts/features-index.sh write`), alles
  re-lesen, `just check` erneut, dann (falls freigegeben) committen. **Nie automatisch
  committen** und nie ohne OK verbuchen. Einen Entwurf aus `private/` danach löschen.
- **Nie pushen, nie ältere Historie ändern** (kein Amend, kein Rebase) — gepusht wird
  nur auf ausdrückliche Bitte des Nutzers.
- Im Body Designentscheidungen kurz begründen (`Decision: X over Y because …`); hat der
  Nutzer abgewogen: „User chose X over Y because …".

### 5a. Commit-E-Mail prüfen (KRITISCH)

Vor jedem `git commit` prüfen, dass die E-Mail eine **GitHub-noreply-Adresse** ist:

```bash
git config --get user.email
```

Erwartetes Format: `<numerische-id>+<github-login>@users.noreply.github.com`.
Weicht sie ab, zur Laufzeit auflösen — nie eine Adresse hardcoden:

```bash
GH_ID=$(gh api user --jq '.id')
GH_LOGIN=$(gh api user --jq '.login')
git config --local user.email "${GH_ID}+${GH_LOGIN}@users.noreply.github.com"
```

Erst dann committen. Nie `--author="…"` mit einer echten E-Mail verwenden. **Warum:** in
einem öffentlichen Repo darf keine private E-Mail in Commits landen — das wäre ein
permanentes Datenleck; Aufräumen hieße `git filter-repo` + Force-Push.

### 5b. Co-Authored-By

Der Commit-Body endet mit:

```
Co-Authored-By: Claude <noreply@anthropic.com>
```

## 6. Graphiti-Wissensgraph

Erst nach der Verbuchung aus Schritt 5 — der Graph soll nur festhalten, was der Nutzer
freigegeben hat.

- `add_memory` mit der group_id aus der Projekt-CLAUDE.md aufrufen (falls verfügbar,
  sonst still überspringen).
- Beschreiben: was fertig wurde (mit dem Pfad der Feature-Datei), welche
  Dateien/Komponenten, welche Config/Endpunkte/Dependencies, welche
  Architektur-/Sicherheitsentscheidungen.
