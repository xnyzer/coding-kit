---
name: audit-code
description: Vollaudit des Projekts. Code, Architektur, Security, Secrets, Dependencies, Deployment-Config. Schreibt AUDIT-RESULTS.md, fixt nichts. Optional auf einen Bereich eingrenzbar.
disable-model-invocation: true
---

# Code- & Stack-Audit

Systematische Vollprüfung des Projekts. **Nur dokumentieren, nichts fixen.**

Argument (optional): Eingrenzung auf einen Bereich — z. B. „security", „deps", „config"
oder ein konkreter Pfad. Ohne Argument: alles prüfen.

**Leitprinzip:** Probleme aufdecken, die zu Sicherheitslücken, Credential-Leaks,
Fail-open-Verhalten, Instabilität oder Unwartbarkeit führen können. Jeder Befund konkret,
reproduzierbar, mit klarer Empfehlung.

**Arbeitsweise:** Gründlich lesen, nichts überspringen. Subagenten für parallele Analyse,
wo sinnvoll. Für Library-/SDK-Fragen aktuelle Doku nutzen (Websuche) und gegen die
tatsächlich gepinnten Versionen prüfen (Lockfiles/Manifeste) — nie aus dem
Modellgedächtnis urteilen.

## Kontext-Recovery

Nach Kompaktierung oder Session-Neustart: bereits geprüfte Bereiche nicht erneut prüfen —
Zwischenstand aus der begonnenen `AUDIT-RESULTS.md` übernehmen und dort weitermachen.

## Phase 0: Berechtigungen einholen

Vor dem Start den Nutzer um alle Berechtigungen bitten, die das gesamte Audit braucht.

## Phase 1: Vorbereitung & Kontext

1. **Projekt-CLAUDE.md** lesen: Zweck/Scope, Stack, Sicherheits-Postur (öffentliches Repo?
   Security-/Auth-Charakter?), Verweise auf weitere Schlüsseldokumente.
2. `CODING-STANDARDS.md` lesen — Referenz für Stil und Architektur (falls vorhanden).
3. Falls vorhanden: `REQUIREMENTS.md` und `THREAT-MODEL.md` — Sicherheitsmodell und
   Anforderungen sind der Vertrag.
4. Versionsstände ermitteln: Lockfiles/Manifeste, gepinnte Image-Tags, `mise.toml`.
5. Deployment-relevante Dateien lesen, soweit vorhanden: `Dockerfile*`,
   `docker-compose*.yml`, Reverse-Proxy-Config, Beispiel-Env.
6. `git log --oneline -20` für den aktuellen Stand.

## Phase 2: Code-Audit (gegen CODING-STANDARDS.md)

Bereich für Bereich durchgehen (Aufteilung aus der Projektstruktur ableiten), jede Regel
pro Datei anwenden, Verstöße notieren. Checks laufen stack-agnostisch über die
just-Rezepte (`just lint`, `just test`, `just check`) — deren Ergebnisse fließen als
Befunde ein, ersetzen aber nicht das Lesen.

**Zusätzlich bei Security-Postur (THREAT-MODEL.md bzw. Security-/Auth-Charakter) —
Verstöße sind severity: high:**

1. **Keine Eigenbau-Krypto:** Signieren/Verifizieren/Hashing auf geprüften Bibliotheken?
2. **Fail-closed:** Lässt irgendein Fehlerpfad eine Anfrage standardmäßig
   authentifiziert/autorisiert durch?
3. **Credential-Hygiene:** kurzlebige, zweckgebundene Tokens? Keine Secrets in
   Logs/Images?
4. **Missbrauchsschutz:** Registrierungs-/Anfragepfade begrenzt und rate-limitiert?
5. **Schnittstellen-Korrektheit:** öffentlich dokumentierte Metadaten/Endpunkte konsistent
   mit dem tatsächlichen Verhalten?

## Phase 3: Security- & Secrets-Audit

- **Secrets:** Tokens/Passwörter/private Schlüssel/private E-Mails/Deployment-IPs in Code
  oder Git-History? Inhalte, die nach `private/` gehören, im öffentlichen Baum?
- **Dependency-Security:** bekannte CVEs; noch gepflegt? Runtime im Support-Fenster?
  **Alle Dependencies permissiv lizenziert (kein GPL/AGPL)?**
- **Input-Validierung:** validieren alle Schnittstellen ihre Eingaben? Config beim Start
  validiert?
- **Credentials:** nichts in Logs/Artefakten; Bearer/Keys maskiert.

## Phase 4: Deployment & Infrastruktur (falls vorhanden)

- **Dockerfiles:** Multi-Stage? Non-Root? aktuelles Base-Image? Healthcheck? keine
  Secrets? Ports/Config via Env?
- **Compose:** Healthchecks + `depends_on: condition: service_healthy`? Restart-Policies?
  Volumes für persistente Daten? Beispiel-Env vollständig?
- **TLS/Reverse-Proxy:** sauber terminiert? keine ungeschützten Routen zu internen
  Diensten?

## Phase 5: Architektur & Robustheit

- **Fehlerbehandlung:** unbehandelte Rejections/Panics? leere `catch`-Blöcke? interne
  Fehlerdetails an Clients geleakt? Graceful Degradation bei ausgefallenen Upstreams?
- **Zuverlässigkeit:** Backoff/Retry wo angemessen; Rotation/Neustart ohne Sessionbruch?
- **Config:** alles dokumentiert? Ports konfigurierbar (keine Konflikte)?
- **Nebenläufigkeit:** geteilter Zustand ohne Koordination? doppelte In-flight-Operationen?

## Phase 6: Ergebnisse zusammenstellen

**Nicht fixen! Nur dokumentieren.** In `AUDIT-RESULTS.md` (Projekt-Root, gitignored,
jeder Lauf überschreibt), in der Sprache der lebenden Doku:

```markdown
# Audit-Ergebnisse — [Datum]

## Zusammenfassung
- Befunde critical / high / medium / low: X / X / X / X
- Empfohlene Sofortmaßnahmen: [Top 3]

## 1. Code-Audit
### [Datei] (Pfad)
| # | Kategorie | Regel | Zeile(n) | Verstoß | Severity |
|---|-----------|-------|----------|---------|----------|

## 2. Security & Secrets
## 3. Deployment & Infrastruktur
## 4. Architektur & Robustheit
## 5. Upgrade-Empfehlungen
| Priorität | Paket/Image | Von | Nach | Grund | Breaking Changes |

## 6. Zusammenfassung nach Severity
```

**Severities:** critical (aktive Lücke / Credential-Leak / fail-open / CVE ohne Fix) ·
high (Security-Best-Practice- oder Threat-Model-Verstoß, fehlende Validierung,
Eigenbau-Krypto) · medium (Strukturverstoß, fehlende Typen, suboptimale Config) ·
low (Stil, Imports).

Dateien ohne Verstöße nicht auflisten. Zum Abschluss eine kurze Zusammenfassung zeigen.
