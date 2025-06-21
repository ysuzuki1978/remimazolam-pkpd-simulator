# Debug script to test infusion rate display issue
# Load required files
source("R/constants.R")
source("R/data_models.R")
source("R/pk_calculation_engine_v2.R")
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

# Create test dose events - bolus followed by continuous infusion
dose_events <- list(
  # Bolus dose at time 0
  DoseEvent$new(
    time_in_minutes = 0,
    bolus_mg = 5,
    continuous_mg_kg_hr = 0
  ),
  # Start continuous infusion at 5 minutes
  DoseEvent$new(
    time_in_minutes = 5,
    bolus_mg = 0,
    continuous_mg_kg_hr = 1.0  # 1 mg/kg/hr
  ),
  # Change infusion rate at 30 minutes
  DoseEvent$new(
    time_in_minutes = 30,
    bolus_mg = 0,
    continuous_mg_kg_hr = 2.0  # 2 mg/kg/hr
  ),
  # Stop infusion at 60 minutes
  DoseEvent$new(
    time_in_minutes = 60,
    bolus_mg = 0,
    continuous_mg_kg_hr = 0
  )
)

# Perform simulation
engine <- PKCalculationEngineV2$new()
results <- engine$perform_simulation(test_patient, dose_events, simulation_duration_min = 120)

# Debug: Print infusion plan structure
cat("=== INFUSION PLAN STRUCTURE ===\n")
print(str(results$pk_parameters$infusion_plan))
cat("\n")

# Debug: Print some time points to see what's happening
cat("=== SAMPLE TIME POINTS ===\n")
for (i in c(1, 6, 31, 61, 91)) {  # Times: 0, 5, 30, 60, 90 minutes
  if (i <= length(results$time_points)) {
    tp <- results$time_points[[i]]
    cat(sprintf("Time %d min: ", tp$time_in_minutes))
    
    # Calculate current infusion rate manually (same logic as in results_module.R)
    current_infusion_rate <- 0.0
    if (!is.null(results$pk_parameters$infusion_plan)) {
      infusion_plan <- results$pk_parameters$infusion_plan
      relevant_rows <- infusion_plan[infusion_plan$time <= tp$time_in_minutes, ]
      if (nrow(relevant_rows) > 0) {
        current_infusion_rate <- tail(relevant_rows$rate, 1)
      }
    }
    
    bolus <- if (is.null(tp$dose_event)) 0.0 else tp$dose_event$bolus_mg
    continuous <- if (is.null(tp$dose_event)) 0.0 else tp$dose_event$continuous_mg_kg_hr
    
    cat(sprintf("Bolus=%s mg, Event Continuous=%s mg/kg/hr, Calculated Rate=%s mg/kg/hr\n",
                bolus, continuous, current_infusion_rate))
  }
}

# Debug: Print entire infusion plan
cat("\n=== COMPLETE INFUSION PLAN ===\n")
if (!is.null(results$pk_parameters$infusion_plan)) {
  print(results$pk_parameters$infusion_plan)
} else {
  cat("infusion_plan is NULL\n")
}