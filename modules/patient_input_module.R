#' Patient Input Module
#'
#' Shiny module for handling patient information input with real-time validation
#' and responsive design. Provides a clean interface for entering patient demographics
#' and clinical characteristics.
#'
#' @param id Module namespace ID
#' @param simulationEnabled Reactive value indicating if simulation is enabled
#'
#' @author Yasuhiro Suzuki

# UI function for patient input module
patientInputModuleUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Patient ID
    textInput(
      ns("patient_id"),
      label = tags$div(
        icon("user"),
        "患者ID",
        tags$span("*", style = "color: red;")
      ),
      placeholder = "例: P001",
      width = "100%"
    ),
    
    # Age input
    numericInput(
      ns("age"),
      label = tags$div(
        icon("calendar-alt"),
        "年齢",
        tags$span("*", style = "color: red;"),
        tags$small("(18-100歳)", style = "color: #6c757d;")
      ),
      value = 50,
      min = VALIDATION_LIMITS$patient$minimum_age,
      max = VALIDATION_LIMITS$patient$maximum_age,
      step = 1,
      width = "100%"
    ),
    
    # Weight and Height in a row
    fluidRow(
      column(6,
        numericInput(
          ns("weight"),
          label = tags$div(
            icon("weight"),
            "体重 (kg)",
            tags$span("*", style = "color: red;")
          ),
          value = 70,
          min = VALIDATION_LIMITS$patient$minimum_weight,
          max = VALIDATION_LIMITS$patient$maximum_weight,
          step = 0.1,
          width = "100%"
        )
      ),
      column(6,
        numericInput(
          ns("height"),
          label = tags$div(
            icon("ruler-vertical"),
            "身長 (cm)",
            tags$span("*", style = "color: red;")
          ),
          value = 170,
          min = VALIDATION_LIMITS$patient$minimum_height,
          max = VALIDATION_LIMITS$patient$maximum_height,
          step = 0.1,
          width = "100%"
        )
      )
    ),
    
    # Sex selection
    radioButtons(
      ns("sex"),
      label = tags$div(
        icon("venus-mars"),
        "性別",
        tags$span("*", style = "color: red;")
      ),
      choices = list(
        "男性" = SexType$MALE,
        "女性" = SexType$FEMALE
      ),
      selected = SexType$MALE,
      inline = TRUE
    ),
    
    # ASA Physical Status
    radioButtons(
      ns("asa_ps"),
      label = tags$div(
        icon("heartbeat"),
        "ASA分類",
        tags$span("*", style = "color: red;")
      ),
      choices = list(
        "ASA I-II" = AsapsType$CLASS1_2,
        "ASA III-IV" = AsapsType$CLASS3_4
      ),
      selected = AsapsType$CLASS1_2,
      inline = TRUE
    ),
    
    # Anesthesia Start Time
    div(
      class = "mb-3",
      tags$label(
        class = "form-label",
        tags$div(
          icon("clock"),
          "麻酔開始時刻",
          tags$span("*", style = "color: red;"),
          tags$small("(H:MM または HH:MM形式)", style = "color: #6c757d; margin-left: 5px;")
        )
      ),
      textInput(
        ns("anesthesia_start_time"),
        label = NULL,
        value = format(Sys.time(), "%H:%M"),
        placeholder = "例: 8:30, 13:45",
        width = "100%"
      ),
      tags$small(
        style = "color: #6c757d;",
        "※ この時刻を基準として投与スケジュールの時刻が設定されます"
      )
    ),
    
    # Calculated BMI display
    div(
      class = "mt-3 p-2 bg-light rounded",
      style = "border: 1px solid #dee2e6;",
      tags$strong("計算値:"),
      br(),
      div(
        style = "font-size: 1.1em; margin-top: 5px;",
        tags$span("BMI: "),
        tags$span(
          id = ns("bmi_display"),
          style = "font-weight: bold; color: #2c3e50;",
          "--"
        ),
        tags$span(" kg/m²")
      )
    ),
    
    # Validation messages
    div(
      id = ns("validation_messages"),
      style = "margin-top: 10px;"
    ),
    
    # Patient data summary (collapsible)
    div(
      class = "mt-3",
      tags$button(
        class = "btn btn-outline-secondary btn-sm",
        type = "button",
        `data-bs-toggle` = "collapse",
        `data-bs-target` = paste0("#", ns("patient_summary")),
        `aria-expanded` = "false",
        icon("eye"),
        "データ確認"
      ),
      div(
        class = "collapse mt-2",
        id = ns("patient_summary"),
        div(
          class = "card card-body bg-light",
          style = "font-size: 0.9em;",
          verbatimTextOutput(ns("patient_summary_text"))
        )
      )
    )
  )
}

