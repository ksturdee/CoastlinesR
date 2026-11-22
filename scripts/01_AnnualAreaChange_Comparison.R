# Annual island area change in the Torres Strait
# Kendra Sturdee
#
# Compares relative changes in reconstructed island area
# across Masig, Iama and Boigu using accepted DEA footprints.
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
  here("data", "processed", "Boigu_AnnualMorphology_2013_2025.csv"),
  show_col_types = FALSE
)

# Standardise annual area measurements

prepare_area <- function(data, island) {
  
  names(data) <- tolower(names(data))
  
  year_col <- grep("^year$", names(data), value = TRUE)
  area_col <- grep("^area_ha$|^areahectares$", names(data), value = TRUE)
  
  if (length(year_col) != 1 || length(area_col) != 1) {
    stop(
      "Year or area column not identified for ", island,
      ". Available columns: ", paste(names(data), collapse = ", ")
    )
  }
  
  result <- data %>%
    transmute(
      Island = island,
      Year = as.integer(.data[[year_col]]),
      Area_ha = as.numeric(.data[[area_col]])
    ) %>%
    filter(!is.na(Year), !is.na(Area_ha)) %>%
    arrange(Year)
  
  if (nrow(result) == 0 || anyDuplicated(result$Year)) {
    stop("Missing or duplicate annual observations for ", island)
  }
  
  if (any(result$Area_ha <= 0)) {
    stop("Invalid island area detected for ", island)
  }
  
  result %>%
    mutate(
      Baseline_ha = first(Area_ha),
      Change_pct = 100 * (Area_ha - Baseline_ha) / Baseline_ha
    )
}

# Combine island records

area_data <- bind_rows(
  prepare_area(masig, "Masig"),
  prepare_area(iama, "Iama"),
  prepare_area(boigu, "Boigu")
)

area_data$Island <- factor(
  area_data$Island,
  levels = c("Masig", "Iama", "Boigu")
)

# Verify observation counts and study periods

area_summary <- area_data %>%
  group_by(Island) %>%
  summarise(
    Observations = n(),
    Start_year = first(Year),
    End_year = last(Year),
    Baseline_ha = first(Area_ha),
    Final_ha = last(Area_ha),
    Net_change_ha = last(Area_ha) - first(Area_ha),
    Net_change_pct = last(Change_pct),
    .groups = "drop"
  )

print(area_summary)

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
    area_summary$Start_year ==
      expected_years[as.character(area_summary$Island)]
  ),
  all(area_summary$End_year == 2025),
  all(
    area_summary$Observations ==
      expected_counts[as.character(area_summary$Island)]
  )
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

endpoints <- area_data %>%
  group_by(Island) %>%
  slice_max(Year, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  mutate(
    EndpointLabel = sprintf("%+.2f%%", Change_pct)
  )

# Create combined area change figure

area_plot <- ggplot(
  area_data,
  aes(
    x = Year,
    y = Change_pct,
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
    breaks = seq(-2, 10, 2),
    labels = function(x) paste0(x, "%"),
    expand = expansion(mult = c(0.08, 0.12))
  ) +
  coord_cartesian(
    clip = "off"
  ) +
  labs(
    title = "Changing island footprints",
    subtitle = "Relative area change across three Torres Strait islands",
    x = "Year",
    y = "Change from baseline (%)",
    colour = NULL,
    caption = paste(
      "Masig and Iama: 1988–2025 | Boigu: 2013–2025",
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

print(area_plot)

ggsave(
  filename = "figures/area_plot.png",
  plot = area_plot,
  width = 10,
  height = 7,
  dpi = 300,
  bg = "white"
)


