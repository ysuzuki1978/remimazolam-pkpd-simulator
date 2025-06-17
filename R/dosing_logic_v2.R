#' Enhanced Dosing Logic for Stepwise Infusion Changes
#'
#' This module handles the complex logic for managing stepwise continuous
#' infusion changes as requested:
#' - 12:23 -> 0.3 mg/kg/hr: Start infusion at 0.3
#' - 12:40 -> 0.5 mg/kg/hr: Change to 0.5  
#' - 12:50 -> 0 mg/kg/hr: Stop infusion
#'
#' @author Yasuhiro Suzuki

#' Process dose events for stepwise infusion logic
#' 
#' @param dose_events List of DoseEvent objects
#' @return List with processed bolus and infusion events
process_stepwise_dosing <- function(dose_events) {
  
  if (length(dose_events) == 0) {
    return(list(
      bolus_events = data.frame(time = numeric(0), amount = numeric(0)),
      infusion_events = data.frame(time = numeric(0), rate = numeric(0))
    ))
  }
  
  # Sort events by time
  sorted_events <- dose_events[order(sapply(dose_events, function(e) e$time_in_minutes))]
  
  # Process bolus events (straightforward)
  bolus_events <- data.frame(
    time = numeric(0),
    amount = numeric(0),
    stringsAsFactors = FALSE
  )
  
  # Process infusion events with stepwise logic
  infusion_events <- data.frame(
    time = numeric(0),
    rate = numeric(0),
    stringsAsFactors = FALSE
  )
  
  # Track current infusion rate
  current_infusion_rate <- 0
  
  for (event in sorted_events) {
    time_min <- event$time_in_minutes
    
    # Handle bolus doses
    if (event$bolus_mg > 0) {
      bolus_events <- rbind(bolus_events, data.frame(
        time = time_min,
        amount = event$bolus_mg,
        stringsAsFactors = FALSE
      ))
    }
    
    # Handle infusion rate changes
    new_rate <- event$continuous_mg_kg_hr
    
    # Only add infusion event if rate actually changes
    if (new_rate != current_infusion_rate) {
      infusion_events <- rbind(infusion_events, data.frame(
        time = time_min,
        rate = new_rate,
        stringsAsFactors = FALSE
      ))
      current_infusion_rate <- new_rate
      
      # Log the change for debugging
      if (DEBUG_CONSTANTS$enable_detailed_logging) {
        cat(sprintf("Infusion rate change at %.1f min: %.2f mg/kg/hr\n", 
                   time_min, new_rate))
      }
    }
  }
  
  # Ensure we start with rate 0 if first event is not at time 0
  if (nrow(infusion_events) > 0 && infusion_events$time[1] > 0) {
    infusion_events <- rbind(
      data.frame(time = 0, rate = 0, stringsAsFactors = FALSE),
      infusion_events
    )
  }
  
  return(list(
    bolus_events = bolus_events,
    infusion_events = infusion_events
  ))
}

#' Create infusion profile for visualization
#' 
#' @param infusion_events Data frame with time and rate columns
#' @param max_time Maximum simulation time
#' @return Data frame with step function for plotting
create_infusion_profile <- function(infusion_events, max_time) {
  
  if (nrow(infusion_events) == 0) {
    return(data.frame(
      time = c(0, max_time),
      rate = c(0, 0),
      stringsAsFactors = FALSE
    ))
  }
  
  profile <- data.frame(
    time = numeric(0),
    rate = numeric(0),
    stringsAsFactors = FALSE
  )
  
  # Sort events by time
  sorted_events <- infusion_events[order(infusion_events$time), ]
  
  current_rate <- 0
  
  for (i in 1:nrow(sorted_events)) {
    event_time <- sorted_events$time[i]
    new_rate <- sorted_events$rate[i]
    
    # Add point just before change (to create step)
    if (event_time > 0) {
      profile <- rbind(profile, data.frame(
        time = event_time - 0.01,
        rate = current_rate,
        stringsAsFactors = FALSE
      ))
    }
    
    # Add point at change
    profile <- rbind(profile, data.frame(
      time = event_time,
      rate = new_rate,
      stringsAsFactors = FALSE
    ))
    
    current_rate <- new_rate
  }
  
  # Extend to max time
  if (nrow(profile) > 0) {
    last_rate <- tail(profile$rate, 1)
    profile <- rbind(profile, data.frame(
      time = max_time,
      rate = last_rate,
      stringsAsFactors = FALSE
    ))
  }
  
  return(profile)
}

