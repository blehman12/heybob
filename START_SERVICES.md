# Running Rails + Sidekiq Together

## Option 1: Using Foreman (Recommended)

First, install foreman if you don't have it:
```powershell
gem install foreman
```

Then run both services:
```powershell
foreman start -f Procfile.dev
```

Press `Ctrl+C` to stop both services.

---

## Option 2: Using PowerShell Script

Simply run:
```powershell
.\start_dev.ps1
```

This will:
- Start Sidekiq in the background
- Start Rails server in the foreground
- When you press `Ctrl+C`, it stops both

---

## Option 3: Manual (Two Terminals)

If the above don't work, just use two separate terminals:

**Terminal 1 - Sidekiq:**
```powershell
bundle exec sidekiq
```

**Terminal 2 - Rails:**
```powershell
rails server
```

---

## Which Should You Use?

- **Foreman** = Most professional, logs from both services appear together
- **PowerShell Script** = Simple, works on Windows without extra gems
- **Two Terminals** = Most reliable, easiest to troubleshoot

Try Foreman first, fall back to the PowerShell script if needed!
