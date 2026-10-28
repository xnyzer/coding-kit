---
id: F-017
title: Eigenschafts-Trigger für Standards-Fragmente auswerten
type: feature
status: DONE
size:
created: 2026-07-18
done: 2026-07-19
depends-on:
superseded-by:
---

# F-017 — Eigenschafts-Trigger für Standards-Fragmente auswerten

## Verlauf

### F-017 — Eigenschafts-Trigger für Standards-Fragmente auswerten (2026-07-19)

**Aufgabe:** Der Fragment-Katalog des project-template kennt Mapping-Zeilen mit
Projekteigenschafts-Triggern (`*characteristic:*`; erster Fall: `audit-logging` mit
„service with user/admin mutations"). Solche Trigger sind über Paket-Manifeste nicht
erkennbar — ohne Kit-Unterstützung würde ein Eigenschafts-Fragment nie gezogen.

**Was entstanden ist (Plugin 0.12.0; der prep-step-Teil kam bereits mit F-015/0.10.0):**

- **define-requirements — Interview-Punkt 5:** die `*characteristic:*`-Zeilen aus
  `modules/standards/README.md` werden zur Laufzeit gelesen und je Zeile als
  Ja/Nein-Frage gestellt (z. B. audit-logging → „Gibt es Nutzer-/Admin-Aktionen, die
  Daten verändern?"), Default nein. **Gate:** nur bei erreichbarem Template (im
  /new-project-Flow ohnehin aufgelöst), sonst stilles Überspringen. Treffer →
  Constraint + Decision-Log-Eintrag in der REQUIREMENTS.md **und** Bestandteil der
  „Rückgabe an den Aufrufer" (Liste bejahter Eigenschafts-Fragmente).
- **new-project § 4b:** komponiert die im Interview bejahten Eigenschafts-Fragmente
  in die anzuhängende Fragmentliste mit — ohne diese Zeile wäre die
  Interview-Antwort verpufft.
- **choose-stack Modus B:** Eigenschafts-Fragmente sind nachrüstbar — sie sind in
  keinem `MODULE.md` deklariert; je Trigger wird gefragt, ob die Eigenschaft aufs
  Projekt zutrifft (Projektentscheidung, Default nein), angehängt nur nach
  Bestätigung mit derselben idempotenten Mechanik.
- **Skalierungs-Einschätzung:** aktuell eine characteristic-Zeile im Katalog → eine
  Interview-Frage; wächst linear, Ja/Nein mit Default nein — bewusst keine
  Extra-Mechanik.
- **Begleitanpassungen:** plugin.json 0.12.0, CHANGELOG-Eintrag, README-Zeilen
  (choose-stack, define-requirements), define-requirements-`description`.
- **Geänderte Dateien:** `plugins/coding-kit/skills/define-requirements/SKILL.md`,
  `plugins/coding-kit/skills/new-project/SKILL.md`,
  `plugins/coding-kit/skills/choose-stack/SKILL.md`,
  `plugins/coding-kit/.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`.
- **Strang komplett:** Mit F-017 ist die Composable-CODING-STANDARDS-Arbeit auf
  Kit-Seite abgeschlossen (F-012–F-017); beide Signaltypen des Katalogs werden an
  allen Lebenszyklus-Punkten ausgewertet.
