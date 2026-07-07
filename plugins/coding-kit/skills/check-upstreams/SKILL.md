---
name: check-upstreams
description: Watchliste externer Vorbild-Repos prüfen. Fasst Neuerungen seit dem zuletzt geprüften Ref zusammen (Commits, Releases), macht Übernahme-Vorschläge fürs Kit/Template und persistiert den neuen Ref in upstreams.json. Übernahmen nur auf Nutzerentscheidung.
disable-model-invocation: true
---

# Upstreams prüfen

Beobachtet externe Repos, aus denen das Kit Muster übernimmt oder übernehmen könnte.
**Nichts wird ohne Nutzerentscheidung übernommen.**

Argument (optional): Name eines Watchlist-Eintrags — sonst alle prüfen.

## 0. Watchliste auflösen

Die Watchliste ist `upstreams.json` im **Kit-Repo** (nicht im Plugin-Install-Verzeichnis —
sie wird geschrieben und committed). Kit-Checkout auflösen wie üblich:
`$CODING_KIT_PROJECTS_DIR/coding-kit`, sonst `gh repo clone
"$(gh api user --jq .login)/coding-kit" <tmp>` (dann gelten Updates als Vorschlag zum
Zurückspielen).

## 1. Je Eintrag: Neuerungen ermitteln (zur Laufzeit, nie aus dem Gedächtnis)

- **`repo` unbekannt/null:** per Websuche auffinden, Fund vom Nutzer bestätigen lassen,
  in `upstreams.json` eintragen.
- **Erstprüfung** (`last_checked_ref: null`): Ist-Zustand erheben — README, letzte
  Releases, Aktivität (`gh api repos/<repo> --jq '{pushed_at, default_branch,
  stargazers_count}'`), Reifegrad gegen die `notes`-Fragen des Eintrags bewerten.
- **Folgeprüfung:** Änderungen seit dem Ref holen:
  `gh api "repos/<repo>/compare/<last_checked_ref>...<default_branch>"` (Commits,
  geänderte Dateien) und `gh api repos/<repo>/releases --jq '.[].tag_name'` für neue
  Releases. Bei sehr vielen Commits: Releases + Commit-Subjects zusammenfassen statt
  jeden Diff zu lesen.

## 2. Bewerten & vorschlagen

Je Eintrag kurz berichten: Was ist neu? Was davon ist für Kit/Template relevant
(gemessen am `why` des Eintrags)? Konkrete Übernahme-Vorschläge als Empfehlung mit
Aufwand/Nutzen — z. B. „neues Muster X in Skill Y einarbeiten" oder „Scanner-Wechsel
vorbereiten". **Übernahme nur auf Entscheidung des Nutzers**; beschlossene Arbeiten via
`/coding-kit:add-feature` als F-Nummer ins Kit-PROGRESS aufnehmen.

## 3. Ref persistieren

Nach jedem geprüften Eintrag in `upstreams.json` aktualisieren: `last_checked_ref` =
aktueller HEAD-SHA des Default-Branch, `last_checked_at` = heutiges Datum, `notes` bei
neuen Erkenntnissen fortschreiben. Änderung zeigen, Commit im Kit-Repo **nur nach OK**
(Conventional Commit, z. B. `chore: record upstream check <name> @ <kurz-sha>`).

## Regeln

- Neue Watchlist-Kandidaten nimmt der Nutzer auf (dieser Skill schlägt sie höchstens vor).
- Ein Eintrag, dessen Zweck erfüllt/obsolet ist (z. B. nach vollzogenem Scanner-Wechsel),
  wird nach Bestätigung entfernt — mit Abschlussnotiz im Commit.
- Eignet sich für `/loop` (z. B. monatlich); im Loop-Modus nur berichten, nie schreiben.
