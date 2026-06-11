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

Python · postgresSQL · docker · pandas · streamlit · scikit-learn · xgboost · matplotlib / plotly · Jupyter

---

## 🚀 Setup

# Postgres DB

# PostgreSQL Setup Guide

## 1. Installation

```bash
sudo apt update && sudo apt install postgresql postgresql-client
```

---

## 2. User und Datenbank anlegen

```bash
sudo -u postgres psql -c "CREATE USER meinuser WITH PASSWORD 'meinpasswort';"
sudo -u postgres createdb -O meinuser abschluss_lokal
```

---

## 3. Schema einlesen und Berechtigungen vergeben

```bash
sudo -u postgres psql -d abschluss_lokal -f database/setup.sql
sudo -u postgres psql -d abschluss_lokal -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO meinuser;"
sudo -u postgres psql -d abschluss_lokal -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO meinuser;"
```

---

## 4. `.env` Datei

Die `.env` muss im gleichen Verzeichnis wie die Import-Skripte abgelegt werden:

```
scripts/import/.env
```

Inhalt:

```env
DATABASE_URL=postgresql://meinuser:meinpasswort@localhost:5432/abschluss_lokal
```

> `meinuser` und `meinpasswort` durch eigene Werte ersetzen – müssen in Schritt 2 und der `.env` übereinstimmen.

---

## 5. Python Dependencies installieren

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

---

## 👥 Team

Sebastian Demmler (sdemmler)

André Janßen (andre-janssen)

---

## 📄 Lizenz

MIT
