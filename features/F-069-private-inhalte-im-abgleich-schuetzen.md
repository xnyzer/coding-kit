---
id: F-069
title: Private Inhalte beim Abgleich und im Privacy-Lint schützen
type: fix
status: BACKLOG
size:
created: 2026-11-22
done:
depends-on:
superseded-by:
---

# F-069 — Private Inhalte beim Abgleich und im Privacy-Lint schützen

## Erfassung

**Problem:** Zwei Wege führen private Inhalte unbemerkt in ein öffentliches Repo:
- Das Template holt mit `!private/README.md` genau die Datei ins Git, die ein Projekt für
  private Notizen nutzen kann, und der Abgleich warnt nicht.
- Privacy-Lint überspringt jeden Pfad, der `/private/` enthält, unter macOS also alles
  unter `/private/tmp`. Ein Prüflauf über migrierte Dateien dort meldete 0 Funde, im
  Projekt waren es 17.

Dazu blockieren Fehlalarme legitime Commits.

**Ziel:**
- **Ist:**
  - `merge` meldet `private/README.md` als `two-way`, obwohl die Projektfassung
    ignoriert ist und private Daten enthält. Wer die Datei und `.gitignore` übernimmt,
    committet die Notizen.
  - `scan()` prüft `*/private/*` gegen den übergebenen Pfad statt gegen den Pfad relativ
    zum Repo.
  - Fehlalarme:
    - Vierteilige Versionen in Lock-Dateien (`uv.lock`) und Abschnittsnummern aus
      RFCs gelten als IP.
    - Doku mit Sperrbereichen oder Platzhaltern blockiert jeden Commit, der die Datei
      stagt, denn eine versionierte Projekt-Allowlist gibt es nicht.
    - `.example` und `example.net` sind nicht erlaubt.
- **Soll:** Kein Ziel wechselt beim Abgleich ohne Warnung von ignoriert zu versioniert.
  Privacy-Lint nimmt nur `private/` relativ zur Wurzel des Repos aus und meldet nur echte
  Funde.
- **Reproduzieren:**
  - Projekt mit ignoriertem `private/README.md` → `merge`.
  - Privacy-Lint über eine Datei unter `/private/tmp`, die eine echte E-Mail-Adresse
    enthält → 0 Funde.

**Lösungsskizze:**
- `merge` prüft je Ziel mit `git check-ignore` gegen die aktuelle `.gitignore` des
  Projekts. Ist die Projektdatei ignoriert und weicht ab, gibt es eine eigene Warnklasse.
  Der Skill stoppt dann und schlägt vor, die Datei zuerst umzubenennen (etwa
  `private/notes.md`). Allgemein bekommt jedes Ziel einen Hinweis, das vom ignorierten in
  den versionierten Zustand wechselt.
- Privacy-Lint nimmt `private/` nur relativ zur Repo-Wurzel aus.
- In Lock-Dateien zählt eine IP nur als Host einer URL (nach `://` oder `@`), Pfade,
  E-Mails und Blocklist werden dort weiter geprüft. Eine Zahl nach `§` ist keine IP.
  `.example` und `example.net` kommen in die Allow-Liste.
- Eine versionierte Projekt-Allowlist: ein exakter Wert je Zeile mit Grund, nie Bereiche.
  Projektzeilen überstehen den Merge wie in `license-policy.txt`, Bereiche wie 10.x,
  172.16.x und 192.168.x bleiben gesperrt.
- Verworfen:
  - Lock-Dateien ganz auszunehmen. Sie können private Registry-Hosts und lokale Pfade
    enthalten.
  - Nur `IP_RE` zu verschärfen. Eine vierteilige Version bleibt eine gültige IP.

**Abhängigkeiten:** keine.

**Noch zu analysieren:**
- Welche Lock-Dateien vierteilige Versionen tragen. Für Python ist es sicher, für
  Composer, Gemfile.lock und NuGet per Websuche belegen.
- Ob `requirements.txt` und Versions-Pins dasselbe brauchen.
- Ob `mise.lock` unter dieselbe Regel fällt, statt ganz übersprungen zu werden.
- Name und Format der Projekt-Allowlist.
