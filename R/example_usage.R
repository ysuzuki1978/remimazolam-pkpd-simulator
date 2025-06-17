#' Example Usage of Remimazolam PKPD Calculator
#'
#' This script demonstrates how to use the remimazolam pharmacokinetic
#' calculation engine to perform accurate simulations.
#'
#' @examples
#' # Load required libraries
#' library(remimazolamPKPD)
#' 
#' # Basic usage example
if (!exists("MASUI_MODEL_CONSTANTS")) source("R/constants.R")
if (!exists("Patient")) source("R/data_models.R")
if (!exists("PKCalculationEngine")) source("R/pk_calculation_engine.R")
#' 
#' # Create a test patient
#' patient <- Patient$new(
#'   id = "PATIENT_001",
#'   age = 65L,
#'   weight = 75.0,
#'   height = 175.0,
#'   sex = SexType$MALE,
#'   asa_ps = AsapsType$CLASS1_2
#' )
#' 
#' # Create dose events
#' dose_events <- list(
#'   DoseEvent$new(0L, 12.0, 0.0),    # 12mg bolus at t=0
#'   DoseEvent$new(1L, 0.0, 1.2),     # 1.2 mg/kg/hr infusion starting at t=1
#'   DoseEvent$new(60L, 0.0, 0.0)     # Stop infusion at t=60
#' )
#' 
#' # Run simulation
#' engine <- PKCalculationEngine$new()
#' result <- engine$perform_simulation(patient, dose_events)
#' 
#' # Export results
#' csv_data <- result$to_csv()
#' writeLines(csv_data, "simulation_result.csv")
#'

