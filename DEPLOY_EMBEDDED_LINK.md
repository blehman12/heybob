# Deploy Embedded Link Feature - FINAL STEPS

## Current Status ✅
All code is in place:
- ✅ Controller created
- ✅ View created  
- ✅ Routes added
- ✅ Models updated
- ✅ Migration file created

## What You Need To Do ⚡

### 1. Run the Database Migration
Open PowerShell in `C:\evm1` and run:

```powershell
rails db:migrate
```

This will add:
- `slug` and `public_rsvp_enabled` columns to the `events` table
- Guest fields (`guest_name`, `guest_email`, `guest_phone`, `is_guest`) to `event_participants` table
- Make `user_id` optional for guest RSVPs

### 2. Restart Your Rails Server
After the migration, restart your server:

```powershell
# Press Ctrl+C to stop the current server, then:
rails server
```

### 3. Test the Feature

#### Enable Public RSVP on an Event
1. Go to your Rails console:
   ```powershell
   rails console
   ```

2. Enable public RSVP for your Cinco de Mayo event:
   ```ruby
   event = Event.find_by(name: "Cinco de Mayo Boat Anniversary Party")
   event.update(public_rsvp_enabled: true)
   puts event.public_url
   exit
   ```

3. Copy the URL it prints (will be something like `http://localhost:3000/e/cinco-de-mayo-boat-anniversary-party-2026`)

#### Test the Public Page
1. Open the URL in your browser
2. Try RSVPing **without logging in** - use just a name
3. Add optional email/phone to test guest data collection
4. Submit and verify it works!

## What This Gives You 🎉

**Shareable Links:**
- `http://localhost:3000/e/cinco-de-mayo-boat-anniversary-party-2026`
- Anyone can RSVP without creating an account
- Perfect for Facebook sharing!

**Guest Capture:**
- Name (required)
- Email (optional - for updates)
- Phone (optional)

**Logged-in Users:**
- Can still RSVP on the same page
- Their account info is automatically used

## Troubleshooting

**If you get "column doesn't exist" errors:**
- Make sure you ran `rails db:migrate`
- Check the output - it should show the migration running

**If the migration fails:**
- Make sure your Rails server is stopped before running migrations
- Check the error message carefully

**If you can't access the public URL:**
- Make sure `public_rsvp_enabled` is `true` for the event
- Check that the slug was generated (run `Event.last.slug` in console)

## Next Steps After Testing

Once confirmed working:
1. Enable public RSVP on other events as needed
2. Share links on Facebook instead of sending emails
3. Monitor guest RSVPs in your admin panel

---
**Ready to deploy? Just run `rails db:migrate` and restart your server!**
