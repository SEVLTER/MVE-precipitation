#' Plot precipitation histories for MVE plots
#'
#' @param data A data frame of processed precipitation data.
#' @param filename File name to create on disk.
#' @param ... Potential arguments passed to `ggplot2::ggsave()`.
#'
#' @returns Path to saved file.
plot_precipitation <- function(data, filename, ...) {
  # Create plot
  p <- 
    ggplot(data, aes(x = Date_Time, y = Precipitation)) +
    geom_line(aes(color = Mean_Var_Trt)) +
    facet_wrap(vars(Plot)) +
    scale_color_manual(values = c("grey70", "turquoise4", "sienna1", "black")) +
    labs(
      title = paste("MVE", toupper(unique(data$Site))),
      x = "Date",
      y = "Hourly precipitation (mm)",
      color = "Treatment"
    ) +
    theme_bw() +
    theme(
      strip.background = element_blank(),
      strip.text = element_text(hjust = 0),
      plot.title = element_text(face = "bold")
    )
  
  # Save plot
  ggsave(filename, p, ...)
}
