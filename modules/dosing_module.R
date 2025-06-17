#' Dosing Schedule Module
#'
#' Shiny module for managing drug dosing schedules with dynamic table editing,
#' real-time validation, and preset dosing regimens. Supports both bolus and
#' continuous infusion dosing with clinical validation.
#'
#' @param id Module namespace ID
#' @param simulationEnabled Reactive value indicating if simulation is enabled
#'
#' @author Yasuhiro Suzuki

# UI function for dosing module
dosingModuleUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Preset dosing regimen selector
    div(
      class = "mb-3",
      selectInput(
        ns("preset_regimen"),
        label = tags$div(
          icon("prescription-bottle-alt"),
          "プリセット投与法"
        ),
        choices = list(
          "カスタム" = "custom",
          "標準導入" = "standard_induction",
          "緩徐導入" = "gentle_induction",
          "維持のみ" = "maintenance_only"
        ),
        selected = "custom",
        width = "100%"
      )
    ),
    
    # Quick add controls
    div(
      class = "row mb-3",
      div(
        class = "col-md-4",
        textInput(
          ns("quick_time"),
          label = "時刻 (H:MM または HH:MM)",
          value = "",
          placeholder = "例: 8:32, 13:45",
          width = "100%"
        )
      ),
      div(
        class = "col-md-4",
        numericInput(
          ns("quick_bolus"),
          label = "ボーラス(mg)",
          value = 0,
          min = 0,
          max = 100,
          step = 0.1,
          width = "100%"
        )
      ),
      div(
        class = "col-md-4",
        numericInput(
          ns("quick_continuous"),
          label = tags$div(
            "持続(mg/kg/hr)",
            tags$small("※0で投与中止", style = "color: #6c757d; display: block;")
          ),
          value = 0,
          min = 0,
          max = 20,
          step = 0.1,
          width = "100%"
        )
      )
    ),
    
    # Add/Clear buttons
    div(
      class = "mb-3 d-flex gap-2",
      actionButton(
        ns("add_dose"),
        label = tags$span(icon("plus"), "追加"),
        class = "btn-primary btn-sm"
      ),
      actionButton(
        ns("clear_all"),
        label = tags$span(icon("trash"), "全削除"),
        class = "btn-warning btn-sm"
      ),
      actionButton(
        ns("sort_doses"),
        label = tags$span(icon("sort"), "時間順"),
        class = "btn-info btn-sm"
      )
    ),
    
    # Dosing table
    div(
      class = "dosing-table",
      withSpinner(
        DT::DTOutput(ns("dosing_table")),
        type = 6,
        color = "#2c3e50"
      )
    ),
    
    # Validation messages
    div(
      id = ns("dosing_validation"),
      style = "margin-top: 10px;"
    ),
    
    # Dosing summary
    div(
      class = "mt-3",
      tags$button(
        class = "btn btn-outline-secondary btn-sm",
        type = "button",
        `data-bs-toggle` = "collapse",
        `data-bs-target` = paste0("#", ns("dosing_summary")),
        `aria-expanded` = "false",
        icon("chart-line"),
        "投与サマリー"
      ),
      div(
        class = "collapse mt-2",
        id = ns("dosing_summary"),
        div(
          class = "card card-body bg-light",
          verbatimTextOutput(ns("dosing_summary_text"))
        )
      )
    )
  )
}

