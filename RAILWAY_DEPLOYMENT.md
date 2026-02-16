# Railway Deployment Guide for Confab

## What I Just Did:
1. ✅ Created production `Procfile` (web server, background worker, migrations)
2. ✅ Updated `database.yml` to use Postgres in production

## Your Turn - Deploy to Railway:

### Step 1: Commit These Changes
```bash
git add .
git commit -m "Prepare for Railway deployment"
git push origin main
```

### Step 2: Sign Up for Railway
1. Go to https://railway.app
2. Click "Login" → "Login with GitHub"
3. Authorize Railway to access your GitHub account

### Step 3: Create New Project
1. Click "New Project"
2. Select "Deploy from GitHub repo"
3. Choose `blehman12/heybob` from the list
4. Railway will start deploying immediately!

### Step 4: Add Postgres Database
1. In your Railway project dashboard, click "New"
2. Select "Database" → "Add PostgreSQL"
3. Railway automatically connects it to your app via DATABASE_URL

### Step 5: Add Redis (for Sidekiq)
1. Click "New" again
2. Select "Database" → "Add Redis"
3. Railway auto-connects via REDIS_URL

### Step 6: Set Environment Variables
Click on your web service, go to "Variables" tab, and add:

```
RAILS_ENV=production
RAILS_MASTER_KEY=<get this from config/master.key on your computer>
RAILS_SERVE_STATIC_FILES=true
```

**To get your master key:**
```bash
cat config/master.key
```
Copy that value for RAILS_MASTER_KEY.

### Step 7: Configure Domain (Optional)
1. In your web service settings, click "Settings"
2. Under "Networking" you'll see a Railway-provided domain like `heybob-production.up.railway.app`
3. Copy this domain - you'll need it for your event URLs!

### Step 8: Update Event Model for Production URL
After deployment, you'll need to update the `public_url` method in your Event model to use your Railway domain instead of localhost.

## Monitoring Deployment:

Watch the "Deployments" tab - you'll see:
1. Build logs (installing gems, compiling assets)
2. Release command (running migrations)
3. Deploy status

If it goes green ✅ - you're live!

## Costs Estimate:

- **Starter tier** (what you'll likely use):
  - $5/month credit (free!)
  - Web service: ~$2-3/month
  - Postgres: ~$1-2/month  
  - Redis: ~$1/month
  - **Total: Likely under $5/month = FREE**

## Troubleshooting:

**If deployment fails:**
- Check the build logs for errors
- Most common: Missing environment variables

**If app loads but looks broken:**
- Check you set RAILS_MASTER_KEY correctly
- Check database migrations ran (look for "release" logs)

**If Sidekiq isn't running:**
- Railway should auto-detect your Procfile and start both web + worker
- Check the "Processes" tab to verify worker is running

## After First Deploy:

You'll need to:
1. Create your first admin user (via Rails console on Railway)
2. Update event slugs to use production domain
3. Test the public RSVP flow end-to-end

---

Ready? Start with Step 1 (commit and push)!
