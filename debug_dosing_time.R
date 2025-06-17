#' Debug Dosing Time Input
#'
#' Detailed debugging of the dosing time input issue

# Load required components
source("R/constants.R")
source("R/data_models.R")

cat("=== Debugging Dosing Time Input ===\n\n")

# Create test patient
test_patient <- Patient$new(
  id = "DEBUG_TIME",
  age = 50L,
  weight = 70.0,
  height = 170.0,
  sex = SexType$MALE,
  asa_ps = AsapsType$CLASS1_2,
  anesthesia_start_time = "8:30"  # Patient starts at 8:30
)

cat("Test patient anesthesia start time:", format(test_patient$anesthesia_start_time, "%H:%M"), "\n\n")

# Simulate the parse_time_input function
parse_time_input_debug <- function(time_input, patient = NULL) {
  cat(sprintf("  Input: '%s'\n", time_input))
  
  if (is.null(patient) || is.null(patient$anesthesia_start_time)) {
    cat("  No patient data - trying numeric conversion\n")
    result <- as.numeric(time_input)
    cat(sprintf("  Result: %s\n", ifelse(is.na(result), "NA", as.character(result))))
    return(result)
  }
  
  cat("  Patient data available\n")
  
  # Test regex
  regex_pattern <- "^([0-9]|[0-1][0-9]|2[0-3]):([0-5][0-9])$"
  regex_match <- grepl(regex_pattern, time_input)
  cat(sprintf("  Regex match: %s\n", regex_match))
  
  if (regex_match) {
    cat("  Parsing as time format\n")
    result <- patient$clock_time_to_minutes(time_input)
    cat(sprintf("  clock_time_to_minutes result: %s\n", result))
    return(result)
  } else {
    cat("  Parsing as numeric minutes\n")
    result <- as.numeric(time_input)
    cat(sprintf("  Numeric result: %s\n", ifelse(is.na(result), "NA", as.character(result))))
    return(result)
  }
}

# Test cases that should work
test_cases <- c("8:00", "8:30", "8:45", "12:00", "15:30")

cat("Testing problematic time inputs:\n")
for (test_time in test_cases) {
  cat(sprintf("\nTesting '%s':\n", test_time))
  
  tryCatch({
    result <- parse_time_input_debug(test_time, test_patient)
    cat(sprintf("  Final result: %s minutes\n", result))
    
    # Check conditions that cause error
    if (is.null(result)) {
      cat("  ❌ Result is NULL\n")
    } else if (is.na(result)) {
      cat("  ❌ Result is NA\n")
    } else if (result < 0) {
      cat(sprintf("  ⚠️  Result is negative (%s) - this might cause issues\n", result))
    } else {
      cat("  ✅ Result looks good\n")
    }
    
  }, error = function(e) {
    cat(sprintf("  ❌ Error: %s\n", e$message))
  })
}

cat("\n=== Testing clock_time_to_minutes function directly ===\n")

# Test the clock_time_to_minutes function directly
test_times_direct <- c("8:00", "8:30", "9:00", "12:00")

for (test_time in test_times_direct) {
  cat(sprintf("\nDirect test '%s':\n", test_time))
  tryCatch({
    result <- test_patient$clock_time_to_minutes(test_time)
    cat(sprintf("  Result: %s minutes\n", result))
    
    # Convert back to verify
    back_time <- test_patient$minutes_to_clock_time(result)
    cat(sprintf("  Converts back to: %s\n", format(back_time, "%H:%M")))
    
  }, error = function(e) {
    cat(sprintf("  ❌ Error: %s\n", e$message))
  })
}

cat("\n=== Analyzing the validation logic ===\n")

# Simulate the validation logic from dosing module
simulate_validation <- function(time_input, patient) {
  cat(sprintf("Simulating validation for '%s':\n", time_input))
  
  # Step 1: Parse time
  time_minutes <- tryCatch({
    parse_time_input_debug(time_input, patient)
  }, error = function(e) {
    cat(sprintf("  Parse error: %s\n", e$message))
    return(NULL)
  })
  
  cat(sprintf("  Parsed result: %s\n", time_minutes))
  
  # Step 2: Validation checks
  if (is.null(time_minutes)) {
    cat("  ❌ Validation failed: NULL result\n")
    return(FALSE)
  }
  
  if (is.na(time_minutes)) {
    cat("  ❌ Validation failed: NA result\n")
    return(FALSE)
  }
  
  if (time_minutes < 0) {
    cat(sprintf("  ❌ Validation failed: Negative result (%s)\n", time_minutes))
    return(FALSE)
  }
  
  cat("  ✅ Validation passed\n")
  return(TRUE)
}

cat("\nTesting full validation logic:\n")
for (test_time in c("8:00", "8:30", "12:00")) {
  cat(sprintf("\n--- Validating '%s' ---\n", test_time))
  result <- simulate_validation(test_time, test_patient)
  cat(sprintf("Final validation result: %s\n", result))
}

cat("\n✅ Debug completed!\n")