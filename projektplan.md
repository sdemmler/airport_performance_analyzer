# ✈️ European Airport Delay Analysis

Datenanalyse- und Machine-Learning-Projekt zu **Verspätungen an europäischen Flughäfen**. Das Projekt kombiniert deskriptive Analysen, Ursachenforschung, saisonale Mustererkennung sowie unsupervised und supervised ML, um die Pünktlichkeit europäischer Flughäfen zu verstehen und vorherzusagen.

---

## 📌 Motivation

Verspätungen verursachen jährlich Milliardenkosten und beeinträchtigen Millionen Passagiere. Doch **wo genau entstehen die Verspätungen** – am Flughafen selbst, im Luftraum, durch Wetter, oder durch Kapazitätsengpässe? Dieses Projekt versucht, diese Frage datengetrieben für Europa zu beantworten und liefert sowohl analytische Insights als auch ein Vorhersagemodell für Verspätungswahrscheinlichkeiten.

---

## 🎯 Forschungsfragen

### 1. Deskriptive Analyse

- Welches sind die **pünktlichsten und unzuverlässigsten Flughäfen** Europas?
- Flughafen-Ranking nach **ATFM-Verspätungsminuten**, normiert auf Minuten/Flug (Nenner: `fact_airport_traffic`).
- Gibt es Veränderungen seit 2019? Ist eine **Corona-Auswirkung** erkennbar?
- Existieren **kritische Flughafen-Paare**, deren Verspätungen besonders stark korrelieren?

### 2. Ursachenanalyse

- **Ursachen-Attribution** – Wetter (W) vs. Kapazität (C) vs. Staffing (S) vs. Aerodrome-Kapazität (G).
  *Beispiel:* Wie viel von EDDFs Arrival-Delay ist tatsächlich kapazitäts-, wetter- oder personalbedingt? → beantwortet *„Warum ist Frankfurt eng?"*
- **Länderanalyse:** Welche Verspätungsursachen sind ländertypisch?
- **Flughafen vs. Luftraum:** Liegt die Verspätung eher am Flughafen (Airport ATFM) oder im umgebenden Luftraum (En-Route ATFM)?
  - Visualisierung: x-Achse = Arrival-Delay/Flug pro Flughafen, y-Achse = En-Route-Delay/Flug des jeweiligen Landes.
  - Beispielinterpretation: *„Frankfurt ist hoch-flughafenlimitiert in einem moderat-luftraumlimitierten Land."*
  - Hinweis: y-Achse ist landesaggregiert – nicht die konkreten Sektoren der jeweiligen Flüge.
- **Wettereinfluss:** Wie stark korrelieren Wind, Niederschlag und Sichtweite mit Verspätungen? Welche Variable hat den stärksten Einfluss? (Join der Open-Meteo-Daten auf Tages-Delays.)
- Strecken-Vergleich über `flight_event_types` zwischen verschiedenen Flughäfen.

### 3. Airline- & Strecken-Analyse

- **Airline-Ranking** basierend auf Actual Times.
- **Flugdauervergleich** nach Strecke, Airline und Flugzeugtyp.
- **Kaskaden-Effekte:** Wie pflanzen sich Verspätungen entlang von Strecken / Rotationen fort?

### 4. Muster & Saisonalität

- **Risiko-Mapping (Heatmap):** An welchen Tagen im Jahr hat ein Flughafen die höchste Verspätung?
- Saisonale Profile pro Flughafen.

### 5. Machine Learning – Unsupervised

- **Clustering von Flughäfen** auf Tagesebene.
- Gibt es Flughäfen, die sich einem Cluster **nur saisonal** zuordnen – z. B. im Sommer Typ A, im Winter Typ B?

### 6. Machine Learning – Supervised

- **Verspätungsprognose:** Wahrscheinlichkeit, dass die Verspätung eines Flugs über einem Schwellenwert liegt.
  - **Input:** Abflugflughafen, Ankunftsflughafen, Datum, aktuelles Wetter
  - **Output:** Wahrscheinlichkeit für eine Verspätung > Schwellenwert

