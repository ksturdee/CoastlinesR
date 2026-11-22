# Annualised island area change rates in the Torres Strait
# Kendra Sturdee
#
# Compares annualised area change between accepted footprints
# across Masig, Iama and Boigu.
# Lines connect observations; missing years are not estimated.

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

# Calculate annualised change between accepted observations

prepare_rates <- function(data, island) {
  
  stopifnot(all(c("Year", "Area_ha") %in% names(data)))
  
  result <- data %>%
    transmute(
      Island = island,
      Year = as.integer(Year),
      Area_ha = as.numeric(Area_ha)
    ) %>%
    arrange(Year)
  
  if (
    nrow(result) < 2 ||
    anyNA(result$Year) ||
    any(!is.finite(result$Area_ha)) ||
    any(result$Area_ha <= 0) ||
    anyDuplicated(result$Year)
  ) {
    stop("Invalid annual morphology data for ", island)
  }
  
  result %>%
    mutate(
      Previous_year = lag(Year),
      Interval_years = Year - Previous_year,
      Area_change_ha = Area_ha - lag(Area_ha),
      Rate_ha_year = Area_change_ha / Interval_years
    ) %>%
    filter(!is.na(Rate_ha_year))
}

# Combine island records

rate_data <- bind_rows(
  prepare_rates(masig, "Masig"),
  prepare_rates(iama, "Iama"),
  prepare_rates(boigu, "Boigu")
)

rate_data$Island <- factor(
  rate_data$Island,
  levels = c("Masig", "Iama", "Boigu")
)

# Verify observation intervals

stopifnot(
  all(rate_data$Interval_years > 0),
  all(is.finite(rate_data$Rate_ha_year))
)

rate_summary <- rate_data %>%
  group_by(Island) %>%
  summarise(
    Intervals = n(),
    Mean_rate = mean(Rate_ha_year),
    Minimum_rate = min(Rate_ha_year),
    Maximum_rate = max(Rate_ha_year),
    .groups = "drop"
  )

print(rate_summary)

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

# Create combined annualised area change figure

figure5 <- ggplot(
  rate_data,
  aes(
    x = Year,
    y = Rate_ha_year,
    colour = Island,
    group = Island
  )
) +
  geom_hline(
    yintercept = 0,
    colour = muted,
    linewidth = 0.6
  ) +
  geom_line(
    linewidth = 0.65,
    alpha = 0.75,
    lineend = "round"
  ) +
  geom_point(
    size = 1.7,
    alpha = 0.85
  ) +
  scale_colour_manual(
    values = island_colours
  ) +
  scale_x_continuous(
    breaks = seq(1990, 2025, 5),
    limits = c(1988, 2026),
    expand = expansion(mult = c(0.02, 0.02))
  ) +
  scale_y_continuous(
    breaks = scales::breaks_pretty(n = 6),
    expand = expansion(mult = c(0.12, 0.12))
  ) +
  labs(
    title = "The pace of island change",
    subtitle = "Annualised area change across three Torres Strait islands",
    x = "Observation year",
    y = "Area change rate (ha/year)",
    colour = NULL,
    caption = paste0(
      "Masig and Iama: 1988–2025 | Boigu: 2013–2025\n",
      "Rates represent change between consecutive accepted footprints.\n",
      "Lines connect observations; missing years were not estimated."
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
      margin = margin(b = 15)
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
      lineheight = 1.4,
      margin = margin(t = 18)
    ),
    plot.margin = margin(25, 40, 25, 25)
  )

# Preview figure

print(figure5)

# Save final figure

dir.create(
  here("figures"),
  showWarnings = FALSE
)

ggsave(
  filename = here("figures", "05_AnnualAreaChangeRates.png"),
  plot = figure5,
  width = 11,
  height = 7,
  dpi = 300,
  bg = ocean
)