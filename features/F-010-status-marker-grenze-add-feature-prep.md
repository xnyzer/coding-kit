---
id: F-010
title: Status-Marker + Grenze add-feature/prep-step
type: feature
status: DONE
size:
created: 2026-07-13
done: 2026-07-13
depends-on:
superseded-by:
---

# F-010 — Status-Marker + Grenze add-feature/prep-step

## Verlauf

### F-010 — Status-Marker-Konvention + Grenze add-feature/prep-step (2026-07-13)

**Was entstanden ist (Plugin 0.6.0):**

- **Anlass (Nutzer-Beobachtung):** add-feature-Einträge waren oft schon fast fertige
  Pläne, prep-step legte noch einmal nach; außerdem war einem Eintrag nicht anzusehen,
  ob er nur aufgenommen (→ prep-step) oder schon geplant (→ build-step) ist.
- **Status-Marker-Konvention:** `**Status:**`-Zeile direkt unter der
  Eintrags-Überschrift mit sprachinvarianten Tokens — `BACKLOG` (setzt add-feature) →
  `PLANNED` (setzt prep-step, zusätzlich `(PLANNED)` an der Index-Zeile); fertig
  bleibt Done-Tabelle + `(DONE)` im FEATURE-INDEX. Toleranz für Alt-Einträge ohne
  Status-Zeile (Substeps vorhanden ≈ geplant; Zeile bei nächster Berührung nachziehen).
- **add-feature geschärft:** „Mögliche Umsetzung" → „Lösungsskizze", explizit
  unverbindlich: keine Dateilisten, keine Zerlegung in Schritte, keine
  Abnahmekriterien (bleibt prep-step); optionale Ablauf-/Ansatz-Zusatzabschnitte
  gestrichen; Alt-Überschriften werden nicht umbenannt.
- **prep-step geschärft:** hinterfragt die Skizze statt sie zu übernehmen (jede
  Annahme gegen den aktuellen Codestand verifizieren, eigene Alternativen mit
  Begründung); Plan-Vorlage um „Bewertung der Lösungsskizze" ergänzt; setzt `PLANNED`
  auch bei kleinen Aufgaben; zieht die Skizze bei Abweichung auf den beschlossenen
  Stand nach.
- **Begleitanpassungen:** build-step prüft den Marker beim Plan-Laden (`BACKLOG` →
  erst prep-step empfehlen); step-done ersetzt `(PLANNED)` durch `(DONE)` und nimmt
  die Status-Zeile nicht mit ins Archiv; `docs/skill-authoring.md` führt die
  Konvention als Pflicht-Baustein; README (Tabellenzeilen, Zyklus-Satz), CHANGELOG,
  plugin.json 0.6.0.
- **Entscheidung:** Trennung add-feature/prep-step bleibt bestehen (Erfassungs- ≠
  Umsetzungszeitpunkt; build-step hängt am prep-step-Output; add-feature muss als
  billiges Scope-Schutz-Ventil erhalten bleiben) — statt eines Merges wurde die
  Grenze geschärft und per Marker sichtbar gemacht.
