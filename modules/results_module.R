#' Results Display Module
#'
#' Shiny module for displaying simulation results with interactive plots,
#' data tables, and export functionality. Provides comprehensive visualization
#' of pharmacokinetic simulation results.
#'
#' @param id Module namespace ID
#' @param simulationResults Reactive simulation results
#' @param simulationEnabled Reactive value indicating if simulation is enabled
#'
#' @author Yasuhiro Suzuki

# UI function for results module
resultsModuleUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Results summary cards
    div(
      id = ns("summary_cards"),
      style = "display: none;",
      fluidRow(
        column(3,
          div(
            class = "card summary-card",
            div(
              class = "card-body text-center",
              div(
                class = "stat-value",
                id = ns("max_plasma_conc")
              ),
              div(
                class = "stat-label",
                "最大血漿中濃度 (µg/mL)"
              )
            )
          )
        ),
        column(3,
          div(
            class = "card summary-card",
            div(
              class = "card-body text-center",
              div(
                class = "stat-value",
                id = ns("max_effect_conc")
              ),
              div(
                class = "stat-label",
                "最大効果部位濃度 (µg/mL)"
              )
            )
          )
        ),
        column(3,
          div(
            class = "card summary-card",
            div(
              class = "card-body text-center",
              div(
                class = "stat-value",
                id = ns("simulation_duration")
              ),
              div(
                class = "stat-label",
                "シミュレーション時間 (分)"
              )
            )
          )
        ),
        column(3,
          div(
            class = "card summary-card",
            div(
              class = "card-body text-center",
              div(
                class = "stat-value",
                id = ns("data_points")
              ),
              div(
                class = "stat-label",
                "データポイント数"
              )
            )
          )
        )
      )
    ),
    
    # Plot tabs
    div(
      id = ns("plot_container"),
      style = "display: none;",
      
      card(
        card_header(
          div(
            class = "d-flex justify-content-between align-items-center",
            tags$span(
              icon("chart-line"),
              "濃度-時間推移"
            ),
            div(
              class = "btn-group btn-group-sm",
              id = ns("plot_controls"),
              tags$span(
                class = "btn btn-primary btn-sm",
                style = "cursor: default;",
                "両方表示"
              )
            )
          )
        ),
        card_body(
          withSpinner(
            plotlyOutput(ns("concentration_plot"), height = "500px"),
            type = 6,
            color = "#2c3e50"
          )
        )
      )
    ),
    
    # Data table and export
    div(
      id = ns("data_container"),
      style = "display: none;",
      
      card(
        card_header(
          div(
            class = "d-flex justify-content-between align-items-center",
            tags$span(
              icon("table"),
              "シミュレーションデータ"
            ),
            div(
              class = "btn-group",
              downloadButton(
                ns("download_csv"),
                label = tags$span(icon("download"), "CSV出力"),
                class = "btn-primary btn-sm"
              ),
              actionButton(
                ns("copy_data"),
                label = tags$span(icon("copy"), "コピー"),
                class = "btn-secondary btn-sm"
              )
            )
          )
        ),
        card_body(
          div(
            class = "table-responsive",
            withSpinner(
              DT::DTOutput(ns("results_table")),
              type = 6,
              color = "#2c3e50"
            )
          )
        )
      )
    ),
    
    # Empty state
    div(
      id = ns("empty_state"),
      class = "text-center",
      style = "padding: 60px 20px; color: #6c757d;",
      div(
        icon("chart-line", style = "font-size: 4em; margin-bottom: 20px; opacity: 0.3;"),
        h4("シミュレーション結果がありません", style = "margin-bottom: 10px;"),
        p("左側のパネルで患者情報と投与スケジュールを入力し、シミュレーションを実行してください。")
      )
    )
  )
}

