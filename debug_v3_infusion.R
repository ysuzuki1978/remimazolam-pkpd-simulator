# Debug script to test V3 engine infusion rate display
# Load required files
source("R/constants.R")
source("R/data_models.R")
source("R/pk_calculation_engine_v2.R")
source("R/pk_calculation_engine_v3.R")
source("R/dosing_logic_v2.R")

# Create test patient
test_patient <- Patient$new(
  id = "TEST001",
  age = 50,
  weight = 70,
  height = 170,
  sex = 0,  # male
  asa_ps = 0  # ASA I-II
)

# Create test dose events
dose_events <- list(
  DoseEvent$new(time_in_minutes = 0, bolus_mg = 5, continuous_mg_kg_hr = 0),
  DoseEvent$new(time_in_minutes = 5, bolus_mg = 0, continuous_mg_kg_hr = 1.0),
  DoseEvent$new(time_in_minutes = 30, bolus_mg = 0, continuous_mg_kg_hr = 2.0),
  DoseEvent$new(time_in_minutes = 60, bolus_mg = 0, continuous_mg_kg_hr = 0)
)

# Test V3 engine
cat("=== TESTING V3 ENGINE ===\n")
engine_v3 <- PKCalculationEngineV3$new()
results_v3 <- engine_v3$perform_simulation(test_patient, dose_events, 
                                           simulation_duration_min = 120, method = "all")

# Check if infusion_plan exists in V3 results
cat("V3 results class:", class(results_v3), "\n")
cat("pk_parameters exists:", !is.null(results_v3$pk_parameters), "\n")
if (!is.null(results_v3$pk_parameters)) {
  cat("infusion_plan exists:", !is.null(results_v3$pk_parameters$infusion_plan), "\n")
  if (!is.null(results_v3$pk_parameters$infusion_plan)) {
    cat("infusion_plan structure:\n")
    print(results_v3$pk_parameters$infusion_plan)
  }
}

# Test the table calculation logic with V3 results
cat("\n=== TESTING TABLE LOGIC WITH V3 RESULTS ===\n")

# Exact reproduction of results_module.R lines 521-534 with V3 results
current_infusion_rates <- rep(0.0, length(results_v3$time_points))
if (!is.null(results_v3$pk_parameters) && !is.null(results_v3$pk_parameters$infusion_plan)) {
  infusion_plan <- results_v3$pk_parameters$infusion_plan
  
  for (i in 1:length(results_v3$time_points)) {
    tp_time <- results_v3$time_points[[i]]$time_in_minutes
    
    # Find the most recent infusion rate change at or before this time
    relevant_rows <- infusion_plan[infusion_plan$time <= tp_time, ]
    if (nrow(relevant_rows) > 0) {
      current_infusion_rates[i] <- tail(relevant_rows$rate, 1)
    }
  }
} else {
  cat("ERROR: infusion_plan is missing in V3 results!\n")
}

cat("Total time points:", length(results_v3$time_points), "\n")
cat("Non-zero infusion rates:", sum(current_infusion_rates > 0), "\n")
cat("Unique rates:", paste(unique(current_infusion_rates), collapse = ", "), "\n")

# Show sample of rates at key time points
sample_times <- c(0, 5, 30, 60, 90)
cat("\nSample rates at key times:\n")
for (time_val in sample_times) {
  # Find the index closest to this time
  time_index <- which.min(abs(sapply(results_v3$time_points, function(tp) tp$time_in_minutes) - time_val))
  if (length(time_index) > 0) {
    actual_time <- results_v3$time_points[[time_index]]$time_in_minutes
    rate <- current_infusion_rates[time_index]
    cat(sprintf("Time %g (index %d): rate = %g mg/kg/hr\n", actual_time, time_index, rate))
  }
}