#' @title run_example_simulation
#' @description Run a complete example simulation
#' @export
run_example_simulation <- function() {
  
  cat("=== Remimazolam PKPD Calculator Example ===\n\n")
  
  # Create example patient
  cat("Creating example patient...\n")
  patient <- Patient$new(
    id = "EXAMPLE_001",
    age = 55L,
    weight = 70.0,
    height = 170.0,
    sex = SexType$FEMALE,
    asa_ps = AsapsType$CLASS1_2
  )
  
  cat("Patient Details:\n")
  cat(sprintf("  ID: %s\n", patient$id))
  cat(sprintf("  Age: %d years\n", patient$age))
  cat(sprintf("  Weight: %.1f kg\n", patient$weight))
  cat(sprintf("  Height: %.1f cm\n", patient$height))
  cat(sprintf("  Sex: %s\n", ifelse(patient$sex == SexType$MALE, "Male", "Female")))
  cat(sprintf("  ASA PS: %s\n", ifelse(patient$asa_ps == AsapsType$CLASS1_2, "I-II", "III-IV")))
  cat(sprintf("  BMI: %.1f kg/m²\n", patient$get_bmi()))
  cat("\n")
  
  # Validate patient data
  validation <- patient$validate()
  if (!validation$is_valid) {
    cat("Patient validation failed:\n")
    for (error in validation$errors) {
      cat(sprintf("  - %s\n", error))
    }
    return(NULL)
  }
  cat("Patient validation: PASSED\n\n")
  
  # Create dose events
  cat("Creating dose events...\n")
  dose_events <- list(
    DoseEvent$new(
      time_in_minutes = 0L,
      bolus_mg = 10.0,
      continuous_mg_kg_hr = 0.0
    ),
    DoseEvent$new(
      time_in_minutes = 2L,
      bolus_mg = 0.0,
      continuous_mg_kg_hr = 1.5
    ),
    DoseEvent$new(
      time_in_minutes = 45L,
      bolus_mg = 5.0,
      continuous_mg_kg_hr = 1.5
    ),
    DoseEvent$new(
      time_in_minutes = 90L,
      bolus_mg = 0.0,
      continuous_mg_kg_hr = 0.0
    )
  )
  
  cat("Dose Events:\n")
  for (i in seq_along(dose_events)) {
    de <- dose_events[[i]]
    cat(sprintf("  %d. t=%d min: Bolus=%.1f mg, Infusion=%.1f mg/kg/hr\n",
                i, de$time_in_minutes, de$bolus_mg, de$continuous_mg_kg_hr))
  }
  cat("\n")
  
  # Validate dose events
  for (i in seq_along(dose_events)) {
    validation <- dose_events[[i]]$validate()
    if (!validation$is_valid) {
      cat(sprintf("Dose event %d validation failed:\n", i))
      for (error in validation$errors) {
        cat(sprintf("  - %s\n", error))
      }
      return(NULL)
    }
  }
  cat("Dose event validation: PASSED\n\n")
  
  # Run simulation
  cat("Running pharmacokinetic simulation...\n")
  start_time <- Sys.time()
  
  engine <- PKCalculationEngine$new()
  result <- engine$perform_simulation(patient, dose_events)
  
  end_time <- Sys.time()
  execution_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
  
  cat(sprintf("Simulation completed in %.3f seconds\n\n", execution_time))
  
  # Display results summary
  cat("=== Simulation Results ===\n")
  cat(sprintf("Number of time points: %d\n", length(result$time_points)))
  cat(sprintf("Simulation duration: %d minutes\n", result$get_simulation_duration_minutes()))
  cat(sprintf("Maximum plasma concentration: %.3f µg/mL\n", result$get_max_plasma_concentration()))
  cat(sprintf("Maximum effect-site concentration: %.3f µg/mL\n", result$get_max_effect_site_concentration()))
  cat(sprintf("Calculated at: %s\n", format(result$calculated_at, "%Y-%m-%d %H:%M:%S")))
  cat("\n")
  
  # Show sample time points
  cat("Sample time points:\n")
  cat("Time(min) | Dose Event | Cp(µg/mL) | Ce(µg/mL)\n")
  cat("----------|------------|-----------|----------\n")
  
  sample_indices <- seq(1, length(result$time_points), by = 10)
  for (i in sample_indices[1:min(10, length(sample_indices))]) {
    tp <- result$time_points[[i]]
    dose_info <- if (is.null(tp$dose_event)) {
      "None"
    } else {
      sprintf("B:%.1f I:%.1f", tp$dose_event$bolus_mg, tp$dose_event$continuous_mg_kg_hr)
    }
    cat(sprintf("%8d | %10s | %9.3f | %8.3f\n",
                tp$time_in_minutes, dose_info, tp$plasma_concentration, tp$effect_site_concentration))
  }
  cat("\n")
  
  # Export to CSV
  output_file <- sprintf("remimazolam_simulation_%s.csv", format(Sys.time(), "%Y%m%d_%H%M%S"))
  csv_data <- result$to_csv()
  writeLines(csv_data, output_file)
  cat(sprintf("Results exported to: %s\n", output_file))
  
  return(result)
}

#' @title compare_dosing_regimens
#' @description Compare different dosing regimens for the same patient
#' @param patient Patient object
#' @export
compare_dosing_regimens <- function(patient = NULL) {
  
  if (is.null(patient)) {
    patient <- Patient$new(
      id = "COMPARISON_PATIENT",
      age = 50L,
      weight = 70.0,
      height = 170.0,
      sex = SexType$MALE,
      asa_ps = AsapsType$CLASS1_2
    )
  }
  
  cat("=== Dosing Regimen Comparison ===\n\n")
  
  # Define different regimens
  regimens <- list(
    "Low Bolus + Moderate Infusion" = list(
      DoseEvent$new(0L, 8.0, 0.0),
      DoseEvent$new(1L, 0.0, 1.0),
      DoseEvent$new(60L, 0.0, 0.0)
    ),
    "High Bolus + Low Infusion" = list(
      DoseEvent$new(0L, 15.0, 0.0),
      DoseEvent$new(1L, 0.0, 0.6),
      DoseEvent$new(60L, 0.0, 0.0)
    ),
    "Moderate Bolus + High Infusion" = list(
      DoseEvent$new(0L, 10.0, 0.0),
      DoseEvent$new(1L, 0.0, 1.5),
      DoseEvent$new(60L, 0.0, 0.0)
    )
  )
  
  engine <- PKCalculationEngine$new()
  results <- list()
  
  for (regimen_name in names(regimens)) {
    cat(sprintf("Simulating: %s\n", regimen_name))
    
    dose_events <- regimens[[regimen_name]]
    result <- engine$perform_simulation(patient, dose_events)
    results[[regimen_name]] <- result
    
    cat(sprintf("  Max Cp: %.3f µg/mL\n", result$get_max_plasma_concentration()))
    cat(sprintf("  Max Ce: %.3f µg/mL\n", result$get_max_effect_site_concentration()))
    cat("\n")
  }
  
  cat("Comparison completed.\n")
  return(results)
}

