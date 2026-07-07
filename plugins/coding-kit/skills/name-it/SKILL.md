---
name: name-it
description: Projektnamen finden. Erzeugt aus der Short-Info Kandidaten nach klaren Kriterien, prüft Verfügbarkeit (GitHub, npm, PyPI, optional Domain) zur Laufzeit und gibt den gewählten Namen an den Aufrufer zurück. Einzeln nutzbar und von /new-project aufrufbar.
disable-model-invocation: false
---

# Projektnamen finden

Argument: die Short-Info des Projekts (ein Satz: was es tut, für wen). Fehlt sie, **eine**
Frage stellen: „Was soll das Projekt können — ein Satz?" (kein Default möglich).

## 1. Kriterien

Kandidaten müssen erfüllen:

- **Kurz & sprechend:** idealerweise ≤ 12 Zeichen, aussprechbar, deutet die Funktion an.
- **Technisch tauglich:** lowercase-kebab funktioniert als Repo-, Paket- und Ordnername
  (keine Umlaute, keine Leerzeichen; für Python auch als snake_case brauchbar).
- **Kollisionsarm:** kein bekanntes Tool/Projekt mit demselben Namen im selben Feld
  (per Websuche prüfen), keine offensichtlichen Markenkonflikte.
- **Kein Wegwerfname:** keine generischen Füller wie „tool", „helper", „app" allein.

## 2. Kandidaten erzeugen

3–6 Kandidaten aus der Short-Info ableiten (Funktions-Metaphern, Komposita,
Wortverschmelzungen). Zu jedem ein halber Satz Begründung.

## 3. Verfügbarkeit prüfen (zur Laufzeit — nie raten)

Prüfumfang hängt vom (voraussichtlichen) Stack ab; GitHub immer:

```bash
OWNER=$(gh api user --jq .login)
gh repo view "$OWNER/<name>" >/dev/null 2>&1 && echo belegt || echo frei   # GitHub (eigener Account)
curl -s -o /dev/null -w '%{http_code}' https://registry.npmjs.org/<name>   # npm: 404 = frei
curl -s -o /dev/null -w '%{http_code}' https://pypi.org/pypi/<name>/json   # PyPI: 404 = frei
```

- Zusätzlich Websuche nach `<name> + Domänenbegriff`, um bekannte Namensvettern zu finden.
- **Domain nur auf Nutzerwunsch** prüfen (`https://rdap.org/domain/<name>.<tld>` —
  404 = frei); Registrar-Check bleibt Nutzeraktion.

## 4. Vorstellen & entscheiden

Kompakte Tabelle: Kandidat · Begründung · GitHub · npm/PyPI · Namensvettern. Mit klarer
**Empfehlung** (ein Kandidat, ein Satz warum). Dann **eine** Frage: „Welcher soll es
sein?" — Default = Empfehlung. Freie Eingabe ist erlaubt (dann Verfügbarkeit nachprüfen).

## Rückgabe an den Aufrufer

Der gewählte Name (lowercase-kebab) — z. B. für `/new-project` als Repo-/Projektname
und abgeleitet als `{{PROJECT_NAME_SNAKE}}`. Keine Dateien schreiben; das macht der
Aufrufer.
