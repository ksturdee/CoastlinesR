# ============================================================
# MASIG AND IAMA: FOOTPRINT CHANGE AND CENTROID DISPLACEMENT
# Publication-style two-panel figure with magnified insets
# ============================================================
#
# Run this AFTER importing the validated footprint and centroid
# objects. The script never edits the source objects. It creates
# transformed copies in memory and exports PNG and vector PDF files.
#
# Required packages:
# install.packages(c("sf", "ggplot2", "dplyr", "readr", "cowplot", "scales"))

library(sf)
library(ggplot2)
library(dplyr)
library(cowplot)
library(scales)
library(grid)

# ------------------------------------------------------------
# 1. OUTPUT LOCATION
# ------------------------------------------------------------
project_root <- paste0(
  "C:/Users/jd161818/Desktop/Coastline_Project/",
  "15NovCoastline_Project"
)
figure_dir <- file.path(project_root, "4_Figures")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

png_file <- file.path(
  figure_dir,
  "Masig_Iama_Footprints_CentroidVectors_1988_2025.png"
)
pdf_file <- file.path(
  figure_dir,
  "Masig_Iama_Footprints_CentroidVectors_1988_2025.pdf"
)

# ------------------------------------------------------------
# 2. OPTIONAL OBJECT OVERRIDES
# ------------------------------------------------------------
# Leave as NULL to auto-detect the imported objects by name.
# If auto-detection reports more than one candidate, replace NULL
# with the exact object name as a quoted string, for example:
# masig_footprints_object <- "masig_footprints_sf"

masig_footprints_object <- NULL
iama_footprints_object  <- NULL
masig_centroids_object  <- NULL
iama_centroids_object   <- NULL

# ------------------------------------------------------------
# 3. RESTRAINED EARTH-TONED PALETTE
# ------------------------------------------------------------
col_1988_fill    <- "#E7D8B2"  # light sandstone
col_1988_edge    <- "#665F52"  # quiet dark taupe
col_masig        <- "#A3634B"  # muted terracotta
col_iama         <- "#667653"  # muted sage/olive
col_intermediate <- "#8B8B87"  # neutral grey
col_black        <- "#000000"
col_white        <- "#FFFFFF"

# ------------------------------------------------------------
# 4. OBJECT RESOLUTION AND VALIDATION
# ------------------------------------------------------------
get_named_object <- function(name) {
  if (is.null(name)) return(NULL)
  if (!exists(name, envir = .GlobalEnv, inherits = FALSE)) {
    stop("Object not found: ", name)
  }
  get(name, envir = .GlobalEnv, inherits = FALSE)
}

find_objects <- function(island, concept, allow_data_frame = FALSE) {
  all_names <- ls(envir = .GlobalEnv)
  island_pattern <- paste0("(?i)", island)
  concept_pattern <- paste0("(?i)", concept)
  candidate_names <- all_names[
    grepl(island_pattern, all_names, perl = TRUE) &
      grepl(concept_pattern, all_names, perl = TRUE)
  ]

  keep <- vapply(candidate_names, function(nm) {
    x <- get(nm, envir = .GlobalEnv, inherits = FALSE)
    inherits(x, "sf") ||
      (allow_data_frame && (is.data.frame(x) || inherits(x, "tbl_df")))
  }, logical(1))

  candidate_names[keep]
}

find_year_field <- function(x) {
  candidates <- c("Year", "YEAR", "year", "Year_", "YEAR_", "yr", "YR")
  hit <- candidates[candidates %in% names(x)]
  if (length(hit) == 0) {
    hit <- names(x)[grepl("(?i)^year$|year", names(x), perl = TRUE)]
  }
  if (length(hit) == 0) return(NA_character_)
  hit[1]
}

