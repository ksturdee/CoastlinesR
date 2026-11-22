# Coastal connectivity descriptive statistics
# Kendra Sturdee
#
# Summarises exploratory elevation-screening results
# across Masig, Iama and Boigu.
# Percentages refer to valid LiDAR-covered land.

library(dplyr)
library(readr)
library(tidyr)
library(here)

# Load processed data

connectivity <- read_csv(
  here("data", "processed", "ThreeIsland_CoastalConnectivity_Comparison.csv"),
  show_col_types = FALSE
)

# Validate data

required <- c(
  "Island",
  "Threshold_m",
  "CoastalContact_pct",
  "ConnectivityUnconfirmed_pct",
  "TotalLowLying_pct"
)

stopifnot(
  all(required %in% names(connectivity)),
  nrow(connectivity) == 6,
  all(is.finite(as.matrix(connectivity[, -1]))),
  all(connectivity$Threshold_m %in% c(1, 2)),
  all(connectivity$TotalLowLying_pct >= 0),
  all(connectivity$TotalLowLying_pct <= 100),
  all(
    abs(
      connectivity$CoastalContact_pct +
        connectivity$ConnectivityUnconfirmed_pct -
        connectivity$TotalLowLying_pct
    ) < 0.03
  )
)

stopifnot(
  all(table(connectivity$Island, connectivity$Threshold_m) == 1)
)

# Summarise each elevation threshold

threshold_summary <- connectivity %>%
  arrange(Island, Threshold_m) %>%
  select(
    Island,
    Threshold_m,
    CoastalContact_pct,
    ConnectivityUnconfirmed_pct,
    TotalLowLying_pct
  )

print(threshold_summary, n = Inf, width = Inf)

# Compare elevation thresholds within islands

island_comparison <- connectivity %>%
  select(
    Island,
    Threshold_m,
    CoastalContact_pct,
    TotalLowLying_pct
  ) %>%
  pivot_wider(
    names_from = Threshold_m,
    values_from = c(
      CoastalContact_pct,
      TotalLowLying_pct
    ),
    names_glue = "{.value}_{Threshold_m}m"
  ) %>%
  mutate(
    Contact_increase_pp =
      CoastalContact_pct_2m - CoastalContact_pct_1m,
    LowLying_increase_pp =
      TotalLowLying_pct_2m - TotalLowLying_pct_1m,
    LowLying_ratio =
      TotalLowLying_pct_2m / TotalLowLying_pct_1m
  ) %>%
  arrange(desc(LowLying_increase_pp))

print(island_comparison, n = Inf, width = Inf)

# Identify minimum and maximum values

extremes <- connectivity %>%
  group_by(Threshold_m) %>%
  summarise(
    Lowest_island = Island[which.min(TotalLowLying_pct)],
    Lowest_pct = min(TotalLowLying_pct),
    Highest_island = Island[which.max(TotalLowLying_pct)],
    Highest_pct = max(TotalLowLying_pct),
    Range_pp = Highest_pct - Lowest_pct,
    .groups = "drop"
  )

print(extremes, width = Inf)

# Generate descriptive statements

for (i in seq_len(nrow(island_comparison))) {
  
  x <- island_comparison[i, ]
  
  cat(
    sprintf(
      "\n%s: Low-lying land increased from %.2f%% at +1 m ",
      x$Island,
      x$TotalLowLying_pct_1m
    ),
    sprintf(
      "to %.2f%% at +2 m AHD, a difference of %.2f percentage points.\n",
      x$TotalLowLying_pct_2m,
      x$LowLying_increase_pp
    ),
    sep = ""
  )
}