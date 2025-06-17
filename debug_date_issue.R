#' Debug Date Issue
#'
#' Understand why there's a date mismatch

cat("=== Current Time Information ===\n")
cat("Sys.time():", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), "\n")
cat("Sys.Date():", as.character(Sys.Date()), "\n")

# Load required components
source("R/constants.R")
source("R/data_models.R")

cat("\n=== Patient Creation ===\n")

# Create test patient step by step
patient_creation_date <- Sys.Date()
cat("Date used in patient creation:", as.character(patient_creation_date), "\n")

anesthesia_start_string <- "8:30"
anesthesia_start_time <- as.POSIXct(paste(patient_creation_date, anesthesia_start_string), 
                                   format = "%Y-%m-%d %H:%M")
cat("Anesthesia start time:", format(anesthesia_start_time, "%Y-%m-%d %H:%M:%S"), "\n")

# Now create patient
test_patient <- Patient$new(
  id = "DATE_DEBUG",
  age = 50L,
  weight = 70.0,
  height = 170.0,
  sex = SexType$MALE,
  asa_ps = AsapsType$CLASS1_2,
  anesthesia_start_time = anesthesia_start_string
)

cat("\nActual patient anesthesia start time:", format(test_patient$anesthesia_start_time, "%Y-%m-%d %H:%M:%S"), "\n")

cat("\n=== Time Conversion Test ===\n")
test_time <- "8:00"
anesthesia_date <- as.Date(test_patient$anesthesia_start_time)
cat("Anesthesia date extracted:", as.character(anesthesia_date), "\n")

parsed_time <- as.POSIXct(paste(anesthesia_date, test_time), format = "%Y-%m-%d %H:%M")
cat("Parsed time for", test_time, ":", format(parsed_time, "%Y-%m-%d %H:%M:%S"), "\n")

diff_minutes <- as.numeric(difftime(parsed_time, test_patient$anesthesia_start_time, units = "mins"))
cat("Difference:", diff_minutes, "minutes\n")

# Test the actual function
func_result <- test_patient$clock_time_to_minutes(test_time)
cat("Function result:", func_result, "minutes\n")