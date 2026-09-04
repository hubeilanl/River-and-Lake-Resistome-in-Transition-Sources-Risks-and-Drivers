rm(list = ls())
# R 4.3.1. OBSERVED_DATA contains the ID and response; GLOBAL_PREDICTORS contains the ID and numeric predictors.
suppressPackageStartupMessages({
  library(randomForest)
  library(caret)
  library(dplyr)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 5) {
  stop(
    "Usage: Rscript 03_random_forest_model.R OBSERVED_DATA GLOBAL_PREDICTORS ",
    "OUTPUT_DIR ID_COLUMN RESPONSE_COLUMN [SEED]"
  )
}

observed_file <- args[1]
global_file <- args[2]
output_dir <- args[3]
id_column <- args[4]
response_column <- args[5]
seed <- if (length(args) >= 6) as.integer(args[6]) else 123L
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

observed <- read.delim(observed_file, sep = "\t", stringsAsFactors = FALSE, check.names = FALSE, quote = "")
global <- read.delim(global_file, sep = "\t", stringsAsFactors = FALSE, check.names = FALSE, quote = "")
required_observed <- c(id_column, response_column)
if (length(setdiff(required_observed, names(observed))) > 0) stop("Observed data lack the ID or response column.")
if (!id_column %in% names(global)) stop("Global predictor data lack the ID column: ", id_column)
if (anyDuplicated(global[[id_column]])) {
  stop("GLOBAL_PREDICTORS contains duplicated IDs. Use a unique country or country-year identifier.")
}

predictor_names <- setdiff(names(global), c(id_column, response_column))
if (length(predictor_names) == 0) stop("No predictors were found in the global predictor table.")
train_data <- merge(
  observed[required_observed],
  global[c(id_column, predictor_names)],
  by = id_column
)
if (nrow(train_data) < 6) stop("At least six training observations are required for nested cross-validation.")

x <- train_data[predictor_names]
y <- train_data[[response_column]]
x_global <- global[predictor_names]
if (!is.numeric(y)) stop("The response column must be numeric.")
if (anyNA(x) || anyNA(x_global)) stop("Predictor matrices contain missing values. Run 02_impute_and_scale.R first.")
if (!all(vapply(x, is.numeric, logical(1)))) stop("All random-forest predictors must be numeric.")

mse_summary <- function(data, lev = NULL, model = NULL) {
  mse <- mean((data$obs - data$pred)^2)
  r2 <- 1 - sum((data$obs - data$pred)^2) / sum((data$obs - mean(data$obs))^2)
  c(MSE = mse, R2 = r2)
}

rfe_control <- rfeControl(
  functions = rfFuncs,
  method = "LOOCV",
  verbose = FALSE,
  returnResamp = "final",
  saveDetails = TRUE
)
rfe_control$functions$summary <- mse_summary

mtry_grid <- seq_len(min(10, ncol(x)))
ntree_grid <- seq(100, 1000, by = 100)
nodesize_grid <- 1:10

grid_cv <- function(x_data, y_data, features, grid, nfolds = 5, local_seed = 42L) {
  set.seed(local_seed)
  folds <- createFolds(y_data, k = min(nfolds, length(y_data)), list = FALSE)
  mse <- numeric(nrow(grid))
  for (g in seq_len(nrow(grid))) {
    prediction <- numeric(length(y_data))
    for (fold in sort(unique(folds))) {
      training <- folds != fold
      validation <- folds == fold
      fit <- randomForest(
        x = x_data[training, features, drop = FALSE],
        y = y_data[training],
        mtry = grid$mtry[g],
        ntree = grid$ntree[g],
        nodesize = grid$nodesize[g]
      )
      prediction[validation] <- predict(fit, newdata = x_data[validation, features, drop = FALSE])
    }
    mse[g] <- mean((y_data - prediction)^2)
  }
  cbind(grid, MSE = mse)
}

n <- nrow(x)
outer_prediction <- rep(NA_real_, n)
outer_features <- vector("list", n)
outer_parameters <- vector("list", n)

for (i in seq_len(n)) {
  training <- setdiff(seq_len(n), i)
  set.seed(seed + 1000L + i)
  rfe_fit <- rfe(
    x = x[training, , drop = FALSE],
    y = y[training],
    sizes = seq_len(ncol(x)),
    metric = "MSE",
    maximize = FALSE,
    rfeControl = rfe_control,
    ntree = 500
  )
  selected <- predictors(rfe_fit)
  outer_features[[i]] <- selected
  tuning_grid <- expand.grid(
    mtry = mtry_grid[mtry_grid <= length(selected)],
    ntree = ntree_grid,
    nodesize = nodesize_grid
  )
  grid_result <- grid_cv(
    x[training, , drop = FALSE], y[training], selected, tuning_grid,
    local_seed = seed + 3000L + i
  )
  best <- grid_result[which.min(grid_result$MSE), , drop = FALSE]
  outer_parameters[[i]] <- best
  set.seed(seed + 2000L + i)
  outer_fit <- randomForest(
    x = x[training, selected, drop = FALSE],
    y = y[training],
    mtry = best$mtry,
    ntree = best$ntree,
    nodesize = best$nodesize,
    importance = TRUE
  )
  outer_prediction[i] <- predict(outer_fit, newdata = x[i, selected, drop = FALSE])
}

cv_mse <- mean((y - outer_prediction)^2)
cv_rmse <- sqrt(cv_mse)
cv_mae <- mean(abs(y - outer_prediction))
cv_r2 <- 1 - sum((y - outer_prediction)^2) / sum((y - mean(y))^2)
write.csv(
  data.frame(
    ID = train_data[[id_column]], Observed = y,
    LOOCV_Predicted = outer_prediction, Residual = y - outer_prediction
  ),
  file.path(output_dir, "nested_loocv_predictions.csv"), row.names = FALSE
)
set.seed(seed)
final_rfe <- rfe(
  x = x, y = y, sizes = seq_len(ncol(x)), metric = "MSE",
  maximize = FALSE, rfeControl = rfe_control, ntree = 500,
  importance = TRUE
)
final_features <- predictors(final_rfe)
cv_adjusted_r2 <- if (n > length(final_features) + 1) {
  1 - (1 - cv_r2) * (n - 1) / (n - length(final_features) - 1)
} else {
  NA_real_
}
write.csv(
  data.frame(
    Response = response_column,
    MSE = cv_mse,
    RMSE = cv_rmse,
    MAE = cv_mae,
    R2 = cv_r2,
    Adjusted_R2 = cv_adjusted_r2
  ),
  file.path(output_dir, "nested_loocv_performance.csv"), row.names = FALSE
)
final_grid <- expand.grid(
  mtry = mtry_grid[mtry_grid <= length(final_features)],
  ntree = ntree_grid,
  nodesize = nodesize_grid
)
final_grid_result <- grid_cv(x, y, final_features, final_grid, local_seed = seed + 3000L)
best_parameters <- final_grid_result[which.min(final_grid_result$MSE), , drop = FALSE]

set.seed(seed)
final_model <- randomForest(
  x = x[final_features], y = y,
  mtry = best_parameters$mtry,
  ntree = best_parameters$ntree,
  nodesize = best_parameters$nodesize,
  importance = TRUE
)

importance_result <- importance(final_model, type = 1)
importance_table <- data.frame(
  Feature = rownames(importance_result),
  IncMSE = importance_result[, 1],
  row.names = NULL
) %>% arrange(desc(IncMSE))

global_prediction <- predict(final_model, newdata = x_global[final_features])
global_prediction[global_prediction < 0] <- 0
global$RF_Predicted_Response <- global_prediction

write.csv(final_rfe$results, file.path(output_dir, "final_rfe_results.csv"), row.names = FALSE)
write.csv(data.frame(Feature = final_features), file.path(output_dir, "final_selected_features.csv"), row.names = FALSE)
write.csv(final_grid_result, file.path(output_dir, "final_grid_search.csv"), row.names = FALSE)
write.csv(best_parameters, file.path(output_dir, "final_optimal_parameters.csv"), row.names = FALSE)
write.csv(importance_table, file.path(output_dir, "final_feature_importance.csv"), row.names = FALSE)
write.csv(global, file.path(output_dir, "global_predictions.csv"), row.names = FALSE)
write.csv(
  data.frame(
    ID_column = id_column,
    Response_column = response_column,
    Seed = seed,
    Training_observations = n,
    Selected_predictors = length(final_features)
  ),
  file.path(output_dir, "model_metadata.csv"), row.names = FALSE
)
write.csv(bind_rows(outer_parameters) %>% mutate(Fold = seq_len(n)), file.path(output_dir, "per_fold_parameters.csv"), row.names = FALSE)
write.csv(bind_rows(lapply(seq_along(outer_features), function(i) data.frame(Fold = i, Feature = outer_features[[i]]))), file.path(output_dir, "per_fold_features.csv"), row.names = FALSE)
saveRDS(final_model, file.path(output_dir, "final_random_forest_model.rds"))
saveRDS(final_rfe, file.path(output_dir, "final_rfe_model.rds"))

cat("Nested LOOCV MSE:", cv_mse, "\n")
cat("Nested LOOCV RMSE:", cv_rmse, "\n")
cat("Nested LOOCV MAE:", cv_mae, "\n")
cat("Nested LOOCV R2:", cv_r2, "\n")
cat("Nested LOOCV adjusted R2:", cv_adjusted_r2, "\n")
