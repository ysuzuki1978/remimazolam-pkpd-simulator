# Install Required Dependencies for Remimazolam PKPD Package
#
# This script ensures all required R packages are installed for the
# remimazolam pharmacokinetic calculation engine.

cat("=== Installing Remimazolam PKPD Package Dependencies ===\n\n")

# Required packages
required_packages <- c(
  "R6",        # Object-oriented programming framework
  "deSolve",   # Solving differential equations (backup for verification)
  "testthat",  # Unit testing framework
  "devtools",  # Package development tools
  "roxygen2",  # Documentation generation
  "knitr",     # Dynamic report generation
  "rmarkdown"  # R Markdown support
)

# Function to check and install packages
install_if_missing <- function(packages) {
  for (pkg in packages) {
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
      cat(sprintf("Installing package: %s\n", pkg))
      install.packages(pkg, dependencies = TRUE, repos = "https://cran.r-project.org/")
      
      # Verify installation
      if (require(pkg, character.only = TRUE, quietly = TRUE)) {
        cat(sprintf("✓ Successfully installed: %s\n", pkg))
      } else {
        cat(sprintf("✗ Failed to install: %s\n", pkg))
      }
    } else {
      cat(sprintf("✓ Already installed: %s\n", pkg))
    }
  }
}

# Install packages
cat("Checking and installing required packages...\n")
install_if_missing(required_packages)

cat("\n=== Dependency Installation Complete ===\n")

# Verify R6 functionality
cat("\nTesting R6 functionality...\n")
library(R6)

TestClass <- R6Class(
  "TestClass",
  public = list(
    value = NULL,
    initialize = function(value = 0) {
      self$value <- value
    },
    get_value = function() {
      return(self$value)
    }
  )
)

test_obj <- TestClass$new(42)
if (test_obj$get_value() == 42) {
  cat("✓ R6 is working correctly\n")
} else {
  cat("✗ R6 test failed\n")
}

# Check R version
cat(sprintf("\nR version: %s\n", R.version.string))
cat(sprintf("Platform: %s\n", R.version$platform))

# Display session info
cat("\n=== Session Information ===\n")
sessionInfo()

cat("\n=== Setup Complete ===\n")
cat("You can now run the remimazolam PKPD calculations.\n")
cat("Example: source('R/example_usage.R'); run_example_simulation()\n")