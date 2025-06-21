#' Data Models for Remimazolam PKPD Calculations
#'
#' This module contains R6 class definitions that mirror the Swift data models
#' for remimazolam pharmacokinetic and pharmacodynamic calculations based on
#' the Masui 2022 population pharmacokinetic model.
#'
#' @import R6
#' @export

# Sex Type Enumeration
#' @export
SexType <- list(
  MALE = 0L,
  FEMALE = 1L
)

# ASA Physical Status Enumeration  
#' @export
AsapsType <- list(
  CLASS1_2 = 0L,  # ASA I-II
  CLASS3_4 = 1L   # ASA III-IV
)

# Validation Result Class
#' @title ValidationResult
#' @description Data validation result container
#' @export
ValidationResult <- R6::R6Class(
  "ValidationResult",
  public = list(
    #' @field is_valid Logical indicating if validation passed
    is_valid = NULL,
    #' @field errors Character vector of validation errors
    errors = NULL,
    
    #' @description Create a new ValidationResult
    #' @param is_valid Logical indicating validation status
    #' @param errors Character vector of error messages
    initialize = function(is_valid = TRUE, errors = character(0)) {
      self$is_valid <- is_valid
      self$errors <- errors
    }
  )
)

# Patient Class
#' @title Patient
#' @description Patient information container with validation
#' @export
Patient <- R6::R6Class(
  "Patient",
  public = list(
    #' @field id Patient identifier
    id = NULL,
    #' @field age Patient age in years
    age = NULL,
    #' @field weight Patient weight in kg
    weight = NULL,
    #' @field height Patient height in cm
    height = NULL,
    #' @field sex Patient sex (SexType$MALE or SexType$FEMALE)
    sex = NULL,
    #' @field asa_ps ASA Physical Status (AsapsType$CLASS1_2 or AsapsType$CLASS3_4)
    asa_ps = NULL,
    #' @field anesthesia_start_time Anesthesia start time (POSIXct)
    anesthesia_start_time = NULL,
    
    #' @description Create a new Patient
    #' @param id Patient identifier string
    #' @param age Patient age in years (18-100)
    #' @param weight Patient weight in kg (30-200)
    #' @param height Patient height in cm (120-220)
    #' @param sex Patient sex (SexType$MALE or SexType$FEMALE)
    #' @param asa_ps ASA Physical Status classification
    #' @param anesthesia_start_time Anesthesia start time (POSIXct or character in HH:MM format)
    initialize = function(id, age, weight, height, sex, asa_ps, anesthesia_start_time = NULL) {
      self$id <- id
      self$age <- as.integer(age)
      self$weight <- as.numeric(weight)
      self$height <- as.numeric(height)
      self$sex <- as.integer(sex)
      self$asa_ps <- as.integer(asa_ps)
      
      # Handle anesthesia start time
      if (!is.null(anesthesia_start_time)) {
        if (is.character(anesthesia_start_time)) {
          # Parse HH:MM format and set to today's date
          today <- Sys.Date()
          self$anesthesia_start_time <- as.POSIXct(paste(today, anesthesia_start_time), 
                                                   format = "%Y-%m-%d %H:%M")
        } else if (inherits(anesthesia_start_time, "POSIXct")) {
          self$anesthesia_start_time <- anesthesia_start_time
        }
      } else {
        # Default to current time
        self$anesthesia_start_time <- Sys.time()
      }
    },
    
    #' @description Calculate BMI
    #' @return Numeric BMI value
    get_bmi = function() {
      return(self$weight / (self$height / 100)^2)
    },
    
    #' @description Get ideal body weight (simplified - using actual weight for now)
    #' @return Numeric ideal body weight in kg
    get_ideal_body_weight = function() {
      return(70.0)  # Simplified implementation
    },
    
    #' @description Get adjusted body weight for PK calculations
    #' @return Numeric adjusted body weight in kg
    get_adjusted_body_weight = function() {
      return(self$weight)  # Using actual weight as per Swift implementation
    },
    
    #' @description Convert minutes from anesthesia start to clock time
    #' @param minutes_from_start Minutes since anesthesia start
    #' @return POSIXct time
    minutes_to_clock_time = function(minutes_from_start) {
      return(self$anesthesia_start_time + minutes_from_start * 60)
    },
    
    #' @description Convert clock time to minutes from anesthesia start
    #' @param clock_time POSIXct time or character time in HH:MM format
    #' @return Numeric minutes from start
    clock_time_to_minutes = function(clock_time) {
      if (is.character(clock_time)) {
        # Store original input time string
        input_time_str <- clock_time
        
        # Use the same date as anesthesia start time to ensure consistency
        # Extract date using format to avoid timezone issues
        anesthesia_date <- format(self$anesthesia_start_time, "%Y-%m-%d")
        parsed_time <- as.POSIXct(paste(anesthesia_date, input_time_str), format = "%Y-%m-%d %H:%M")
        
        # Calculate time difference
        diff_mins <- as.numeric(difftime(parsed_time, self$anesthesia_start_time, units = "mins"))
        
        # If the result is negative (clock time is earlier than anesthesia start),
        # assume it's the next day
        if (diff_mins < 0) {
          next_day <- as.Date(anesthesia_date) + 1
          parsed_time <- as.POSIXct(paste(next_day, input_time_str), format = "%Y-%m-%d %H:%M")
          diff_mins <- as.numeric(difftime(parsed_time, self$anesthesia_start_time, units = "mins"))
        }
        
        return(diff_mins)
      } else {
        return(as.numeric(difftime(clock_time, self$anesthesia_start_time, units = "mins")))
      }
    },
    
    #' @description Format anesthesia start time
    #' @return Character time in HH:MM format
    get_formatted_start_time = function() {
      return(format(self$anesthesia_start_time, "%H:%M"))
    },
    
    #' @description Validate patient data
    #' @return ValidationResult object
    validate = function() {
      errors <- character(0)
      
      # ID validation
      if (is.null(self$id) || trimws(self$id) == "") {
        errors <- c(errors, "患者IDが入力されていません")
      }
      
      # Age validation
      if (is.null(self$age) || self$age < 18 || self$age > 100) {
        errors <- c(errors, "年齢は18歳から100歳の範囲で入力してください")
      }
      
      # Weight validation
      if (is.null(self$weight) || self$weight < 30.0 || self$weight > 200.0) {
        errors <- c(errors, "体重は30kgから200kgの範囲で入力してください")
      }
      
      # Height validation
      if (is.null(self$height) || self$height < 120.0 || self$height > 220.0) {
        errors <- c(errors, "身長は120cmから220cmの範囲で入力してください")
      }
      
      # BMI validation
      if (!is.null(self$weight) && !is.null(self$height)) {
        bmi <- self$get_bmi()
        if (bmi < 12.0 || bmi > 50.0) {
          errors <- c(errors, sprintf("BMIが極端な値です（計算値: %.1f）", bmi))
        }
      }
      
      return(ValidationResult$new(is_valid = length(errors) == 0, errors = errors))
    }
  )
)

