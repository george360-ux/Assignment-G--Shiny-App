# data-raw/01_clean_prizes.R
library(dplyr)
library(tidytuesdayR)
library(readr)
library(stringr)

# Load TidyTuesday data
tuesdata <- tidytuesdayR::tt_load('2025-10-28')
prizes_raw <- tuesdata$prizes

prizes_clean <- prizes_raw %>%
  # Standardize some text columns a bit
  mutate(
    prize_genre       = str_to_title(prize_genre),
    gender            = if_else(gender == "", NA_character_, gender),
    ethnicity_macro   = if_else(ethnicity_macro == "", NA_character_, ethnicity_macro),
    highest_degree    = if_else(highest_degree == "", NA_character_, highest_degree),
    degree_field_cat  = degree_field_category,
    # Make simple “winner / shortlisted / other” variable
    role_simple = case_when(
      str_detect(person_role, regex("winner", ignore_case = TRUE))      ~ "Winner",
      str_detect(person_role, regex("shortlist|short-listed", TRUE))    ~ "Shortlisted",
      TRUE                                                               ~ "Other"
    )
  ) %>%
  # Keep only columns that are most useful for your app
  select(
    prize_id, prize_name, prize_alias, prize_institution,
    prize_year, prize_genre,
    person_id, first_name, last_name, gender,
    uk_residence, ethnicity_macro,
    highest_degree, degree_field_cat,
    degree_institution, degree_field,
    role_simple, person_role,
    book_id, book_title
  )

# Create data/ folder if needed
if (!dir.exists("data")) dir.create("data")

write_csv(prizes_clean, "data/prizes_clean.csv")
