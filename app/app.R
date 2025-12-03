# Quarto Tournament Tracker - R Shiny App

library(shiny)
library(DBI)
library(RSQLite)
library(DT)
library(bslib)

# ------------------------------------------------------------------------------
# Database Setup
# ------------------------------------------------------------------------------

db_path <- "chess_tournament.sqlite"

init_db <- function() {
  con <- dbConnect(SQLite(), db_path)
  
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS matches (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      match_date DATE NOT NULL,
      white_player TEXT NOT NULL,
      black_player TEXT NOT NULL,
      result TEXT NOT NULL,
      winner TEXT,
      notes TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  ")
  
  dbDisconnect(con)
}

get_matches <- function() {
  con <- dbConnect(SQLite(), db_path)
  matches <- dbGetQuery(con, "
    SELECT id, match_date, white_player, black_player, result, winner, notes
    FROM matches 
    ORDER BY match_date DESC, id DESC
  ")
  dbDisconnect(con)
  
  if (nrow(matches) > 0) {
    matches$match_date <- as.Date(matches$match_date)
  }
  
  return(matches)
}

add_match <- function(match_date, white, black, result, notes) {
  winner <- switch(result,
    "white" = white,
    "black" = black,
    NA_character_
  )
  
  con <- dbConnect(SQLite(), db_path)
  dbExecute(con, "
    INSERT INTO matches (match_date, white_player, black_player, result, winner, notes)
    VALUES (?, ?, ?, ?, ?, ?)
  ", params = list(as.character(match_date), white, black, result, winner, notes))
  dbDisconnect(con)
}

delete_match <- function(id) {
  con <- dbConnect(SQLite(), db_path)
  dbExecute(con, "DELETE FROM matches WHERE id = ?", params = list(id))
  dbDisconnect(con)
}

get_players <- function() {
  con <- dbConnect(SQLite(), db_path)
  players <- dbGetQuery(con, "
    SELECT DISTINCT player FROM (
      SELECT white_player AS player FROM matches
      UNION
      SELECT black_player AS player FROM matches
    ) ORDER BY player
  ")
  dbDisconnect(con)
  return(players$player)
}

calculate_standings <- function(matches) {
  if (nrow(matches) == 0) {
    return(data.frame(
      Player = character(),
      Wins = integer(),
      Losses = integer(),
      Draws = integer(),
      `Win Rate` = numeric(),
      check.names = FALSE
    ))
  }
  
  # Get all unique players
  players <- unique(c(matches$white_player, matches$black_player))
  
  standings <- data.frame(
    Player = players,
    Wins = 0,
    Losses = 0,
    Draws = 0,
    stringsAsFactors = FALSE
  )
  
  for (i in seq_len(nrow(matches))) {
    white <- matches$white_player[i]
    black <- matches$black_player[i]
    result <- matches$result[i]
    
    white_idx <- which(standings$Player == white)
    black_idx <- which(standings$Player == black)
    
    if (result == "white") {
      standings$Wins[white_idx] <- standings$Wins[white_idx] + 1
      standings$Losses[black_idx] <- standings$Losses[black_idx] + 1
    } else if (result == "black") {
      standings$Wins[black_idx] <- standings$Wins[black_idx] + 1
      standings$Losses[white_idx] <- standings$Losses[white_idx] + 1
    } else {
      standings$Draws[white_idx] <- standings$Draws[white_idx] + 1
      standings$Draws[black_idx] <- standings$Draws[black_idx] + 1
    }
  }
  
  standings$Total <- standings$Wins + standings$Losses + standings$Draws
  standings$`Win Rate` <- ifelse(
    standings$Total > 0,
    round((standings$Wins + 0.5 * standings$Draws) / standings$Total * 100, 1),
    0
  )
  
  # Sort by wins, then win rate

standings <- standings[order(-standings$Wins, -standings$`Win Rate`), ]
  standings$Rank <- seq_len(nrow(standings))
  
  standings <- standings[, c("Rank", "Player", "Wins", "Losses", "Draws", "Win Rate")]
  
  return(standings)
}

# Initialize database
init_db()

# ------------------------------------------------------------------------------
# UI
# ------------------------------------------------------------------------------

ui <- page_navbar(
  title = "♟️ Quarto Tournament Tracker",
  theme = bs_theme(
    bootswatch = "flatly",
    primary = "#2c3e50"
  ),
  
  # Home / Standings Tab
  nav_panel(
    title = "Standings",
    icon = icon("trophy"),
    
    layout_columns(
      col_widths = c(7, 5),
      
      card(
        card_header("🏆 Current Standings"),
        card_body(
          DTOutput("standings_table")
        )
      ),
      
      card(
        card_header("📅 Recent Matches"),
        card_body(
          DTOutput("recent_matches")
        )
      )
    )
  ),
  
 # Record Match Tab
  nav_panel(
    title = "Record Match",
    icon = icon("plus-circle"),
    
    layout_columns(
      col_widths = c(6, 6),
      
      card(
        card_header("📝 New Match"),
        card_body(
          dateInput("match_date", "Date:", value = Sys.Date()),
          
          fluidRow(
            column(6, 
              selectizeInput("white_player", "⬜ White Player:",
                choices = NULL,
                options = list(create = TRUE, placeholder = "Select or type name")
              )
            ),
            column(6,
              selectizeInput("black_player", "⬛ Black Player:",
                choices = NULL,
                options = list(create = TRUE, placeholder = "Select or type name")
              )
            )
          ),
          
          radioButtons("result", "Result:",
            choices = c(
              "White wins" = "white",
              "Black wins" = "black",
              "Draw" = "draw"
            ),
            inline = TRUE
          ),
          
          textAreaInput("notes", "Notes (optional):", 
            placeholder = "Opening, notable moves, etc.",
            rows = 2
          ),
          
          actionButton("submit_match", "Record Match", 
            class = "btn-primary btn-lg w-100 mt-3"
          )
        )
      ),
      
      card(
        card_header("✅ Confirmation"),
        card_body(
          uiOutput("confirmation_message")
        )
      )
    )
  ),
  
  # Match History Tab
  nav_panel(
    title = "History",
    icon = icon("history"),
    
    card(
      card_header(
        class = "d-flex justify-content-between align-items-center",
        span("📜 All Matches"),
        div(
          downloadButton("export_csv", "Export CSV", class = "btn-sm btn-outline-primary me-2"),
          actionButton("refresh_history", "Refresh", class = "btn-sm btn-outline-secondary", icon = icon("sync"))
        )
      ),
      card_body(
        DTOutput("history_table")
      )
    )
  )
)

# ------------------------------------------------------------------------------
# Server
# ------------------------------------------------------------------------------

server <- function(input, output, session) {
  
  # Reactive values
  rv <- reactiveValues(
    matches = get_matches(),
    last_match = NULL
  )
  
  # Update player choices when app loads or matches change
  observe({
    players <- get_players()
    updateSelectizeInput(session, "white_player", choices = players, server = TRUE)
    updateSelectizeInput(session, "black_player", choices = players, server = TRUE)
  })
  
  # Submit match
  observeEvent(input$submit_match, {
    req(input$white_player, input$black_player)
    
    white <- trimws(input$white_player)
    black <- trimws(input$black_player)
    
    # Validation
    if (white == "" || black == "") {
      showNotification("Please enter both player names", type = "error")
      return()
    }
    
    if (tolower(white) == tolower(black)) {
      showNotification("Players must be different!", type = "error")
      return()
    }
    
    # Add match
    add_match(
      match_date = input$match_date,
      white = white,
      black = black,
      result = input$result,
      notes = input$notes
    )
    
    # Store last match for confirmation
    rv$last_match <- list(
      white = white,
      black = black,
      result = input$result,
      date = input$match_date
    )
    
    # Refresh data
    rv$matches <- get_matches()
    
    # Reset form
    updateTextAreaInput(session, "notes", value = "")
    updateSelectizeInput(session, "white_player", selected = "")
    updateSelectizeInput(session, "black_player", selected = "")
    
    # Update player list
    players <- get_players()
    updateSelectizeInput(session, "white_player", choices = players, server = TRUE)
    updateSelectizeInput(session, "black_player", choices = players, server = TRUE)
    
    showNotification("Match recorded!", type = "message")
  })
  
  # Confirmation message
  output$confirmation_message <- renderUI({
    if (is.null(rv$last_match)) {
      return(div(
        class = "text-muted text-center py-4",
        icon("chess", class = "fa-3x mb-3"),
        p("Record a match to see confirmation here")
      ))
    }
    
    m <- rv$last_match
    result_text <- switch(m$result,
      "white" = paste(m$white, "wins!"),
      "black" = paste(m$black, "wins!"),
      "Draw!"
    )
    
    div(
      class = "text-center py-4",
      icon("check-circle", class = "fa-3x text-success mb-3"),
      h4("Match Recorded!"),
      p(
        strong(m$white), " vs ", strong(m$black),
        br(),
        format(m$date, "%B %d, %Y"),
        br(),
        span(class = "badge bg-primary fs-6 mt-2", result_text)
      )
    )
  })
  
  # Standings table
  output$standings_table <- renderDT({
    standings <- calculate_standings(rv$matches)
    
    datatable(
      standings,
      rownames = FALSE,
      options = list(
        pageLength = 10,
        dom = 't',
        ordering = FALSE
      )
    ) |>
      formatStyle("Wins", color = "#27ae60", fontWeight = "bold") |>
      formatStyle("Losses", color = "#e74c3c") |>
      formatStyle("Win Rate", 
        background = styleColorBar(c(0, 100), "#3498db40"),
        backgroundSize = "98% 88%",
        backgroundRepeat = "no-repeat",
        backgroundPosition = "center"
      )
  })
  
  # Recent matches
  output$recent_matches <- renderDT({
    matches <- head(rv$matches, 5)
    
    if (nrow(matches) == 0) {
      return(NULL)
    }
    
    display <- data.frame(
      Date = format(matches$match_date, "%b %d"),
      Match = paste(matches$white_player, "vs", matches$black_player),
      Result = sapply(seq_len(nrow(matches)), function(i) {
        switch(matches$result[i],
          "white" = paste(matches$white_player[i], "wins"),
          "black" = paste(matches$black_player[i], "wins"),
          "Draw"
        )
      })
    )
    
    datatable(
      display,
      rownames = FALSE,
      options = list(
        pageLength = 5,
        dom = 't',
        ordering = FALSE
      )
    )
  })
  
  # History table
  output$history_table <- renderDT({
    matches <- rv$matches
    
    if (nrow(matches) == 0) {
      return(NULL)
    }
    
    display <- data.frame(
      ID = matches$id,
      Date = format(matches$match_date, "%Y-%m-%d"),
      White = matches$white_player,
      Black = matches$black_player,
      Result = sapply(matches$result, function(r) {
        switch(r, "white" = "1-0", "black" = "0-1", "½-½")
      }),
      Winner = ifelse(is.na(matches$winner), "Draw", matches$winner),
      Notes = ifelse(is.na(matches$notes) | matches$notes == "", "-", matches$notes)
    )
    
    datatable(
      display,
      rownames = FALSE,
      selection = "single",
      options = list(
        pageLength = 15,
        order = list(list(1, "desc"))
      ),
      callback = JS("
        table.on('click', 'tr', function() {
          var data = table.row(this).data();
          if (data) {
            Shiny.setInputValue('selected_match_id', data[0], {priority: 'event'});
          }
        });
      ")
    )
  })
  
  # Delete match (click on row then confirm)
  observeEvent(input$selected_match_id, {
    showModal(modalDialog(
      title = "Delete Match?",
      paste("Are you sure you want to delete match #", input$selected_match_id, "?"),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_delete", "Delete", class = "btn-danger")
      )
    ))
  })
  
  observeEvent(input$confirm_delete, {
    delete_match(input$selected_match_id)
    rv$matches <- get_matches()
    removeModal()
    showNotification("Match deleted", type = "message")
  })
  
  # Refresh history
  observeEvent(input$refresh_history, {
    rv$matches <- get_matches()
    showNotification("Refreshed!", type = "message")
  })
  
  # Export CSV
  output$export_csv <- downloadHandler(
    filename = function() {
      paste0("chess_tournament_", Sys.Date(), ".csv")
    },
    content = function(file) {
      write.csv(rv$matches, file, row.names = FALSE)
    }
  )
}

# Run the app
shinyApp(ui, server)