# DoseEvent Class
#' @title DoseEvent
#' @description Drug dose event container with validation
#' @export
DoseEvent <- R6::R6Class(
  "DoseEvent",
  public = list(
    #' @field time_in_minutes Time of dose administration in minutes
    time_in_minutes = NULL,
    #' @field bolus_mg Bolus dose in mg
    bolus_mg = NULL,
    #' @field continuous_mg_kg_hr Continuous dose rate in mg/kg/hr
    continuous_mg_kg_hr = NULL,
    
    #' @description Create a new DoseEvent
    #' @param time_in_minutes Time in minutes from start
    #' @param bolus_mg Bolus dose in mg
    #' @param continuous_mg_kg_hr Continuous infusion rate in mg/kg/hr
    initialize = function(time_in_minutes, bolus_mg, continuous_mg_kg_hr) {
      self$time_in_minutes <- as.integer(time_in_minutes)
      self$bolus_mg <- as.numeric(bolus_mg)
      self$continuous_mg_kg_hr <- as.numeric(continuous_mg_kg_hr)
    },
    
    #' @description Calculate continuous infusion rate in mg/min
    #' @param patient Patient object
    #' @return Numeric continuous rate in mg/min
    continuous_rate_mg_min = function(patient) {
      return((self$continuous_mg_kg_hr * patient$weight) / 60.0)
    },
    
    #' @description Validate dose event data
    #' @return ValidationResult object
    validate = function() {
      errors <- character(0)
      
      if (is.null(self$time_in_minutes) || is.na(self$time_in_minutes)) {
        errors <- c(errors, "投与時間が無効です")
      }
      
      if (is.null(self$bolus_mg) || self$bolus_mg < 0 || self$bolus_mg > 100) {
        errors <- c(errors, "ボーラス投与量は0mgから100mgの範囲で入力してください")
      }
      
      if (is.null(self$continuous_mg_kg_hr) || self$continuous_mg_kg_hr < 0 || self$continuous_mg_kg_hr > 20) {
        errors <- c(errors, "持続投与量は0mg/kg/hrから20mg/kg/hrの範囲で入力してください")
      }
      
      return(ValidationResult$new(is_valid = length(errors) == 0, errors = errors))
    }
  )
)

