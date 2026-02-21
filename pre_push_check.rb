#!/usr/bin/env ruby
# evm1 Pre-Push Validator
# Run before every git push to catch errors before the Railway deploy cycle
# Usage: ruby pre_push_check.rb

require 'open3'

RUBY_BIN = File.expand_path("~/.rbenv/bin/rbenv")
RAILS_ROOT = File.expand_path(".")

errors = []
warnings = []
checked = []

# ── Helpers ──────────────────────────────────────────────────────────────────

def rbenv_ruby(args)
  `~/.rbenv/bin/rbenv exec ruby #{args} 2>&1`
end

def colorize(text, color)
  codes = { red: 31, green: 32, yellow: 33, cyan: 36, bold: 1 }
  "\e[#{codes[color]}m#{text}\e[0m"
end

def header(msg)
  puts "\n" + colorize("── #{msg} ", :cyan) + "─" * [0, 50 - msg.length].max
end

# ── Get staged files ──────────────────────────────────────────────────────────

staged = `git diff --cached --name-only --diff-filter=ACM 2>/dev/null`.split("\n")
all_rb  = `git ls-files '*.rb' 2>/dev/null`.split("\n")
all_erb = `git ls-files '*.erb' 2>/dev/null`.split("\n")

changed_rb  = staged.select { |f| f.end_with?('.rb') }
changed_erb = staged.select { |f| f.end_with?('.erb') }

# Fall back to all tracked files if nothing is staged (e.g. pre-commit check)
changed_rb  = all_rb  if changed_rb.empty?
changed_erb = all_erb if changed_erb.empty?

# ── 1. Ruby syntax check ──────────────────────────────────────────────────────

header("Ruby syntax check (ruby -c)")

changed_rb.each do |file|
  next unless File.exist?(file)
  result = rbenv_ruby("-c #{file}")
  if result.include?("Syntax OK")
    puts colorize("  ✓ #{file}", :green)
    checked << file
  else
    puts colorize("  ✗ #{file}", :red)
    result.lines.each { |l| puts "    #{l.chomp}" }
    errors << { file: file, type: :syntax, detail: result }
  end
end

# ── 2. End/def/do balance check ───────────────────────────────────────────────
# Scoped to controllers and models only — these are the files where missing `end`
# actually crashes Railway. Specs, migrations, and config use different patterns
# that produce too many false positives.

header("Keyword balance check — controllers & models only")

OPENERS = %w[def do if unless case begin class module].freeze

BALANCE_SCOPE = %w[app/controllers/ app/models/].freeze

balance_files = changed_rb.select { |f| BALANCE_SCOPE.any? { |scope| f.start_with?(scope) } }

