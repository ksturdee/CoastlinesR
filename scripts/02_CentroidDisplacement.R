# Historical centroid displacement in the Torres Strait
# Kendra Sturdee
#
# Compares displacement of reconstructed island centroids
# across Masig, Iama and Boigu using accepted DEA footprints.
# Displacement is measured relative to each island's baseline.
# Missing observations are not interpolated.

library(ggplot2)
library(dplyr)
library(readr)
library(here)

# Load processed morphology data

masig <- read_csv(
  here("data", "processed", "Masig_05_AnnualMorphology_Diagnostics.csv"),
  show_col_types = FALSE
)

iama <- read_csv(
  here("data", "processed", "Iama_04_AnnualMorphology_Diagnostics.csv"),
  show_col_types = FALSE
)

boigu <- read_csv(
  here("data", "processed", "Boigu_10_AnnualMorphology_2013_2025.csv"),
  show_col_types = FALSE
)

# Standardise centroid displacement measurements

prepare_centroid <- function(data, island, displacement_col) {
  
  if (!all(c("Year", displacement_col) %in% names(data))) {
    stop(
      "Required columns not identified for ", island,
      ". Available columns: ", paste(names(data), collapse = ", ")
    )
  }
  
  result <- data %>%
    transmute(
      Island = island,
      Year = as.integer(Year),
      Displacement_m = as.numeric(.data[[displacement_col]])
    ) %>%
    filter(!is.na(Year), !is.na(Displacement_m)) %>%
    arrange(Year)
  
  if (nrow(result) == 0 || anyDuplicated(result$Year)) {
    stop("Missing or duplicate annual observations for ", island)
  }
  
  if (any(!is.finite(result$Displacement_m)) ||
      any(result$Displacement_m < 0)) {
    stop("Invalid centroid displacement detected for ", island)
  }
  
  result
}

# Combine island records

centroid_data <- bind_rows(
  prepare_centroid(
    masig,
    "Masig",
    "CentroidDisplacementFrom1988_m"
  ),
  prepare_centroid(
    iama,
    "Iama",
    "CentroidDisp_1988_m"
  ),
  prepare_centroid(
    boigu,
    "Boigu",
    "CentroidDisp_2013_m"
  )
)

centroid_data$Island <- factor(
  centroid_data$Island,
  levels = c("Masig", "Iama", "Boigu")
)

# Verify observation counts and study periods

centroid_summary <- centroid_data %>%
  group_by(Island) %>%
  summarise(
    Observations = n(),
    Start_year = first(Year),
    End_year = last(Year),
    Final_displacement_m = last(Displacement_m),
    Maximum_displacement_m = max(Displacement_m),
    .groups = "drop"
  )

print(centroid_summary)

expected_years <- c(
  Masig = 1988,
  Iama = 1988,
  Boigu = 2013
)

expected_counts <- c(
  Masig = 33,
  Iama = 34,
  Boigu = 8
)

stopifnot(
  all(
    centroid_summary$Start_year ==
      expected_years[as.character(centroid_summary$Island)]
  ),
  all(centroid_summary$End_year == 2025),
  all(
    centroid_summary$Observations ==
      expected_counts[as.character(centroid_summary$Island)]
  )
)

# Verify baseline displacement

baseline_data <- centroid_data %>%
  group_by(Island) %>%
  slice_min(Year, n = 1, with_ties = FALSE) %>%
  ungroup()

stopifnot(
  all(abs(baseline_data$Displacement_m) < 1e-6)
)

# StoryMap colour palette

island_colours <- c(
  Masig = "#00E5D4",
  Iama = "#FF936B",
  Boigu = "#C5F277"
)

ocean <- "#102D35"
ivory <- "#FAF8F2"
muted <- "#AFC4C8"
grid_colour <- "#294A53"

# Identify final observations

endpoints <- centroid_data %>%
  group_by(Island) %>%
  slice_max(Year, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  mutate(
    EndpointLabel = sprintf("%.1f m", Displacement_m)
  )

# Create combined centroid displacement figure

centroid_plot <- ggplot(
  centroid_data,
  aes(
    x = Year,
    y = Displacement_m,
    colour = Island,
    group = Island
  )
) +
  geom_hline(
    yintercept = 0,
    colour = "#78969D",
    linewidth = 0.5,
    linetype = "dashed"
  ) +
  geom_line(
    linewidth = 1.2,
    lineend = "round"
  ) +
  geom_point(
    size = 1.8
  ) +
  geom_point(
    data = endpoints,
    shape = 21,
    size = 3.8,
    stroke = 1.4,
    fill = ocean,
    show.legend = FALSE
  ) +
  geom_text(
    data = endpoints,
    aes(label = EndpointLabel),
    hjust = -0.15,
    vjust = -0.65,
    fontface = "bold",
    size = 3.6,
    show.legend = FALSE
  ) +
  scale_colour_manual(
    values = island_colours
  ) +
  scale_x_continuous(
    breaks = seq(1990, 2025, 5),
    limits = c(1988, 2029),
    expand = expansion(mult = c(0.01, 0.01))
  ) +
  scale_y_continuous(
    labels = function(x) paste0(x, " m"),
    expand = expansion(mult = c(0.05, 0.15))
  ) +
  coord_cartesian(
    clip = "off"
  ) +
  labs(
    title = "Shifting island centroids",
    subtitle = "Historical centroid displacement across three Torres Strait islands",
    x = "Year",
    y = "Displacement from baseline (m)",
    colour = NULL,
    caption = paste(
      "Masig and Iama: relative to 1988 | Boigu: relative to 2013",
      "\nAccepted DEA-derived footprints only.",
      "Lines connect observations; missing years were not interpolated."
    )
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.background = element_rect(
      fill = ocean,
      colour = NA
    ),
    panel.background = element_rect(
      fill = ocean,
      colour = NA
    ),
    plot.title = element_text(
      colour = ivory,
      face = "bold",
      size = 19,
      margin = margin(b = 8)
    ),
    plot.subtitle = element_text(
      colour = muted,
      size = 11,
      margin = margin(b = 12)
    ),
    axis.title = element_text(
      colour = ivory,
      size = 11
    ),
    axis.text = element_text(
      colour = muted,
      size = 10
    ),
    panel.grid.major.y = element_line(
      colour = grid_colour,
      linewidth = 0.35
    ),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    axis.ticks = element_blank(),
    legend.position = "top",
    legend.justification = "left",
    legend.text = element_text(
      colour = ivory,
      size = 11
    ),
    legend.key = element_rect(
      fill = ocean,
      colour = NA
    ),
    legend.background = element_rect(
      fill = ocean,
      colour = NA
    ),
    plot.caption = element_text(
      colour = muted,
      size = 9,
      hjust = 0,
      lineheight = 1.3,
      margin = margin(t = 16)
    ),
    plot.margin = margin(20, 65, 20, 20)
  )

# Preview figure

print(centroid_plot)