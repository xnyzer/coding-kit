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

## Projekte anbinden

In der `renovate.json` des Projekts (macht `/new-project` bzw. das project-template
automatisch):

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

## Dogfooding

Beide Kit-Repos nutzen das Preset selbst:

- `coding-kit/renovate.json` → extendet `github>xnyzer/coding-kit` (dieses Repo).
- `project-template/renovate.json` (Repo-Root) → extendet dasselbe Preset.

Damit bekommen auch die im Kit/Template gepinnten Action-SHAs und mise-Tools automatisch
Update-PRs.

## Preset ändern

Änderungen an `default.json` wirken auf **alle** angebundenen Projekte beim nächsten
Renovate-Lauf. Deshalb: Änderungen klein halten, in der Commit-Message begründen und im
`CHANGELOG.md` festhalten.