#' @title validate_against_known_values
#' @description Validate calculations against known pharmacokinetic values
#' @export
validate_against_known_values <- function() {
  
  cat("=== Validation Against Known Values ===\n\n")
  
  # Standard patient from literature
  standard_patient <- Patient$new(
    id = "STANDARD_PATIENT",
    age = 54L,  # Standard age from Masui 2022
    weight = 67.3,  # Standard weight from Masui 2022
    height = 170.0,
    sex = SexType$MALE,
    asa_ps = AsapsType$CLASS1_2
  )
  
  # Simple bolus dose
  bolus_events <- list(
    DoseEvent$new(0L, 10.0, 0.0)
  )
  
  engine <- PKCalculationEngine$new()
  result <- engine$perform_simulation(standard_patient, bolus_events)
  
  # Check initial concentration (should be ~10/V1)
  pk_params <- engine$.__enclos_env__$private$calculate_pk_parameters(standard_patient)
  expected_initial_conc <- 10.0 / pk_params$v1
  actual_initial_conc <- result$time_points[[2]]$plasma_concentration  # t=1 min
  
  cat(sprintf("Expected initial concentration: %.3f µg/mL\n", expected_initial_conc))
  cat(sprintf("Actual initial concentration: %.3f µg/mL\n", actual_initial_conc))
  cat(sprintf("Relative error: %.1f%%\n", abs(actual_initial_conc - expected_initial_conc) / expected_initial_conc * 100))
  cat("\n")
  
  # Check PK parameters are in expected ranges from literature
  cat("PK Parameters:\n")
  cat(sprintf("  V1: %.2f L (expected ~3.6 L)\n", pk_params$v1))
  cat(sprintf("  V2: %.2f L (expected ~11.4 L)\n", pk_params$v2))
  cat(sprintf("  V3: %.2f L (expected ~27.4 L)\n", pk_params$v3))
  cat(sprintf("  CL: %.3f L/min (expected ~1.04 L/min)\n", pk_params$cl))
  cat(sprintf("  Q2: %.3f L/min (expected ~1.11 L/min)\n", pk_params$q2))
  cat(sprintf("  Q3: %.3f L/min (expected ~0.40 L/min)\n", pk_params$q3))
  cat(sprintf("  ke0: %.4f 1/min\n", pk_params$ke0))
  cat("\n")
  
  # Check mass balance over time
  times_to_check <- c(1, 5, 10, 30, 60)
  cat("Mass balance check:\n")
  cat("Time(min) | Total Amount (mg) | Elimination (%)\n")
  cat("----------|-------------------|---------------\n")
  
  initial_amount <- 10.0
  for (time_min in times_to_check) {
    tp <- result$time_points[[time_min + 1]]  # +1 because 0-indexed
    
    # Calculate total amount in system (excluding effect site)
    state <- engine$.__enclos_env__$private$integrate_ode(
      from = 0L,
      to = time_min,
      initial_state = SystemState$new(a1 = 10.0, a2 = 0.0, a3 = 0.0, ce = 0.0),
      infusion_rate = 0.0,
      pk_params = pk_params
    )
    
    total_amount <- state$a1 + state$a2 + state$a3
    elimination_percent <- (initial_amount - total_amount) / initial_amount * 100
    
    cat(sprintf("%8d | %16.3f | %13.1f\n", time_min, total_amount, elimination_percent))
  }
  
  cat("\nValidation completed.\n")
  return(result)
}