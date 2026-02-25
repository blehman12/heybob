## Mode: FULL DEPLOY

After completing all changes and tests:
- If any tests fail: report failures, DO NOT push, stop here
- If tests pass:
  1. git add only the files changed in this task (be specific, not `git add .`)
  2. git commit with the message specified in the task (or a concise summary if none given)
  3. git push origin main
  4. Report commit SHA, then wait 90 seconds for Railway to deploy
  5. Run smoke checks against production:
     curl -s -o /dev/null -w "/ → %{http_code}\n" https://heybob-production.up.railway.app/
     curl -s -o /dev/null -w "/admin/events → %{http_code}\n" https://heybob-production.up.railway.app/admin/events
     curl -s -o /dev/null -w "/e/sakuracon-2026-2026 → %{http_code}\n" https://heybob-production.up.railway.app/e/sakuracon-2026-2026
  6. Report: test results + commit SHA + smoke check HTTP codes
     Flag anything that is not 200 or 302
