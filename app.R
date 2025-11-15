library(shiny)
library(dplyr)
library(ggplot2)
library(readr)
library(DT)
library(forcats)

# Load cleaned data 
prizes <- read_csv("prizes_clean.csv", show_col_types = FALSE)

# Precompute choices for inputs
year_min <- min(prizes$prize_year, na.rm = TRUE)
year_max <- max(prizes$prize_year, na.rm = TRUE)

genre_choices   <- sort(unique(prizes$prize_genre))
role_choices    <- sort(unique(prizes$role_simple))
gender_choices  <- sort(unique(prizes$gender[!is.na(prizes$gender)]))

degree_choices  <- prizes %>%
  distinct(highest_degree) %>%
  filter(!is.na(highest_degree)) %>%
  pull(highest_degree) %>%
  sort()

# Add user interface
ui <- fluidPage(
  titlePanel("British Literary Prizes Explorer"),
  
  sidebarLayout(
    sidebarPanel(
      h4("Filters"),
      sliderInput(
        "year_range", "Prize year:",
        min = year_min,
        max = year_max,
        value = c(year_min, year_max),
        sep = ""
      ),
      selectInput(
        "genre", "Genre (one or more):",
        choices  = genre_choices,
        selected = genre_choices,
        multiple = TRUE
      ),
      selectInput(
        "role", "Prize role:",
        choices  = c("All", role_choices),
        selected = "All"
      ),
      selectInput(
        "gender", "Author gender:",
        choices  = c("All", gender_choices),
        selected = "All"
      ),
      checkboxInput(
        "uk_only", "UK-resident authors only", value = FALSE
      ),
      hr(),
      helpText("Data: #TidyTuesday 2025-10-28 (literary prizes).")
    ),
    
    mainPanel(
      tabsetPanel(
        id = "tabs",
        
        tabPanel(
          "Overview",
          br(),
          h3("Genre distribution in filtered data"),
          plotOutput("plot_overview", height = "400px"),
          br(),
          verbatimTextOutput("summary_overview")
        ),
        
        tabPanel(
          "Prizes over time",
          br(),
          h3("Number of prizes over time, by genre"),
          plotOutput("plot_time", height = "400px"),
          br(),
          helpText("Counts are based on people × prize entries, not unique books.")
        ),
        
        tabPanel(
          "Demographics",
          br(),
          h3("Gender and degree patterns across genres"),
          fluidRow(
            column(
              width = 4,
              selectInput(
                "degree_filter", "Highest degree:",
                choices  = c("All", degree_choices),
                selected = "All"
              )
            )
          ),
          plotOutput("plot_gender_degree", height = "450px"),
          br(),
          helpText("Bars show counts of prize entries by genre, gender, and degree.")
        ),
        
        tabPanel(
          "Data table",
          br(),
          h3("Filtered dataset"),
          DTOutput("table_prizes")
        )
      )
    )
  )
)

# Add server
server <- function(input, output, session) {
  
  # Common reactive: filtered dataset based on sidebar filters
  filtered_prizes <- reactive({
    df <- prizes
    
    # Year filter
    df <- df %>%
      filter(
        prize_year >= input$year_range[1],
        prize_year <= input$year_range[2]
      )
    
    # Genre filter
    if (!is.null(input$genre) && length(input$genre) > 0) {
      df <- df %>% filter(prize_genre %in% input$genre)
    }
    
    # Role filter
    if (!is.null(input$role) && input$role != "All") {
      df <- df %>% filter(role_simple == input$role)
    }
    
    # Gender filter
    if (!is.null(input$gender) && input$gender != "All") {
      df <- df %>% filter(gender == input$gender)
    }
    
    # UK residence filter
    if (isTRUE(input$uk_only)) {
      df <- df %>% filter(uk_residence == TRUE)
    }
    
    df
  })
  # Start adding tabs
  # Tab 1: Overview 
  output$plot_overview <- renderPlot({
    df <- filtered_prizes()
    req(nrow(df) > 0)
    
    genre_counts <- df %>%
      count(prize_genre, name = "n") %>%
      mutate(
        pct = n / sum(n),
        prize_genre = fct_reorder(prize_genre, n)
      )
    
    ggplot(genre_counts, aes(x = prize_genre, y = n)) +
      geom_col() +
      coord_flip() +
      labs(
        x = "Prize genre",
        y = "Number of prize entries",
        title = "Distribution of prize entries by genre"
      ) +
      theme_minimal()
  })
  
  output$summary_overview <- renderPrint({
    df <- filtered_prizes()
    n_entries <- nrow(df)
    n_authors <- df %>% distinct(person_id) %>% nrow()
    n_books   <- df %>% distinct(book_id)   %>% nrow()
    years     <- range(df$prize_year, na.rm = TRUE)
    
    cat("Summary of filtered data\n",
        "------------------------\n",
        "Prize entries: ", n_entries, "\n",
        "Unique authors:", n_authors, "\n",
        "Unique books:  ", n_books, "\n",
        "Year range:    ", years[1], "–", years[2], "\n", sep = "")
  })
  
  # Tab 2: Prizes Over Time
  output$plot_time <- renderPlot({
    df <- filtered_prizes()
    req(nrow(df) > 0)
    
    by_year_genre <- df %>%
      count(prize_year, prize_genre, name = "n")
    
    ggplot(by_year_genre, aes(x = prize_year, y = n, color = prize_genre)) +
      geom_line() +
      geom_point() +
      labs(
        x = "Year",
        y = "Number of prize entries",
        color = "Genre",
        title = "Prize entries over time by genre"
      ) +
      theme_minimal()
  })
  
  # Tab 3: Demographics 
  output$plot_gender_degree <- renderPlot({
    df <- filtered_prizes()
    req(nrow(df) > 0)
    
    # Optional degree filter
    if (!is.null(input$degree_filter) && input$degree_filter != "All") {
      df <- df %>% filter(highest_degree == input$degree_filter)
    }
    
    df <- df %>%
      mutate(
        gender = if_else(is.na(gender), "Unknown", gender),
        highest_degree = if_else(is.na(highest_degree), "Unknown", highest_degree)
      )
    
    demo_counts <- df %>%
      count(prize_genre, gender, highest_degree, name = "n")
    
    ggplot(demo_counts,
           aes(x = fct_reorder(prize_genre, n, .fun = sum),
               y = n,
               fill = gender)) +
      geom_col(position = "dodge") +
      coord_flip() +
      labs(
        x = "Prize genre",
        y = "Number of prize entries",
        fill = "Gender",
        title = "Gender distribution by genre (faceted by degree)"
      ) +
      facet_wrap(~ highest_degree) +
      theme_minimal()
  })
  
  # Tab 4: Data table 
  output$table_prizes <- renderDT({
    df <- filtered_prizes()
    
    df %>%
      select(
        prize_year, prize_name, prize_genre, role_simple,
        first_name, last_name, gender, uk_residence,
        highest_degree, degree_field_cat,
        book_title
      ) %>%
      datatable(
        options = list(pageLength = 10),
        filter = "top",
        rownames = FALSE
      )
  })
}

shinyApp(ui = ui, server = server)
