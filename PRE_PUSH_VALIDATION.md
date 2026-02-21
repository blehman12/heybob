# EVM1 Pre-Push Validation

## Why This Exists

Railway deploys take 3-5 minutes. A syntax error that slips through means:
push → build → deploy → crash → read logs → fix → push again.
That's easily 10+ minutes for a one-line mistake.

The pre-push validator catches errors **before** they hit Railway.

---

## How It Works

### Automatic (Git Hook)
The validator runs **automatically** on every `git push` via a git pre-push hook
installed at `.git/hooks/pre-push`. If any errors are found, the push is aborted.

To bypass in an emergency (not recommended):
```bash
git push --no-verify
```

### Manual Run
Run it yourself at any time from the project root in WSL:
```bash
~/.rbenv/bin/rbenv exec ruby pre_push_check.rb
```

---

## What It Checks

| Check | What It Catches |
|---|---|
| `ruby -c` syntax | Missing end, bad syntax, typos in .rb files |
| Keyword balance | Unmatched `def`/`do`/`if` vs `end` count per file |
| Brace balance | Mismatched `{}`, `[]`, `()` |
| ERB syntax | Template errors in .html.erb files |
| Controller structure | Missing `private`, unmatched `respond_to` blocks |

---

## Output

**All clear:**
```
✓ ALL CHECKS PASSED — safe to push
```

**Errors (push blocked):**
```
✗ app/controllers/admin/participants_controller.rb: 1 extra `end` — too many by 1
Fix errors above before pushing.
```

**Warnings (push allowed, review recommended):**
```
⚠ app/controllers/admin/events_controller.rb: Missing private section
Push anyway? (warnings are non-blocking)
```

---

## Railway API Utilities

Two helper scripts are also available for checking Railway status from WSL:

### Check deployment status
```bash
bash railway_status.sh
```
Returns the last 3 deployments with status (SUCCESS, CRASHED, REMOVED).

### Pull logs for a specific deployment
```bash
bash railway_logs2.sh
```
Prints readable deploy logs for the most recent crashed deployment.
Update `DEPLOYMENT_ID` in the script to target a different deployment.

### Railway credentials
- **Token:** stored in `railway_status.sh` / `railway_logs2.sh`
- **Project ID:** `cd84274b-b735-436c-9d61-cf24d133f92f`
- **Service ID:** `5a33929a-f70b-4971-ad46-88f54cc543c7`
- **Environment ID:** `f40e4776-260c-4eb2-b46e-343b704fbb5a`
- **App URL:** https://heybob-production.up.railway.app

---

## Adding New Checks

Edit `pre_push_check.rb`. Each check section is clearly labeled with a header comment.
Good candidates for future checks:
- Verify migration files have a matching `down` method
- Detect `binding.pry` or `debugger` left in code
- Check for hardcoded `localhost` in non-dev files
- Validate that new controllers inherit from the right base class

---

## Files

| File | Purpose |
|---|---|
| `pre_push_check.rb` | Main validator script |
| `.git/hooks/pre-push` | Git hook that runs validator automatically |
| `railway_status.sh` | Check Railway deployment status via API |
| `railway_logs2.sh` | Pull Railway deploy logs via API |
