#' Remimazolam Pharmacokinetic Simulator - Main Shiny Application
#'
#' A modern, responsive Shiny application for simulating remimazolam pharmacokinetics
#' based on the Masui 2022 population pharmacokinetic model.
#'
#' Features:
#' - Responsive UI with Bootstrap styling
#' - Modular architecture
#' - Real-time validation
#' - Interactive visualization
#' - CSV data export
#'
#' @author Yasuhiro Suzuki
#' @version 3.3.0 - Fixed midnight crossing calculation bug

# Load required libraries
library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(DT)
library(plotly)
library(shinycssloaders)
library(shinyjs)
library(R6)
library(bslib)

# Source application modules
source("R/constants.R")
source("R/data_models.R")
source("R/pk_calculation_engine_v2.R")
source("R/dosing_logic_v2.R")
source("modules/patient_input_module.R")
source("modules/dosing_module.R")
source("modules/simulation_module.R")
source("modules/results_module.R")
source("modules/disclaimer_module.R")

# Define UI
ui <- page_navbar(
  title = "Remimazolam PK/PD Simulator",
  theme = bs_theme(
    version = 5,
    bootswatch = "flatly",
    primary = "#2c3e50",
    secondary = "#34495e",
    success = "#27ae60",
    info = "#3498db",
    warning = "#f39c12",
    danger = "#e74c3c"
  ),
  
  # Add custom CSS and JavaScript
  tags$head(
    tags$style(HTML("
      .navbar-brand {
        font-weight: bold;
        font-size: 1.2em;
      }
      .card {
        margin-bottom: 20px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      }
      .card-header {
        background-color: #f8f9fa;
        border-bottom: 1px solid #dee2e6;
        font-weight: bold;
      }
      .error-text {
        color: #e74c3c;
        font-size: 0.9em;
        margin-top: 5px;
      }
      .success-text {
        color: #27ae60;
        font-size: 0.9em;
        margin-top: 5px;
      }
      .loading-overlay {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(255, 255, 255, 0.8);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 9999;
      }
      .dosing-table .form-control {
        padding: 0.25rem 0.5rem;
        font-size: 0.875rem;
      }
      .concentration-plot {
        height: 500px;
      }
      .summary-card {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        border: none;
      }
      .summary-card .card-body {
        padding: 1.5rem;
      }
      .stat-value {
        font-size: 2rem;
        font-weight: bold;
        display: block;
      }
      .stat-label {
        font-size: 0.9rem;
        opacity: 0.9;
      }
      @media (max-width: 768px) {
        .card {
          margin-bottom: 15px;
        }
        .concentration-plot {
          height: 400px;
        }
      }
    "))
  ),
  
  useShinyjs(),
  
  # Main simulation tab
  nav_panel(
    title = "シミュレーション",
    icon = icon("calculator"),
    
    # Disclaimer modal
    disclaimerModuleUI("disclaimer"),
    
    layout_columns(
      col_widths = c(4, 8),
      
      # Left panel - Input controls
      div(
        class = "input-panel",
        
        # Patient information card
        card(
          card_header("患者情報"),
          card_body(
            patientInputModuleUI("patient_input")
          )
        ),
        
        # Dosing schedule card
        card(
          card_header("投与スケジュール"),
          card_body(
            dosingModuleUI("dosing")
          )
        ),
        
        # Simulation controls
        card(
          card_header("シミュレーション制御"),
          card_body(
            simulationModuleUI("simulation")
          )
        )
      ),
      
      # Right panel - Results
      div(
        class = "results-panel",
        resultsModuleUI("results")
      )
    )
  ),
  
  # About tab
  nav_panel(
    title = "アプリについて",
    icon = icon("info-circle"),
    
    div(
      class = "container-fluid",
      style = "max-width: 800px; margin: 0 auto; padding: 20px;",
      
      card(
        card_header("Remimazolam PK/PD Simulator について"),
        card_body(
          h4("概要"),
          p("本アプリケーションは、レミマゾラムの薬物動態シミュレーションを行う教育・研究用ツールです。"),
          p("Masui 2022年の母集団薬物動態モデルに基づいて、患者個別の薬物動態パラメータを計算し、
            血漿中および効果部位濃度の時間推移をシミュレーションします。"),
          
          h4("特徴"),
          tags$ul(
            tags$li("個別化薬物動態パラメータの計算"),
            tags$li("高精度数値積分（4次Runge-Kutta法）"),
            tags$li("リアルタイム濃度推移表示"),
            tags$li("CSV形式でのデータエクスポート"),
            tags$li("レスポンシブデザイン対応")
          ),
          
          h4("参考文献"),
          tags$ol(
            tags$li("Masui, K., et al. (2022). A population pharmacokinetic model of remimazolam for general anesthesia and consideration of remimazolam dose in clinical practice. Journal of Anesthesia, 36(4), 493-505. doi:10.1007/s00540-022-03079-y"),
            tags$li("Masui, K., & Hagihira, S. (2022). Equilibration rate constant, ke0, to determine effect-site concentration for the Masui remimazolam population pharmacokinetic model in general anesthesia patients. Journal of Anesthesia, 36(6), 733-742. doi:10.1007/s00540-022-03099-8")
          ),
          
          h4("免責事項"),
          div(
            class = "alert alert-warning",
            HTML("<strong>重要:</strong> 本アプリケーションは教育・研究目的のシミュレーションツールです。
                 実際の臨床判断には使用しないでください。すべての臨床判断は、
                 資格を持つ医療専門家の責任において行われるべきです。")
          ),
          
          h4("既知の問題"),
          div(
            class = "alert alert-info",
            HTML("<strong>日をまたぐ投与スケジュール:</strong> 麻酔開始時刻から24時間を超える投与スケジュールにおいて、
                 グラフ表示で時刻軸の表示が正しくない場合があります。ただし、薬物濃度の予測計算は正常に実行されており、
                 CSVデータ出力では正確な時刻と濃度値が記録されます。")
          ),
          
          h4("開発情報"),
          div(
            class = "row",
            div(
              class = "col-md-6",
              h5("開発者"),
              p(strong(APP_CONSTANTS$developer_name)),
              tags$ul(
                class = "list-unstyled",
                tags$li(icon("hospital"), " ", APP_CONSTANTS$developer_affiliations[1]),
                tags$li(icon("university"), " ", APP_CONSTANTS$developer_affiliations[2])
              )
            ),
            div(
              class = "col-md-6",
              h5("技術情報"),
              p(icon("code"), " ", APP_CONSTANTS$development_language),
              p(icon("robot"), " ", APP_CONSTANTS$development_tools),
              p(icon("tag"), " バージョン: ", APP_CONSTANTS$version),
              p(icon("calendar"), " ", APP_CONSTANTS$copyright)
            )
          ),
          
          hr(),
          
          div(
            class = "text-center",
            p(
              class = "text-muted",
              style = "font-size: 0.9em;",
              APP_CONSTANTS$app_purpose
            )
          )
        )
      )
    )
  ),
  
  nav_spacer(),
  
  nav_item(
    tags$a(
      href = "https://github.com/ysuzuki1978/remimazolam-pkpd-simulator",
      target = "_blank",
      icon("github"),
      "GitHub"
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # Initialize disclaimer
  disclaimerResult <- disclaimerModuleServer("disclaimer")
  
  # Show disclaimer on app start
  observe({
    if (!disclaimerResult$accepted()) {
      showModal(
        modalDialog(
          title = DISCLAIMER_CONSTANTS$title,
          DISCLAIMER_CONSTANTS$full_text,
          footer = tagList(
            actionButton("accept_disclaimer", DISCLAIMER_CONSTANTS$accept_button_title, 
                        class = "btn-primary")
          ),
          easyClose = FALSE,
          fade = TRUE,
          size = "l"
        )
      )
    }
  })
  
  # Handle disclaimer acceptance
  observeEvent(input$accept_disclaimer, {
    disclaimerResult$accept()
    removeModal()
  })
  
  # Reactive value to store simulation enabled state
  simulationEnabled <- reactive({
    disclaimerResult$accepted()
  })
  
  # Initialize modules
  patientData <- patientInputModuleServer("patient_input", simulationEnabled)
  dosingData <- dosingModuleServer("dosing", simulationEnabled, patientData)
  simulationControl <- simulationModuleServer("simulation", patientData, dosingData, simulationEnabled)
  resultsModuleServer("results", simulationControl$results, simulationEnabled, patientData)
  
  # Debug mode information
  if (DEBUG_CONSTANTS$is_debug_mode) {
    observe({
      cat("=== Debug Information ===\n")
      cat("Patient data valid:", patientData$is_valid(), "\n")
      cat("Dosing data valid:", dosingData$is_valid(), "\n")
      cat("Simulation enabled:", simulationEnabled(), "\n")
      if (DEBUG_CONSTANTS$enable_detailed_logging && !is.null(simulationControl$results())) {
        result <- simulationControl$results()
        if (!is.null(result)) {
          cat("Simulation duration:", result$get_simulation_duration_minutes(), "min\n")
          cat("Max plasma conc:", result$get_max_plasma_concentration(), "µg/mL\n")
          cat("Max effect-site conc:", result$get_max_effect_site_concentration(), "µg/mL\n")
        }
      }
      cat("========================\n")
    })
  }
}

# Run the application
shinyApp(ui = ui, server = server)