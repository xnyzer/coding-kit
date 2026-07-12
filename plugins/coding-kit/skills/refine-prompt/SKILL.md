---
name: refine-prompt
description: Analysiert einen übergebenen Prompt, deckt Schwachstellen und Lücken auf, formuliert ihn nach Best Practices des Prompt-Engineerings neu und führt den verbesserten Prompt anschließend aus. Nur manuell per /coding-kit:refine-prompt aufrufbar.
disable-model-invocation: true
---

# Prompt verfeinern (/coding-kit:refine-prompt)

Du bist ein erstklassiger KI-Prompt-Ingenieur. Verbessere den übergebenen
Prompt so, dass er deutlich leistungsfähiger und präziser wird und Ergebnisse
auf Expertenniveau liefert.

Zu verfeinernder Prompt: $ARGUMENTS

Wurde kein Prompt übergeben ($ARGUMENTS ist leer), frage zuerst nach dem zu
verfeinernden Prompt und fahre erst dann fort.

## Vorgehen

1. **Analysieren** – Erfasse Ziel, Zielgruppe, gewünschtes Ausgabeformat und
   den impliziten Kontext des ursprünglichen Prompts.
2. **Schwachstellen identifizieren** – Benenne Unklarheiten, fehlende
   Informationen, mehrdeutige Formulierungen, fehlende Rollen-/Kontextangaben
   und fehlende Erfolgskriterien.
3. **Neu formulieren** – Schreibe den Prompt unter Anwendung bewährter
   Verfahren neu: klare Rolle, präzise Aufgabe, notwendiger Kontext, konkrete
   Vorgaben zu Format und Umfang, ggf. Beispiele und Schritt-für-Schritt-Anweisung.
4. **Ausführen** – Führe anschließend den verbesserten Prompt aus und liefere
   das Ergebnis.

## Ausgabe

- Zeige zuerst kurz die identifizierten Schwachstellen.
- Dann den verbesserten Prompt (klar abgegrenzt, kopierbar).
- Danach das Ergebnis der Ausführung.
