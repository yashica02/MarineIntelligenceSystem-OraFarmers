# 🐬 Marine Intelligence System
### OraFarmers

> 🏆 **1st Place — AnDackaThon 2026** | Built in 24 hours at the Analytics & Data Oracle User Community Hackathon, Oracle Conference Center, Redwood Shores → San Jose State University

---

## The Problem

San Francisco Bay is one of the most ecologically significant marine environments on the Pacific Coast. Humpback whales, grey whales, sea lions, dolphins, and dozens of other species share these waters with one of the busiest maritime corridors in the United States — thousands of cargo ships, tankers, ferries, and container vessels transiting every year.

The data tells a quiet but serious story. Marine mammal sightings that numbered in the hundreds annually in 2021 have been declining steadily through 2025. Water quality indicators are shifting. Microplastic concentrations are rising. And vessel activity shows no sign of slowing.

The gap is not a lack of data — it is a lack of connection. Marine ecosystem intelligence and maritime activity have never been analyzed together in a single system. Ships move through sensitive habitat zones with no awareness of what lives beneath them. Researchers track species decline without visibility into the vessel pressure those species face daily. No one has built the bridge — until now.

---

## Case Studies

**"Gray Whales Are Out of Luck in San Francisco Bay"** — *SFGATE*
A 2026 scientific study found at least 18% of grey whales entering SF Bay die there. Many deaths are directly linked to vessel strikes and starvation driven by climate-affected food supplies.

**"Grey Whales, Once Rare in SF Bay, Dying There at Alarming Rates"** — *The Guardian*
As climate change disrupts whale food sources, more whales are entering the Bay to hunt — directly into one of the world's busiest shipping corridors, with mortality rates possibly approaching 50%.

**"San Francisco Bay Area a Hot Spot for Marine Mammal Harassment"** — *The Marine Mammal Center*
SF Bay and the California coast are identified as hotspots for human-caused marine mammal harassment, including vessel crowding, separation of parent and offspring, and acoustic disturbance.

---

## What We Built

The Marine Intelligence System is an Oracle APEX application that connects historical marine ecosystem data with vessel movement data to detect ecological risk in real time and guide safer vessel behavior across San Francisco Bay.

It visualizes wildlife sightings, habitat zones, and vessel positions on a single interactive map — scoring each habitat zone with a dynamic Marine Risk Score and firing targeted alerts when vessels enter ecologically sensitive areas.

**100% Oracle: from spatial queries to ML forecasts to dashboards.**

---

## Approach

The problem was broken into four clear layers, each built on top of the previous one.

**1. Aggregate & Clean**
Marine wildlife sightings, vessel records, habitat boundaries, microplastics sampling, and water quality readings were ingested into Oracle Autonomous Database 26ai and organized across two schemas. Raw data arrived with significant quality issues — inconsistent timestamp formats across six different patterns, dirty station IDs with mixed casing and delimiters, out-of-bounds coordinates, and impossible numeric values. The data engineering layer resolved these systematically: a cross-schema view architecture was designed so that marine ecosystem data (OTTER schema) and vessel traffic data (SMART schema) could be queried together through explicit access grants, without duplicating or moving data between schemas. Enrichment views joined vessel registry data to AIS traffic records, computed vessel impact weights from speed and length, and aggregated water quality and biodiversity metrics per habitat zone — creating a clean analytical foundation that every other layer depended on.

**2. Score & Classify**
A spatial risk-scoring model was built that weighs five ecological factors per habitat zone and produces a 0–100 Marine Risk Score, classified as Low, Medium, or High. Wildlife pressure carries the highest weight, reflecting that confirmed species sightings are the most direct signal of ecological sensitivity. Water stress, microplastic concentration, habitat type, and vessel traffic level contribute the remaining weight.

**3. Detect & Alert**
Oracle Spatial operators (`SDO_RELATE`, `SDO_WITHIN_DISTANCE`) detect in real time when a vessel is inside or approaching a high-risk zone. Alerts are classified as CRITICAL, HIGH, MEDIUM, or INFO based on the combination of zone risk class and vessel impact weight, and fired through Oracle APEX Dynamic Actions with targeted intervention messages — slow down, reroute, or avoid a radius.

**4. Predict & Simulate**
Oracle Machine Learning (AutoML) was applied to forecast future wildlife sightings, model vessel traffic growth, and project ecosystem degradation without intervention — giving decision-makers a view of what happens if behavior does not change.

---

## Tech Stack

| Layer | Technology | Role |
|---|---|---|
| UI & Maps | Oracle APEX | Interactive dashboards, map layers, Dynamic Actions, alerts |
| Database | Oracle Autonomous Database 26ai | Stores all views, cleaned datasets, scoring results |
| Spatial Engine | Oracle Spatial | Zone detection, geofencing, proximity alerts via SDO_RELATE |
| Route Intelligence | Oracle Graph | Finds optimal vessel paths that avoid high-risk zones |
| Predictions | Oracle Machine Learning (AutoML) | Forecasts wildlife decline, projects risk under traffic growth |

**Notable Oracle APEX features used:**
- Native Map Region with SDO_GEOMETRY layer support
- Dynamic Actions for real-time vessel alert triggers
- Time-based filters across 2021–2025 data range
- AutoML for prediction model building and deployment

---

## Risk Score Formula

```
Marine Risk Score (0–100) =
  Wildlife Pressure Score    × 0.35
  Habitat Sensitivity Score  × 0.20
  Microplastic Score         × 0.20
  Water Stress Score         × 0.20
  Vessel Pressure Score      × 0.05
```

**Vessel Impact Weight** — vessel disturbance to marine life is scored as:
```
Impact Weight (1–25) = Speed Factor (1–5) × Length Factor (1–5)
```
Speed dominates the formula because acoustic disturbance — the primary threat to marine mammals — scales with velocity, not just physical size. A passenger ferry at 18 knots causes significantly more acoustic harm than a large cargo ship moving at 5 knots.

**Risk Classification:**
- Score `< 33` → LOW
- Score `33–66` → MEDIUM
- Score `> 66` → HIGH

---

## Environmental Impact

**Reduce Habitat Disruption** — By prompting vessels to adjust speed or route during peak wildlife presence, the system minimizes underwater noise, turbulence, and collision risk that stress or injure marine animals and disrupt feeding, migration, and social behaviors.

**Reduce Vessel-Wildlife Collisions** — Encouraging slower speeds and increased awareness gives vessels more time to detect and avoid species like whales and dolphins that surface unexpectedly — directly addressing one of the leading human-caused threats in coastal ecosystems.

---

## What Comes Next

The current system is a proof of concept, but the architecture is built to scale:

- **Live AIS vessel feed** — replace static vessel data with real-time Automatic Identification System feeds so alerts fire on actual vessel positions
- **Push notifications** — use Oracle APEX PWA push notifications to send alerts directly to vessel operators' devices
- **Per-species risk profiles** — different alert thresholds for endangered species like grey whales versus less vulnerable marine life

---

## Team

| Name | Role |
|---|---|
| Gayathri Ananya | Data Engineer |
| Yashica Sharma | Project Lead, Problem Statement & Risk Score Design |
| Therese Virata | Machine Learning & Predictions |
| Sarah Acosta | Oracle APEX & Map Development |
| Shresthkumar Karnani | Machine Learning & Predictions |

---

## Presentation

[View our full presentation slides](https://canva.link/ju0we7ikjfu9rey)

---

*AnDackaThon 2026 — Analytics & Data Oracle User Community (AnDOUC)*