# Server function for patient input module
patientInputModuleServer <- function(id, simulationEnabled) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Reactive value to store current patient data
    currentPatient <- reactiveVal(NULL)
    
    # Reactive value for validation status
    validationStatus <- reactiveVal(ValidationResult$new(FALSE))
    
    # Calculate and display BMI
    observeEvent(list(input$weight, input$height), {
      req(input$weight, input$height)
      
      if (is.numeric(input$weight) && is.numeric(input$height) && 
          input$weight > 0 && input$height > 0) {
        bmi <- input$weight / (input$height / 100)^2
        
        # Update BMI display with color coding
        bmi_color <- if (bmi < 18.5) "#e74c3c" else if (bmi > 25) "#f39c12" else "#27ae60"
        
        runjs(paste0(
          "document.getElementById('", ns("bmi_display"), "').innerHTML = '", 
          sprintf("%.1f", bmi), 
          "'; document.getElementById('", ns("bmi_display"), 
          "').style.color = '", bmi_color, "';"
        ))
      } else {
        runjs(paste0(
          "document.getElementById('", ns("bmi_display"), "').innerHTML = '--'; ",
          "document.getElementById('", ns("bmi_display"), "').style.color = '#6c757d';"
        ))
      }
    }, ignoreInit = FALSE, ignoreNULL = FALSE)
    
    # Create patient object and validate when inputs change
    observe({
      req(simulationEnabled())
      
      # Check if all required inputs are available
      if (!is.null(input$patient_id) && !is.null(input$age) && 
          !is.null(input$weight) && !is.null(input$height) &&
          !is.null(input$sex) && !is.null(input$asa_ps) &&
          !is.null(input$anesthesia_start_time)) {
        
        tryCatch({
          # Validate anesthesia start time format - allow both H:MM and HH:MM
          start_time_valid <- grepl("^([0-9]|[0-1][0-9]|2[0-3]):([0-5][0-9])$", input$anesthesia_start_time)
          
          if (!start_time_valid) {
            stop("麻酔開始時刻は H:MM または HH:MM 形式で入力してください")
          }
          
          # Create patient object
          patient <- Patient$new(
            id = input$patient_id,
            age = input$age,
            weight = input$weight,
            height = input$height,
            sex = input$sex,
            asa_ps = input$asa_ps,
            anesthesia_start_time = input$anesthesia_start_time
          )
          
          # Validate patient data
          validation <- patient$validate()
          
          # Update reactive values
          currentPatient(patient)
          validationStatus(validation)
          
        }, error = function(e) {
          # Handle errors in patient creation
          validationStatus(ValidationResult$new(
            is_valid = FALSE,
            errors = paste("患者データエラー:", e$message)
          ))
          currentPatient(NULL)
        })
      } else {
        # Required inputs missing
        validationStatus(ValidationResult$new(
          is_valid = FALSE,
          errors = "必須項目が入力されていません"
        ))
        currentPatient(NULL)
      }
    })
    
    # Display validation messages
    observe({
      validation <- validationStatus()
      
      if (validation$is_valid) {
        html_content <- '<div class="success-text"><i class="fas fa-check-circle"></i> 患者データは有効です</div>'
      } else {
        error_messages <- paste(validation$errors, collapse = "<br>")
        html_content <- paste0('<div class="error-text"><i class="fas fa-exclamation-triangle"></i> ', error_messages, '</div>')
      }
      
      # Update validation messages div
      runjs(paste0(
        "document.getElementById('", ns("validation_messages"), 
        "').innerHTML = '", html_content, "';"
      ))
    })
    
    # Patient summary output
    output$patient_summary_text <- renderText({
      patient <- currentPatient()
      if (is.null(patient)) {
        return("患者データが設定されていません")
      }
      
      paste(
        paste("患者ID:", patient$id),
        paste("年齢:", patient$age, "歳"),
        paste("体重:", sprintf("%.1f", patient$weight), "kg"),
        paste("身長:", sprintf("%.1f", patient$height), "cm"),
        paste("性別:", if (patient$sex == SexType$MALE) "男性" else "女性"),
        paste("ASA分類:", if (patient$asa_ps == AsapsType$CLASS1_2) "ASA I-II" else "ASA III-IV"),
        paste("BMI:", sprintf("%.1f", patient$get_bmi()), "kg/m²"),
        paste("調整体重:", sprintf("%.1f", patient$get_adjusted_body_weight()), "kg"),
        sep = "\n"
      )
    })
    
    # Return reactive values for other modules to use
    return(list(
      patient = currentPatient,
      is_valid = reactive({ validationStatus()$is_valid }),
      validation = validationStatus
    ))
  })
}