resolve_footprints <- function(island, override_name = NULL) {
  supplied <- get_named_object(override_name)
  if (!is.null(supplied)) {
    if (!inherits(supplied, "sf")) stop(island, " footprint object is not sf.")
    return(supplied)
  }

  candidates <- unique(c(
    find_objects(island, "footprint"),
    find_objects(island, "validated")
  ))

  # Prefer one sf object that already contains a year field.
  with_year <- candidates[vapply(candidates, function(nm) {
    !is.na(find_year_field(get(nm, envir = .GlobalEnv)))
  }, logical(1))]

  if (length(with_year) == 1) {
    return(get(with_year, envir = .GlobalEnv))
  }

  # Otherwise assemble separately imported 1988 and 2025 sf objects.
  names_1988 <- ls(envir = .GlobalEnv)
  names_1988 <- names_1988[
    grepl(paste0("(?i)", island), names_1988, perl = TRUE) &
      grepl("1988", names_1988)
  ]
  names_2025 <- ls(envir = .GlobalEnv)
  names_2025 <- names_2025[
    grepl(paste0("(?i)", island), names_2025, perl = TRUE) &
      grepl("2025", names_2025)
  ]

  names_1988 <- names_1988[vapply(names_1988, function(nm) {
    inherits(get(nm, envir = .GlobalEnv), "sf")
  }, logical(1))]
  names_2025 <- names_2025[vapply(names_2025, function(nm) {
    inherits(get(nm, envir = .GlobalEnv), "sf")
  }, logical(1))]

  if (length(names_1988) == 1 && length(names_2025) == 1) {
    a <- get(names_1988, envir = .GlobalEnv) |> mutate(Year = 1988L)
    b <- get(names_2025, envir = .GlobalEnv) |> mutate(Year = 2025L)
    if (st_crs(a) != st_crs(b)) b <- st_transform(b, st_crs(a))
    return(bind_rows(a, b))
  }

  stop(
    "Could not uniquely identify ", island, " footprint data. Candidates: ",
    paste(candidates, collapse = ", "),
    ". Set the corresponding *_footprints_object value in section 2."
  )
}

resolve_centroids <- function(island, override_name = NULL) {
  supplied <- get_named_object(override_name)
  if (!is.null(supplied)) return(supplied)

  candidates <- unique(c(
    find_objects(island, "centroid", allow_data_frame = TRUE),
    find_objects(island, "displacement", allow_data_frame = TRUE)
  ))

  if (length(candidates) != 1) {
    stop(
      "Could not uniquely identify ", island, " centroid data. Candidates: ",
      paste(candidates, collapse = ", "),
      ". Set the corresponding *_centroids_object value in section 2."
    )
  }
  get(candidates, envir = .GlobalEnv)
}

endpoint_footprints <- function(x, island) {
  if (!inherits(x, "sf")) stop(island, " footprints must be an sf object.")
  year_field <- find_year_field(x)
  if (is.na(year_field)) {
    stop(island, " footprint object has no identifiable year field.")
  }

  out <- x |>
    mutate(.year = as.integer(.data[[year_field]])) |>
    filter(.year %in% c(1988L, 2025L)) |>
    st_make_valid()

  if (!all(c(1988L, 2025L) %in% out$.year)) {
    stop(island, " footprint data must contain both 1988 and 2025.")
  }
  if (is.na(st_crs(out))) stop(island, " footprints have no CRS.")
  if (st_is_longlat(out)) {
    stop(island, " footprints must use a projected metre-based CRS, not longitude/latitude.")
  }

  out |>
    group_by(.year) |>
    summarise(geometry = st_union(geometry), .groups = "drop")
}

first_matching_field <- function(x, candidates, pattern = NULL) {
  hit <- candidates[candidates %in% names(x)]
  if (length(hit) > 0) return(hit[1])
  if (!is.null(pattern)) {
    hit <- names(x)[grepl(pattern, names(x), perl = TRUE)]
    if (length(hit) > 0) return(hit[1])
  }
  NA_character_
}

centroids_to_sf <- function(x, island, target_crs) {
  year_field <- find_year_field(x)
  if (is.na(year_field)) stop(island, " centroid data have no identifiable year field.")

  if (inherits(x, "sf")) {
    out <- x |>
      mutate(.year = as.integer(.data[[year_field]])) |>
      st_transform(target_crs)
  } else {
    x_field <- first_matching_field(
      x,
      c("CentroidX", "Easting_m", "Centroid_Easting", "Easting", "X", "x"),
      "(?i)centroid.*x|easting"
    )
    y_field <- first_matching_field(
      x,
      c("CentroidY", "Northing_m", "Centroid_Northing", "Northing", "Y", "y"),
      "(?i)centroid.*y|northing"
    )
    if (is.na(x_field) || is.na(y_field)) {
      stop(island, " centroid coordinate columns could not be identified.")
    }
    out <- x |>
      mutate(
        .year = as.integer(.data[[year_field]]),
        .x = as.numeric(.data[[x_field]]),
        .y = as.numeric(.data[[y_field]])
      ) |>
      filter(is.finite(.x), is.finite(.y)) |>
      st_as_sf(coords = c(".x", ".y"), crs = target_crs, remove = FALSE)
  }

  out <- out |>
    filter(!is.na(.year)) |>
    arrange(.year)

  if (!all(c(1988L, 2025L) %in% out$.year)) {
    stop(island, " centroid data must contain both 1988 and 2025.")
  }
  out
}