---

## 🗂️ Datenquellen

| Quelle | Inhalt |
|---|---|
| `fact_airport_traffic` | Flugbewegungen pro Flughafen (Nenner für Normierung) |
| ATFM Delay Data | Air Traffic Flow Management Verspätungen, kategorisiert nach Ursache (C/W/S/G) |
| Actual Flight Times | Tatsächliche Abflug- und Ankunftszeiten |
| `flight_event_types` | Streckenbezogene Eventdaten |
| Open-Meteo | Historische Wetterdaten (Wind, Niederschlag, Sicht, Temperatur) |

---

## 🏗️ Projektstruktur

```
.
├── data/
│   ├── raw/               # Originaldaten (nicht im Repo)
│   ├── processed/         # Aufbereitete Datensätze
│   └── external/          # Open-Meteo, Stammdaten
├── notebooks/
│   ├── 01_descriptive/    # Rankings, Corona-Vergleich, Korrelationen
│   ├── 02_causes/         # C/W/S/G-Attribution, Länderanalyse
│   ├── 03_weather/        # Wetterjoin & Korrelationsanalyse
│   ├── 04_seasonality/    # Heatmaps, saisonale Muster
│   ├── 05_clustering/     # Unsupervised ML
│   └── 06_prediction/     # Supervised ML, Verspätungsprognose
├── src/
│   ├── data/              # Loader, Cleaning, Joins
│   ├── features/          # Feature Engineering
│   ├── models/            # Training & Inferenz
│   └── viz/               # Plot-Funktionen
├── reports/
│   └── figures/           # Exportierte Grafiken
├── requirements.txt
└── README.md
```

---

## 🛠️ Tech Stack

- **Python 3.11+**
- **Datenverarbeitung:** pandas, polars, numpy
- **Visualisierung:** matplotlib, seaborn, plotly
- **ML:** scikit-learn, xgboost / lightgbm
- **Clustering:** scikit-learn, hdbscan
- **Wetter-API:** open-meteo-py
- **Notebooks:** Jupyter / VS Code

---

## 🚀 Setup

```bash
# Repository klonen
git clone https://github.com/<user>/<repo>.git
cd <repo>

# Virtuelle Umgebung anlegen
python -m venv .venv
source .venv/bin/activate   # macOS/Linux
# .venv\Scripts\activate    # Windows

# Abhängigkeiten installieren
pip install -r requirements.txt
```

Rohdaten unter `data/raw/` ablegen (siehe `data/README.md` für Details zu den erwarteten Dateien).

---

## ▶️ Nutzung

Die Notebooks sind nummeriert und können in Reihenfolge durchlaufen werden:

```bash
jupyter lab notebooks/
```

Für das Prognosemodell:

```bash
python -m src.models.train          # Training
python -m src.models.predict --from EDDF --to LFPG --date 2025-07-15
```

---

## 📊 Ergebnisse (Highlights)

> *Wird im Laufe des Projekts ergänzt.*

- Top 10 pünktlichste / unpünktlichste Flughäfen Europas
- Corona-Effekt: Vergleich 2019 vs. 2020–2022 vs. Recovery
- Wetter-Variable mit stärkstem Verspätungseinfluss
- Beste Cluster-Konfiguration für saisonale Flughafenprofile
- Performance des Prognosemodells (AUC, Precision/Recall)

---

## 📈 Roadmap

- [ ] Datenakquise und initiales Cleaning
- [ ] Deskriptives Ranking + Corona-Analyse
- [ ] Ursachen-Attribution (C/W/S/G)
- [ ] Wetterjoin + Korrelationsanalyse
- [ ] Saisonale Heatmaps
- [ ] Unsupervised Clustering
- [ ] Supervised Modell + Evaluation
- [ ] Dashboard / Reporting

---

## 👥 Team

André Janßen (andre-janssen)

---

## 📄 Lizenz

MIT