# PKParameters Class
#' @title PKParameters
#' @description Pharmacokinetic parameters from Masui 2022 model
#' @export
PKParameters <- R6::R6Class(
  "PKParameters",
  public = list(
    #' @field v1 Central compartment volume (L)
    v1 = NULL,
    #' @field v2 Peripheral compartment 1 volume (L)
    v2 = NULL,
    #' @field v3 Peripheral compartment 2 volume (L)
    v3 = NULL,
    #' @field cl Total body clearance (L/min)
    cl = NULL,
    #' @field q2 Inter-compartmental clearance 1-2 (L/min)
    q2 = NULL,
    #' @field q3 Inter-compartmental clearance 1-3 (L/min)
    q3 = NULL,
    #' @field ke0 Effect-site equilibration rate constant (1/min)
    ke0 = NULL,
    
    #' @description Create new PKParameters
    #' @param v1 Central compartment volume
    #' @param v2 Peripheral compartment 1 volume
    #' @param v3 Peripheral compartment 2 volume
    #' @param cl Total body clearance
    #' @param q2 Inter-compartmental clearance 1-2
    #' @param q3 Inter-compartmental clearance 1-3
    #' @param ke0 Effect-site equilibration rate constant
    initialize = function(v1, v2, v3, cl, q2, q3, ke0) {
      self$v1 <- as.numeric(v1)
      self$v2 <- as.numeric(v2)
      self$v3 <- as.numeric(v3)
      self$cl <- as.numeric(cl)
      self$q2 <- as.numeric(q2)
      self$q3 <- as.numeric(q3)
      self$ke0 <- as.numeric(ke0)
    },
    
    #' @description Calculate k10 (elimination rate constant)
    #' @return Numeric k10 value
    get_k10 = function() {
      return(self$cl / self$v1)
    },
    
    #' @description Calculate k12 (central to peripheral 1)
    #' @return Numeric k12 value
    get_k12 = function() {
      return(self$q2 / self$v1)
    },
    
    #' @description Calculate k21 (peripheral 1 to central)
    #' @return Numeric k21 value
    get_k21 = function() {
      return(self$q2 / self$v2)
    },
    
    #' @description Calculate k13 (central to peripheral 2)
    #' @return Numeric k13 value
    get_k13 = function() {
      return(self$q3 / self$v1)
    },
    
    #' @description Calculate k31 (peripheral 2 to central)
    #' @return Numeric k31 value
    get_k31 = function() {
      return(self$q3 / self$v3)
    }
  )
)

