
<!-- README.md is generated from README.Rmd. Please edit that file -->

# birdCloudGnnR

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/birdCloudGnnR)](https://CRAN.R-project.org/package=birdCloudGnnR)
<!-- badges: end -->

The goal of birdCloudGnnR is to facilitate using the
[bird-cloud-gnn](https://github.com/point-cloud-radar/bird-cloud-gnn)
model from R.

## Installation

You can install the development version of birdCloudGnnR from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("point-cloud-radar/birdCloudGnnR")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
devtools::load_all()
#> ℹ Loading birdCloudGnnR
sp::set_evolution_status(2L)
#> The legacy packages maptools, rgdal, and rgeos, underpinning the sp package,
#> which was just loaded, will retire in October 2023.
#> Please refer to R-spatial evolution reports for details, especially
#> https://r-spatial.org/r/2023/05/15/evolution4.html.
#> It may be desirable to make the sf package available;
#> package maintainers should consider adding sf to Suggests:.
#> The sp package is now running under evolution status 2
#>      (status 2 uses the sf package in place of rgdal)
#> [1] 2
require(reticulate)
#> Loading required package: reticulate
require(bioRad)
#> Loading required package: bioRad
#> Welcome to bioRad version 0.7.0.9603
#> Assigning sp_evolution_status to 2. See sp::get_evolution_status()
#> This is required until the 'sp' package deprecates 'rgdal'
require(ggplot2)
#> Loading required package: ggplot2
require(dplyr)
#> Loading required package: dplyr
#> 
#> Attaching package: 'dplyr'
#> 
#> The following object is masked from 'package:testthat':
#> 
#>     matches
#> 
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> 
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
pvol_dir <- "~/ownCloudUva/labels/old"
pvol_files <- list.files(pvol_dir, "*.h5$", full.names = TRUE)
file <- pvol_files[1]
pvol <- read_pvolfile(file, param = "all") |>
  select(-any_of(c("CPAH", "SQIH", "CCORH", "SQIV", "CCORV", "UPHIDP")))
r <- pvol_to_dataframe(pvol)

features <- c(
  "range",
  "azimuth",
  "elevation",
  "TH",
  "TV",
  "DBZH",
  "DBZV",
  "RHOHV",
  "VRADH",
  "VRADV",
  "centered_x",
  "centered_y"
)
rds <- import("bird_cloud_gnn.radar_dataset")
rr <- r %>% filter(range < 24000, range > 17000, z < 10000, azimuth < 180)
rm(r)
rr$BIOLOGY_GNN <- 0 # RadarDataSet selects for existing labels
system.time(l <- rds$RadarDataset(rr %>% select(-scan_id),
  features = features, target = "BIOLOGY_GNN", max_poi_per_label = 500000L,
  num_neighbours = 50, max_edge_distance = 650
))
#>    user  system elapsed 
#>   8.180   1.406   9.944
assertthat::assert_that(l$`__len__`() == nrow(rr))
#> [1] TRUE
rr$BIOLOGY_GNN <- infer(l, "/home/bart/testModel.pth",
  n_features = length(features)
)
table(rr$BIOLOGY_GNN)
#> 
#>     0     1 
#> 15109 49740
mean(rr$BIOLOGY_GNN)
#> [1] 0.7670126
pvol2 <- dataframe_into_pvol(rr, pvol, to_add = "BIOLOGY_GNN")
e <- unique(get_elevation_angles(pvol2))[1:3]
ppis <- plot_scans_ppis(pvol2, e,
  params = c("DBZH", "VRADH", "BIOLOGY_GNN"),
  range_max = 30000
)

patchwork::wrap_plots(ppis, nrow = length(e)) &
  ggplot2::theme(
    plot.background =
      ggplot2::element_rect(
        fill = "black",
        color = "black"
      )
  )
#> Warning: Removed 12752 rows containing missing values (`geom_raster()`).
#> Warning: Removed 12796 rows containing missing values (`geom_raster()`).
#> Warning: Removed 12886 rows containing missing values (`geom_raster()`).
```

<img src="man/figures/README-example-1.png" width="100%" />
