# Renovate-Preset

Das Kit stellt ein Shareable Preset in [`default.json`](../default.json) (Repo-Root)
bereit — die eine Stelle, an der die Renovate-Grundkonfiguration aller Projekte gepflegt
wird.

## Was das Preset macht

- **`config:recommended`** — Renovates empfohlene Basis (Gruppierung, Schedules,
  Dashboards, sinnvolle Defaults).
- **`helpers:pinGitHubActionDigests`** — GitHub Actions werden auf Commit-SHAs gepinnt
  (Supply-Chain-Härtung); Renovate hält die Pins aktuell und zeigt den Versions-Tag als
  Kommentar.
- **`labels: ["dependencies"]`** — alle Update-PRs bekommen das Label `dependencies`.
- **mise in der Azure-Pipeline** — eine Regel (`customManagers`) liest `MISE_VERSION` in
  `azure-pipelines.yml` und schlägt neue Releases von jdx/mise vor.
- **Tools in `mise.lock`** — Lock File Maintenance nur für den Manager `mise`: einmal
  pro Woche (Renovates Vorgabe, montags früh) führt Renovate `mise lock --bump` aus und
  hebt jedes Tool auf die neueste Version seiner Hauptversion; `mise.toml` mit den
  Hauptversionen bleibt, wie sie ist. Ein PR für alle Tools, bei grüner CI automatisch
  gemergt. Ohne Status-Checks im Projekt bleibt der PR offen; ein Projekt mit Freigabe
  über das Dashboard (`:dependencyDashboardApproval`) gibt ihn dort frei. Die
  Sperrdateien der Stack-Module (npm, uv …) pflegt die Regel nicht. Von Hand hebt
  `just bump-tools` (`mise lock --bump`) dasselbe an.

## Projekte anbinden

In der `renovate.json` des Projekts (legt `/new-project` aus dem Template automatisch
an):

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["github>xnyzer/coding-kit"]
}
```

`github>owner/repo` lädt die `default.json` aus dem Repo-Root. Optional lässt sich ein
fester Stand referenzieren (`github>xnyzer/coding-kit#<tag>`); Subpfad-Presets gingen via
`//`, werden hier aber nicht genutzt.

## Wichtig: App-Installation ist eine Nutzeraktion

Renovate läuft als GitHub-App. Die App wird **manuell vom Nutzer** installiert
(GitHub → Settings → Integrations → [Renovate](https://github.com/apps/renovate) →
gewünschte Repos freigeben) — das ist bewusst nicht gescriptet. Ohne installierte App
bleibt die `renovate.json` wirkungslos (aber harmlos).

Auf Azure DevOps gibt es die App nicht: Renovate läuft dort zentral in der Organisation
(eine eigene Pipeline über die Repos), das Projekt bringt nur die `renovate.json` mit. Das
Preset holt Renovate auch dort von GitHub, ohne Anmeldung; ein Lauf über viele Repos
braucht dafür einen GitHub-Token, sonst greift das Abruflimit von GitHub.

**`mise.lock` bei selbst betriebenem Renovate:** `mise lock` kann Befehle aus dem Repo
ausführen, deshalb führt Renovate es nur aus, wenn der Betreiber es erlaubt. Der
gehostete Dienst auf GitHub tut das bereits. Wer Renovate selbst betreibt — etwa als
Pipeline in Azure DevOps —, trägt in die globale Konfiguration des Laufs
`"allowedUnsafeExecutions": ["mise"]` ein und nutzt ein aktuelles Renovate-Image, das
mise enthält. Fehlt eines davon, bleibt die `mise.lock` stehen; die Projekte heben die
Tools dann von Hand an, mit `just bump-tools`.

## Dogfooding

Das Kit nutzt das Preset selbst: `renovate.json` im Repo-Root extendet
`github>xnyzer/coding-kit` (dieses Repo). Damit bekommen die Kit-eigenen Dateien —
Workflows im Root, `mise.lock` — automatisch Update-PRs.

**Versionen im Template sind Startwerte.** Was unter `plugins/coding-kit/template/` steht
(Actions in den Workflows, Sprachen und Tools der Module, Abhängigkeiten in
`package.json` …), bekommt ein neues Projekt beim Anlegen; danach entscheidet das
Projekt mit seinem eigenen Renovate, ob es eine neuere Version übernimmt. Das Kit hebt
diese Werte nur bewusst an, etwa wenn ein Modul überarbeitet und mit der neuen Version
geprüft wird. Deshalb öffnet Renovate dafür keine PRs: Eine Regel in `renovate.json`
führt die Updates im Dependency Dashboard unter „Pending Approval“, auf Branches mit dem
Präfix `template-`. Die Liste zeigt jederzeit, welche Startwerte veraltet sind.

So hebt das Kit einen Startwert an:

1. Im Dashboard das Häkchen beim Update setzen — Renovate öffnet den PR.
2. Der PR ist Plugin-Inhalt: Die CI (Versionsregel) bleibt rot, bis die Plugin-Version
   angehoben und der CHANGELOG-Eintrag mit Abschnitt `### Template` ergänzt ist. Das
   betroffene Modul vorher mit der neuen Version prüfen.
3. Mergen und veröffentlichen. Steht die Version in einer managed Datei (Workflows,
   `azure-pipelines.yml`, `mise.toml` der Module), bietet `/update-conventions` die
   Anhebung jedem Projekt an, und das Projekt bestätigt sie je Datei. Eine Version, die
   das Kit nicht ändert, löst dort nichts aus; Seed-Dateien wie `package.json` erreicht
   die Anhebung nur in neuen Projekten.

Sollen mehrere Startwerte zusammen steigen (etwa Sprache, Paketmanager und Testwerkzeug
eines Moduls oder die Actions der Workflows), hebt das Kit sie direkt auf main an, statt
je Update einen PR zu öffnen: die Werte im Template ändern, ein Projekt aus dem
Arbeitsstand rendern und darin `just check` laufen lassen, dann Version und CHANGELOG
wie in Schritt 2. Was `just check` nicht sieht, wird von Hand geprüft: Eine Action steht
mit dem Commit-SHA ihres Tags da (`gh api repos/<owner>/<repo>/commits/<tag>`), der
Kommentar nennt genau diesen Tag; für `MISE_VERSION` gibt es die `install.sh` des
Releases. Nach dem Push verschwinden die Einträge der angehobenen Werte aus dem
Dashboard; ist inzwischen eine neuere Version erschienen, bleibt der Eintrag mit ihr
stehen.

## Preset ändern

Änderungen an `default.json` wirken auf **alle** angebundenen Projekte beim nächsten
Renovate-Lauf. Deshalb: Änderungen klein halten, in der Commit-Message begründen und im
CHANGELOG (`plugins/coding-kit/CHANGELOG.md`, beim nächsten Release) festhalten.
