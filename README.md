# MSc-Thesis-Template

Portfolio-grade R templates for longitudinal data integrity, attrition/selectivity reporting, two-wave change-score construction, mixed-effects modeling (LME), mediation-style decomposition (bootstrap), and interaction visualization using estimated marginal means.

**Note:** This is a methodological template illustrated with simulated data. It does not include raw project data, exact manuscript model specifications, or manuscript results.

## What this repo demonstrates
- Data integrity / QA utilities (complete-case filtering, duplicate checks, age correction/bands)
- Attrition + selectivity reporting (returnee/dropout classification; standardized selectivity indices; baseline tests)
- Two-wave change-score estimands (raw / percent / log ratio / absolute)
- LME workflow with lightweight diagnostics and influence screening
- Mediation-style decomposition with bootstrap simulation
- Interaction interpretation using EMM grids + standardized plotting helpers

## Quick start
Run the end-to-end demo:
- `analysis/run_example_msc.qmd`

Core reusable functions live in:
- `R/msc_thesis_template.R`
- `R/msc_moderation_plots.R`
