# ♟️ Chess Tournament Tracker

A web app for tracking chess tournament results, with a GitHub Pages landing page and R Shiny backend.

## Architecture

```
GitHub Pages (static site)     shinyapps.io (Shiny app)
        │                              │
        │      ┌──────────────┐        │
        └─────►│   Website    │◄───────┘
               │  (iframe)    │
               └──────────────┘
```

- **GitHub Pages**: Hosts the landing page (`docs/index.html`)
- **shinyapps.io**: Runs the actual Shiny app
- The website embeds the Shiny app via iframe

## Quick Start

### Step 1: Deploy Shiny App to shinyapps.io

```r
# Install packages
install.packages(c("shiny", "DBI", "RSQLite", "DT", "bslib", "rsconnect"))

# Set up shinyapps.io account (get credentials from shinyapps.io dashboard)
rsconnect::setAccountInfo(
  name = 'YOUR_USERNAME',
  token = 'YOUR_TOKEN',
  secret = 'YOUR_SECRET'
)

# Deploy the app
rsconnect::deployApp("app")
```

Note your app URL: `https://YOUR_USERNAME.shinyapps.io/app/`

### Step 2: Update the Website

Edit `docs/index.html` and set your Shiny app URL (around line 95):

```javascript
const SHINY_APP_URL = "https://YOUR_USERNAME.shinyapps.io/app/";
```

### Step 3: Push to GitHub

```bash
git init
git add .
git commit -m "Chess tournament tracker"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/chess-tournament.git
git push -u origin main
```

### Step 4: Enable GitHub Pages

1. Go to your repo on GitHub
2. **Settings** → **Pages**
3. Source: **Deploy from a branch**
4. Branch: `main`, Folder: `/docs`
5. Click **Save**

Your site will be live at: `https://YOUR_USERNAME.github.io/chess-tournament/`

---

## Project Structure

```
chess-tournament/
├── app/
│   └── app.R              # Shiny application (deploy to shinyapps.io)
├── docs/
│   └── index.html         # GitHub Pages website (embeds Shiny app)
├── .gitignore
└── README.md
```

## Features

- **Record Matches**: Date, players, result, notes
- **Live Standings**: Auto-calculated rankings
- **Match History**: Full history with CSV export
- **Persistent Storage**: SQLite database
- **Player Autocomplete**: Remembers previous players

## Local Development

### Run Shiny app locally:

```r
shiny::runApp("app")
```

### Preview website locally:

Just open `docs/index.html` in a browser (the iframe won't work until you configure the URL).

---

## Updating the App

After making changes to `app/app.R`:

```r
rsconnect::deployApp("app")
```

After making changes to `docs/`:

```bash
git add docs/
git commit -m "Update website"
git push
```

---

## Troubleshooting

### Shiny app not loading in iframe?

Some browsers block cross-origin iframes. The "Open in new tab" link provides a fallback.

### Data disappeared on shinyapps.io?

Free tier can wipe data on inactivity/redeployment. For reliable persistence, consider:
- Upgrading to paid tier
- Using Google Sheets as backend (let me know if you want this)
- Using an external database

### GitHub Pages not updating?

- Check that you selected `/docs` folder in Pages settings
- Wait a few minutes for propagation
- Check the Actions tab for deployment status

---

## License

MIT
