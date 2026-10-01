library(shiny)
library(DT)
library(readxl)
library(writexl)
library(caret)

# ============================================================
# Load trained Random Forest models
#
# Repository structure:
#
# app.R
# models/
# ├── ranger_loso_bundle_FC10_Bottom.rds
# ├── ranger_loso_bundle_FC33_Bottom.rds
# ├── ranger_loso_bundle_PWP_Bottom.rds
# ├── ranger_loso_bundle_FC10_Top.rds
# ├── ranger_loso_bundle_FC33_Top.rds
# └── ranger_loso_bundle_PWP_Top.rds
#
# Matrix layout:
#
# Rows:
#   1 = Subsoil (Bottom)
#   2 = Topsoil (Top)
#
# Columns:
#   1 = FC10
#   2 = FC33
#   3 = PWP
# ============================================================

model_dir <- "models"

rfs <- matrix(list(), nrow = 2, ncol = 3)

bundle <- readRDS(file.path(model_dir, "ranger_loso_bundle_FC10_Bottom.rds"))
rfs[[1, 1]] <- bundle$model

bundle <- readRDS(file.path(model_dir, "ranger_loso_bundle_FC33_Bottom.rds"))
rfs[[1, 2]] <- bundle$model

bundle <- readRDS(file.path(model_dir, "ranger_loso_bundle_PWP_Bottom.rds"))
rfs[[1, 3]] <- bundle$model

bundle <- readRDS(file.path(model_dir, "ranger_loso_bundle_FC10_Top.rds"))
rfs[[2, 1]] <- bundle$model

bundle <- readRDS(file.path(model_dir, "ranger_loso_bundle_FC33_Top.rds"))
rfs[[2, 2]] <- bundle$model

bundle <- readRDS(file.path(model_dir, "ranger_loso_bundle_PWP_Top.rds"))
rfs[[2, 3]] <- bundle$model


# Predictor variables required by the models
predictors <- c("Sand", "Silt", "Clay", "Cox")

# ============================================================
# User Interface
# ============================================================

ui <- fluidPage(
  
  titlePanel("Soil Water Retention Prediction"),
  
  sidebarLayout(
    
    sidebarPanel(
      
      fileInput(
        "file",
        "Upload CSV or Excel File",
        accept = c(".csv", ".xls", ".xlsx")
      ),
      
      actionButton(
        "add_row",
        "Add Empty Row"
      ),
      
      actionButton(
        "predict_btn",
        "Run Prediction"
      ),
      
      downloadButton(
        "download_pred",
        "Download Results"
      )
    ),
    
    mainPanel(
      
      h4("Input Data"),
      DTOutput("table"),
      
      h4("Predictions"),
      DTOutput("pred_table")
    )
  )
)

# ============================================================
# Server
# ============================================================

