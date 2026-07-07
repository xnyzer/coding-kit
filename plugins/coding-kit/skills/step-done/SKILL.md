---
name: step-done
description: Nach Abschluss einer Aufgabe ausführen. Review gegen CODING-STANDARDS, Checks über just, Secrets-Scan, Privacy-Scan der lebenden Doku, PROGRESS-Pflege, Graphiti-Update und Commit-Vorbereitung.
disable-model-invocation: false
---

# Abschluss-Checkliste

Eine Aufgabe oder ein Substep ist fertig — gilt für F-Nummern (F-001, F-001a) und
Alt-Formate (Schritt „1.2") gleichermaßen. Arbeite die Checkliste systematisch ab und
erledige jeden Punkt selbst — **außer wo ausdrücklich eine Nutzerfrage verlangt ist**.
Fasse am Ende zusammen, was du getan hast.

## 0. Projektkontext ermitteln

Lies die **Projekt-CLAUDE.md**: Sprache der lebenden Doku, Graphiti-group_id (ohne
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
- **Verstöße direkt beheben** — nicht als Frage an den Nutzer zurückspielen.
- Checks stack-agnostisch über die just-Standardrezepte ausführen: **`just check`** ist
  das Vollgate; bei Bedarf gezielt `just test` / `just lint`. Gibt es kein justfile:
  projektübliche Checks aus CLAUDE.md/README ermitteln — nie einen Stack raten. Bei
  reinen Doku-Änderungen: interne Links und Formatierung prüfen.
- Rote Ergebnisse sofort fixen. **Nie mit roten Checks committen.** Vorbestehende rote
  Tests trotzdem fixen oder explizit melden.
- **Write-then-Verify:** Nach jedem Edit die Datei re-lesen; nichts als erledigt melden,
  was nicht per Tool-Ausgabe belegt ist.

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

## 4. PROGRESS.md + PROGRESS-ARCHIVE.md

In der Sprache der lebenden Doku (siehe Schritt 0):

- **PROGRESS-ARCHIVE.md:** Den kompletten Abschnitt der fertigen Aufgabe aus der
  `PROGRESS.md` übernehmen und ergänzen: welche Dateien tatsächlich entstanden/geändert,
  was konkret umgesetzt, nennenswerte Entscheidungen/Abweichungen.
- **PROGRESS.md:** Detailabschnitt **entfernen** und eine Zeile in die Done-Tabelle:
  `| F-004a | Kurzbeschreibung | JJJJ-MM-TT |`
- Bei komplett fertiger F-Nummer: Eintrag im `<!-- FEATURE-INDEX … -->` als `(DONE)`
  markieren. **Direkt tun, ohne zu fragen.**
- **F-Nummern-Toleranz:** Alt-Formate lesen, aber alles Neue als F-NNN schreiben; fehlt
  der FEATURE-INDEX-Block, anlegen und bestehende Nummern unverändert übernehmen.

## 5. Graphiti-Wissensgraph

- `add_memory` mit der group_id aus der Projekt-CLAUDE.md aufrufen (falls verfügbar,
  sonst still überspringen).
- Beschreiben: was fertig wurde, welche Dateien/Komponenten, welche Config/Endpunkte/
  Dependencies, welche Architektur-/Sicherheitsentscheidungen.

## 6. Commit vorbereiten

- **Nie automatisch committen!** Den Nutzer fragen und eine aussagekräftige
  Conventional-Commits-Message auf Englisch vorschlagen.
- Im Body Designentscheidungen kurz begründen (`Decision: X over Y because …`); hat der
  Nutzer abgewogen: „User chose X over Y because …".

### 6a. Commit-E-Mail prüfen (KRITISCH)

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

### 6b. Co-Authored-By

Der Commit-Body endet mit:

```
Co-Authored-By: Claude <noreply@anthropic.com>
```
