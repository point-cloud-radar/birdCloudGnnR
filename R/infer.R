#' Title
#'
#' @param x
#' @param model Either a model or a math to a stored model
#' @param n_features The number of features if `model` is a path
#'
#' @return A vector with inferred class labels
#' @export
#'
#' @examples
infer <- function(x, model, features = NA) {
  assertthat::assert_that(all(!is.na(features)))
  if (rlang::is_scalar_character(model)) {
    assertthat::assert_that(file.exists(model))
    gcn <- import("bird_cloud_gnn.gnn_model")
    model_tmp <- gcn$GCN(length(features),
      h_feats = 32L,
      num_classes = 2L
    )
    torch <- import("torch")
    model_tmp$load_state_dict(torch$load(model))
    model <- model_tmp
  }
  if (is.data.frame(x)) {
    assertthat::assert_that(all(x$z < 10000))
    il <- split(seq_len(nrow(x)), round(seq_len(nrow(x)) / 5000))
    res <- seq_len(nrow(r))
    rds <- import("bird_cloud_gnn.radar_dataset")

    for (i in cli::cli_progress_along(seq_along(il), "Inferring")) {
      res[il[[i]]] <- model$infer(
        rds$RadarDataset(x %>% select(-scan_id),
          features = features, target = "BIOLOGY_GNN",
          max_poi_per_label = 500000L,
          num_nodes = 50, max_edge_distance = 650,
          points_of_interest = il[[i]] - 1L,
          # minus one for python counting
          skip_cache = TRUE
        )
      )
      gc()
    }
    return(res)
  } else {
    return(c(model$infer(dataset = x, batch_size = 1024L)))
  }
}
