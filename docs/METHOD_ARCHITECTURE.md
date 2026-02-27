# Method architecture (template)

## Repository intent
This is a methodological template. It demonstrates reusable analysis components for two-wave longitudinal studies without exposing project data, exact model specifications, or manuscript results.

## File layout

- `R/msc_thesis_template.R`
  - One “engine” file containing generic, reusable functions:
    - QA helpers
    - Attrition/selectivity utilities
    - Change-score builders
    - LME fitting + lightweight diagnostics
    - Mediation-style decomposition wrapper

- `R/msc_moderation_plots.R`
  - One small module for interaction visualization:
    - Build EMM grids (emmeans)
    - Choose representative moderator levels
    - Plot standardized interaction figures with uncertainty intervals

- `analysis/run_example_msc.qmd`
  - End-to-end runnable demo using simulated two-wave data:
    - QA → attrition → selectivity → change scores → LME → mediation → interaction plots

- `docs/DECISIONS.md`
  - A short decision log explaining design choices at the template level (not project-specific).

## Design principles

- **Data-agnostic**: functions accept variable names as arguments; no dataset-specific objects.
- **Separation of concerns**: preprocessing, modeling, diagnostics, and plotting are modular.
- **Reproducible by default**: deterministic seeds in examples, explicit outputs, minimal side effects.
- **Readable and testable**: functions are small, documented, and avoid hidden global state.