server <- function(input, output, session) {
  
  # Create empty input table
  init_df <- data.frame(
    matrix(
      ncol = length(predictors),
      nrow = 0
    )
  )
  
  colnames(init_df) <- predictors
  
  init_df$Depth <- character(0)
  init_df$Sample_ID <- character(0)
  init_df$Location <- character(0)
  
  df <- reactiveVal(init_df)
  
  # Ensure all predictor columns exist
  ensure_predictors <- function(df, predictors) {
    
    missing_cols <- setdiff(
      predictors,
      colnames(df)
    )
    
    if(length(missing_cols) > 0) {
      df[missing_cols] <- NA
    }
    
    df[, predictors, drop = FALSE]
  }
  
  # ----------------------------------------------------------
  # Editable input table
  # ----------------------------------------------------------
  
  output$table <- renderDT({
    datatable(
      df(),
      editable = TRUE,
      options = list(scrollX = TRUE)
    )
  })
  
  # ----------------------------------------------------------
  # Cell editing
  # ----------------------------------------------------------
  
  observeEvent(input$table_cell_edit, {
    
    info <- input$table_cell_edit
    
    tmp <- df()
    
    tmp[info$row, info$col] <- DT::coerceValue(
      info$value,
      tmp[info$row, info$col]
    )
    
    if("Depth" %in% names(tmp)) {
      tmp$Depth <- toupper(as.character(tmp$Depth))
    }
    
    df(tmp)
  })
  
  # ----------------------------------------------------------
  # Add empty row
  # ----------------------------------------------------------
  
  observeEvent(input$add_row, {
    
    tmp <- df()
    
    new_row <- setNames(
      as.list(rep(NA, length(predictors))),
      predictors
    )
    
    new_row$Depth <- ""
    new_row$Sample_ID <- ""
    new_row$Location <- ""
    
    tmp <- rbind(tmp, new_row)
    
    df(tmp)
  })
  
  # ----------------------------------------------------------
  # Import CSV or Excel file
  # ----------------------------------------------------------
  
  observeEvent(input$file, {
    
    req(input$file)
    
    ext <- tools::file_ext(input$file$name)
    
    tmp <- switch(
      
      ext,
      
      csv = {
        
        first_line <- readLines(
          input$file$datapath,
          n = 1
        )
        
        if(grepl(";", first_line)) {
          read.csv2(
            input$file$datapath,
            stringsAsFactors = FALSE
          )
        } else {
          read.csv(
            input$file$datapath,
            stringsAsFactors = FALSE
          )
        }
      },
      
      xlsx = read_excel(input$file$datapath),
      xls  = read_excel(input$file$datapath),
      
      stop("Unsupported file format.")
    )
    
    tmp_model <- tmp[
      ,
      predictors[predictors %in% colnames(tmp)],
      drop = FALSE
    ]
    
    tmp_model <- ensure_predictors(
      tmp_model,
      predictors
    )
    
    num_cols <- c(
      "Sand",
      "Silt",
      "Clay",
      "Cox"
    )
    
    tmp_model[num_cols] <- lapply(
      tmp_model[num_cols],
      function(x) {
        as.numeric(
          gsub(
            ",",
            ".",
            as.character(x),
            fixed = TRUE
          )
        )
      }
    )
    
    if(!"Depth" %in% names(tmp)) {
      tmp$Depth <- ""
    }
    
    if(!"Sample_ID" %in% names(tmp)) {
      tmp$Sample_ID <- ""
    }
    
    if(!"Location" %in% names(tmp)) {
      tmp$Location <- ""
    }
    
    tmp$Depth <- toupper(
      as.character(tmp$Depth)
    )
    
    tmp_final <- cbind(
      tmp_model,
      Depth = tmp$Depth,
      Sample_ID = as.character(tmp$Sample_ID),
      Location = as.character(tmp$Location)
    )
    
    tmp_final <- tmp_final[
      ,
      c(
        predictors,
        "Depth",
        "Sample_ID",
        "Location"
      )
    ]
    
    df(tmp_final)
  })
  
  # ----------------------------------------------------------
  # Run predictions
  # ----------------------------------------------------------
  
  pred <- eventReactive(
    input$predict_btn,
    {
      
      req(nrow(df()) > 0)
      
      tmp <- df()
      
      num_cols <- c(
        "Sand",
        "Silt",
        "Clay",
        "Cox"
      )
      
      tmp[num_cols] <- lapply(
        tmp[num_cols],
        function(x) {
          as.numeric(
            gsub(
              ",",
              ".",
              as.character(x),
              fixed = TRUE
            )
          )
        }
      )
      
      valid_rows <- which(
        complete.cases(
          tmp[, num_cols, drop = FALSE]
        )
      )
      
      invalid_rows <- which(
        !complete.cases(
          tmp[, num_cols, drop = FALSE]
        )
      )
      
      if(length(invalid_rows) > 0) {
        
        showNotification(
          paste(
            length(invalid_rows),
            "rows were skipped because of missing predictor values."
          ),
          type = "warning"
        )
      }
      
      pred_mat <- matrix(
        NA_real_,
        nrow = nrow(tmp),
        ncol = 3
      )
      
      colnames(pred_mat) <- c(
        "FC10",
        "FC33",
        "PWP"
      )
      
      depth_to_row <- function(depth) {
        
        if(is.na(depth) ||
           trimws(depth) == "") {
          return(1L)
        }
        
        first <- toupper(
          substr(
            trimws(depth),
            1,
            1
          )
        )
        
        if(first == "B") {
          return(1L)
        }
        
        if(first == "T") {
          return(2L)
        }
        
        return(1L)
      }
      
      model_rows <- vapply(
        tmp$Depth,
        depth_to_row,
        integer(1)
      )
      
      for(row_index in 1:2) {
        
        idx <- intersect(
          which(model_rows == row_index),
          valid_rows
        )
        
        if(length(idx) == 0) {
          next
        }
        
        new_data <- tmp[
          idx,
          predictors,
          drop = FALSE
        ]
        
        for(j in 1:3) {
          
          pred_mat[idx, j] <- as.numeric(
            predict(
              rfs[[row_index, j]],
              newdata = new_data
            )
          )
        }
      }
      
      data.frame(
        Sample_ID = tmp$Sample_ID,
        Location = tmp$Location,
        pred_mat,
        check.names = FALSE
      )
    }
  )
  
  # ----------------------------------------------------------
  # Display predictions
  # ----------------------------------------------------------
  
  output$pred_table <- renderDT({
    
    req(pred())
    
    result <- pred()
    
    result[, 3:5] <- round(
      result[, 3:5],
      4
    )
    
    datatable(result)
  })
  
  # ----------------------------------------------------------
  # Export input data and predictions
  # ----------------------------------------------------------
  
  df_with_pred <- reactive({
    
    req(pred())
    
    cbind(
      df(),
      pred()
    )
  })
  
  output$download_pred <- downloadHandler(
    
    filename = function() {
      paste0(
        "predictions_",
        Sys.Date(),
        ".xlsx"
      )
    },
    
    content = function(file) {
      
      writexl::write_xlsx(
        df_with_pred(),
        path = file
      )
    }
  )
}

# ============================================================
# Launch application
# ============================================================

shinyApp(ui, server)