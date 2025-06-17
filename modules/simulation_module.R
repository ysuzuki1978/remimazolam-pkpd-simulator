#' Simulation Control Module
#'
#' Shiny module for controlling pharmacokinetic simulations with progress tracking,
#' error handling, and result management. Integrates patient data and dosing schedules
#' with the PK calculation engine.
#'
#' @param id Module namespace ID
#' @param patientData Reactive patient data from patient input module
#' @param dosingData Reactive dosing data from dosing module
#' @param simulationEnabled Reactive value indicating if simulation is enabled
#'
#' @author Yasuhiro Suzuki

# UI function for simulation control module
simulationModuleUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Simulation status
    div(
      id = ns("simulation_status"),
      class = "mb-3",
      style = "min-height: 60px; padding: 15px; border: 1px solid #dee2e6; border-radius: 5px; background-color: #f8f9fa;",
      div(
        style = "display: flex; align-items: center; justify-content: center;",
        icon("info-circle", style = "color: #6c757d; margin-right: 10px;"),
        span("シミュレーション準備中...", style = "color: #6c757d;")
      )
    ),
    
    # Simulation button
    div(
      class = "d-grid gap-2 mb-3",
      actionButton(
        ns("run_simulation"),
        label = tags$div(
          icon("play-circle", style = "margin-right: 8px;"),
          "シミュレーション実行"
        ),
        class = "btn-success btn-lg",
        style = "font-weight: bold;",
        disabled = TRUE
      )
    ),
    
    # Advanced options (collapsible)
    div(
      class = "mb-3",
      tags$button(
        class = "btn btn-outline-secondary btn-sm",
        type = "button",
        `data-bs-toggle` = "collapse",
        `data-bs-target` = paste0("#", ns("advanced_options")),
        `aria-expanded` = "false",
        icon("cog"),
        "詳細設定"
      ),
      div(
        class = "collapse mt-2",
        id = ns("advanced_options"),
        div(
          class = "card card-body",
          
          # Simulation duration
          numericInput(
            ns("simulation_duration"),
            label = tags$div(
              icon("clock"),
              "シミュレーション時間延長 (分)",
              tags$small("(最終投与後の追加時間)", style = "color: #6c757d;")
            ),
            value = 120,
            min = 60,
            max = 480,
            step = 30,
            width = "100%"
          ),
          
          # Integration precision
          selectInput(
            ns("integration_precision"),
            label = tags$div(
              icon("calculator"),
              "積分精度"
            ),
            choices = list(
              "標準 (0.1分)" = 0.1,
              "高精度 (0.05分)" = 0.05,
              "最高精度 (0.01分)" = 0.01
            ),
            selected = 0.1,
            width = "100%"
          ),
          
          # Calculation engine selection
          selectInput(
            ns("calculation_engine"),
            label = tags$div(
              icon("microchip"),
              "計算エンジン"
            ),
            choices = list(
              "V2 標準 (deSolve)" = "v2",
              "V3 比較 (複数手法)" = "v3"
            ),
            selected = "v2",
            width = "100%"
          ),
          
          # Debug mode
          checkboxInput(
            ns("debug_mode"),
            label = "デバッグモード",
            value = DEBUG_CONSTANTS$is_debug_mode
          )
        )
      )
    ),
    
    # Progress bar (hidden initially)
    div(
      id = ns("progress_container"),
      style = "display: none;",
      div(
        class = "progress mb-3",
        style = "height: 25px;",
        div(
          id = ns("progress_bar"),
          class = "progress-bar progress-bar-striped progress-bar-animated",
          role = "progressbar",
          style = "width: 0%",
          `aria-valuenow` = "0",
          `aria-valuemin` = "0",
          `aria-valuemax` = "100",
          "0%"
        )
      )
    ),
    
    # Last simulation info
    div(
      id = ns("last_simulation_info"),
      class = "mt-3",
      style = "display: none;",
      div(
        class = "card",
        div(
          class = "card-header",
          style = "background-color: #e9ecef;",
          tags$strong("最終シミュレーション情報")
        ),
        div(
          class = "card-body",
          style = "font-size: 0.9em;",
          div(id = ns("simulation_details"))
        )
      )
    )
  )
}