# SystemState Class
#' @title SystemState
#' @description System state for differential equation integration
#' @export
SystemState <- R6::R6Class(
  "SystemState",
  public = list(
    #' @field a1 Central compartment drug amount (mg)
    a1 = NULL,
    #' @field a2 Peripheral compartment 1 drug amount (mg)
    a2 = NULL,
    #' @field a3 Peripheral compartment 2 drug amount (mg)
    a3 = NULL,
    #' @field ce Effect-site concentration (µg/mL)
    ce = NULL,
    
    #' @description Create new SystemState
    #' @param a1 Central compartment amount
    #' @param a2 Peripheral compartment 1 amount
    #' @param a3 Peripheral compartment 2 amount
    #' @param ce Effect-site concentration
    initialize = function(a1 = 0.0, a2 = 0.0, a3 = 0.0, ce = 0.0) {
      self$a1 <- as.numeric(a1)
      self$a2 <- as.numeric(a2)
      self$a3 <- as.numeric(a3)
      self$ce <- as.numeric(ce)
    },
    
    #' @description Convert to numeric vector for ODE integration
    #' @return Numeric vector c(a1, a2, a3, ce)
    to_vector = function() {
      return(c(self$a1, self$a2, self$a3, self$ce))
    },
    
    #' @description Create SystemState from numeric vector
    #' @param vec Numeric vector c(a1, a2, a3, ce)
    #' @return New SystemState object
    from_vector = function(vec) {
      return(SystemState$new(vec[1], vec[2], vec[3], vec[4]))
    }
  )
)

# TimePoint Class
#' @title TimePoint
#' @description Time point data for simulation results
#' @export
TimePoint <- R6::R6Class(
  "TimePoint",
  public = list(
    #' @field time_in_minutes Time in minutes
    time_in_minutes = NULL,
    #' @field dose_event DoseEvent at this time point (or NULL)
    dose_event = NULL,
    #' @field plasma_concentration Plasma concentration (µg/mL)
    plasma_concentration = NULL,
    #' @field effect_site_concentration Effect-site concentration (µg/mL)
    effect_site_concentration = NULL,
    
    #' @description Create new TimePoint
    #' @param time_in_minutes Time in minutes
    #' @param dose_event DoseEvent object or NULL
    #' @param plasma_concentration Plasma concentration
    #' @param effect_site_concentration Effect-site concentration
    initialize = function(time_in_minutes, dose_event, plasma_concentration, effect_site_concentration) {
      self$time_in_minutes <- as.integer(time_in_minutes)
      self$dose_event <- dose_event
      self$plasma_concentration <- as.numeric(plasma_concentration)
      self$effect_site_concentration <- as.numeric(effect_site_concentration)
    },
    
    #' @description Format plasma concentration as string
    #' @return Character string
    get_plasma_concentration_string = function() {
      return(sprintf("%.3f", self$plasma_concentration))
    },
    
    #' @description Format effect-site concentration as string
    #' @return Character string
    get_effect_site_concentration_string = function() {
      return(sprintf("%.3f", self$effect_site_concentration))
    }
  )
)

