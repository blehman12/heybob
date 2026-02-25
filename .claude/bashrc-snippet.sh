# --- EVM1 Claude CLI workflow ---
run-task() {
  local mode=${1:-light}
  local ctx="/mnt/c/evm1/.claude/context.md"
  local task="/mnt/c/evm1/.claude/task.md"
  local mode_file="/mnt/c/evm1/.claude/modes/${mode}.md"

  if [[ ! -f "$mode_file" ]]; then
    echo "Unknown mode: $mode (use: local, light, full)"
    return 1
  fi

  # Show elapsed time on stderr while Claude is thinking
  local start=$SECONDS
  ( while true; do
      sleep 3
      echo -ne "\r  still running... $(( SECONDS - start ))s" >&2
    done ) &
  local timer_pid=$!

  echo "Running task in [${mode}] mode..."
  cat "$ctx" "$task" "$mode_file" | claude --dangerously-skip-permissions --print

  kill $timer_pid 2>/dev/null
  echo >&2
}

alias show-context='cat /mnt/c/evm1/.claude/context.md'
alias run-specs='cd /mnt/c/evm1 && bundle exec rspec --format progress'
run-spec() { cd /mnt/c/evm1 && bundle exec rspec "$1" --format documentation; }
alias smoke='curl -s -o /dev/null -w "/ → %{http_code}\n" https://heybob-production.up.railway.app/ && curl -s -o /dev/null -w "/admin/events → %{http_code}\n" https://heybob-production.up.railway.app/admin/events && curl -s -o /dev/null -w "/e/sakuracon-2026-2026 → %{http_code}\n" https://heybob-production.up.railway.app/e/sakuracon-2026-2026'
# --------------------------------
