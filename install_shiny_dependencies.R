# Install dependencies for remimazolamPKPD Shiny application
#
# This script installs all required packages for the remimazolamPKPD Shiny app.
# Run this script before launching the application.

# Core R packages for PK calculations
core_packages <- c(
  "R6",
  "deSolve"
)

# Shiny and UI packages
shiny_packages <- c(
  "shiny",
  "shinydashboard",
  "shinyWidgets", 
  "DT",
  "plotly",
  "shinycssloaders",
  "shinyjs",
  "bslib",
  "htmltools"
)

# Development and testing packages
dev_packages <- c(
  "testthat",
  "knitr",
  "rmarkdown"
)

# All required packages
all_packages <- c(core_packages, shiny_packages, dev_packages)

# Function to check and install missing packages
install_if_missing <- function(packages, category = "") {
  missing_packages <- packages[!packages %in% rownames(installed.packages())]
  
  if (length(missing_packages) > 0) {
    cat("Installing", category, "packages:", paste(missing_packages, collapse = ", "), "\n")
    tryCatch({
      install.packages(missing_packages, dependencies = TRUE)
      cat("Successfully installed", category, "packages.\n")
    }, error = function(e) {
      cat("Error installing", category, "packages:", e$message, "\n")
      return(FALSE)
    })
  } else {
    cat("All", category, "packages are already installed.\n")
  }
  return(TRUE)
}

# Function to check package versions
check_versions <- function() {
  cat("\n=== Package Version Check ===\n")
  
  # Check critical packages and their versions
  critical_packages <- c("shiny", "bslib", "DT", "plotly", "R6")
  
  for (pkg in critical_packages) {
    if (pkg %in% rownames(installed.packages())) {
      version <- packageVersion(pkg)
      cat(sprintf("%-15s: %s\n", pkg, version))
    } else {
      cat(sprintf("%-15s: NOT INSTALLED\n", pkg))
    }
  }
  
  # Check for minimum versions
  if ("shiny" %in% rownames(installed.packages())) {
    shiny_version <- packageVersion("shiny")
    if (shiny_version < "1.7.0") {
      cat("\nWARNING: Shiny version", shiny_version, "is below recommended minimum (1.7.0)\n")
      cat("Please update with: install.packages('shiny')\n")
    }
  }
  
  if ("bslib" %in% rownames(installed.packages())) {
    bslib_version <- packageVersion("bslib")
    if (bslib_version < "0.4.0") {
      cat("\nWARNING: bslib version", bslib_version, "is below recommended minimum (0.4.0)\n")
      cat("Please update with: install.packages('bslib')\n")
    }
  }
}

# Main installation process
cat("=== Remimazolam PKPD Shiny App - Dependency Installation ===\n\n")

cat("Installing core PK calculation packages...\n")
success1 <- install_if_missing(core_packages, "core")

cat("\nInstalling Shiny and UI packages...\n")
success2 <- install_if_missing(shiny_packages, "Shiny/UI")

cat("\nInstalling development packages...\n")
success3 <- install_if_missing(dev_packages, "development")

# Check versions
check_versions()

# Test critical functionality
cat("\n=== Functionality Test ===\n")

test_packages <- c("shiny", "R6", "DT", "plotly", "bslib")
all_loaded <- TRUE

for (pkg in test_packages) {
  tryCatch({
    library(pkg, character.only = TRUE)
    cat("✓", pkg, "loaded successfully\n")
  }, error = function(e) {
    cat("✗", pkg, "failed to load:", e$message, "\n")
    all_loaded <- FALSE
  })
}

if (all_loaded) {
  cat("\n✓ All critical packages loaded successfully!\n")
  cat("You can now run the Shiny application with: shiny::runApp('app.R')\n")
} else {
  cat("\n✗ Some packages failed to load. Please check the errors above.\n")
}

# Clean up
rm(list = ls())
cat("\nDependency installation completed.\n")