# SimulationResult Class
#' @title SimulationResult
#' @description Complete simulation result container
#' @export
SimulationResult <- R6::R6Class(
  "SimulationResult",
  public = list(
    #' @field patient Patient object
    patient = NULL,
    #' @field dose_events List of DoseEvent objects
    dose_events = NULL,
    #' @field time_points List of TimePoint objects
    time_points = NULL,
    #' @field patient_info List with patient information
    patient_info = NULL,
    #' @field pk_parameters List with PK parameters
    pk_parameters = NULL,
    #' @field calculation_method String describing calculation method
    calculation_method = NULL,
    #' @field calculated_at POSIXct timestamp of calculation
    calculated_at = NULL,
    
    #' @description Create new SimulationResult
    #' @param time_points List of TimePoint objects
    #' @param patient_info List with patient information (optional)
    #' @param pk_parameters List with PK parameters (optional)
    #' @param calculation_method String describing calculation method (optional)
    #' @param calculated_at POSIXct timestamp (optional)
    initialize = function(time_points, patient_info = NULL, pk_parameters = NULL, 
                         calculation_method = "Unknown", calculated_at = NULL) {
      self$time_points <- time_points
      self$patient_info <- patient_info
      self$pk_parameters <- pk_parameters
      self$calculation_method <- calculation_method
      self$calculated_at <- if (is.null(calculated_at)) Sys.time() else calculated_at
    },
    
    #' @description Get maximum plasma concentration
    #' @return Numeric maximum plasma concentration
    get_max_plasma_concentration = function() {
      concentrations <- sapply(self$time_points, function(tp) tp$plasma_concentration)
      return(max(concentrations, na.rm = TRUE))
    },
    
    #' @description Get maximum effect-site concentration
    #' @return Numeric maximum effect-site concentration
    get_max_effect_site_concentration = function() {
      concentrations <- sapply(self$time_points, function(tp) tp$effect_site_concentration)
      return(max(concentrations, na.rm = TRUE))
    },
    
    #' @description Get simulation duration in minutes
    #' @return Integer simulation duration
    get_simulation_duration_minutes = function() {
      if (length(self$time_points) == 0) return(0L)
      return(self$time_points[[length(self$time_points)]]$time_in_minutes)
    },
    
    #' @description Export to CSV format
    #' @return Character string in CSV format
    to_csv = function() {
      csv_lines <- c("Time(min),Bolus(mg),Continuous(mg/kg/hr),Cp(ug/mL),Ce(ug/mL)")
      
      for (tp in self$time_points) {
        bolus <- if (is.null(tp$dose_event)) 0.0 else tp$dose_event$bolus_mg
        continuous <- if (is.null(tp$dose_event)) 0.0 else tp$dose_event$continuous_mg_kg_hr
        
        line <- sprintf("%d,%.1f,%.2f,%.3f,%.3f",
                       tp$time_in_minutes,
                       bolus,
                       continuous,
                       tp$plasma_concentration,
                       tp$effect_site_concentration)
        csv_lines <- c(csv_lines, line)
      }
      
      return(paste(csv_lines, collapse = "\n"))
    }
  )
)

