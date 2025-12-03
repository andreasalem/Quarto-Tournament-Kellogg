# ♟️ Chess Tournament Tracker (R Shiny)

A Shiny web app for tracking chess tournament results with persistent SQLite storage.

## Features

- **Record Matches**: Log games with date, players, result, and notes
- **Live Standings**: Auto-calculated rankings by wins and win rate
- **Match History**: View, export, and delete past matches
- **Persistent Storage**: SQLite database persists across sessions
- **Player Autocomplete**: Previous players appear as suggestions
- **Export to CSV**: Download your data anytime

## Local Setup

### Prerequisites

- R (≥ 4.0)
- Required packages:

```r
install.packages(c("shiny", "DBI", "RSQLite", "DT", "bslib"))
```

### Run Locally

```r
shiny::runApp()
```

Or in RStudio, open `app.R` and click "Run App".

---

## Deploy to shinyapps.io

### Step 1: Create Account

1. Go to [shinyapps.io](https://www.shinyapps.io/)
2. Sign up for a free account (25 active hours/month)

### Step 2: Install rsconnect

```r
install.packages("rsconnect")
```

### Step 3: Configure Your Account

1. In shinyapps.io, go to **Account → Tokens**
2. Click **Show Token** and copy the command
3. Run it in R:

```r
rsconnect::setAccountInfo(
  name = 'YOUR_ACCOUNT_NAME',
  token = 'YOUR_TOKEN',
  secret = 'YOUR_SECRET'
)
```
### Step 4: Deploy

```r
# Navigate to your app directory
setwd("/path/to/chess-tournament-shiny")

# Deploy
rsconnect::deployApp()
```

Your app will be live at: `https://YOUR_ACCOUNT.shinyapps.io/chess-tournament-shiny/`

---

## Deploy to GitHub + Host Elsewhere

If you want version control:

```bash
cd chess-tournament-shiny
git init
git add .
git commit -m "Chess tournament tracker"
git remote add origin https://github.com/YOUR-USERNAME/chess-tournament-shiny.git
git push -u origin main
```

### Alternative Hosting Options

| Platform | Free Tier | Notes |
|----------|-----------|-------|
| [shinyapps.io](https://shinyapps.io) | 25 hrs/month | Easiest |
| [Posit Connect Cloud](https://connect.posit.cloud/) | 5 apps | New option |
| Self-hosted (Shiny Server) | Unlimited | Requires server |

---

## File Structure

```
chess-tournament-shiny/
├── app.R                    # Main Shiny application
├── chess_tournament.sqlite  # SQLite database (created on first run)
└── README.md
```

## Data Persistence Notes

- **Local**: SQLite file persists in the app directory
- **shinyapps.io**: Data persists BUT may be wiped on redeployment or after periods of inactivity
- **For production use**: Consider connecting to an external database (PostgreSQL, Google Sheets, etc.)

### Optional: Use Google Sheets for Reliable Persistence

If you need data to persist reliably on shinyapps.io, you can modify the app to use `googlesheets4`. Let me know if you'd like that version!

---

## Customization

- **Theme**: Change `bootswatch = "flatly"` in the `bs_theme()` call to any [Bootswatch theme](https://bootswatch.com/)
- **Add Players**: Players are automatically added when you record their first match
- **Scoring**: Win rate includes draws as 0.5 wins (standard chess scoring)

## License

MIT - Use freely!