#' Validate dosing schedule for clinical safety
#' 
#' @param dose_events List of DoseEvent objects
#' @return ValidationResult object
validate_dosing_schedule <- function(dose_events) {
  errors <- character(0)
  warnings <- character(0)
  
  if (length(dose_events) == 0) {
    errors <- c(errors, "投与スケジュールが空です")
    return(ValidationResult$new(FALSE, errors))
  }
  
  # Sort events by time for validation
  sorted_events <- dose_events[order(sapply(dose_events, function(e) e$time_in_minutes))]
  
  # Check for negative times
  negative_times <- sapply(sorted_events, function(e) e$time_in_minutes < 0)
  if (any(negative_times)) {
    errors <- c(errors, "負の時間は指定できません")
  }
  
  # Check bolus dose limits
  excessive_bolus <- sapply(sorted_events, function(e) e$bolus_mg > VALIDATION_LIMITS$dosing$maximum_bolus)
  if (any(excessive_bolus)) {
    errors <- c(errors, paste("ボーラス投与量が上限", VALIDATION_LIMITS$dosing$maximum_bolus, "mgを超えています"))
  }
  
  # Check infusion rate limits
  excessive_infusion <- sapply(sorted_events, function(e) e$continuous_mg_kg_hr > VALIDATION_LIMITS$dosing$maximum_continuous)
  if (any(excessive_infusion)) {
    errors <- c(errors, paste("持続投与量が上限", VALIDATION_LIMITS$dosing$maximum_continuous, "mg/kg/hrを超えています"))
  }
  
  # Check for rapid rate changes (clinical warning)
  if (length(sorted_events) > 1) {
    for (i in 2:length(sorted_events)) {
      prev_event <- sorted_events[[i-1]]
      curr_event <- sorted_events[[i]]
      
      time_diff <- curr_event$time_in_minutes - prev_event$time_in_minutes
      rate_change <- abs(curr_event$continuous_mg_kg_hr - prev_event$continuous_mg_kg_hr)
      
      # Warn about rapid large changes
      if (time_diff < 5 && rate_change > 1.0) {
        warnings <- c(warnings, sprintf("時刻 %.1f分: 急激な投与量変更 (%.2f mg/kg/hr)", 
                                       curr_event$time_in_minutes, rate_change))
      }
    }
  }
  
  # Check for overlapping events at same time
  time_points <- sapply(sorted_events, function(e) e$time_in_minutes)
  duplicate_times <- duplicated(time_points)
  if (any(duplicate_times)) {
    warnings <- c(warnings, "同じ時刻に複数の投与イベントがあります")
  }
  
  # Combine errors and warnings
  all_messages <- c(errors, warnings)
  is_valid <- length(errors) == 0
  
  return(ValidationResult$new(is_valid, all_messages))
}

#' Generate preset dosing regimens with time-based format
#' 
#' @param patient Patient object for weight-based calculations
#' @param start_time_minutes Start time in minutes from anesthesia start
#' @return List of preset regimens
generate_preset_regimens <- function(patient = NULL, start_time_minutes = 0) {
  
  # Weight-adjusted doses (if patient available)
  standard_bolus <- if (!is.null(patient)) {
    min(12, max(6, patient$weight * 0.15))  # 0.15 mg/kg, 6-12mg range
  } else {
    8  # Default
  }
  
  gentle_bolus <- standard_bolus * 0.5
  
  presets <- list(
    standard_induction = list(
      name = "標準導入",
      description = "標準的な導入プロトコル",
      events = list(
        list(time = start_time_minutes, bolus = standard_bolus, continuous = 0),
        list(time = start_time_minutes, bolus = 0, continuous = 1.0),
        list(time = start_time_minutes + 5, bolus = 0, continuous = 0.5)
      )
    ),
    
    gentle_induction = list(
      name = "緩徐導入", 
      description = "高齢者や状態不安定患者向け",
      events = list(
        list(time = start_time_minutes, bolus = gentle_bolus, continuous = 0),
        list(time = start_time_minutes, bolus = 0, continuous = 0.5),
        list(time = start_time_minutes + 10, bolus = 0, continuous = 0.3)
      )
    ),
    
    maintenance_only = list(
      name = "維持のみ",
      description = "導入後の維持投与",
      events = list(
        list(time = start_time_minutes, bolus = 0, continuous = 0.3)
      )
    ),
    
    stepwise_example = list(
      name = "段階的投与例",
      description = "投与量を段階的に変更する例",
      events = list(
        list(time = start_time_minutes, bolus = 6, continuous = 0),
        list(time = start_time_minutes + 2, bolus = 0, continuous = 0.3),
        list(time = start_time_minutes + 20, bolus = 0, continuous = 0.5),
        list(time = start_time_minutes + 40, bolus = 0, continuous = 0.2),
        list(time = start_time_minutes + 60, bolus = 0, continuous = 0)
      )
    )
  )
  
  return(presets)
}