# SimulationResultV3 Class - Extended for multiple calculation methods
#' @title SimulationResultV3
#' @description Extended simulation result container with multiple effect-site calculation methods
#' @export
SimulationResultV3 <- R6::R6Class(
  "SimulationResultV3",
  inherit = SimulationResult,
  public = list(
    #' @field alternative_methods List containing results from different calculation methods
    alternative_methods = NULL,
    #' @field time_vector Vector of time points for comparison
    time_vector = NULL,
    
    #' @description Create new SimulationResultV3
    #' @param time_points List of TimePoint objects
    #' @param patient_info List with patient information (optional)
    #' @param pk_parameters List with PK parameters (optional)
    #' @param calculation_method String describing calculation method (optional)
    #' @param calculated_at POSIXct timestamp (optional)
    #' @param alternative_methods List of alternative calculation results
    #' @param time_vector Vector of time points
    initialize = function(time_points, patient_info = NULL, pk_parameters = NULL, 
                         calculation_method = "V3 Multi-Method", calculated_at = NULL,
                         alternative_methods = NULL, time_vector = NULL) {
      super$initialize(time_points, patient_info, pk_parameters, calculation_method, calculated_at)
      self$alternative_methods <- alternative_methods
      self$time_vector <- time_vector
    },
    
    #' @description Get effect-site concentrations for a specific method
    #' @param method Method name ("discrete", "exponential", "hybrid", "original")
    #' @return Vector of effect-site concentrations
    get_effect_site_by_method = function(method) {
      if (method == "original") {
        return(sapply(self$time_points, function(tp) tp$effect_site_concentration))
      }
      
      if (!is.null(self$alternative_methods) && method %in% names(self$alternative_methods)) {
        return(self$alternative_methods[[method]]$effect_site)
      }
      
      stop(paste("Method", method, "not found in results"))
    },
    
    #' @description Get plasma concentrations (same for all methods)
    #' @return Vector of plasma concentrations
    get_plasma_concentrations = function() {
      return(sapply(self$time_points, function(tp) tp$plasma_concentration))
    },
    
    #' @description Get maximum effect-site concentration for a specific method
    #' @param method Method name
    #' @return Numeric maximum concentration
    get_max_effect_site_by_method = function(method) {
      concentrations <- self$get_effect_site_by_method(method)
      return(max(concentrations, na.rm = TRUE))
    },
    
    #' @description Get available calculation methods
    #' @return Character vector of method names
    get_available_methods = function() {
      methods <- c("original")
      if (!is.null(self$alternative_methods)) {
        methods <- c(methods, names(self$alternative_methods))
      }
      return(methods)
    },
    
    #' @description Compare methods at specific time points
    #' @param target_times Vector of time points to compare
    #' @return Data frame with comparison results
    compare_methods_at_times = function(target_times) {
      available_methods <- self$get_available_methods()
      
      # Find closest time indices for each target time
      comparison_data <- data.frame(
        target_time = numeric(0),
        actual_time = numeric(0),
        method = character(0),
        plasma_conc = numeric(0),
        effect_site_conc = numeric(0),
        stringsAsFactors = FALSE
      )
      
      for (target_time in target_times) {
        # Find closest time point
        time_diffs <- abs(self$time_vector - target_time)
        closest_idx <- which.min(time_diffs)
        actual_time <- self$time_vector[closest_idx]
        
        plasma_conc <- self$get_plasma_concentrations()[closest_idx]
        
        for (method in available_methods) {
          effect_site_conc <- self$get_effect_site_by_method(method)[closest_idx]
          
          comparison_data <- rbind(comparison_data, data.frame(
            target_time = target_time,
            actual_time = actual_time,
            method = method,
            plasma_conc = plasma_conc,
            effect_site_conc = effect_site_conc,
            stringsAsFactors = FALSE
          ))
        }
      }
      
      return(comparison_data)
    },
    
    #' @description Export comparison to CSV format
    #' @return Character string in CSV format with all methods
    to_csv_comparison = function() {
      available_methods <- self$get_available_methods()
      
      # Create header
      header_parts <- c("Time(min)", "Cp(ug/mL)")
      for (method in available_methods) {
        header_parts <- c(header_parts, paste0("Ce_", method, "(ug/mL)"))
      }
      
      csv_lines <- c(paste(header_parts, collapse = ","))
      
      # Add data rows
      plasma_conc <- self$get_plasma_concentrations()
      
      for (i in 1:length(self$time_vector)) {
        row_parts <- c(
          sprintf("%.0f", self$time_vector[i]),
          sprintf("%.3f", plasma_conc[i])
        )
        
        for (method in available_methods) {
          ce_conc <- self$get_effect_site_by_method(method)[i]
          row_parts <- c(row_parts, sprintf("%.3f", ce_conc))
        }
        
        csv_lines <- c(csv_lines, paste(row_parts, collapse = ","))
      }
      
      return(paste(csv_lines, collapse = "\n"))
    },
    
    #' @description Calculate differences between methods
    #' @param reference_method Reference method for comparison (default: "original")
    #' @return List of difference statistics
    calculate_method_differences = function(reference_method = "original") {
      available_methods <- self$get_available_methods()
      reference_ce <- self$get_effect_site_by_method(reference_method)
      
      differences <- list()
      
      for (method in available_methods) {
        if (method != reference_method) {
          method_ce <- self$get_effect_site_by_method(method)
          
          # Calculate various difference metrics
          abs_diff <- abs(method_ce - reference_ce)
          rel_diff <- abs_diff / pmax(reference_ce, 1e-6) * 100  # Relative difference in %
          
          differences[[method]] <- list(
            mean_abs_diff = mean(abs_diff, na.rm = TRUE),
            max_abs_diff = max(abs_diff, na.rm = TRUE),
            mean_rel_diff = mean(rel_diff, na.rm = TRUE),
            max_rel_diff = max(rel_diff, na.rm = TRUE),
            rmse = sqrt(mean((method_ce - reference_ce)^2, na.rm = TRUE))
          )
        }
      }
      
      return(differences)
    }
  )
)