# Resolve imported objects without modifying them.
masig_fp_raw <- resolve_footprints("masig", masig_footprints_object)
iama_fp_raw  <- resolve_footprints("iama",  iama_footprints_object)
masig_c_raw  <- resolve_centroids("masig", masig_centroids_object)
iama_c_raw   <- resolve_centroids("iama",  iama_centroids_object)

masig_fp <- endpoint_footprints(masig_fp_raw, "Masig")
iama_fp  <- endpoint_footprints(iama_fp_raw,  "Iama")
masig_c  <- centroids_to_sf(masig_c_raw, "Masig", st_crs(masig_fp))
iama_c   <- centroids_to_sf(iama_c_raw,  "Iama",  st_crs(iama_fp))

# ------------------------------------------------------------
# 5. PLOTTING HELPERS
# ------------------------------------------------------------
plain_theme <- function(base_size = 9.2) {
  theme_minimal(base_family = "Arial", base_size = base_size) +
    theme(
      text = element_text(colour = col_black, face = "plain"),
      plot.title = element_text(colour = col_black, face = "plain", size = 11.2,
                                hjust = 0, margin = margin(b = 5)),
      plot.subtitle = element_text(colour = col_black, face = "plain", size = 8.6,
                                   hjust = 0, margin = margin(b = 6)),
      axis.title = element_text(colour = col_black, face = "plain", size = 8.2),
      axis.text = element_text(colour = col_black, face = "plain", size = 7.2),
      axis.ticks = element_line(colour = col_black, linewidth = 0.3),
      axis.ticks.length = unit(1.8, "mm"),
      panel.grid = element_blank(),
      panel.border = element_rect(colour = col_black, fill = NA, linewidth = 0.45),
      plot.background = element_rect(fill = col_white, colour = NA),
      panel.background = element_rect(fill = col_white, colour = NA),
      plot.margin = margin(7, 7, 7, 7)
    )
}

square_limits <- function(fp, pad_fraction = 0.055) {
  bb <- st_bbox(fp)
  cx <- mean(c(bb[["xmin"]], bb[["xmax"]]))
  cy <- mean(c(bb[["ymin"]], bb[["ymax"]]))
  half <- max(
    bb[["xmax"]] - bb[["xmin"]],
    bb[["ymax"]] - bb[["ymin"]]
  ) * (0.5 + pad_fraction)
  list(x = c(cx - half, cx + half), y = c(cy - half, cy + half))
}

centroid_table <- function(c_sf) {
  xy <- st_coordinates(c_sf)
  tibble(
    year = c_sf$.year,
    x = xy[, 1],
    y = xy[, 2]
  ) |>
    arrange(year) |>
    distinct(year, .keep_all = TRUE)
}

relative_centroids <- function(c_sf) {
  z <- centroid_table(c_sf)
  origin <- z |> filter(year == 1988L) |> slice(1)
  z |>
    mutate(dx = x - origin$x, dy = y - origin$y)
}

endpoint_distance <- function(c_sf) {
  z <- relative_centroids(c_sf)
  end <- z |> filter(year == 2025L) |> slice(1)
  sqrt(end$dx^2 + end$dy^2)
}

