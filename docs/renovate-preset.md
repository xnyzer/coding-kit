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
