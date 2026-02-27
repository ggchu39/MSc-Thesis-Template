# R/msc_thesis_template/longitudinal-neuroimaging.R
# Portfolio template: 2-wave longitudinal QA + attrition/selectivity + change scores + LME + mediation
# Data-agnostic: works on any df that has ID/time/age/sex + outcomes/ROIs you specify.

#' Make corrected age (e.g., Age + 4 at follow-up)
#' @param df data.frame
#' @param id participant id column (string)
#' @param time_var timepoint column (string)
#' @param age_var baseline age column (string)
#' @param followup_level value in time_var that indicates follow-up (default 2)
#' @param followup_increment numeric years added at follow-up (default 4)
#' @param out_var name for corrected age column
#' @return df with new corrected age column
qa_make_age_corrected <- function(df, id, time_var, age_var,
                                  followup_level = 2,
                                  followup_increment = 4,
                                  out_var = "Age_Corrected") {
  stopifnot(is.data.frame(df))
  df[[out_var]] <- ifelse(df[[time_var]] == followup_level,
                          df[[age_var]] + followup_increment,
                          df[[age_var]])
  df
}

#' Make age groups (decade bins by default)
#' @param df data.frame
#' @param age_corrected_var corrected age column
#' @param breaks numeric breaks vector
#' @param right see ?cut
#' @param out_var output factor column
#' @return df with age group factor
qa_make_age_groups <- function(df, age_corrected_var,
                               breaks = seq(20, 90, 10),
                               right = FALSE,
                               out_var = "Age_Group") {
  stopifnot(is.data.frame(df))
  labs <- paste0(breaks[-length(breaks)], "-", breaks[-1] - 1)
  df[[out_var]] <- cut(df[[age_corrected_var]],
                       breaks = breaks,
                       right = right,
                       include.lowest = TRUE,
                       labels = labs)
  df
}

#' Complete-case filter with drop log
#' @param df data.frame
#' @param required_vars character vector of required column names
#' @return list(df = filtered_df, dropped_n = int, dropped_pct = numeric, missing_by_var = named int)
qa_complete_case <- function(df, required_vars) {
  stopifnot(is.data.frame(df))
  stopifnot(all(required_vars %in% names(df)))

  miss_by <- vapply(required_vars, function(v) sum(is.na(df[[v]])), integer(1))
  keep <- stats::complete.cases(df[, required_vars, drop = FALSE])
  out <- df[keep, , drop = FALSE]
  list(
    df = out,
    dropped_n = sum(!keep),
    dropped_pct = mean(!keep),
    missing_by_var = miss_by
  )
}

#' Check duplicates (ID x timepoint)
#' @return data.frame of duplicates (0 rows if none)
qa_check_duplicates <- function(df, id, time_var) {
  stopifnot(is.data.frame(df))
  key <- paste(df[[id]], df[[time_var]], sep = "__")
  df[duplicated(key) | duplicated(key, fromLast = TRUE), , drop = FALSE]
}

#' Add attrition status (Returnee vs Dropout)
attrition_status <- function(df_long, id, time_var, followup_level = 2,
                             out_var = "Status") {
  stopifnot(is.data.frame(df_long))
  ids_fu <- unique(df_long[df_long[[time_var]] == followup_level, id, drop = TRUE])
  df_long[[out_var]] <- ifelse(df_long[[id]] %in% ids_fu, "Returnee", "Dropout")
  df_long
}

#' Attrition summary counts
attrition_summary <- function(df_long, id, time_var, tp1 = 1, tp2 = 2) {
  n1 <- length(unique(df_long[df_long[[time_var]] == tp1, id, drop = TRUE]))
  n2 <- length(unique(df_long[df_long[[time_var]] == tp2, id, drop = TRUE]))
  lost <- n1 - n2
  rate <- if (n1 == 0) NA_real_ else 100 * lost / n1
  data.frame(TP1 = n1, TP2 = n2, Lost = lost, AttritionRatePct = rate)
}

#' Lindenberger-style selectivity index
selectivity_index <- function(mean_returnees, mean_parent, sd_parent) {
  (mean_returnees - mean_parent) / sd_parent
}

