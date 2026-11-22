# Endpoint land redistribution in the Torres Strait
# Kendra Sturdee
#
# Compares land gained, lost and net area change
# between accepted baseline and 2025 island footprints.
# Masig and Iama: 1988–2025; Boigu: 2013–2025.

library(ggplot2)
library(dplyr)
library(readr)
library(tidyr)
library(here)

# Load validated redistribution data

masig <- read_csv(
  here("data", "processed", "Masig_07_LandRedistribution_1988_2025.csv"),
  show_col_types = FALSE
)

boigu <- read_csv(
  here("data", "processed", "Boigu_LandPersistence_Redistribution.csv"),
  show_col_types = FALSE
)

# Extract Masig measurements

get_metric <- function(data, metric, unit) {
  value <- data %>%
    filter(Metric == metric, Unit == unit) %>%
    pull(Value)
  
  if (length(value) != 1 || !is.finite(value)) {
    stop("Missing or invalid measurement: ", metric, " (", unit, ")")
  }
  
  value
}

masig_baseline <- get_metric(masig, "1988 area", "ha")
masig_gain <- get_metric(masig, "Land gained", "ha")
masig_loss <- get_metric(masig, "Land lost", "ha")
masig_net <- get_metric(masig, "Net area change", "ha")

# Iama endpoint measurements from Analysis_Log.md
# Recorded 2026-11-16 16:41

iama_baseline <- 169.2901
iama_gain <- 15.8940
iama_loss <- 2.1557
iama_net <- 13.7383

# Verify Boigu source measurements

required_boigu <- c(
  "Area2013_ha",
  "Gained_ha",
  "Lost_ha",
  "NetChange_ha"
)

stopifnot(
  nrow(boigu) == 1,
  all(required_boigu %in% names(boigu))
)

# Combine endpoint redistribution measurements

redistribution <- tibble(
  Island = c("Masig", "Iama", "Boigu"),
  Baseline_ha = c(
    masig_baseline,
    iama_baseline,
    boigu$Area2013_ha
  ),
  Gained_ha = c(
    masig_gain,
    iama_gain,
    boigu$Gained_ha
  ),
  Lost_ha = c(
    masig_loss,
    iama_loss,
    boigu$Lost_ha
  ),
  Net_ha = c(
    masig_net,
    iama_net,
    boigu$NetChange_ha
  )
) %>%
  mutate(
    Gained_pct = 100 * Gained_ha / Baseline_ha,
    Lost_pct = 100 * Lost_ha / Baseline_ha,
    Net_pct = 100 * Net_ha / Baseline_ha
  )

# Verify area balances

stopifnot(
  all(is.finite(as.matrix(redistribution[, -1]))),
  all(redistribution$Baseline_ha > 0),
  all(redistribution$Gained_ha >= 0),
  all(redistribution$Lost_ha >= 0),
  all(
    abs(
      redistribution$Gained_ha -
        redistribution$Lost_ha -
        redistribution$Net_ha
    ) < 0.02
  )
)

print(redistribution, width = Inf)

redistribution$Island <- factor(
  redistribution$Island,
  levels = c("Boigu", "Iama", "Masig")
)

# GIS colour palette

ocean <- "#102D35"
ivory <- "#FAF8F2"
muted <- "#AFC4C8"
grid_colour <- "#294A53"

gain_colour <- "#20A39E"
loss_colour <- "#C66B4E"
net_colour <- "#153653"

# Prepare gain and loss measurements

redistribution_long <- redistribution %>%
  transmute(
    Island,
    `Land gained` = Gained_pct,
    `Land lost` = -Lost_pct
  ) %>%
  pivot_longer(
    cols = c(`Land gained`, `Land lost`),
    names_to = "Category",
    values_to = "Change_pct"
  )

redistribution_long$Category <- factor(
  redistribution_long$Category,
  levels = c("Land gained", "Land lost")
)

# Prepare endpoint annotations

gain_labels <- redistribution %>%
  mutate(
    Label = sprintf("+%.2f%%", Gained_pct),
    Label_x = ifelse(
      Island == "Boigu",
      0.75,
      Gained_pct + 0.20
    )
  )

loss_labels <- redistribution %>%
  mutate(
    Label = sprintf("-%.2f%%", Lost_pct),
    Label_x = ifelse(
      Island == "Boigu",
      -0.35,
      -Lost_pct - 0.20
    )
  )

net_labels <- redistribution %>%
  mutate(
    Label = sprintf("Net %+.2f%%", Net_pct),
    Label_y = as.numeric(Island) + ifelse(
      Island == "Boigu",
      0.35,
      0.30
    )
  )

# Create redistribution figure

figure3 <- ggplot(
  redistribution_long,
  aes(
    x = Change_pct,
    y = Island,
    fill = Category
  )
) +
  geom_vline(
    xintercept = 0,
    colour = muted,
    linewidth = 0.5
  ) +
  geom_col(
    width = 0.42,
    colour = ocean,
    linewidth = 0.3
  ) +
  geom_text(
    data = gain_labels,
    aes(
      x = Label_x,
      y = Island,
      label = Label
    ),
    inherit.aes = FALSE,
    hjust = 0,
    colour = gain_colour,
    fontface = "bold",
    size = 3.7,
    show.legend = FALSE
  ) +
  geom_text(
    data = loss_labels,
    aes(
      x = Label_x,
      y = Island,
      label = Label
    ),
    inherit.aes = FALSE,
    hjust = 1,
    colour = loss_colour,
    fontface = "bold",
    size = 3.7,
    show.legend = FALSE
  ) +
  geom_point(
    data = redistribution,
    aes(
      x = Net_pct,
      y = Island
    ),
    inherit.aes = FALSE,
    shape = 23,
    size = 4,
    fill = net_colour,
    colour = ivory,
    stroke = 1,
    show.legend = FALSE
  ) +
  geom_text(
    data = net_labels,
    aes(
      x = Net_pct,
      y = Label_y,
      label = Label
    ),
    inherit.aes = FALSE,
    colour = ivory,
    fontface = "bold",
    size = 3.5,
    vjust = 0,
    show.legend = FALSE
  ) +
  scale_fill_manual(
    values = c(
      "Land gained" = gain_colour,
      "Land lost" = loss_colour
    )
  ) +
  scale_x_continuous(
    breaks = seq(-4, 10, 2),
    labels = function(x) paste0(x, "%"),
    expand = expansion(mult = c(0.08, 0.08))
  ) +
  coord_cartesian(
    xlim = c(-4.5, 11),
    clip = "off"
  ) +
  labs(
    title = "Land gained, land lost",
    subtitle = "Endpoint redistribution across three Torres Strait islands",
    x = "Percentage of baseline island area",
    y = NULL,
    fill = NULL,
    caption = paste0(
      "Masig and Iama: 1988–2025 | Boigu: 2013–2025\n",
      "Diamonds indicate net endpoint area change.\n",
      "Values describe mapped footprint redistribution; positional uncertainty is not quantified."
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

print(figure3)