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

## Dogfooding

Das Kit nutzt das Preset selbst: `renovate.json` im Repo-Root extendet
`github>xnyzer/coding-kit` (dieses Repo). Damit bekommen die gepinnten Action-SHAs und
mise-Tools automatisch Update-PRs — auch die im Template unter
`plugins/coding-kit/template/`. Ein PR, der dort Pins ändert, ist Plugin-Inhalt: die CI
(Versionsregel) bleibt rot, bis die Version angehoben und der CHANGELOG-Eintrag mit
Abschnitt `### Template` ergänzt ist — so kommt die neue Pin-Fassung auch über
`/update-conventions` in die Projekte.

## Preset ändern

Änderungen an `default.json` wirken auf **alle** angebundenen Projekte beim nächsten
Renovate-Lauf. Deshalb: Änderungen klein halten, in der Commit-Message begründen und im
CHANGELOG (`plugins/coding-kit/CHANGELOG.md`, beim nächsten Release) festhalten.
