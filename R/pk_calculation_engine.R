#' Remimazolam Pharmacokinetic Calculation Engine
#'
#' This module implements the complete pharmacokinetic calculation engine for remimazolam
#' based on the Masui 2022 population pharmacokinetic model. It provides high-precision
#' numerical integration using the 4th-order Runge-Kutta method for accurate simulation
#' of drug concentrations in plasma and effect-site compartments.
#'
#' @import R6
#' @export

# Custom Error Classes
PKCalculationError <- R6::R6Class(
  "PKCalculationError",
  public = list(
    #' @field message Error message
    message = NULL,
    #' @field reason Error reason
    reason = NULL,
    
    #' @description Create new PKCalculationError
    #' @param message Error message
    #' @param reason Error reason
    initialize = function(message, reason = NULL) {
      self$message <- message
      self$reason <- reason
    }
  )
)

#' @title PKCalculationEngine
#' @description Main pharmacokinetic calculation engine
#' @export
PKCalculationEngine <- R6::R6Class(
  "PKCalculationEngine",
  public = list(
    
    #' @description Perform complete pharmacokinetic simulation
    #' @param patient Patient object
    #' @param dose_events List of DoseEvent objects
    #' @return SimulationResult object
    perform_simulation = function(patient, dose_events) {
      # Input data validation
      patient_validation <- patient$validate()
      if (!patient_validation$is_valid) {
        stop("患者データが無効です")
      }
      
      for (dose_event in dose_events) {
        dose_validation <- dose_event$validate()
        if (!dose_validation$is_valid) {
          stop("投与データが無効です")
        }
      }
      
      # Calculate pharmacokinetic parameters
      pk_params <- private$calculate_pk_parameters(patient)
      
      # Run simulation
      time_points <- private$run_simulation(patient, dose_events, pk_params)
      
      return(SimulationResult$new(patient, dose_events, time_points))
    }
  ),
  
  private = list(
    
    #' @description Calculate individualized pharmacokinetic parameters
    #' @param patient Patient object
    #' @return PKParameters object
    calculate_pk_parameters = function(patient) {
      abw <- patient$get_adjusted_body_weight()
      
      # Calculate volumes and clearances (Masui 2022 model)
      v1 <- MASUI_MODEL_CONSTANTS$theta1 * (abw / MASUI_MODEL_CONSTANTS$standard_weight)
      v2 <- MASUI_MODEL_CONSTANTS$theta2 * (abw / MASUI_MODEL_CONSTANTS$standard_weight)
      v3 <- (MASUI_MODEL_CONSTANTS$theta3 + 
             MASUI_MODEL_CONSTANTS$theta8 * (patient$age - MASUI_MODEL_CONSTANTS$standard_age)) * 
            (abw / MASUI_MODEL_CONSTANTS$standard_weight)
      
      cl <- (MASUI_MODEL_CONSTANTS$theta4 + 
             MASUI_MODEL_CONSTANTS$theta9 * patient$sex + 
             MASUI_MODEL_CONSTANTS$theta10 * patient$asa_ps) * 
            (abw / MASUI_MODEL_CONSTANTS$standard_weight)^0.75
      
      q2 <- MASUI_MODEL_CONSTANTS$theta5 * (abw / MASUI_MODEL_CONSTANTS$standard_weight)^0.75
      q3 <- MASUI_MODEL_CONSTANTS$theta6 * (abw / MASUI_MODEL_CONSTANTS$standard_weight)^0.75
      
      # Calculate ke0 (Masui & Hagihira 2022 model)
      ke0 <- private$calculate_ke0(patient)
      
      return(PKParameters$new(v1, v2, v3, cl, q2, q3, ke0))
    },
    
    #' @description Calculate effect-site equilibration rate constant (ke0)
    #' @param patient Patient object
    #' @return Numeric ke0 value
    calculate_ke0 = function(patient) {
      age <- as.numeric(patient$age)
      tbw <- patient$weight  # Total Body Weight
      height <- patient$height
      sex <- as.numeric(patient$sex)
      asa <- as.numeric(patient$asa_ps)
      bmi <- patient$get_bmi()
      
      # Masui & Hagihira 2022 Appendix 2 Eq. 14 implementation
      # ke0 = -9.06 + F(age) + F(TBW) + ...
      
      # Age function
      f_age <- function(x) {
        return(KE0_MODEL_CONSTANTS$age_amplitude * 
               exp(-0.5 * ((x - KE0_MODEL_CONSTANTS$age_mean) / KE0_MODEL_CONSTANTS$age_standard_deviation)^2))
      }
      
      # Weight function
      f_tbw <- function(x) {
        return(KE0_MODEL_CONSTANTS$weight_amplitude * 
               exp(-0.5 * ((x - KE0_MODEL_CONSTANTS$weight_mean) / KE0_MODEL_CONSTANTS$weight_standard_deviation)^2))
      }
      
      # Height function
      f_height <- function(x) {
        return(KE0_MODEL_CONSTANTS$height_amplitude * 
               exp(-0.5 * ((x - KE0_MODEL_CONSTANTS$height_mean) / KE0_MODEL_CONSTANTS$height_standard_deviation)^2))
      }
      
      # BMI function
      f_bmi <- function(x) {
        return(KE0_MODEL_CONSTANTS$bmi_amplitude * 
               exp(-0.5 * ((x - KE0_MODEL_CONSTANTS$bmi_mean) / KE0_MODEL_CONSTANTS$bmi_standard_deviation)^2))
      }
      
      # ke0 calculation
      ke0_log <- KE0_MODEL_CONSTANTS$base_log_ke0 + 
                 f_age(age) + 
                 f_tbw(tbw) + 
                 f_height(height) + 
                 f_bmi(bmi) + 
                 KE0_MODEL_CONSTANTS$gender_effect * sex + 
                 KE0_MODEL_CONSTANTS$asa_effect * asa
      
      ke0 <- exp(ke0_log) / KE0_MODEL_CONSTANTS$time_conversion_factor  # Convert to 1/min
      
      # Physiological validity check
      if (ke0 <= 0.00001 || ke0 >= 2.0) {
        stop(paste("ke0値が生理学的範囲外:", ke0))
      }
      
      # Warning for extreme values
      if (ke0 < 0.001 || ke0 > 1.0) {
        warning(sprintf("ke0値が極端な値です (%.6f 1/min): 計算結果の妥当性を確認してください", ke0))
      }
      
      return(ke0)
    },
    
    #' @description Run numerical integration simulation
    #' @param patient Patient object
    #' @param dose_events List of DoseEvent objects
    #' @param pk_params PKParameters object
    #' @return List of TimePoint objects
    run_simulation = function(patient, dose_events, pk_params) {
      # Determine output times
      max_dose_time <- max(sapply(dose_events, function(de) de$time_in_minutes), 0)
      simulation_end_time <- max_dose_time + 120  # 120 minutes after last dose
      output_times <- 0:simulation_end_time
      
      # Sort dose events by time
      sorted_dose_events <- dose_events[order(sapply(dose_events, function(de) de$time_in_minutes))]
      
      time_points <- list()
      current_state <- SystemState$new()
      current_time <- 0L
      dose_event_index <- 1L
      
      # Current infusion rate
      current_infusion_rate <- 0.0
      
      for (target_time in output_times) {
        
        # Process dose events up to this time
        while (dose_event_index <= length(sorted_dose_events) && 
               sorted_dose_events[[dose_event_index]]$time_in_minutes <= target_time) {
          
          dose_event <- sorted_dose_events[[dose_event_index]]
          
          # Handle bolus dose
          if (dose_event$bolus_mg > 0) {
            # Integrate to dose time
            if (dose_event$time_in_minutes > current_time) {
              current_state <- private$integrate_ode(
                from = current_time,
                to = dose_event$time_in_minutes,
                initial_state = current_state,
                infusion_rate = current_infusion_rate,
                pk_params = pk_params
              )
              current_time <- dose_event$time_in_minutes
            }
            
            # Add bolus dose instantaneously
            current_state$a1 <- current_state$a1 + dose_event$bolus_mg
          }
          
          # Update infusion rate
          current_infusion_rate <- dose_event$continuous_rate_mg_min(patient)
          
          dose_event_index <- dose_event_index + 1L
        }
        
        # Integrate to target time
        if (target_time > current_time) {
          current_state <- private$integrate_ode(
            from = current_time,
            to = target_time,
            initial_state = current_state,
            infusion_rate = current_infusion_rate,
            pk_params = pk_params
          )
          current_time <- target_time
        }
        
        # Calculate plasma concentration
        plasma_concentration <- current_state$a1 / pk_params$v1
        
        # Get dose event at this time
        dose_event_at_this_time <- NULL
        for (de in sorted_dose_events) {
          if (de$time_in_minutes == target_time) {
            dose_event_at_this_time <- de
            break
          }
        }
        
        # Create TimePoint
        time_point <- TimePoint$new(
          time_in_minutes = target_time,
          dose_event = dose_event_at_this_time,
          plasma_concentration = plasma_concentration,
          effect_site_concentration = current_state$ce
        )
        
        time_points <- append(time_points, list(time_point))
      }
      
      return(time_points)
    },
    
    #' @description High-precision ODE integration using 4th-order Runge-Kutta method
    #' @param from Start time in minutes
    #' @param to End time in minutes
    #' @param initial_state SystemState object
    #' @param infusion_rate Infusion rate in mg/min
    #' @param pk_params PKParameters object
    #' @return SystemState object
    integrate_ode = function(from, to, initial_state, infusion_rate, pk_params) {
      dt <- 0.1  # Integration step size (minutes)
      steps <- as.integer((to - from) / dt)
      
      state <- initial_state
      t <- as.numeric(from)
      
      for (i in 1:steps) {
        state <- private$runge_kutta_4_step(
          state = state,
          t = t,
          dt = dt,
          infusion_rate = infusion_rate,
          pk_params = pk_params
        )
        t <- t + dt
      }
      
      # Handle remaining time (fractional part)
      remaining_time <- (to - from) - steps * dt
      if (remaining_time > 0) {
        state <- private$runge_kutta_4_step(
          state = state,
          t = t,
          dt = remaining_time,
          infusion_rate = infusion_rate,
          pk_params = pk_params
        )
      }
      
      return(state)
    },
    
    #' @description Single step of 4th-order Runge-Kutta integration
    #' @param state SystemState object
    #' @param t Current time
    #' @param dt Time step
    #' @param infusion_rate Infusion rate in mg/min
    #' @param pk_params PKParameters object
    #' @return SystemState object
    runge_kutta_4_step = function(state, t, dt, infusion_rate, pk_params) {
      k1 <- private$calculate_derivatives(state, infusion_rate, pk_params)
      
      state2 <- SystemState$new(
        a1 = state$a1 + k1$a1 * dt / 2,
        a2 = state$a2 + k1$a2 * dt / 2,
        a3 = state$a3 + k1$a3 * dt / 2,
        ce = state$ce + k1$ce * dt / 2
      )
      k2 <- private$calculate_derivatives(state2, infusion_rate, pk_params)
      
      state3 <- SystemState$new(
        a1 = state$a1 + k2$a1 * dt / 2,
        a2 = state$a2 + k2$a2 * dt / 2,
        a3 = state$a3 + k2$a3 * dt / 2,
        ce = state$ce + k2$ce * dt / 2
      )
      k3 <- private$calculate_derivatives(state3, infusion_rate, pk_params)
      
      state4 <- SystemState$new(
        a1 = state$a1 + k3$a1 * dt,
        a2 = state$a2 + k3$a2 * dt,
        a3 = state$a3 + k3$a3 * dt,
        ce = state$ce + k3$ce * dt
      )
      k4 <- private$calculate_derivatives(state4, infusion_rate, pk_params)
      
      return(SystemState$new(
        a1 = state$a1 + dt / 6 * (k1$a1 + 2 * k2$a1 + 2 * k3$a1 + k4$a1),
        a2 = state$a2 + dt / 6 * (k1$a2 + 2 * k2$a2 + 2 * k3$a2 + k4$a2),
        a3 = state$a3 + dt / 6 * (k1$a3 + 2 * k2$a3 + 2 * k3$a3 + k4$a3),
        ce = state$ce + dt / 6 * (k1$ce + 2 * k2$ce + 2 * k3$ce + k4$ce)
      ))
    },
    
    #' @description Calculate derivatives for the differential equation system
    #' @param state SystemState object
    #' @param infusion_rate Infusion rate in mg/min
    #' @param pk_params PKParameters object
    #' @return SystemState object with derivatives
    calculate_derivatives = function(state, infusion_rate, pk_params) {
      # dA1/dt = R(t) - (k10 + k12 + k13)A1 + k21*A2 + k31*A3
      dA1dt <- infusion_rate - (pk_params$get_k10() + pk_params$get_k12() + pk_params$get_k13()) * state$a1 + 
               pk_params$get_k21() * state$a2 + pk_params$get_k31() * state$a3
      
      # dA2/dt = k12*A1 - k21*A2
      dA2dt <- pk_params$get_k12() * state$a1 - pk_params$get_k21() * state$a2
      
      # dA3/dt = k13*A1 - k31*A3
      dA3dt <- pk_params$get_k13() * state$a1 - pk_params$get_k31() * state$a3
      
      # dCe/dt = ke0 * (A1/V1 - Ce)
      plasma_concentration <- state$a1 / pk_params$v1
      dCedt <- pk_params$ke0 * (plasma_concentration - state$ce)
      
      return(SystemState$new(a1 = dA1dt, a2 = dA2dt, a3 = dA3dt, ce = dCedt))
    }
  )
)