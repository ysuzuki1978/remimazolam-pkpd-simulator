#!/usr/bin/env Rscript

#' Launch Remimazolam PK/PD Simulator Shiny Application
#'
#' This script provides a convenient way to launch the Remimazolam PK/PD
#' simulator with proper error handling and environment checking.
#'
#' Usage:
#'   Rscript launch_app.R
#'   # or from R console:
#'   source("launch_app.R")
#'
#' @author Yasuhiro Suzuki

# Clear workspace
rm(list = ls())

# Set working directory to script location
if (!interactive()) {
  # Try to get script directory, fallback to current directory
  tryCatch({
    script_dir <- dirname(sys.frame(1)$ofile)
    setwd(script_dir)
  }, error = function(e) {
    # If script directory detection fails, stay in current directory
    cat("Note: Using current working directory\n")
  })
}

cat("=== Remimazolam PK/PD Simulator Launcher ===\n\n")

# Function to check if packages are installed
check_packages <- function(packages) {
  missing <- packages[!packages %in% rownames(installed.packages())]
  return(missing)
}

# Function to load packages safely
load_packages <- function(packages) {
  for (pkg in packages) {
    tryCatch({
      library(pkg, character.only = TRUE, quietly = TRUE)
      cat("✓ Loaded:", pkg, "\n")
    }, error = function(e) {
      cat("✗ Failed to load:", pkg, "-", e$message, "\n")
      return(FALSE)
    })
  }
  return(TRUE)
}

# Essential packages for the app
essential_packages <- c(
  "shiny",
  "shinydashboard", 
  "shinyWidgets",
  "DT",
  "plotly",
  "shinycssloaders",
  "shinyjs",
  "bslib",
  "R6"
)

# Check for missing packages
cat("Checking required packages...\n")
missing_packages <- check_packages(essential_packages)

if (length(missing_packages) > 0) {
  cat("\n❌ Missing packages detected:", paste(missing_packages, collapse = ", "), "\n")
  cat("Please run the following command to install missing packages:\n")
  cat("source('install_shiny_dependencies.R')\n\n")
  
  # Ask user if they want to install automatically
  if (interactive()) {
    install_now <- readline("Would you like to install missing packages now? (y/n): ")
    
    if (tolower(substr(install_now, 1, 1)) == "y") {
      cat("Installing missing packages...\n")
      tryCatch({
        source("install_shiny_dependencies.R")
        cat("✓ Packages installed successfully.\n")
      }, error = function(e) {
        cat("✗ Package installation failed:", e$message, "\n")
        cat("Please run 'source(\"install_shiny_dependencies.R\")' manually.\n")
        return()
      })
    } else {
      cat("Exiting. Please install required packages and try again.\n")
      return()
    }
  } else {
    return()
  }
}

# Load packages
cat("\nLoading packages...\n")
if (!load_packages(essential_packages)) {
  cat("✗ Failed to load some packages. Please check your installation.\n")
  return()
}

# Check if required source files exist
required_files <- c(
  "app.R",
  "R/constants.R",
  "R/data_models.R", 
  "R/pk_calculation_engine.R",
  "modules/patient_input_module.R",
  "modules/dosing_module.R",
  "modules/simulation_module.R",
  "modules/results_module.R",
  "modules/disclaimer_module.R"
)

cat("\nChecking required files...\n")
missing_files <- c()
for (file in required_files) {
  if (file.exists(file)) {
    cat("✓ Found:", file, "\n")
  } else {
    cat("✗ Missing:", file, "\n")
    missing_files <- c(missing_files, file)
  }
}

if (length(missing_files) > 0) {
  cat("\n❌ Missing required files. Please ensure all application files are present.\n")
  return()
}

# Display system information
cat("\n=== System Information ===\n")
cat("R version:", R.version.string, "\n")
cat("Platform:", R.version$platform, "\n")
cat("Working directory:", getwd(), "\n")

# Check Shiny version
shiny_version <- packageVersion("shiny")
cat("Shiny version:", as.character(shiny_version), "\n")

if (shiny_version < "1.7.0") {
  cat("⚠️  Warning: Shiny version is below recommended minimum (1.7.0)\n")
}

# Launch application
cat("\n=== Launching Application ===\n")
cat("Starting Remimazolam PK/PD Simulator...\n")
cat("The application will open in your default web browser.\n")
cat("To stop the application, press Ctrl+C (or Cmd+C on Mac) in this console.\n\n")

# Set options for better performance
options(
  shiny.maxRequestSize = 30*1024^2,  # 30MB max file size
  shiny.launch.browser = TRUE,       # Open browser automatically
  shiny.host = "127.0.0.1",         # Local host only
  shiny.port = NULL                  # Auto-select port
)

# Enhanced error handling
tryCatch({
  # Run the application
  shiny::runApp(
    appDir = ".",
    launch.browser = TRUE,
    host = getOption("shiny.host"),
    port = getOption("shiny.port")
  )
}, error = function(e) {
  cat("\n❌ Application failed to start:\n")
  cat("Error:", e$message, "\n")
  cat("\nTroubleshooting tips:\n")
  cat("1. Check that all required packages are installed\n")
  cat("2. Ensure all application files are present\n")
  cat("3. Try running: shiny::runApp('app.R') directly\n")
  cat("4. Check the console for detailed error messages\n")
}, interrupt = function(e) {
  cat("\n\n✅ Application stopped by user.\n")
  cat("Thank you for using Remimazolam PK/PD Simulator!\n")
}, finally = {
  # Cleanup
  cat("\nPerforming cleanup...\n")
})

cat("\n=== Session Complete ===\n")