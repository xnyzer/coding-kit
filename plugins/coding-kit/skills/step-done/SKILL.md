---
name: step-done
description: Nach Abschluss einer Aufgabe ausführen. Review gegen CODING-STANDARDS, Checks über just, Erkennungs-Backstop (neu eingeführte Frameworks ohne Fragment, Sprachen ohne Stack-Modul), Backstop für geänderte managed Dateien ohne Registry-Eintrag, Secrets-Scan, Privacy-Scan der lebenden Doku, PROGRESS-Verbuchung und Commit nach einer gemeinsamen Freigabe (Vorschau vor dem Schreiben), Graphiti-Update.
disable-model-invocation: false
---

# Abschluss-Checkliste

Eine Aufgabe oder ein Substep ist fertig — gilt für F-Nummern (F-001, F-001a) und
Alt-Formate (Schritt „1.2") gleichermaßen. Arbeite die Checkliste systematisch ab und
erledige jeden Punkt selbst — **außer wo ausdrücklich eine Nutzerfrage verlangt ist**.
Fasse am Ende zusammen, was du getan hast.

## 0. Projektkontext ermitteln

Lies die **Projekt-CLAUDE.md**: Sprachen (Languages-Block; Alt-Projekte: einzeilige
Doku-Sprach-Angabe), Graphiti-group_id (ohne
Graphiti-Block/MCP → Graphiti still überspringen), Sicherheits-Postur (öffentliches Repo
oder Security-/Auth-Charakter, z. B. `THREAT-MODEL.md` vorhanden → strengster Maßstab
bei Secrets/Privacy). Nichts davon hardcoden.

## Kontext-Recovery

Nach Kompaktierung oder Session-Neustart: (1) Projekt-CLAUDE.md und PROGRESS.md neu lesen,
(2) `git status` + `git diff` für den tatsächlichen Arbeitsstand, (3) beim aktuellen
Punkt der Checkliste weitermachen — erledigte Arbeit nicht wiederholen.

## 1. Code-Review & Checks

- `CODING-STANDARDS.md` lesen (falls vorhanden und noch nicht im Kontext).
- **Alle in diesem Schritt geänderten/neuen Dateien** gegen die Regeln prüfen.
- **Kommentar-/Docstring-Sprache** gegen den Languages-Block prüfen (ohne Block:
  englisch).
- **Verstöße direkt beheben** — nicht als Frage an den Nutzer zurückspielen.
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
  `covered`, `declined` oder `missing` (`MANIFEST.md` § Detection). Keine Zeile oder nur
  `covered`/`declined` → still weiter. Ohne `.claude/template-answers` prüft das Skript
  keine Module; dann auf die Migration per `/coding-kit:update-conventions` hinweisen.
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
- **Dauerhaft ablehnen** geht auch für ein Fragment (Rules-Zeile `fragment:NAME`); danach
  meldet kein Skill den Vorschlag mehr. `*characteristic:*`-Trigger erkennt kein Skript —
  sie sind Planungsmaterie von prep-step 2a.
- Der Abschluss wird dadurch **nicht blockiert**; lehnt der Nutzer nur für diesmal ab,
  die offene Lücke im Archiv-Eintrag (Schritt 4) vermerken, damit sie sichtbar bleibt.
- Enthält der Diff einen **neu angelegten projektlokalen Fragment-Block**
  (`fragment:NAME` ohne Katalog-Pendant) → den **Übernahme-Vorschlag** fürs Template
  ausgeben (kopierfertiger Prompt bzw. GitHub-Request — siehe
  `/coding-kit:update-conventions` § Übernahme-Vorschlag); rein informativ, der
  Nutzer stößt die Aufnahme manuell an.

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
  **(b)** die Änderung zurücknehmen, **(c)** einen Übernahme-Vorschlag fürs Template
  (`/coding-kit:update-conventions` § Übernahme-Vorschlag), wenn die Änderung allen
  Projekten nützt. Zeilen mit einer Art sind registriert — nichts melden.
- `snapshot-edited`: Den Snapshot setzen nur `/coding-kit:update-conventions`,
  `/coding-kit:new-project`, `/coding-kit:choose-stack` und `/coding-kit:choose-license`.
  War dieser Schritt ein solcher Lauf, ist die Änderung erwartet; sonst wurde der
  Snapshot von Hand geändert — als Fehler melden und das Zurücknehmen anbieten
  (`git checkout -- <Pfad>`).
- **Nicht blockierend:** Lehnt der Nutzer alles ab, geht der Abschluss weiter; die
  unregistrierte Abweichung im Archiv-Eintrag (Schritt 4) vermerken.

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

Zusätzlich zum Secrets-Scan: die in diesem Schritt geänderte **lebende Doku** (PROGRESS.md,
PROGRESS-ARCHIVE.md, REQUIREMENTS.md, CLAUDE.md, README …) auf Privatinfos prüfen —
jedes Projekt muss jederzeit publishbar bleiben:

- Klarnamen, Kunden-/Arbeitgebernamen, private E-Mail-Adressen.
- Absolute lokale Pfade (`/Users/…`, `/home/…`), Rechner-/Gerätenamen, WLAN-/Share-Namen.
- Private IPs/Hostnames aus der eigenen Infrastruktur.
- Verweise auf Inhalte, die nur in `private/` existieren.

Erlaubt sind dokumentierte Platzhalter (example.com, RFC-5737-IPs wie 192.0.2.x,
GitHub-noreply-Adressen). Befunde **vor** dem Commit-Vorschlag beheben: Inhalt nach
`private/` verschieben **oder** neutral umformulieren (generische Platzhalter) — im
Zweifel den Nutzer fragen, welche Variante er will.

## 4. PROGRESS-Verbuchung vorbereiten (Vorschau)

**Freigabe-Gate:** Jeder neue oder geänderte Eintrag in `PROGRESS.md`,
`PROGRESS-ARCHIVE.md` oder im FEATURE-INDEX wird zuerst als Vorschau gezeigt und erst
nach ausdrücklichem OK des Nutzers geschrieben (ausgenommen: genau der zuvor
freigegebene Text). In diesem Schritt also **nur vorbereiten, noch nicht schreiben** —
die Vorschau geht in Schritt 5 zusammen mit der Commit-Message an den Nutzer.

Vorzubereiten, in der Sprache der lebenden Doku (siehe Schritt 0):

- **PROGRESS-ARCHIVE.md:** Den kompletten Abschnitt der fertigen Aufgabe aus der
  `PROGRESS.md` übernehmen und ergänzen: welche Dateien tatsächlich entstanden/geändert,
  was konkret umgesetzt, nennenswerte Entscheidungen/Abweichungen.
- **PROGRESS.md:** Detailabschnitt **entfernen** und eine Zeile in die Done-Tabelle:
  `| F-004a | Kurzbeschreibung | JJJJ-MM-TT |`
- Bei komplett fertiger F-Nummer: Eintrag im `<!-- FEATURE-INDEX … -->` als `(DONE)`
  markieren — ein `(PLANNED)`-Suffix wird ersetzt.
- Eine `**Status:**`-Zeile (BACKLOG/PLANNED) wandert nicht mit ins Archiv — beim
  Übernehmen entfernen; den Zustand „fertig" tragen Done-Tabelle und `(DONE)`-Marker.
- **F-Nummern-Toleranz:** Alt-Formate lesen, aber alles Neue als F-NNN schreiben; fehlt
  der FEATURE-INDEX-Block, anlegen und bestehende Nummern unverändert übernehmen.

## 5. Freigabe, Verbuchung und Commit

- **Eine Frage für beides:** die Vorschau aus Schritt 4 (Done-Zeile, Archiv-Eintrag,
  Index-Marker) und eine aussagekräftige Conventional-Commits-Message zeigen — Prosa in
  der Commit-Sprache des Projekts (Languages-Block; ohne Block englisch),
  Format-Tokens immer englisch. Antwortmöglichkeiten: verbuchen und committen / nur
  verbuchen / Änderungen am Text.
- **Nach OK:** PROGRESS-Dateien schreiben, re-lesen, `just check` erneut, dann (falls
  freigegeben) committen. **Nie automatisch committen** und nie ohne OK verbuchen.
- **Ausnahme — autonomer Lauf:** Hat der Nutzer für den laufenden Lauf ausdrücklich
  Verbuchen und Commits freigegeben (beim Start von `/coding-kit:build-step … autonom`;
  die Freigabe muss im Verlauf dokumentiert sein), verbuche die geplanten Substeps und
  committe nach grünen Checks und Scans ohne erneute Nachfrage — **nie pushen, nie
  ältere Historie ändern.** Neue Einträge (z. B. eine unterwegs entdeckte Idee) fallen
  nicht darunter: sie werden nur gesammelt und am Ende des Laufs vorgeschlagen. Läuft
  ein autonomer Lauf **ohne** solche Freigabe: Verbuchung und Commit-Message als
  Vorschlag festhalten und weiterarbeiten, nicht auf eine Antwort warten.
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
- Beschreiben: was fertig wurde, welche Dateien/Komponenten, welche Config/Endpunkte/
  Dependencies, welche Architektur-/Sicherheitsentscheidungen.
