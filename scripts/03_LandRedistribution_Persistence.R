# Endpoint land redistribution in the Torres Strait
# Kendra Sturdee
#
# Compares land gained, land lost and net area change
# between the first and last accepted island footprints.
# Values are from the completed spatial analysis.

library(ggplot2)
library(dplyr)
library(tidyr)

# Load previously calculated spatial statistics

redistribution <- tibble(
  Island = c("Masig", "Iama", "Boigu"),
  Gained_pct = c(2.56, 9.39, 0.44),
  Lost_pct = c(3.43, 1.27, 0.05),
  Net_pct = c(-0.87, 8.12, 0.39)
)

# Verify analytical values

stopifnot(
  all(
    abs(
      redistribution$Gained_pct -
        redistribution$Lost_pct -
        redistribution$Net_pct
    ) < 0.02
  )
)

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
    caption = paste(
      "Masig and Iama: 1988–2025 | Boigu: 2013–2025",
      "\nDiamonds indicate net endpoint area change.",
      "Values are descriptive and exclude positional uncertainty."
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


ggsave(
  filename = here::here("figures", "03_LandRedistribution.png"),
  plot = figure3,
  width = 10,
  height = 7,
  dpi = 300,
  bg = "#102D35"
)