balance_files.each do |file|
  next unless File.exist?(file)
  source = File.read(file)
  lines  = source.lines

  opens = 0
  closes = 0

  lines.each do |line|
    stripped = line.strip
    next if stripped.start_with?('#')

    # Count openers (avoid false positives like 'defined?' or 'end_with?')
    OPENERS.each do |kw|
      opens += line.scan(/\b#{kw}\b/).count { |_| true }
    end
    opens -= line.scan(/\bdefined\?/).count
    opens -= line.scan(/\bend_with\?/).count
    opens -= line.scan(/\bdo_something\b/).count

    # One-liners that open and close on same line (e.g. def foo; bar; end)
    if line =~ /\b(def|if|unless|do|begin)\b.*\bend\b/
      opens  -= 1
      closes -= 1
    end

    closes += line.scan(/\bend\b/).count { |_| true }
    closes -= line.scan(/\bend_with\?/).count
    closes -= line.scan(/\bend_of\b/).count
  end

  diff = opens - closes
  if diff == 0
    puts colorize("  ✓ #{file} (balanced)", :green)
  else
    # Only escalate to error if ruby -c also failed — the counter can't handle
    # Rails idioms like `validates :x, if: :condition` or `before_action unless:`
    syntax_ok = rbenv_ruby("-c #{file}").include?("Syntax OK")
    if diff > 0
      msg = "#{file}: #{diff} unclosed opener(s) — missing #{diff} `end`"
    else
      msg = "#{file}: #{diff.abs} extra `end`(s) — too many by #{diff.abs}"
    end
    if syntax_ok
      puts colorize("  ⚠ #{msg} (ruby -c OK, likely Rails keyword in symbol)", :yellow)
      warnings << { file: file, type: :balance, detail: msg + " [ruby -c passed]" }
    else
      puts colorize("  ✗ #{msg}", :red)
      errors << { file: file, type: :balance, detail: msg }
    end
  end
end

# ── 3. Brace balance check ────────────────────────────────────────────────────
# Also scoped to controllers and models — false positive rate is too high in
# specs and config files (RSpec matchers, Puma DSL, etc.)

header("Brace balance check — controllers & models only")

balance_files.each do |file|
  next unless File.exist?(file)
  source = File.read(file)

  # Strip string contents and comments to avoid false positives
  cleaned = source.gsub(/#.*$/, '').gsub(/"[^"]*"/, '""').gsub(/'[^']*'/, "''")

  curly_diff  = cleaned.count('{') - cleaned.count('}')
  square_diff = cleaned.count('[') - cleaned.count(']')
  paren_diff  = cleaned.count('(') - cleaned.count(')')

  issues = []
  issues << "#{curly_diff > 0 ? 'missing' : 'extra'} #{curly_diff.abs} `}`" if curly_diff != 0
  issues << "#{square_diff > 0 ? 'missing' : 'extra'} #{square_diff.abs} `]`" if square_diff != 0
  issues << "#{paren_diff > 0 ? 'missing' : 'extra'} #{paren_diff.abs} `)`" if paren_diff != 0

  if issues.empty?
    puts colorize("  ✓ #{file}", :green)
  else
    msg = "#{file}: #{issues.join(', ')}"
    puts colorize("  ✗ #{msg}", :yellow)
    warnings << { file: file, type: :braces, detail: msg }
  end
end

# ── 4. ERB tag balance check ──────────────────────────────────────────────────
# NOTE: We intentionally do NOT use `erb -x | ruby -c` here.
# That approach generates false positives on valid Rails form helpers that use
# block syntax (form_with do |f|, etc.) — essentially all real Rails views fail.
# Instead we check what actually matters: unbalanced <% %> tags, which would
# cause a true ERB parse failure at runtime.

header("ERB tag balance check (app/views only)")

erb_scope_files = changed_erb.select { |f| f.start_with?('app/views/') }

erb_scope_files.each do |file|
  next unless File.exist?(file)
  source = File.read(file)

  opens  = source.scan(/<%/).count
  closes = source.scan(/%>/).count
  diff   = opens - closes

  # Also check for obviously unclosed Ruby blocks in ERB (end without opener, etc.)
  # by looking at <% ... %> blocks only
  ruby_lines = source.scan(/<%[^=\-](.*?)%>/m).flatten.join("\n")

  if diff == 0
    puts colorize("  ✓ #{file}", :green)
  else
    direction = diff > 0 ? "missing #{diff} closing `%>`" : "#{diff.abs} extra `%>`"
    msg = "#{file}: #{direction}"
    puts colorize("  ✗ #{msg}", :red)
    errors << { file: file, type: :erb_tags, detail: msg }
  end
end

# ── 5. Controller-specific checks ────────────────────────────────────────────

header("Controller structure check")

changed_rb.select { |f| f.include?('controllers/') }.each do |file|
  next unless File.exist?(file)
  source = File.read(file)
  issues = []

  issues << "respond_to block without end?" if source.include?('respond_to') && source.scan(/respond_to/).count > source.scan(/end/).count - 1
  issues << "Missing private section" if source.include?('def generate_') && !source.include?('private')

  if issues.empty?
    puts colorize("  ✓ #{file}", :green)
  else
    issues.each do |i|
      puts colorize("  ⚠ #{file}: #{i}", :yellow)
      warnings << { file: file, type: :structure, detail: i }
    end
  end
end

# ── Summary ───────────────────────────────────────────────────────────────────

puts "\n" + "─" * 52

if errors.empty? && warnings.empty?
  puts colorize("✓ ALL CHECKS PASSED — safe to push", :green)
  exit 0
elsif errors.empty?
  puts colorize("⚠ #{warnings.count} warning(s) — review before pushing:", :yellow)
  warnings.each { |w| puts "  • #{w[:detail]}" }
  puts colorize("\nPush anyway? (warnings are non-blocking)", :yellow)
  exit 0
else
  puts colorize("✗ #{errors.count} error(s) — DO NOT PUSH:", :red)
  errors.each { |e| puts "  • #{e[:detail]}" }
  puts warnings.map { |w| colorize("  ⚠ #{w[:detail]}", :yellow) }.join("\n") if warnings.any?
  puts "\n" + colorize("Fix errors above before pushing.", :red)
  exit 1
end
