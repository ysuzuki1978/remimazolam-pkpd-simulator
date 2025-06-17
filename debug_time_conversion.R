#' Debug Time Conversion
#'
#' Debug the clock_time_to_minutes conversion to understand why negative times are wrong

# Load required components
source("R/constants.R")
source("R/data_models.R")

cat("=== Debugging Time Conversion ===\n\n")

# Create test patient with anesthesia start at 8:30
test_patient <- Patient$new(
  id = "TIME_DEBUG",
  age = 50L,
  weight = 70.0,
  height = 170.0,
  sex = SexType$MALE,
  asa_ps = AsapsType$CLASS1_2,
  anesthesia_start_time = "8:30"
)

cat("Patient anesthesia start time:", format(test_patient$anesthesia_start_time, "%Y-%m-%d %H:%M:%S"), "\n")
cat("Formatted time:", test_patient$get_formatted_start_time(), "\n\n")

# Test time conversions
test_times <- c("8:00", "8:15", "8:30", "8:45", "9:00", "12:00")

cat("Time conversion tests:\n")
for (time_str in test_times) {
  minutes <- test_patient$clock_time_to_minutes(time_str)
  cat(sprintf("  '%s' -> %d minutes\n", time_str, minutes))
}

cat("\nDetailed debugging for 8:00:\n")
time_str <- "8:00"
today <- as.Date(test_patient$anesthesia_start_time)
clock_time <- as.POSIXct(paste(today, time_str), format = "%Y-%m-%d %H:%M")
cat("Today date:", as.character(today), "\n")
cat("Parsed clock time:", format(clock_time, "%Y-%m-%d %H:%M:%S"), "\n")
cat("Anesthesia start:", format(test_patient$anesthesia_start_time, "%Y-%m-%d %H:%M:%S"), "\n")
diff_mins <- as.numeric(difftime(clock_time, test_patient$anesthesia_start_time, units = "mins"))
cat("Difference in minutes:", diff_mins, "\n")

cat("\n=== Debug Complete ===\n")