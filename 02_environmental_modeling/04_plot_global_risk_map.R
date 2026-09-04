rm(list = ls())
# R 4.3.1. The prediction table contains a country field and RF_Predicted_Response.
suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(sf)
  library(rnaturalearth)
  library(countrycode)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) {
  stop(
    "Usage: Rscript 04_plot_global_risk_map.R PREDICTIONS_CSV COUNTRY_COLUMN OUTPUT_PREFIX ",
    "[RISK_COLUMN] [TRANSFORM]\n",
    "Use TRANSFORM=log2 for Fig. 5d and Fig. S11d (default); use none for raw values."
  )
}

prediction_file <- args[1]
country_column <- args[2]
output_prefix <- args[3]
risk_column <- if (length(args) >= 4) args[4] else "RF_Predicted_Response"
transform <- if (length(args) >= 5) tolower(args[5]) else "log2"
if (!transform %in% c("log2", "none")) stop("TRANSFORM must be log2 or none.")

prediction <- read.csv(prediction_file, check.names = FALSE, stringsAsFactors = FALSE)
required <- c(country_column, risk_column)
if (length(setdiff(required, names(prediction))) > 0) stop("Prediction table lacks the country or risk column.")

prediction$iso3 <- countrycode(prediction[[country_column]], origin = "country.name", destination = "iso3c", warn = TRUE)
unmatched <- prediction[is.na(prediction$iso3), c(country_column, risk_column), drop = FALSE]
write.csv(unmatched, paste0(output_prefix, "_unmatched_countries.csv"), row.names = FALSE)

country_prediction <- prediction %>%
  filter(!is.na(iso3)) %>%
  group_by(iso3) %>%
  summarise(Predicted_risk = mean(.data[[risk_column]], na.rm = TRUE), .groups = "drop") %>%
  mutate(
    Mapped_risk = if (transform == "log2") {
      ifelse(Predicted_risk > 0, log2(Predicted_risk), NA_real_)
    } else {
      Predicted_risk
    }
  )

if (transform == "log2" && any(country_prediction$Predicted_risk <= 0, na.rm = TRUE)) {
  warning("Non-positive predicted risks cannot be log2-transformed and are mapped as missing.")
}

world <- ne_countries(scale = "medium", returnclass = "sf") %>%
  left_join(country_prediction, by = c("iso_a3" = "iso3"))

map_plot <- ggplot(world) +
  geom_sf(aes(fill = Mapped_risk), colour = "white", linewidth = 0.08) +
  scale_fill_gradientn(
    colours = c("#3C8CC3", "#AAAEC4", "#F4A582"),
    na.value = "grey80",
    name = if (transform == "log2") "Risk score\n(log2)" else "Risk score"
  ) +
  coord_sf(expand = FALSE) +
  labs(x = NULL, y = NULL) +
  theme_void() +
  theme(legend.position = "right")

ggsave(paste0(output_prefix, ".pdf"), map_plot, width = 10, height = 5.4)
ggsave(paste0(output_prefix, ".png"), map_plot, width = 10, height = 5.4, dpi = 300)
write.csv(st_drop_geometry(world), paste0(output_prefix, "_mapped_values.csv"), row.names = FALSE)
