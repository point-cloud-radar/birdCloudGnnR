test_that("values get correctly added", {
  pvol <- bioRad::read_pvolfile(system.file("extdata",
    "volume.h5",
    package = "bioRad"
  ))
  df <- pvol_to_dataframe(pvol)
  pvol2 <- bioRad::calculate_param(pvol, ZDR2 = ZDR * 2)
  pvol_via_df <- df |>
    dplyr::mutate(ZDR2 = ZDR * 2) |>
    dataframe_into_pvol(pvol = pvol, to_add = "ZDR2")
  expect_equal(pvol2, pvol_via_df)
})
