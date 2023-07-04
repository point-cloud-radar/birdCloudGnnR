#' @export
plot_scans_ppis <- function(pvol, elangles,
                            params = c(
                              "DBZH", "VRADH", "DR",
                              "LABEL", "BIOLOGY"
                            ), ...) {
  ppis <- lapply(elangles, function(x) {
    if (which(x == elangles) == 1) {
      plot_scan_params(pvol,
        elangle = x,
        params = params, legend = TRUE, ...
      )
    } else {
      plot_scan_params(pvol,
        elangle = x,
        params = params, ...
      )
    }
  })
  unlist(ppis, recursive = FALSE)
}
#' @export
plot_scan_params <- function(pvol, elangle, params,
                             legend = FALSE,
                             axes = FALSE, range_max = 100000) {
  scan <- get_scan(pvol, elangle, all = TRUE)[[1]]
  # in case of 0.3 degree scan picks high unamb velocity dual-prf
  scan <- calculate_param(scan,
    ZDR = 10**((DBZH - DBZV) / 10),
    DR = suppressWarnings(10 * log10((ZDR + 1 - 2 * ZDR^0.5 * RHOHV) /
      (ZDR + 1 + 2 * ZDR^0.5 * RHOHV))),
    # LABEL = (RHOHV < 0.95) * 1,  # nolint
    LABEL = (DR > -12) * 1,
    BIOLOGY = LABEL
  )
  ppi <- project_as_ppi(scan, grid_size = 500, range_max = range_max)

  ppis <- lapply(params, FUN = function(param) {
    if (param %in% c("LABEL", "BIOLOGY", "CLASS", "BIOLOGY_GNN")) {
      suppressMessages(ppi <- plot(ppi, param = param, zlim = c(0, 1)) +
        ggplot2::scale_fill_viridis_b(
          na.value = NA, name = param, breaks = c(0, 0.5, 1),
          option = "plasma", labels = c("Non-Bio", "", "Bio")
        ))
    } else if (param == "DR") {
      ppi <- plot(ppi, param = param, zlim = c(-15, 5)) +
        ggplot2::scale_fill_viridis_c(
          na.value = NA,
          name = param
        )
    } else if (param == "RHOHV") {
      ppi <- plot(ppi, param = param, zlim = c(0, 1)) +
        ggplot2::scale_fill_viridis_c(
          na.value = NA,
          name = param
        )
    } else {
      ppi <- plot(ppi, param = param)
    }
    base_size <- 11
    if (legend) {
      ppi <- ppi + ggplot2::geom_point(x = 0, y = 0) +
        ggdark::dark_mode(ggplot2::theme_bw(
          base_size = base_size, base_family = "",
          base_line_size = base_size / 22,
          base_rect_size = base_size / 22
        ), verbose = FALSE) +
        ggplot2::theme(
          legend.position = "top",
          legend.direction = "horizontal"
        ) +
        ggplot2::guides(fill = ggplot2::guide_colorbar(
          title.position = "top", title.hjust = 0.5,
          barheight = 0.7
        ))
    } else {
      ppi <- ppi + ggplot2::geom_point(x = 0, y = 0) +
        ggdark::dark_mode(ggplot2::theme_bw(
          base_size = base_size, base_family = "",
          base_line_size = base_size / 22,
          base_rect_size = base_size / 22
        ), verbose = FALSE) +
        ggplot2::theme(legend.position = "none")
    }

    if (!axes) {
      ppi <- ppi +
        ggplot2::theme(
          axis.title.x = ggplot2::element_blank(),
          axis.title.y = ggplot2::element_blank(),
          axis.text.x = ggplot2::element_blank(),
          axis.text.y = ggplot2::element_blank()
        )
    }

    suppressMessages(ppi <- ppi +
      ggplot2::coord_equal(expand = FALSE))
    ppi
  })
  ppis
}
