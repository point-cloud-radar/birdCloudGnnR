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
infer <- function(x, model, n_features = NA) {
  if (rlang::is_scalar_character(model)) {
    assertthat::assert_that(file.exists(model))
    gcn <- import("bird_cloud_gnn.gnn_model")
    model_tmp <- gcn$GCN(n_features,
      h_feats = 32L,
      num_classes = 2L
    )
    torch <- import("torch")
    model_tmp$load_state_dict(torch$load(model))
    model <- model_tmp
  }
  return(c(model$infer(dataset = x, batch_size = 1024L)))
}