# Server function for results module
resultsModuleServer <- function(id, simulationResults, simulationEnabled, patientData = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Always show combined plot (both concentrations)
    plotTypeSelection <- reactiveVal("combined")
    
    # Update UI visibility based on results
    observe({
      results <- simulationResults()
      
      if (is.null(results)) {
        # Show empty state
        runjs(paste0(
          "document.getElementById('", ns("empty_state"), "').style.display = 'block';",
          "document.getElementById('", ns("summary_cards"), "').style.display = 'none';",
          "document.getElementById('", ns("plot_container"), "').style.display = 'none';",
          "document.getElementById('", ns("data_container"), "').style.display = 'none';"
        ))
      } else {
        # Show results
        runjs(paste0(
          "document.getElementById('", ns("empty_state"), "').style.display = 'none';",
          "document.getElementById('", ns("summary_cards"), "').style.display = 'block';",
          "document.getElementById('", ns("plot_container"), "').style.display = 'block';",
          "document.getElementById('", ns("data_container"), "').style.display = 'block';"
        ))
        
        # Check if this is a V3 result with multiple methods
        is_v3_result <- inherits(results, "SimulationResultV3") && !is.null(results$alternative_methods)
        
        # Update plot controls based on result type
        if (is_v3_result) {
          available_methods <- results$get_available_methods()
          method_buttons <- sapply(available_methods, function(method) {
            method_label <- switch(method,
              "original" = "V2 標準",
              "discrete" = "離散",
              "exponential" = "指数",
              "hybrid" = "混合",
              method
            )
            paste0('<button class="btn btn-outline-secondary btn-sm method-btn" data-method="', method, '">', method_label, '</button>')
          })
          
          controls_html <- paste0(
            '<div class="btn-group btn-group-sm" role="group">',
            paste(method_buttons, collapse = ""),
            '</div>'
          )
          
          runjs(paste0(
            "document.getElementById('", ns("plot_controls"), "').innerHTML = '", controls_html, "';",
            "document.querySelectorAll('.method-btn').forEach(btn => {",
            "  btn.addEventListener('click', function() {",
            "    document.querySelectorAll('.method-btn').forEach(b => b.classList.remove('btn-secondary'));",
            "    document.querySelectorAll('.method-btn').forEach(b => b.classList.add('btn-outline-secondary'));",
            "    this.classList.remove('btn-outline-secondary');",
            "    this.classList.add('btn-secondary');",
            "    Shiny.setInputValue('", ns("selected_method"), "', this.dataset.method, {priority: 'event'});",
            "  });",
            "});",
            "document.querySelector('.method-btn').click();"  # Select first method by default
          ))
        }
        
        # Update summary cards
        runjs(paste0(
          "document.getElementById('", ns("max_plasma_conc"), "').innerHTML = '", 
          sprintf("%.3f", results$get_max_plasma_concentration()), "';",
          "document.getElementById('", ns("max_effect_conc"), "').innerHTML = '", 
          sprintf("%.3f", results$get_max_effect_site_concentration()), "';",
          "document.getElementById('", ns("simulation_duration"), "').innerHTML = '", 
          results$get_simulation_duration_minutes(), "';",
          "document.getElementById('", ns("data_points"), "').innerHTML = '", 
          length(results$time_points), "';"
        ))
      }
    })
    
    # Create concentration plot
    output$concentration_plot <- renderPlotly({
      req(simulationResults())
      
      results <- simulationResults()
      
      # Check if this is V3 result with multiple methods
      is_v3_result <- inherits(results, "SimulationResultV3") && !is.null(results$alternative_methods)
      
      # Get data based on result type
      if (is_v3_result) {
        # Use V3 time vector and methods
        time_data <- results$time_vector
        plasma_data <- results$get_plasma_concentrations()
        
        # Get selected method for effect-site data
        selected_method <- input$selected_method %||% "original"
        effect_data <- results$get_effect_site_by_method(selected_method)
        
        # Get all methods for comparison overlay
        all_methods <- results$get_available_methods()
        
      } else {
        # Standard V2 result
        time_data <- sapply(results$time_points, function(tp) tp$time_in_minutes)
        plasma_data <- sapply(results$time_points, function(tp) tp$plasma_concentration)
        effect_data <- sapply(results$time_points, function(tp) tp$effect_site_concentration)
      }
      
      # Get patient data for time conversion
      current_patient <- if (!is.null(patientData) && is.function(patientData$patient)) {
        patientData$patient()
      } else {
        NULL
      }
      
      # Convert time data for display
      if (!is.null(current_patient) && !is.null(current_patient$anesthesia_start_time)) {
        # Convert to clock times
        time_display <- sapply(time_data, function(t) {
          clock_time <- current_patient$minutes_to_clock_time(t)
          format(clock_time, "%H:%M")
        })
        x_axis_title <- "時刻"
        time_hover_format <- '時刻: %{x}<br>'
      } else {
        # Use minutes
        time_display <- time_data
        x_axis_title <- "時間 (分)"
        time_hover_format <- '時間: %{x} 分<br>'
      }
      
      # Create base plot
      p <- plot_ly()
      
      # Always add plasma concentration
      p <- p %>% add_trace(
        x = time_display,
        y = plasma_data,
        type = 'scatter',
        mode = 'lines',
        name = '血漿中濃度',
        line = list(color = '#e74c3c', width = 3),
        hovertemplate = paste(
          '<b>血漿中濃度</b><br>',
          time_hover_format,
          '濃度: %{y:.3f} µg/mL<br>',
          '<extra></extra>'
        )
      )
      
      # Add effect-site concentration(s)
      if (is_v3_result) {
        # For V3 results, show all methods with different line styles
        colors <- c('#3498db', '#2ecc71', '#f39c12', '#9b59b6', '#1abc9c')
        line_types <- c('solid', 'dash', 'dot', 'dashdot', 'longdash')
        
        for (i in seq_along(all_methods)) {
          method <- all_methods[i]
          method_data <- results$get_effect_site_by_method(method)
          
          method_label <- switch(method,
            "original" = "効果部位濃度 (V2標準)",
            "discrete" = "効果部位濃度 (離散)",
            "exponential" = "効果部位濃度 (指数)",
            "hybrid" = "効果部位濃度 (混合)",
            paste("効果部位濃度", method)
          )
          
          # Highlight selected method
          line_width <- if (method == selected_method) 4 else 2
          line_opacity <- if (method == selected_method) 1.0 else 0.6
          
          p <- p %>% add_trace(
            x = time_display,
            y = method_data,
            type = 'scatter',
            mode = 'lines',
            name = method_label,
            line = list(
              color = colors[((i-1) %% length(colors)) + 1],
              width = line_width,
              dash = line_types[((i-1) %% length(line_types)) + 1]
            ),
            opacity = line_opacity,
            hovertemplate = paste(
              '<b>', method_label, '</b><br>',
              time_hover_format,
              '濃度: %{y:.3f} µg/mL<br>',
              '<extra></extra>'
            )
          )
        }
      } else {
        # Standard V2 result
        p <- p %>% add_trace(
          x = time_display,
          y = effect_data,
          type = 'scatter',
          mode = 'lines',
          name = '効果部位濃度',
          line = list(color = '#3498db', width = 3),
          hovertemplate = paste(
            '<b>効果部位濃度</b><br>',
            time_hover_format,
            '濃度: %{y:.3f} µg/mL<br>',
            '<extra></extra>'
          )
        )
      }
      
      # Add dose events markers
      dose_times <- c()
      dose_types <- c()
      dose_amounts <- c()
      
      for (tp in results$time_points) {
        if (!is.null(tp$dose_event)) {
          dose_times <- c(dose_times, tp$time_in_minutes)
          
          if (tp$dose_event$bolus_mg > 0) {
            dose_types <- c(dose_types, "ボーラス")
            dose_amounts <- c(dose_amounts, paste(tp$dose_event$bolus_mg, "mg"))
          } else {
            dose_types <- c(dose_types, "持続開始")
            dose_amounts <- c(dose_amounts, paste(tp$dose_event$continuous_mg_kg_hr, "mg/kg/hr"))
          }
        }
      }
      
      if (length(dose_times) > 0) {
        max_conc <- max(c(plasma_data, effect_data), na.rm = TRUE)
        
        # Convert dose times for display
        dose_times_display <- if (!is.null(current_patient) && !is.null(current_patient$anesthesia_start_time)) {
          sapply(dose_times, function(t) {
            clock_time <- current_patient$minutes_to_clock_time(t)
            format(clock_time, "%H:%M")
          })
        } else {
          dose_times
        }
        
        p <- p %>% add_trace(
          x = dose_times_display,
          y = rep(max_conc * 0.95, length(dose_times_display)),
          type = 'scatter',
          mode = 'markers',
          name = '投与',
          marker = list(
            symbol = 'triangle-down',
            size = 12,
            color = '#f39c12',
            line = list(color = '#e67e22', width = 2)
          ),
          text = paste(dose_types, dose_amounts, sep = ": "),
          hovertemplate = paste(
            '<b>投与イベント</b><br>',
            time_hover_format,
            '%{text}<br>',
            '<extra></extra>'
          )
        )
      }
      
      # Layout configuration
      p <- p %>% layout(
        title = list(
          text = "レミマゾラム血漿中・効果部位濃度推移",
          font = list(size = 16, color = '#2c3e50')
        ),
        xaxis = list(
          title = x_axis_title,
          showgrid = TRUE,
          gridcolor = '#ecf0f1',
          zeroline = FALSE
        ),
        yaxis = list(
          title = "濃度 (µg/mL)",
          showgrid = TRUE,
          gridcolor = '#ecf0f1',
          zeroline = FALSE,
          rangemode = 'tozero'
        ),
        legend = list(
          orientation = "h",
          x = 0.5,
          xanchor = 'center',
          y = -0.15,
          bgcolor = 'rgba(255,255,255,0.8)',
          bordercolor = '#bdc3c7',
          borderwidth = 1
        ),
        hovermode = 'x unified',
        plot_bgcolor = 'rgba(0,0,0,0)',
        paper_bgcolor = 'rgba(0,0,0,0)',
        margin = list(l = 60, r = 20, t = 80, b = 80)
      )
      
      # Configure plotly
      p %>% config(
        displayModeBar = TRUE,
        modeBarButtonsToRemove = c('pan2d', 'select2d', 'lasso2d', 'autoScale2d'),
        displaylogo = FALSE,
        toImageButtonOptions = list(
          format = 'png',
          filename = paste0('remimazolam_simulation_', format(Sys.Date(), "%Y%m%d")),
          height = 600,
          width = 1000,
          scale = 2
        )
      )
    })
    
    # Create results data table
    output$results_table <- DT::renderDT({
      req(simulationResults())
      
      results <- simulationResults()
      
      # Get patient data for time conversion
      current_patient <- if (!is.null(patientData) && is.function(patientData$patient)) {
        patientData$patient()
      } else {
        NULL
      }
      
      # Convert time for display
      time_minutes <- sapply(results$time_points, function(tp) tp$time_in_minutes)
      if (!is.null(current_patient) && !is.null(current_patient$anesthesia_start_time)) {
        time_display <- sapply(time_minutes, function(t) {
          clock_time <- current_patient$minutes_to_clock_time(t)
          format(clock_time, "%H:%M")
        })
        time_column_name <- "時刻"
      } else {
        time_display <- time_minutes
        time_column_name <- "時間(分)"
      }
      
      # Calculate current infusion rates for each time point
      current_infusion_rates <- rep(0.0, length(results$time_points))
      if (!is.null(results$pk_parameters) && !is.null(results$pk_parameters$infusion_plan)) {
        infusion_plan <- results$pk_parameters$infusion_plan
        
        for (i in 1:length(results$time_points)) {
          tp_time <- results$time_points[[i]]$time_in_minutes
          
          # Find the most recent infusion rate change at or before this time
          relevant_rows <- infusion_plan[infusion_plan$time <= tp_time, ]
          if (nrow(relevant_rows) > 0) {
            current_infusion_rates[i] <- tail(relevant_rows$rate, 1)
          }
        }
      }
      
      # Prepare table data
      table_data <- data.frame(
        time_display,
        "ボーラス(mg)" = sapply(results$time_points, function(tp) {
          if (is.null(tp$dose_event)) return(0.0)
          return(tp$dose_event$bolus_mg)
        }),
        "持続(mg/kg/hr)" = current_infusion_rates,
        "血漿中濃度(µg/mL)" = sapply(results$time_points, function(tp) tp$plasma_concentration),
        "効果部位濃度(µg/mL)" = sapply(results$time_points, function(tp) tp$effect_site_concentration),
        stringsAsFactors = FALSE
      )
      
      # Set column names
      names(table_data)[1] <- time_column_name
      
      DT::datatable(
        table_data,
        options = list(
          pageLength = 15,
          lengthMenu = c(10, 15, 25, 50, 100),
          scrollX = TRUE,
          scrollY = "400px",
          searching = TRUE,
          ordering = TRUE,
          info = TRUE,
          dom = 'Bfrtip',
          buttons = list(
            list(extend = 'copy', text = 'コピー'),
            list(extend = 'csv', text = 'CSV'),
            list(extend = 'excel', text = 'Excel')
          ),
          language = list(
            search = "検索:",
            lengthMenu = "_MENU_ 件表示",
            info = "_START_ - _END_ / _TOTAL_ 件",
            paginate = list(
              first = "最初",
              last = "最後",
              "next" = "次へ",
              previous = "前へ"
            ),
            emptyTable = "データがありません"
          )
        ),
        rownames = FALSE,
        selection = 'none',
        extensions = c('Buttons', 'Scroller')
      ) %>%
        DT::formatRound(columns = c(2, 3, 4, 5), digits = 3) %>%
        DT::formatStyle(
          columns = c(4, 5),
          backgroundColor = DT::styleInterval(
            cuts = c(0.5, 1.0, 2.0),
            values = c('white', '#fff3cd', '#ffeaa7', '#fab1a0')
          )
        )
    })
    
    # CSV download handler
    output$download_csv <- downloadHandler(
      filename = function() {
        req(simulationResults())
        results <- simulationResults()
        timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
        
        # Get patient ID from results
        patient_id <- if (!is.null(results$patient_info) && !is.null(results$patient_info$id)) {
          # Sanitize patient ID for filename (remove special characters)
          gsub("[^a-zA-Z0-9_-]", "_", results$patient_info$id)
        } else {
          "unknown"
        }
        
        # Determine calculation logic identification symbol
        calc_symbol <- if (inherits(results, "SimulationResultV3") && !is.null(results$alternative_methods)) {
          # V3 multiple methods calculation
          "_V3comp"
        } else {
          # V2 standard calculation
          "_V2std"
        }
        
        paste0("remimazolam_", patient_id, calc_symbol, "_", timestamp, ".csv")
      },
      content = function(file) {
        req(simulationResults())
        
        results <- simulationResults()
        csv_content <- results$to_csv()
        
        # Get patient ID for header
        patient_id <- if (!is.null(results$patient_info) && !is.null(results$patient_info$id)) {
          results$patient_info$id
        } else {
          "Unknown"
        }
        
        # Determine calculation method information
        calc_method_info <- if (inherits(results, "SimulationResultV3") && !is.null(results$alternative_methods)) {
          available_methods <- results$get_available_methods()
          paste("# Calculation Methods: V3 Multiple Methods Comparison -", paste(available_methods, collapse = ", "))
        } else {
          "# Calculation Method: V2 Standard (deSolve)"
        }
        
        # Add header information
        header_info <- paste(
          "# Remimazolam PK/PD Simulation Results",
          paste("# Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
          paste("# Patient ID:", patient_id),
          calc_method_info,
          paste("# Simulation Duration:", results$get_simulation_duration_minutes(), "minutes"),
          paste("# Max Plasma Concentration:", sprintf("%.3f", results$get_max_plasma_concentration()), "µg/mL"),
          paste("# Max Effect-site Concentration:", sprintf("%.3f", results$get_max_effect_site_concentration()), "µg/mL"),
          "#",
          csv_content,
          sep = "\n"
        )
        
        writeLines(header_info, file, useBytes = TRUE)
      },
      contentType = "text/csv"
    )
    
    # Copy data to clipboard
    observeEvent(input$copy_data, {
      req(simulationResults())
      
      results <- simulationResults()
      csv_content <- results$to_csv()
      
      # Use JavaScript to copy to clipboard
      runjs(paste0(
        "navigator.clipboard.writeText(`", csv_content, "`).then(function() {",
        "  Shiny.setInputValue('", ns("copy_success"), "', Math.random(), {priority: 'event'});",
        "}).catch(function() {",
        "  Shiny.setInputValue('", ns("copy_error"), "', Math.random(), {priority: 'event'});",
        "});"
      ))
    })
    
    observeEvent(input$copy_success, {
      showNotification(
        "データをクリップボードにコピーしました",
        type = "message",
        duration = 3
      )
    })
    
    observeEvent(input$copy_error, {
      showNotification(
        "クリップボードへのコピーに失敗しました",
        type = "error",
        duration = 5
      )
    })
  })
}