make_inset <- function(c_sf, accent, expected_distance, island) {
  z <- relative_centroids(c_sf)
  p0 <- z |> filter(year == 1988L) |> slice(1)
  p1 <- z |> filter(year == 2025L) |> slice(1)
  middle <- z |> filter(!year %in% c(1988L, 2025L))
  observed <- endpoint_distance(c_sf)

  if (abs(observed - expected_distance) > 0.25) {
    warning(
      island, " endpoint displacement is ", round(observed, 2),
      " m; expected approximately ", expected_distance, " m."
    )
  }

  span <- max(diff(range(z$dx)), diff(range(z$dy)), expected_distance)
  margin <- max(5, span * 0.18)
  xlim <- range(z$dx) + c(-margin, margin)
  ylim <- range(z$dy) + c(-margin, margin)

  ggplot(z, aes(dx, dy)) +
    geom_path(colour = alpha(col_intermediate, 0.70), linewidth = 0.42) +
    geom_point(
      data = middle,
      colour = col_intermediate,
      fill = alpha(col_white, 0.85),
      shape = 21,
      size = 1.55,
      stroke = 0.38
    ) +
    geom_segment(
      data = data.frame(x = p0$dx, y = p0$dy, xend = p1$dx, yend = p1$dy),
      aes(x = x, y = y, xend = xend, yend = yend),
      inherit.aes = FALSE,
      colour = accent,
      linewidth = 0.75,
      arrow = arrow(length = unit(2.0, "mm"), type = "closed")
    ) +
    geom_point(data = p0, shape = 21, fill = col_white, colour = col_black,
               size = 2.4, stroke = 0.58) +
    geom_point(data = p1, shape = 21, fill = accent, colour = col_black,
               size = 2.5, stroke = 0.50) +
    annotate(
      "label",
      x = xlim[1] + 0.04 * diff(xlim),
      y = ylim[2] - 0.05 * diff(ylim),
      label = paste0("Centroid inset\n", formatC(observed, format = "f", digits = 2), " m"),
      hjust = 0,
      vjust = 1,
      family = "Arial",
      fontface = "plain",
      size = 2.45,
      colour = col_black,
      fill = alpha(col_white, 0.88),
      label.size = 0,
      label.padding = unit(1.2, "mm")
    ) +
    coord_equal(xlim = xlim, ylim = ylim, expand = FALSE) +
    labs(x = "Eastward displacement (m)", y = "Northward displacement (m)") +
    scale_x_continuous(labels = label_number(accuracy = 1)) +
    scale_y_continuous(labels = label_number(accuracy = 1)) +
    plain_theme(7.4) +
    theme(
      axis.title = element_text(size = 6.3),
      axis.text = element_text(size = 5.8),
      axis.ticks.length = unit(1.1, "mm"),
      panel.border = element_rect(colour = col_black, fill = NA, linewidth = 0.42),
      plot.margin = margin(3, 3, 3, 3)
    )
}

make_main_panel <- function(fp, c_sf, island, descriptor, tag, accent,
                            expected_distance) {
  fp_1988 <- fp |> filter(.year == 1988L)
  fp_2025 <- fp |> filter(.year == 2025L)
  ctab <- centroid_table(c_sf)
  c1988 <- ctab |> filter(year == 1988L) |> slice(1)
  c2025 <- ctab |> filter(year == 2025L) |> slice(1)
  cmid  <- ctab |> filter(!year %in% c(1988L, 2025L))
  lims <- square_limits(fp)

  main <- ggplot() +
    geom_sf(
      data = fp_1988,
      fill = col_1988_fill,
      colour = col_1988_edge,
      linewidth = 0.50
    ) +
    geom_sf(
      data = fp_2025,
      fill = alpha(accent, 0.075),
      colour = accent,
      linewidth = 0.88
    ) +
    geom_path(
      data = ctab,
      aes(x, y),
      colour = alpha(col_intermediate, 0.72),
      linewidth = 0.38
    ) +
    geom_point(
      data = cmid,
      aes(x, y),
      shape = 21,
      colour = col_intermediate,
      fill = alpha(col_white, 0.80),
      size = 1.20,
      stroke = 0.34
    ) +
    geom_segment(
      data = data.frame(
        x = c1988$x, y = c1988$y,
        xend = c2025$x, yend = c2025$y
      ),
      aes(x = x, y = y, xend = xend, yend = yend),
      colour = accent,
      linewidth = 0.74,
      arrow = arrow(length = unit(2.0, "mm"), type = "closed")
    ) +
    geom_point(
      data = c1988, aes(x, y),
      shape = 21, fill = col_white, colour = col_black,
      size = 2.15, stroke = 0.55
    ) +
    geom_point(
      data = c2025, aes(x, y),
      shape = 21, fill = accent, colour = col_black,
      size = 2.25, stroke = 0.50
    ) +
    coord_sf(
      xlim = lims$x,
      ylim = lims$y,
      expand = FALSE,
      datum = NA
    ) +
    scale_x_continuous(labels = label_number(big.mark = ",", accuracy = 1)) +
    scale_y_continuous(labels = label_number(big.mark = ",", accuracy = 1)) +
    labs(
      title = paste0(tag, "  ", island, " | ", descriptor),
      subtitle = "Validated island footprints and accepted annual centroids",
      x = "Easting (m)",
      y = "Northing (m)"
    ) +
    plain_theme(9.0)

  inset <- make_inset(c_sf, accent, expected_distance, island)

  # Cowplot is used deliberately; no overloaded composition operator is required.
  ggdraw() +
    draw_plot(main, x = 0, y = 0, width = 1, height = 1) +
    draw_plot(
      inset,
      x = 0.565, y = 0.075,
      width = 0.405, height = 0.405
    )
}

