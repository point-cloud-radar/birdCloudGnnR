globalVariables(c("azim", "DBZH", "ZDR", "DBZV", "if_any", "any_of"))
#' Convert a pvol to a data frame
#'
#' @param pvol
#' @param to_retain
#'
#' @return
#' @export
#'
#' @examples
pvol_to_dataframe <- function(pvol, to_retain = any_of(c(
                                "scan_id",
                                "elevation", "azimuth", "range",
                                "x", "y", "z", "DBZH", "DBZV",
                                "TH", "TV", "VRADH", "VRADV", "WRADH",
                                "WRADV", "PHIDP", "RHOHV",
                                "KDP", "ZDR", "CLASS", "BIOLOGY"
                              ))) {
  assertthat::assert_that(bioRad::is.pvol(pvol))

  e <- bioRad::get_elevation_angles(pvol)
  pvol$scans <- pvol$scans[e != 90]
  r <- dplyr::bind_rows(mapply(dplyr::bind_cols,
    scan_id = seq_along(pvol$scans),
    elevation = bioRad::get_elevation_angles(pvol),
    lapply(
      pvol$scans,
      function(x) {
        bioRad::scan_to_spatial(x) |>
          as.data.frame() |>
          dplyr::as_tibble()
      }
    ), SIMPLIFY = FALSE
  )) %>%
    dplyr::rename(azimuth = azim, z = height)
  if (all(c(FALSE, TRUE, TRUE) == c("ZDR", "DBZH", "DBZV") %in% colnames(r))) {
    r <- r %>% dplyr::mutate(ZDR = DBZH - DBZV)
  }
  r <- r |>
    dplyr::select({{ to_retain }}) |>
    dplyr::filter(if_any(-any_of(c(
      "x", "y", "z", "range", "azimuth", "elevation",
      "scan_id", "CLASS", "BIOLOGY", "distance"
    )), ~ !is.na(.x)))
  return(r)
}