# Server function for simulation control module
simulationModuleServer <- function(id, patientData, dosingData, simulationEnabled) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Reactive values
    simulationResults <- reactiveVal(NULL)
    isSimulationReady <- reactiveVal(FALSE)
    simulationInProgress <- reactiveVal(FALSE)
    
    # PK calculation engines
    pkEngineV2 <- PKCalculationEngineV2$new()
    pkEngineV3 <- NULL  # Initialize on demand
    
    # Check if simulation is ready
    observe({
      ready <- simulationEnabled() && 
               !is.null(patientData$patient()) && 
               patientData$is_valid() && 
               !is.null(dosingData$dose_events()) && 
               length(dosingData$dose_events()) > 0 && 
               dosingData$is_valid()
      
      isSimulationReady(ready)
      
      # Update simulation button state
      if (ready && !simulationInProgress()) {
        enable("run_simulation")
        updateActionButton(session, "run_simulation", 
                          label = tags$div(
                            icon("play-circle", style = "margin-right: 8px;"),
                            "シミュレーション実行"
                          ))
      } else {
        disable("run_simulation")
      }
    })
    
    # Update simulation status display
    observe({
      if (!simulationEnabled()) {
        status_html <- '
          <div style="display: flex; align-items: center; justify-content: center;">
            <i class="fas fa-lock" style="color: #dc3545; margin-right: 10px;"></i>
            <span style="color: #dc3545;">免責事項への同意が必要です</span>
          </div>'
      } else if (simulationInProgress()) {
        status_html <- '
          <div style="display: flex; align-items: center; justify-content: center;">
            <div class="spinner-border spinner-border-sm" role="status" style="margin-right: 10px;"></div>
            <span style="color: #007bff;">シミュレーション実行中...</span>
          </div>'
      } else if (isSimulationReady()) {
        status_html <- '
          <div style="display: flex; align-items: center; justify-content: center;">
            <i class="fas fa-check-circle" style="color: #28a745; margin-right: 10px;"></i>
            <span style="color: #28a745;">シミュレーション準備完了</span>
          </div>'
      } else {
        errors <- c()
        if (is.null(patientData$patient()) || !patientData$is_valid()) {
          errors <- c(errors, "患者データが無効")
        }
        if (is.null(dosingData$dose_events()) || length(dosingData$dose_events()) == 0 || !dosingData$is_valid()) {
          errors <- c(errors, "投与データが無効")
        }
        
        error_text <- paste(errors, collapse = ", ")
        status_html <- paste0('
          <div style="display: flex; align-items: center; justify-content: center;">
            <i class="fas fa-exclamation-triangle" style="color: #ffc107; margin-right: 10px;"></i>
            <span style="color: #ffc107;">', error_text, '</span>
          </div>')
      }
      
      runjs(paste0("document.getElementById('", ns("simulation_status"), "').innerHTML = '", status_html, "';"))
    })
    
    # Run simulation
    observeEvent(input$run_simulation, {
      req(isSimulationReady(), !simulationInProgress())
      
      # Start simulation
      simulationInProgress(TRUE)
      disable("run_simulation")
      
      # Show progress bar
      runjs(paste0("document.getElementById('", ns("progress_container"), "').style.display = 'block';"))
      
      # Update progress
      updateProgress <- function(value, detail = "") {
        runjs(paste0(
          "var bar = document.getElementById('", ns("progress_bar"), "');",
          "bar.style.width = '", value, "%';",
          "bar.setAttribute('aria-valuenow', '", value, "');",
          "bar.innerHTML = '", value, "%';",
          if (detail != "") paste0("console.log('Simulation: ", detail, "');") else ""
        ))
      }
      
      tryCatch({
        updateProgress(10, "患者データ準備中...")
        patient <- patientData$patient()
        
        updateProgress(20, "投与データ準備中...")
        dose_events <- dosingData$dose_events()
        
        updateProgress(30, "薬物動態パラメータ計算中...")
        Sys.sleep(0.1)  # Small delay for UI responsiveness
        
        updateProgress(50, "シミュレーション実行中...")
        
        # Select and run the appropriate simulation engine
        start_time <- Sys.time()
        
        if (input$calculation_engine == "v3") {
          # Initialize V3 engine if needed
          if (is.null(pkEngineV3)) {
            source("R/pk_calculation_engine_v3.R")
            pkEngineV3 <<- PKCalculationEngineV3$new()
          }
          result <- pkEngineV3$perform_simulation(patient, dose_events)
        } else {
          # Use V2 engine (default)
          result <- pkEngineV2$perform_simulation(patient, dose_events)
        }
        
        end_time <- Sys.time()
        
        updateProgress(80, "結果処理中...")
        
        # Store results
        simulationResults(result)
        
        updateProgress(100, "完了")
        
        # Calculate simulation metrics
        calculation_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
        
        # Update last simulation info
        details_html <- paste0(
          "<strong>実行時間:</strong> ", sprintf("%.2f", calculation_time), " 秒<br>",
          "<strong>シミュレーション期間:</strong> ", result$get_simulation_duration_minutes(), " 分<br>",
          "<strong>データポイント数:</strong> ", length(result$time_points), " 点<br>",
          "<strong>最大血漿中濃度:</strong> ", sprintf("%.3f", result$get_max_plasma_concentration()), " µg/mL<br>",
          "<strong>最大効果部位濃度:</strong> ", sprintf("%.3f", result$get_max_effect_site_concentration()), " µg/mL<br>",
          "<strong>計算日時:</strong> ", format(result$calculated_at, "%Y-%m-%d %H:%M:%S")
        )
        
        runjs(paste0(
          "document.getElementById('", ns("simulation_details"), "').innerHTML = '", details_html, "';",
          "document.getElementById('", ns("last_simulation_info"), "').style.display = 'block';"
        ))
        
        # Show success notification
        showNotification(
          "シミュレーションが正常に完了しました",
          type = "message",
          duration = 5
        )
        
        # Debug output
        if (input$debug_mode && DEBUG_CONSTANTS$show_calculation_details) {
          cat("=== Simulation Debug Info ===\n")
          cat("Patient ID:", patient$id, "\n")
          cat("Dose events:", length(dose_events), "\n")
          cat("Calculation time:", calculation_time, "seconds\n")
          cat("Max Cp:", result$get_max_plasma_concentration(), "µg/mL\n")
          cat("Max Ce:", result$get_max_effect_site_concentration(), "µg/mL\n")
          cat("===============================\n")
        }
        
      }, error = function(e) {
        # Handle simulation errors
        simulationResults(NULL)
        
        error_message <- paste("シミュレーションエラー:", e$message)
        
        runjs(paste0(
          "document.getElementById('", ns("simulation_details"), "').innerHTML = '",
          "<span style=\"color: #dc3545;\"><i class=\"fas fa-exclamation-triangle\"></i> ",
          error_message, "</span>';",
          "document.getElementById('", ns("last_simulation_info"), "').style.display = 'block';"
        ))
        
        showNotification(
          error_message,
          type = "error",
          duration = 10
        )
        
        # Log error for debugging
        if (DEBUG_CONSTANTS$enable_detailed_logging) {
          cat("=== Simulation Error ===\n")
          cat("Error message:", e$message, "\n")
          cat("Error call:", deparse(e$call), "\n")
          cat("========================\n")
        }
        
      }, finally = {
        # Cleanup
        simulationInProgress(FALSE)
        
        # Hide progress bar after delay
        Sys.sleep(0.5)
        runjs(paste0("document.getElementById('", ns("progress_container"), "').style.display = 'none';"))
        
        # Re-enable button if simulation is ready
        if (isSimulationReady()) {
          enable("run_simulation")
          updateActionButton(session, "run_simulation", 
                            label = tags$div(
                              icon("play-circle", style = "margin-right: 8px;"),
                              "シミュレーション実行"
                            ))
        }
      })
    })
    
    # Return reactive values for other modules
    return(list(
      results = simulationResults,
      is_ready = isSimulationReady,
      in_progress = simulationInProgress,
      run_simulation = reactive({ input$run_simulation })
    ))
  })
}