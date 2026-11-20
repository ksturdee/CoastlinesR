# Historical island footprint persistence in the Torres Strait
# Kendra Sturdee
#
# Compares persistent land and variable margins across
# all accepted annual island footprints.
# Values are from the completed spatial analysis.

library(ggplot2)
library(dplyr)
library(tidyr)

# Load previously calculated spatial statistics

persistence <- tibble(
  Island = c("Masig", "Iama", "Boigu"),
  Persistent_pct = c(89.85, 86.51, 99.02),
  Variable_pct = c(10.15, 13.49, 0.98),
  Observations = c(33, 34, 8),
  Period = c("1988–2025", "1988–2025", "2013–2025")
)

# Verify analytical values

stopifnot(
  all(
    abs(
      persistence$Persistent_pct +
        persistence$Variable_pct - 100
    ) < 0.01
  )
)

persistence$Island <- factor(
  persistence$Island,
  levels = c("Boigu", "Iama", "Masig")
)

# GIS colour palette

ocean <- "#102D35"
ivory <- "#FAF8F2"
muted <- "#AFC4C8"
grid_colour <- "#294A53"

persistent_colour <- "#D1B38D"
variable_colour <- "#70C8CD"

# Prepare persistence measurements

persistence_long <- persistence %>%
  transmute(
    Island,
    `Persistent core` = Persistent_pct,
    `Variable margins` = Variable_pct
  ) %>%
  pivot_longer(
    cols = c(`Persistent core`, `Variable margins`),
    names_to = "Category",
    values_to = "Share_pct"
  )

persistence_long$Category <- factor(
  persistence_long$Category,
  levels = c("Variable margins", "Persistent core")
)

# Prepare annotations

persistence_labels <- persistence %>%
  mutate(
    PersistentLabel = sprintf(
      "%.2f%% persistent",
      Persistent_pct
    ),
    VariableLabel = sprintf(
      "%.2f%% variable",
      Variable_pct
    )
  )

# Create persistence figure

figure4 <- ggplot(
  persistence_long,
  aes(
    x = Share_pct,
    y = Island,
    fill = Category
  )
) +
  geom_col(
    width = 0.48,
    colour = ocean,
    linewidth = 0.4,
    position = position_stack(reverse = FALSE)
  ) +
  geom_text(
    data = persistence_labels,
    aes(
      x = Persistent_pct / 2,
      y = Island,
      label = PersistentLabel
    ),
    inherit.aes = FALSE,
    colour = ocean,
    fontface = "bold",
    size = 3.8
  ) +
  geom_text(
    data = persistence_labels,
    aes(
      x = 101,
      y = Island,
      label = VariableLabel
    ),
    inherit.aes = FALSE,
    hjust = 0,
    colour = variable_colour,
    fontface = "bold",
    size = 3.6
  ) +
  scale_fill_manual(
    values = c(
      "Persistent core" = persistent_colour,
      "Variable margins" = variable_colour
    ),
    breaks = c("Persistent core", "Variable margins")
  ) +
  scale_x_continuous(
    breaks = seq(0, 100, 20),
    labels = function(x) paste0(x, "%"),
    expand = expansion(mult = c(0, 0))
  ) +
  coord_cartesian(
    xlim = c(0, 122),
    clip = "off"
  ) +
  labs(
    title = "The persistent island",
    subtitle = "Historical footprint persistence across three Torres Strait islands",
    x = "Share of historical footprint envelope",
    y = NULL,
    fill = NULL,
    caption = paste(
      "Masig: 1988–2025 (n = 33) |",
      "Iama: 1988–2025 (n = 34) |",
      "Boigu: 2013–2025 (n = 8)",
      "\nPersistent core: land present in every accepted footprint.",
      "Variable margins: land absent from at least one accepted footprint.",
      "\nValues are descriptive and exclude positional uncertainty."
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
      size = 11
    ),
    panel.grid.major.x = element_line(
      colour = grid_colour,
      linewidth = 0.35
    ),
    panel.grid.major.y = element_blank(),
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
      margin = margin(t = 20)
    ),
    plot.margin = margin(25, 45, 25, 25)
  )

# Preview figure

print(figure4)

ggsave(
  filename = here::here("figures", "04_FootprintPersistence.png"),
  plot = figure4,
  width = 10,
  height = 7,
  dpi = 300,
  bg = "#102D35"
)