# Server function for dosing module
dosingModuleServer <- function(id, simulationEnabled, patientData = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Helper function to format time display
    format_time_display <- function(time_minutes, patient = NULL) {
      if (is.null(patient) || is.null(patient$anesthesia_start_time)) {
        return(paste0(time_minutes, "分"))
      } else {
        clock_time <- patient$minutes_to_clock_time(time_minutes)
        return(format(clock_time, "%H:%M"))
      }
    }
    
    # Helper function to parse time input to minutes
    parse_time_input <- function(time_input, patient = NULL) {
      if (is.null(patient) || is.null(patient$anesthesia_start_time)) {
        # Fallback to minutes if no patient data
        return(as.numeric(time_input))
      }
      
      if (grepl("^([0-9]|[0-1][0-9]|2[0-3]):([0-5][0-9])$", time_input)) {
        # Parse as HH:MM format
        return(patient$clock_time_to_minutes(time_input))
      } else {
        # Try as numeric minutes
        return(as.numeric(time_input))
      }
    }
    
    # Reactive values for dosing data
    dosingData <- reactiveVal(data.frame(
      time_min = integer(0),
      bolus_mg = numeric(0),
      continuous_mg_kg_hr = numeric(0),
      stringsAsFactors = FALSE
    ))
    
    doseEvents <- reactiveVal(list())
    validationStatus <- reactiveVal(ValidationResult$new(TRUE))
    
    # Preset regimen definitions
    presetRegimens <- list(
      standard_induction = data.frame(
        time_min = c(0, 0, 5),
        bolus_mg = c(6, 0, 0),
        continuous_mg_kg_hr = c(0, 1.0, 0.5),
        stringsAsFactors = FALSE
      ),
      gentle_induction = data.frame(
        time_min = c(0, 0, 10),
        bolus_mg = c(3, 0, 0),
        continuous_mg_kg_hr = c(0, 0.5, 0.3),
        stringsAsFactors = FALSE
      ),
      maintenance_only = data.frame(
        time_min = c(0),
        bolus_mg = c(0),
        continuous_mg_kg_hr = c(0.2),
        stringsAsFactors = FALSE
      )
    )
    
    # Handle preset regimen selection
    observeEvent(input$preset_regimen, {
      req(simulationEnabled())
      
      if (input$preset_regimen != "custom" && input$preset_regimen %in% names(presetRegimens)) {
        dosingData(presetRegimens[[input$preset_regimen]])
        updateValidationAndEvents()
      }
    })
    
    # Add dose event
    observeEvent(input$add_dose, {
      req(simulationEnabled())
      
      # Get current patient for time conversion
      current_patient <- if (!is.null(patientData) && is.function(patientData$patient)) {
        patientData$patient()
      } else {
        NULL
      }
      
      # Validate and parse time input
      if (is.null(input$quick_time) || trimws(input$quick_time) == "") {
        showNotification("時刻を入力してください", type = "error", duration = 3)
        return()
      }
      
      time_minutes <- tryCatch({
        parse_time_input(input$quick_time, current_patient)
      }, error = function(e) {
        showNotification("時刻の形式が正しくありません (H:MM または HH:MM)", type = "error", duration = 3)
        return(NULL)
      })
      
      if (is.null(time_minutes) || is.na(time_minutes)) {
        showNotification("時刻の形式が正しくありません", type = "error", duration = 3)
        return()
      }
      
      # Validate dose inputs
      if (is.na(input$quick_bolus) || input$quick_bolus < 0 ||
          is.na(input$quick_continuous) || input$quick_continuous < 0) {
        showNotification("投与量が無効です", type = "error", duration = 3)
        return()
      }
      
      # Check if both bolus and continuous are zero (allow for stopping infusion)
      # Only show warning if this appears to be the first event (no existing doses)
      current_data <- dosingData()
      if (input$quick_bolus == 0 && input$quick_continuous == 0 && nrow(current_data) == 0) {
        showNotification("最初の投与イベントではボーラスまたは持続投与を入力してください", type = "warning", duration = 3)
        return()
      }
      
      # Add new row
      new_row <- data.frame(
        time_min = as.integer(time_minutes),
        bolus_mg = as.numeric(input$quick_bolus),
        continuous_mg_kg_hr = as.numeric(input$quick_continuous),
        stringsAsFactors = FALSE
      )
      
      updated_data <- rbind(current_data, new_row)
      dosingData(updated_data)
      
      # Show appropriate success message
      if (input$quick_bolus > 0 && input$quick_continuous > 0) {
        showNotification("ボーラス投与と持続投与を追加しました", type = "message", duration = 3)
      } else if (input$quick_bolus > 0) {
        showNotification("ボーラス投与を追加しました", type = "message", duration = 3)
      } else if (input$quick_continuous > 0) {
        showNotification("持続投与を開始しました", type = "message", duration = 3)
      } else {
        showNotification("投与を中止しました", type = "message", duration = 3)
      }
      
      # Reset quick inputs
      updateNumericInput(session, "quick_bolus", value = 0)
      updateNumericInput(session, "quick_continuous", value = 0)
      updateNumericInput(session, "quick_time", value = max(updated_data$time_min, 0) + 5)
      
      # Switch to custom if not already
      if (input$preset_regimen != "custom") {
        updateSelectInput(session, "preset_regimen", selected = "custom")
      }
      
      updateValidationAndEvents()
    })
    
    # Clear all doses
    observeEvent(input$clear_all, {
      req(simulationEnabled())
      
      showModal(modalDialog(
        title = "確認",
        "すべての投与データを削除しますか？",
        footer = tagList(
          modalButton("キャンセル"),
          actionButton(ns("confirm_clear"), "削除", class = "btn-danger")
        )
      ))
    })
    
    observeEvent(input$confirm_clear, {
      dosingData(data.frame(
        time_min = integer(0),
        bolus_mg = numeric(0),
        continuous_mg_kg_hr = numeric(0),
        stringsAsFactors = FALSE
      ))
      updateSelectInput(session, "preset_regimen", selected = "custom")
      removeModal()
      updateValidationAndEvents()
    })
    
    # Sort doses by time
    observeEvent(input$sort_doses, {
      req(simulationEnabled())
      
      current_data <- dosingData()
      if (nrow(current_data) > 1) {
        sorted_data <- current_data[order(current_data$time_min), ]
        dosingData(sorted_data)
        updateValidationAndEvents()
      }
    })
    
    # Render dosing table
    output$dosing_table <- DT::renderDT({
      req(simulationEnabled())
      
      data <- dosingData()
      
      if (nrow(data) == 0) {
        # Empty table
        empty_data <- data.frame(
          "時間(分)" = character(0),
          "ボーラス(mg)" = character(0),
          "持続(mg/kg/hr)" = character(0),
          stringsAsFactors = FALSE
        )
        
        return(DT::datatable(
          empty_data,
          options = list(
            dom = 't',
            ordering = FALSE,
            paging = FALSE,
            searching = FALSE,
            info = FALSE,
            language = list(emptyTable = "投与データがありません")
          ),
          rownames = FALSE,
          editable = FALSE,
          selection = 'none'
        ))
      }
      
      # Format data for display
      current_patient <- if (!is.null(patientData) && is.function(patientData$patient)) {
        patientData$patient()
      } else {
        NULL
      }
      
      time_display <- sapply(data$time_min, function(t) format_time_display(t, current_patient))
      
      display_data <- data.frame(
        "時刻" = time_display,
        "ボーラス(mg)" = sprintf("%.1f", data$bolus_mg),
        "持続(mg/kg/hr)" = sprintf("%.2f", data$continuous_mg_kg_hr),
        stringsAsFactors = FALSE
      )
      
      DT::datatable(
        display_data,
        options = list(
          dom = 't',
          ordering = FALSE,
          paging = FALSE,
          searching = FALSE,
          info = FALSE,
          scrollY = "200px",
          scrollCollapse = TRUE,
          language = list(
            emptyTable = "投与データがありません"
          )
        ),
        rownames = TRUE,
        editable = list(target = "cell", disable = list(columns = c(0))),
        selection = 'single'
      ) %>%
        DT::formatStyle(
          columns = 1:3,
          fontSize = '12px'
        )
    })
    
    # Handle cell editing
    observeEvent(input$dosing_table_cell_edit, {
      req(simulationEnabled())
      
      info <- input$dosing_table_cell_edit
      current_data <- dosingData()
      
      if (info$row <= nrow(current_data)) {
        tryCatch({
          new_value <- as.numeric(info$value)
          if (is.na(new_value) || new_value < 0) {
            showNotification("無効な値です", type = "error", duration = 3)
            return()
          }
          
          # Update data based on column
          if (info$col == 0) {  # Time column
            current_data$time_min[info$row] <- as.integer(new_value)
          } else if (info$col == 1) {  # Bolus column
            if (new_value > VALIDATION_LIMITS$dosing$maximum_bolus) {
              showNotification(paste("ボーラス投与量は", VALIDATION_LIMITS$dosing$maximum_bolus, "mg以下にしてください"), 
                             type = "error", duration = 3)
              return()
            }
            current_data$bolus_mg[info$row] <- new_value
          } else if (info$col == 2) {  # Continuous column
            if (new_value > VALIDATION_LIMITS$dosing$maximum_continuous) {
              showNotification(paste("持続投与量は", VALIDATION_LIMITS$dosing$maximum_continuous, "mg/kg/hr以下にしてください"), 
                             type = "error", duration = 3)
              return()
            }
            current_data$continuous_mg_kg_hr[info$row] <- new_value
          }
          
          dosingData(current_data)
          updateSelectInput(session, "preset_regimen", selected = "custom")
          updateValidationAndEvents()
          
        }, error = function(e) {
          showNotification("データ更新エラー", type = "error", duration = 3)
        })
      }
    })
    
    # Handle row deletion
    observeEvent(input$dosing_table_rows_selected, {
      req(simulationEnabled())
      
      if (length(input$dosing_table_rows_selected) > 0) {
        showModal(modalDialog(
          title = "行の削除",
          paste("選択した行を削除しますか？（行番号:", input$dosing_table_rows_selected, "）"),
          footer = tagList(
            modalButton("キャンセル"),
            actionButton(ns("confirm_delete_row"), "削除", class = "btn-danger")
          )
        ))
      }
    })
    
    observeEvent(input$confirm_delete_row, {
      req(input$dosing_table_rows_selected)
      
      current_data <- dosingData()
      if (input$dosing_table_rows_selected <= nrow(current_data)) {
        updated_data <- current_data[-input$dosing_table_rows_selected, ]
        dosingData(updated_data)
        updateSelectInput(session, "preset_regimen", selected = "custom")
        updateValidationAndEvents()
      }
      removeModal()
    })
    
    # Update validation and dose events
    updateValidationAndEvents <- function() {
      current_data <- dosingData()
      
      if (nrow(current_data) == 0) {
        validationStatus(ValidationResult$new(
          is_valid = FALSE,
          errors = "投与スケジュールが設定されていません"
        ))
        doseEvents(list())
        return()
      }
      
      # Create DoseEvent objects and validate
      events <- list()
      errors <- character(0)
      
      for (i in 1:nrow(current_data)) {
        tryCatch({
          dose_event <- DoseEvent$new(
            time_in_minutes = current_data$time_min[i],
            bolus_mg = current_data$bolus_mg[i],
            continuous_mg_kg_hr = current_data$continuous_mg_kg_hr[i]
          )
          
          validation <- dose_event$validate()
          if (!validation$is_valid) {
            errors <- c(errors, paste("行", i, ":", paste(validation$errors, collapse = ", ")))
          } else {
            events <- append(events, list(dose_event))
          }
          
        }, error = function(e) {
          errors <- c(errors, paste("行", i, ": データエラー -", e$message))
        })
      }
      
      # Update reactive values
      if (length(errors) == 0) {
        validationStatus(ValidationResult$new(TRUE))
        doseEvents(events)
      } else {
        validationStatus(ValidationResult$new(
          is_valid = FALSE,
          errors = errors
        ))
        doseEvents(list())
      }
    }
    
    # Display validation messages
    observe({
      validation <- validationStatus()
      
      if (validation$is_valid && length(doseEvents()) > 0) {
        html_content <- '<div class="success-text"><i class="fas fa-check-circle"></i> 投与スケジュールは有効です</div>'
      } else {
        error_messages <- paste(validation$errors, collapse = "<br>")
        html_content <- paste0('<div class="error-text"><i class="fas fa-exclamation-triangle"></i> ', error_messages, '</div>')
      }
      
      runjs(paste0(
        "document.getElementById('", ns("dosing_validation"), 
        "').innerHTML = '", html_content, "';"
      ))
    })
    
    # Dosing summary
    output$dosing_summary_text <- renderText({
      data <- dosingData()
      events <- doseEvents()
      
      if (nrow(data) == 0) {
        return("投与スケジュールが設定されていません")
      }
      
      total_bolus <- sum(data$bolus_mg, na.rm = TRUE)
      max_continuous <- max(data$continuous_mg_kg_hr, na.rm = TRUE)
      duration <- if (nrow(data) > 0) max(data$time_min, na.rm = TRUE) else 0
      
      paste(
        paste("投与イベント数:", nrow(data)),
        paste("総ボーラス投与量:", sprintf("%.1f mg", total_bolus)),
        paste("最大持続投与量:", sprintf("%.2f mg/kg/hr", max_continuous)),
        paste("投与期間:", duration, "分"),
        paste("有効イベント数:", length(events)),
        sep = "\n"
      )
    })
    
    # Return reactive values for other modules
    return(list(
      dose_events = doseEvents,
      is_valid = reactive({ validationStatus()$is_valid }),
      validation = validationStatus,
      summary = reactive({
        data <- dosingData()
        list(
          total_events = nrow(data),
          total_bolus = sum(data$bolus_mg, na.rm = TRUE),
          max_continuous = if (nrow(data) > 0) max(data$continuous_mg_kg_hr, na.rm = TRUE) else 0,
          duration = if (nrow(data) > 0) max(data$time_min, na.rm = TRUE) else 0
        )
      })
    ))
  })
}