#' Baseline tests: returnees vs dropouts
#' - continuous: t-test or Welch
#' - categorical: chi-square with optional Yates
baseline_returnee_tests <- function(df_baseline, status_var,
                                    vars_continuous = character(0),
                                    vars_categorical = character(0),
                                    welch = TRUE,
                                    yates = TRUE) {
  stopifnot(is.data.frame(df_baseline))
  stopifnot(status_var %in% names(df_baseline))

  out <- list()

  for (v in vars_continuous) {
    g1 <- df_baseline[df_baseline[[status_var]] == "Returnee", v, drop = TRUE]
    g0 <- df_baseline[df_baseline[[status_var]] == "Dropout",  v, drop = TRUE]
    tt <- stats::t.test(g1, g0, var.equal = !welch)
    out[[paste0("t_", v)]] <- data.frame(
      var = v, test = if (welch) "Welch t-test" else "t-test",
      estimate_diff = unname(diff(tt$estimate)),
      p = tt$p.value
    )
  }

  for (v in vars_categorical) {
    tab <- table(df_baseline[[v]], df_baseline[[status_var]])
    ch <- suppressWarnings(stats::chisq.test(tab, correct = yates))
    out[[paste0("chisq_", v)]] <- data.frame(
      var = v, test = if (yates) "Chi-square (Yates)" else "Chi-square",
      p = ch$p.value
    )
  }

  do.call(rbind, out)
}

#' Convert long 2-wave to wide for selected vars
make_wide_two_wave <- function(df_long, id, time_var, vars, tp1 = 1, tp2 = 2) {
  stopifnot(is.data.frame(df_long))
  stopifnot(all(c(id, time_var, vars) %in% names(df_long)))

  d1 <- df_long[df_long[[time_var]] == tp1, c(id, vars), drop = FALSE]
  d2 <- df_long[df_long[[time_var]] == tp2, c(id, vars), drop = FALSE]
  names(d1)[names(d1) %in% vars] <- paste0(vars, "_TP1")
  names(d2)[names(d2) %in% vars] <- paste0(vars, "_TP2")
  merge(d1, d2, by = id)
}

#' Compute change for one variable in wide df
compute_change <- function(df_wide, var, method = c("raw","pct","logratio","abs")) {
  method <- match.arg(method)
  v1 <- df_wide[[paste0(var, "_TP1")]]
  v2 <- df_wide[[paste0(var, "_TP2")]]

  if (method == "raw")      return(v2 - v1)
  if (method == "pct")      return(100 * (v2 - v1) / v1)
  if (method == "logratio") return(log(v2 / v1))
  if (method == "abs")      return(abs(v2 - v1))
}

#' Compute change columns for a set of vars
compute_change_set <- function(df_wide, vars, method = "pct", prefix = "Change_") {
  for (v in vars) df_wide[[paste0(prefix, v)]] <- compute_change(df_wide, v, method = method)
  df_wide
}

#' Fit LME safely (random intercept style)
fit_lme_safely <- function(formula, data, reml = FALSE) {
  if (!requireNamespace("lme4", quietly = TRUE)) stop("Need lme4.")
  warns <- character(0)
  fit <- withCallingHandlers(
    try(lme4::lmer(formula, data = data, REML = reml), silent = TRUE),
    warning = function(w) { warns <<- c(warns, conditionMessage(w)); invokeRestart("muffleWarning") }
  )
  list(fit = fit, warns = warns)
}

#' Basic diagnostics plots (lightweight)
lme_basic_diagnostics <- function(fit) {
  if (inherits(fit, "try-error")) stop("Fit failed.")
  op <- par(mfrow = c(1,2))
  on.exit(par(op), add = TRUE)
  r <- resid(fit)
  f <- fitted(fit)
  qqnorm(r); qqline(r)
  plot(f, r, xlab = "Fitted", ylab = "Residuals"); abline(h = 0, lty = 2)
  invisible(TRUE)
}

#' Cook's distance (if available)
influence_cooks <- function(fit, cutoff = 1) {
  if (!requireNamespace("influence.ME", quietly = TRUE)) {
    return(list(note = "Install influence.ME for Cook's distance in LME."))
  }
  infl <- influence.ME::influence(fit, obs = TRUE)
  cd <- influence.ME::cooks.distance(infl)
  data.frame(row = seq_along(cd), cooks_d = cd, flag = cd > cutoff)
}

#' Mediation decomposition wrapper (bootstrapped)
mediation_decompose <- function(df, treat, mediator, outcome,
                                covariates = NULL,
                                sims = 500, seed = 1234) {
  if (!requireNamespace("mediation", quietly = TRUE)) stop("Need mediation.")
  set.seed(seed)

  rhs_m <- c(treat, covariates)
  rhs_y <- c(treat, mediator, covariates)

  f_m <- stats::as.formula(paste(mediator, "~", paste(rhs_m, collapse = " + ")))
  f_y <- stats::as.formula(paste(outcome,  "~", paste(rhs_y, collapse = " + ")))

  m_fit <- stats::lm(f_m, data = df)
  y_fit <- stats::lm(f_y, data = df)

  med <- mediation::mediate(m_fit, y_fit, treat = treat, mediator = mediator,
                            boot = TRUE, sims = sims)

  s <- summary(med)
  data.frame(
    ACME = s$d0, ACME_p = s$d0.p,
    ADE  = s$z0, ADE_p  = s$z0.p,
    Total = s$tau.coef, Total_p = s$tau.p,
    PropMediated = s$n0
  )
}