# ------------------------------------------------------------
# 6. BUILD THE TWO INDEPENDENTLY CENTRED PANELS
# ------------------------------------------------------------
masig_panel <- make_main_panel(
  fp = masig_fp,
  c_sf = masig_c,
  island = "Masig",
  descriptor = "coral cay",
  tag = "A",
  accent = col_masig,
  expected_distance = 17.25
)

iama_panel <- make_main_panel(
  fp = iama_fp,
  c_sf = iama_c,
  island = "Iama",
  descriptor = "continental island",
  tag = "B",
  accent = col_iama,
  expected_distance = 36.03
)

panels <- plot_grid(
  masig_panel,
  iama_panel,
  nrow = 1,
  rel_widths = c(1, 1),
  align = "h",
  axis = "tb"
)

title_block <- ggdraw() +
  draw_label(
    "Island-footprint change and centroid displacement, 1988-2025",
    x = 0.02, y = 0.72,
    hjust = 0, vjust = 0.5,
    fontfamily = "Arial", fontface = "plain",
    fontsize = 14.0, colour = col_black
  ) +
  draw_label(
    "Masig and Iama Islands, Torres Strait | projected coordinates in metres",
    x = 0.02, y = 0.25,
    hjust = 0, vjust = 0.5,
    fontfamily = "Arial", fontface = "plain",
    fontsize = 9.5, colour = col_black
  )

note_block <- ggdraw() +
  draw_label(
    paste0(
      "Sandstone: 1988 footprint. Panel-coloured outline: 2025 footprint. ",
      "Open/filled circles: 1988/2025 centroids; grey points: intermediate accepted years.\n",
      "Insets magnify centroid trajectories only; displacement vectors retain their true scale. ",
      "Centroid change describes redistribution of mapped footprint geometry, not physical island translation."
    ),
    x = 0.02, y = 0.52,
    hjust = 0, vjust = 0.5,
    fontfamily = "Arial", fontface = "plain",
    fontsize = 8.0, colour = col_black,
    lineheight = 1.18
  )

final_figure <- plot_grid(
  title_block,
  panels,
  note_block,
  ncol = 1,
  rel_heights = c(0.105, 0.815, 0.080)
)

# ------------------------------------------------------------
# 7. EXPORT PUBLICATION-QUALITY OUTPUTS
# ------------------------------------------------------------
png_device <- if (requireNamespace("ragg", quietly = TRUE)) {
  ragg::agg_png
} else {
  "png"
}

pdf_device <- if (capabilities("cairo")) {
  cairo_pdf
} else {
  "pdf"
}

ggsave(
  filename = png_file,
  plot = final_figure,
  width = 12.0,
  height = 7.6,
  units = "in",
  dpi = 600,
  device = png_device,
  bg = col_white
)

ggsave(
  filename = pdf_file,
  plot = final_figure,
  width = 12.0,
  height = 7.6,
  units = "in",
  device = pdf_device,
  bg = col_white
)

message("Figure exported:")
message("  PNG: ", png_file)
message("  PDF: ", pdf_file)
message("Observed endpoint displacements:")
message("  Masig: ", formatC(endpoint_distance(masig_c), format = "f", digits = 2), " m")
message("  Iama:  ", formatC(endpoint_distance(iama_c),  format = "f", digits = 2), " m")
