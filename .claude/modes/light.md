## Mode: LIGHT DEPLOY

After completing all changes and tests:
- If any tests fail: report failures, DO NOT push, stop here
- If tests pass:
  1. git add only the files changed in this task (be specific, not `git add .`)
  2. git commit with the message specified in the task (or a concise summary if none given)
  3. git push origin main
  4. Report: test results + commit SHA + "Railway deploy triggered"
