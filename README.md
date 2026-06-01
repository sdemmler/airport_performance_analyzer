# ✈️ European Airport Delay Analysis

Datenanalyse- und Machine-Learning-Projekt zu **ATFM-Verspätungen an europäischen Flughäfen**.

---

## 🎯 Worum geht es?

Wir untersuchen Verspätungen, die durch das europäische **Verkehrsflussmanagement (ATFM)** entstehen – also Wartezeiten, die zentral angeordnet werden, wenn die Nachfrage die Kapazität eines Flughafens oder Luftraums zu übersteigen droht.

Im Fokus stehen zwei Ursachenorte:

- **Engpässe beim Anflug** an einem Zielflughafen
- **Engpässe im Luftraum** (Flugsicherungssektoren)

Die Leitfrage lautet:

> **„Wo belastet das Verkehrsflussmanagement das Netz?"**

## 🚫 Was wir bewusst *nicht* betrachten

- Abflugseitige Flughafenbeschränkungen
- Die vom Passagier *erlebte* Gesamtverspätung – diese umfasst zusätzlich betriebliche Ursachen wie Gepäckabfertigung, Enteisung oder Bauarbeiten sowie Folgeverspätungen aus vorangegangenen Flügen (zusammen rund die Hälfte aller Verspätungen).

Die Analyse beantwortet also *nicht* die Frage „Wie viel Verspätung erlebt der einzelne Passagier?", sondern fokussiert sich auf strukturelle Netzbelastung.

---

## 🧭 Analysefelder

- **Deskriptive Analyse** – Rankings, Corona-Effekt, Korrelationen zwischen Flughäfen
- **Ursachenanalyse** – Wetter vs. Kapazität vs. Staffing; Flughafen vs. Luftraum
- **Saisonalität** – Heatmaps und Muster über den Jahresverlauf
- **Unsupervised ML** – Clustering von Flughäfen nach Verspätungsprofilen
- **Supervised ML** – Vorhersage der Verspätungswahrscheinlichkeit eines Flugs

> Detaillierte Forschungsfragen, Methodik und Roadmap → siehe [`projektplan.md`](./projektplan.md)

---

## 🗂️ Datenquellen

- **EUROCONTROL** – ATFM-Verspätungen, `fact_airport_traffic`, Actual Flight Times, `flight_event_types`
- **Open-Meteo** – historische Wetterdaten (Wind, Niederschlag, Sicht, Temperatur)

---

## 🛠️ Tech Stack

Python · pandas · scikit-learn · xgboost · matplotlib / plotly · Jupyter

---

## 🚀 Setup

```bash
git clone https://github.com/<user>/<repo>.git
cd <repo>
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
jupyter lab
```

---

## 👥 Team & Lizenz

*Ergänzen.*
