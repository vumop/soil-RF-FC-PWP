# Soil Water Retention Prediction App

A Shiny application for predicting soil water retention characteristics using Random Forest models trained on the public subset of the EU-HYDI soil database.

The application predicts:

- **FC10** (Field Capacity at pF 2.0, −10 kPa)
- **FC33** (Field Capacity at pF 2.5, −33 kPa)
- **PWP** (Permanent Wilting Point, −1500 kPa)

Predictions are generated from four commonly available soil properties:

- Sand (%)
- Silt (%)
- Clay (%)
- Cox (% organic carbon)

Separate models are used for **topsoil** and **subsoil** samples.

---

# Repository Structure

```text
.
├── app.R
├── models/
│   ├── ranger_loso_bundle_FC10_Bottom.rds
│   ├── ranger_loso_bundle_FC33_Bottom.rds
│   ├── ranger_loso_bundle_PWP_Bottom.rds
│   ├── ranger_loso_bundle_FC10_Top.rds
│   ├── ranger_loso_bundle_FC33_Top.rds
│   └── ranger_loso_bundle_PWP_Top.rds
└── README.md
```

---

# Installation

## 1. Install R

Download and install R:

- https://cran.r-project.org

## 2. Install required packages

Run:

```r
install.packages(c(
  "shiny",
  "DT",
  "readxl",
  "writexl",
  "caret"
))
```

---

# Running the Application

Open R or RStudio in the repository directory and run:

```r
shiny::runApp()
```

or

```r
source("app.R")
```

The application will open in your default web browser.

---

# Input Data Format

The application requires the following columns:

| Column | Description | Unit |
|----------|------------|---------|
| Sand | Sand content | % |
| Silt | Silt content | % |
| Clay | Clay content | % |
| Cox | Organic carbon content | % |
| Depth | Soil layer identifier | T or B |
| Sample_ID | Sample identifier (optional) | text |
| Location | Sampling location (optional) | text |

Only the four predictor variables are required for prediction.

---

# Depth Codes

The application automatically selects the appropriate model according to the value in the **Depth** column.

| Value | Model used |
|---------|-----------|
| T | Topsoil model |
| B | Subsoil model |

If the depth is missing, the subsoil model is used by default.

---

# Example Input File

```csv
Sample_ID,Location,Depth,Sand,Silt,Clay,Cox
S001,Site_A,T,45,35,20,1.25
S002,Site_A,B,38,41,21,0.82
S003,Site_B,T,62,21,17,1.68
```

European CSV files using decimal commas are also supported:

```csv
Sample_ID;Location;Depth;Sand;Silt;Clay;Cox
S001;Site_A;T;45;35;20;1,25
S002;Site_A;B;38;41;21;0,82
```

---

# How to Use

## Option 1: Upload a File

1. Click **Upload CSV or Excel File**.
2. Select a CSV, XLS, or XLSX file.
3. Verify the imported data.
4. Click **Run Prediction**.
5. Review the generated predictions.
6. Click **Download Results** to export the results as an Excel file.

## Option 2: Enter Data Manually

1. Click **Add Empty Row**.
2. Enter values directly into the table.
3. Repeat for additional samples.
4. Click **Run Prediction**.
5. Download the results if desired.

---

# Output

The application returns:

| Column | Description |
|----------|------------|
| FC10 | Predicted water content at −10 kPa |
| FC33 | Predicted water content at −33 kPa |
| PWP | Predicted water content at −1500 kPa |

The downloaded Excel file contains:

- Original input data
- Predicted FC10 values
- Predicted FC33 values
- Predicted PWP values

---

# Missing Data Handling

Rows with missing values in any of the required predictor columns:

- Sand
- Silt
- Clay
- Cox

are automatically skipped during prediction.

A warning message will indicate how many rows were omitted.

---

# Citation

If you use this application in scientific work, please cite the associated publication:

```text
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXxx
```

---

# Disclaimer

This software is provided for research and educational purposes.

Predictions are valid only within the range of soil properties represented in the model training dataset. Extrapolation beyond the calibration domain may lead to unreliable estimates.
