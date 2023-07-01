#' @importFrom rlang .data
NULL
utils::globalVariables(".data")

#' Add parameters to an existing pvol from a `data.frame`
#'
#' @param x A data frame or tibble
#' @param pvol a polar volume as a [pvol][bioRad::is.pvol] object
#' @param scan_id_column The name of the column identifying the scan id
#' @param range_column The name of the column containing the ranges
#' to the cell centers from the radar
#' @param azimuth_column The name of the column containing the
#'  azimuth of the cell centers
#' @param to_add The name of the one or more columns to add
#'
#' @return A polar volume with the columns `to_add` from `x` have been added to.
#' @export
#'
#' @examples
dataframe_into_pvol <- function(x, pvol,
                                scan_id_column = "scan_id",
                                range_column = "range",
                                azimuth_column = "azimuth",
                                to_add = "CLASS") {
  assertthat::assert_that(bioRad::is.pvol(pvol))
  assertthat::assert_that(rlang::is_scalar_character(scan_id_column))
  assertthat::assert_that(rlang::is_scalar_character(range_column))
  assertthat::assert_that(rlang::is_scalar_character(azimuth_column))
  assertthat::assert_that(is.data.frame(x))
  for (i in seq_along(pvol$scans)) {
    s <- pvol$scans[[i]]
    assertthat::assert_that(rlang::is_scalar_double(s$geo$rscale))
    assertthat::assert_that(rlang::is_scalar_double(s$geo$rstart))
    assertthat::assert_that(rlang::is_scalar_double(s$geo$ascale))
    if (!is.null(s$geo$astart)) {
      assertthat::assert_that(rlang::is_scalar_double(s$geo$astart))
      astart <- s$geo$astart
    } else {
      astart <- 0
    }
    d <- dim(s)[-1]
    df_sub <- x |>
      dplyr::filter(!!rlang::sym(scan_id_column) == i) |>
      dplyr::mutate(
        range_std = (!!rlang::sym(range_column) - c(s$geo$rstart)) /
          s$geo$rscale + 0.5,
        azimuth_std = (!!rlang::sym(azimuth_column) - c(astart)) /
          s$geo$ascale + 0.5
      ) %>%
      dplyr::mutate(
        index = range_std + d[1] * (azimuth_std - 1)
      )
    assertthat::assert_that(rlang::is_integerish(df_sub$azimuth_std))
    assertthat::assert_that(rlang::is_integerish(df_sub$range_std))
    assertthat::assert_that(all(s$params$DBZH[df_sub$index] == df_sub$DBZH,
      na.rm = TRUE
    ))
    p <- s$params[[1]]
    for (j in to_add) {
      p[] <- NA
      attr(p, "param") <- j
      attr(p, "conversion") <- NULL
      p[df_sub$index] <- df_sub[, j, drop = TRUE]
      pvol$scans[[i]]$params[[j]] <- p
    }
  }
  return(pvol)
}
