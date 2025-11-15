# Assignment G — Shiny App  
*Exploring British Literary Prize Data (TidyTuesday 2025 Week 43)*

This repository contains a complete Shiny application for interactively exploring the **TidyTuesday literary prizes dataset**.  
The app supports filtering, visualization, and multi-tab exploration of prize patterns, author demographics, and book information.

---

## Features of the Shiny App

### Interactive filters
Users can dynamically filter the dataset by:
- Prize year range  
- Prize genre  
- Prize role (Winner, Shortlisted, Other)  
- Author gender  
- UK residency  
- Highest degree (optional filter in demographics tab)

### Multi-page dashboard
The interface includes four tabs:

#### 1. **Overview**
- Bar plot showing the distribution of prize entries by genre  
- Text summary of selected subset  
- Helps answer: *Which genres dominate award activity?*

#### 2. **Prizes Over Time**
- Line plot of prize activity over time, by genre  
- Helps answer: *How has literary prize activity changed across decades?*

#### 3. **Demographics**
- Faceted bar charts of gender × education × genre  
- Helps answer: *How do demographic and educational patterns vary among authors?*

#### 4. **Data Table**
- Searchable, filterable table of all prize entries matching current filters  
- Provides transparency and allows users to explore individual records

---

## Data Preparation

The cleaned dataset is produced using the script:

data-raw/01_clean_prizes.R

yaml
Copy code

This script:
- Loads TidyTuesday 2025-10-28  
- Standardizes missing categories  
- Simplifies prize roles  
- Selects relevant variables  
- Writes `data/prizes_clean.csv` for the Shiny app  

You **do not** need to run this script when using the app, but it is included for reproducibility.

---

## Running the App

In R, simply run:

```r
shiny::runApp()
OR explicitly:
```
```r
Copy code
shiny::runApp("app.R")

```
The application will launch in your browser (or inside RStudio Viewer if enabled).

 Required R Packages

The app uses the following R packages:

shiny,
dplyr,
ggplot2,
readr,
forcats,
DT

