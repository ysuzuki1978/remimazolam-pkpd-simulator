#' Disclaimer Module
#'
#' Shiny module for handling application disclaimer acceptance.
#' Ensures users acknowledge the educational nature of the application
#' and its limitations before using the simulation features.
#'
#' @param id Module namespace ID
#'
#' @author Yasuhiro Suzuki

# UI function for disclaimer module
disclaimerModuleUI <- function(id) {
  ns <- NS(id)
  
  # This module doesn't need visible UI elements
  # as it uses modals controlled by the main app
  tags$div()
}

# Server function for disclaimer module
disclaimerModuleServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    # Reactive value to track disclaimer acceptance
    disclaimerAccepted <- reactiveVal(FALSE)
    
    # Check if disclaimer was previously accepted in this session
    observe({
      # In a production app, you might want to store this in browser storage
      # or as a session variable
      session_accepted <- session$userData$disclaimer_accepted
      if (!is.null(session_accepted) && session_accepted) {
        disclaimerAccepted(TRUE)
      }
    })
    
    # Return list of reactive functions for parent to use
    return(list(
      accepted = disclaimerAccepted,
      accept = function() {
        disclaimerAccepted(TRUE)
        session$userData$disclaimer_accepted <- TRUE
        
        # Log acceptance for debugging
        if (DEBUG_CONSTANTS$enable_detailed_logging) {
          cat("Disclaimer accepted at:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
        }
      }
    ))
  })
}