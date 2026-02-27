# Decisions (template)

This log records template-level methodological choices (not project-specific).

- Complete-case filtering is provided as a utility because many longitudinal pipelines require a consistent analysis dataset per model family; missingness handling is left to the user/project.
- Attrition is summarized using unique IDs at each time point to avoid double-counting repeated observations.
- Baseline selectivity testing supports both t-tests and Welch’s t-tests because variance equality cannot be assumed by default; the user can choose.
- Chi-squared tests optionally apply Yates continuity correction for small-sample 2×2 tables.
- Change-score utilities support multiple estimands (raw / percent / log ratio / absolute) because “change” is definition-dependent.
- LME models are fit with random intercepts by default to reflect repeated measures structure; random slopes are left to the user.
- Diagnostics are lightweight (QQ, residuals vs fitted) to keep the template dependency-minimal; projects can extend diagnostics as needed.
- Mediation-style decomposition is implemented as a statistical decomposition template; causal interpretation depends on design and assumptions.
- Interaction plots use EMM grids at representative moderator values (quantiles) to avoid overinterpreting extreme min/max values.
