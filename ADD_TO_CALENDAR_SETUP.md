# Add to Calendar Feature - Quick Setup

## What I Added:

1. **"Add to Calendar" button** on the confirmation page (only shows for "Yes" RSVPs)
2. **Calendar download endpoint** that generates .ics files
3. **icalendar gem** to Gemfile

## To Complete Setup:

### 1. Stop Foreman
Press `Ctrl+C` to stop your server

### 2. Install the Calendar Gem
```powershell
bundle install
```

### 3. Restart Foreman
```powershell
foreman start -f Procfile.dev
```

## How It Works:

When someone RSVPs "Yes":
- They see a green "Add to Calendar" button on the confirmation page
- Clicking it downloads a `.ics` file
- The file works with:
  - Google Calendar
  - Apple Calendar
  - Outlook
  - Any other calendar app

## Test It:

1. Go to `http://localhost:3000/e/cinco-de-mayo-party-2026`
2. RSVP as "Yes"
3. On the confirmation page, click "Add to Calendar"
4. The file will download
5. Open it - your calendar app should prompt to add the event!

---

That's it! No more "don't forget" messages - now they have a button to actually do it.
