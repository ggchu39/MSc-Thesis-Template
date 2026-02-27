# Analysis approach (template)

This repository provides a reusable template for longitudinal analysis workflows commonly used in cognitive/neuroimaging studies. It demonstrates data integrity checks, attrition/selectivity reporting, two-wave change-score construction, mixed-effects modeling, mediation-style decomposition, and interaction visualization using estimated marginal means. All examples run on simulated data and intentionally omit project-specific datasets, exact model specifications, and results.

## Outcomes and data structure

- Two-wave longitudinal data are represented in **long format** (two rows per participant: TP1 and TP2).
- Change-score analyses are performed in **wide format** (one row per participant) after reshaping.

## A) Data integrity / QA

Core QA utilities implement:
- Age correction for follow-up time points (e.g., +4 years) for age-at-assessment displays.
- Age band creation for descriptive stratification (e.g., 10-year bins).
- Complete-case filtering for required variables, with explicit logging of dropped rows/columns.
- Duplicate checks for the (ID, time-point) key to detect repeated observations.

## B) Attrition and selectivity

Attrition is summarized by:
- Identifying follow-up attendance (“Returnee” vs “Dropout”) from the long-format data.
- Reporting TP1/TP2 participant counts, lost-to-follow-up counts, and attrition rate.

Selectivity is assessed by:
- Computing a standardized selectivity index (Returnees vs parent sample) for baseline measures.
- Running baseline comparisons between returnees and dropouts:
  - Continuous variables via t-test or Welch’s t-test (configurable).
  - Categorical variables via chi-squared tests with optional Yates continuity correction (configurable).

## C) Change-score construction (two-wave)

Change-score helpers support multiple estimands:
- Raw signed change: TP2 − TP1
- Percent change: 100 × (TP2 − TP1) / TP1
- Log ratio: log(TP2 / TP1)
- Absolute magnitude: |TP2 − TP1|

These are generated after reshaping long → wide for specified variables.

## D) Mixed-effects modeling (LME template)

Mixed-effects models are fitted to long-format data with:
- Random intercepts for participant ID to account for repeated measurements.
- Fixed-effect structures specified by the user (e.g., Time, Sex, Age, interactions).
- Lightweight diagnostics (QQ plot; residuals vs fitted) to support assumption checking.
- Influence screening via Cook’s distance extraction where available.

## E) Mediation-style decomposition (template)

A mediation helper runs a mediation-style decomposition using bootstrap simulation:
- Fits mediator and outcome models with optional covariate adjustment.
- Returns a compact summary (ACME, ADE, total effect, proportion mediated, and uncertainty intervals).
- Intended as a general statistical decomposition template; interpretation depends on design and assumptions.

## F) Interaction visualization (interpretability layer)

Higher-order interactions can be visualized using:
- Estimated marginal means grids (via `emmeans`) evaluated at representative moderator values
  (e.g., low/median/high quantiles).
- Consistent plotting helpers that separate:
  **model fit → EMM grid → visualization**
  to keep inference and reporting reproducible.

## Reproducibility signals

- Deterministic seeds in demo scripts.
- Consistent naming and a clear separation between:
  engine functions (`R/`) and runnable examples (`analysis/`).
- Outputs are generated from scripts rather than manual editing.
