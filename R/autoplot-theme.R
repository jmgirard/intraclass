# Shared plot styling for the autoplot methods ---------------------------------
#
# A cohesive internal look for the three `icc` plot views (the coefficient forest
# plot, the variance-component bars, and the d-study reliability curve). These
# helpers reference ggplot2 and are only ever called from the
# `check_installed("ggplot2")`-guarded autoplot methods, so ggplot2 stays a
# Suggests dependency (ADR-010 light-install). Internal only -- not exported; a
# user-facing `theme_intraclass()` is a deferred candidate (M61 plan gate).

# The Okabe-Ito qualitative palette: eight colourblind-safe hues (Okabe & Ito
# 2008, the grDevices/ggplot2 reference palette). Component-bar fills and the
# multilevel per-level colours draw from it in order.
icc_palette <- function() {
  c(
    "#0072B2", # blue
    "#E69F00", # orange
    "#009E73", # bluish green
    "#CC79A7", # reddish purple
    "#D55E00", # vermillion
    "#56B4E9", # sky blue
    "#F0E442", # yellow
    "#999999" # grey
  )
}

# The house theme: a clean minimal base with a bold, plot-aligned title, a muted
# subtitle, no minor gridlines, and bold facet strips. Legends are suppressed --
# colour re-encodes the facet or the axis-labelled component, never new
# information, so a legend would only add clutter. `plot.title.position = "plot"`
# is the theme's test fingerprint (the ggplot2 default is "panel").
icc_theme <- function() {
  ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold"),
      plot.title.position = "plot",
      plot.subtitle = ggplot2::element_text(colour = "grey30"),
      panel.grid.minor = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "bold"),
      legend.position = "none"
    )
}
