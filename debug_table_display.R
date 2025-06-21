# Debug script to test table display logic specifically
# This mimics the exact logic from results_module.R lines 521-534

# Load required files
source("R/constants.R")
source("R/data_models.R")
source("R/pk_calculation_engine_v2.R")
source("R/dosing_logic_v2.R")

# Create test patient and simulation (same as before)
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

# Perform simulation
engine <- PKCalculationEngineV2$new()
results <- engine$perform_simulation(test_patient, dose_events, simulation_duration_min = 120)

# Exact reproduction of results_module.R lines 521-534
cat("=== REPRODUCING TABLE LOGIC ===\n")

# Calculate current infusion rates for each time point
current_infusion_rates <- rep(0.0, length(results$time_points))
if (!is.null(results$pk_parameters) && !is.null(results$pk_parameters$infusion_plan)) {
  infusion_plan <- results$pk_parameters$infusion_plan
  
  cat("Infusion plan available:\n")
  print(infusion_plan)
  cat("\n")
  
  for (i in 1:length(results$time_points)) {
    tp_time <- results$time_points[[i]]$time_in_minutes
    
    # Find the most recent infusion rate change at or before this time
    relevant_rows <- infusion_plan[infusion_plan$time <= tp_time, ]
    if (nrow(relevant_rows) > 0) {
      current_infusion_rates[i] <- tail(relevant_rows$rate, 1)
    }
    
    # Debug print for first few time points
    if (i <= 10 || tp_time %in% c(5, 30, 60, 90)) {
      cat(sprintf("Time %g: relevant_rows=%d, rate=%g\n", 
                  tp_time, nrow(relevant_rows), current_infusion_rates[i]))
    }
  }
} else {
  cat("infusion_plan is NULL or pk_parameters is NULL\n")
  cat("results$pk_parameters exists:", !is.null(results$pk_parameters), "\n")
  if (!is.null(results$pk_parameters)) {
    cat("infusion_plan exists:", !is.null(results$pk_parameters$infusion_plan), "\n")
  }
}

cat("\n=== SUMMARY OF CALCULATED RATES ===\n")
cat("Total time points:", length(results$time_points), "\n")
cat("Non-zero infusion rates:", sum(current_infusion_rates > 0), "\n")
cat("Unique rates:", paste(unique(current_infusion_rates), collapse = ", "), "\n")

# Show sample of the final table data structure
cat("\n=== SAMPLE TABLE DATA ===\n")
sample_indices <- c(1, 6, 31, 61, 91)  # Times: 0, 5, 30, 60, 90 minutes

for (i in sample_indices) {
  if (i <= length(results$time_points)) {
    tp <- results$time_points[[i]]
    bolus_val <- if (is.null(tp$dose_event)) 0.0 else tp$dose_event$bolus_mg
    continuous_val <- current_infusion_rates[i]
    plasma_val <- tp$plasma_concentration
    effect_val <- tp$effect_site_concentration
    
    cat(sprintf("Row %d (Time %g): Bolus=%g, Continuous=%g, Plasma=%g, Effect=%g\n",
                i, tp$time_in_minutes, bolus_val, continuous_val, plasma_val, effect_val))
  }
}