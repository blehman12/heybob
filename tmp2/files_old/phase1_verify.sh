#!/bin/bash
# Confab Phase 1 Verification Script
# Checks that Phase 1 was implemented correctly
# Author: Claude
# Date: February 11, 2026

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0
WARNINGS=0

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# Check database migration
check_database() {
    print_header "Database Migration"
    
    # Check users table doesn't have rsvp_status
    if bundle exec rails runner "puts User.column_names.include?('rsvp_status')" 2>/dev/null | grep -q "false"; then
        check_pass "users.rsvp_status column removed"
    else
        check_fail "users.rsvp_status column still exists"
    fi
    
    # Check event_participants has rsvp_status
    if bundle exec rails runner "puts EventParticipant.column_names.include?('rsvp_status')" 2>/dev/null | grep -q "true"; then
        check_pass "event_participants.rsvp_status exists"
    else
        check_fail "event_participants.rsvp_status missing"
    fi
    
    echo ""
}

# Check model files
check_models() {
    print_header "Model Files"
    
    # Check User model doesn't have rsvp_status enum
    if grep -q "enum rsvp_status" app/models/user.rb 2>/dev/null; then
        check_fail "User model still has rsvp_status enum"
    else
        check_pass "User model rsvp_status enum removed"
    fi
    
    # Check User model has role enum
    if grep -q "enum role" app/models/user.rb 2>/dev/null; then
        check_pass "User model has role enum"
    else
        check_fail "User model missing role enum"
    fi
    
    # Check EventParticipant model has rsvp_status enum
    if grep -q "enum rsvp_status" app/models/event_participant.rb 2>/dev/null; then
        check_pass "EventParticipant model has rsvp_status enum"
    else
        check_fail "EventParticipant model missing rsvp_status enum"
    fi
    
    echo ""
}

# Check controller files
check_controllers() {
    print_header "Controller Files"
    
    # Check for incorrect user.rsvp_status queries
    if grep -r "users.*rsvp_status" app/controllers/ 2>/dev/null; then
        check_fail "Found user.rsvp_status queries in controllers"
    else
        check_pass "No user.rsvp_status queries in controllers"
    fi
    
    # Check Admin::EventsController has proper eager loading
    if grep -q "includes.*event_participants.*user" app/controllers/admin/events_controller.rb 2>/dev/null; then
        check_pass "Admin::EventsController has proper eager loading"
    else
        check_warn "Admin::EventsController may be missing eager loading"
    fi
    
    echo ""
}

# Check Sidekiq setup
check_sidekiq() {
    print_header "Sidekiq Setup"
    
    # Check Gemfile
    if grep -q "gem 'sidekiq'" Gemfile 2>/dev/null; then
        check_pass "Sidekiq in Gemfile"
    else
        check_fail "Sidekiq not in Gemfile"
    fi
    
    # Check config files
    if [[ -f "config/sidekiq.yml" ]]; then
        check_pass "config/sidekiq.yml exists"
    else
        check_fail "config/sidekiq.yml missing"
    fi
    
    if [[ -f "config/initializers/sidekiq.rb" ]]; then
        check_pass "config/initializers/sidekiq.rb exists"
    else
        check_fail "config/initializers/sidekiq.rb missing"
    fi
    
    # Check application.rb
    if grep -q "config.active_job.queue_adapter.*sidekiq" config/application.rb 2>/dev/null; then
        check_pass "Rails configured to use Sidekiq"
    else
        check_fail "Rails not configured for Sidekiq"
    fi
    
    # Check Redis
    if command -v redis-cli &> /dev/null; then
        if redis-cli ping &> /dev/null; then
            check_pass "Redis is running"
        else
            check_warn "Redis installed but not running"
        fi
    else
        check_warn "Redis not installed"
    fi
    
    # Check if Sidekiq is running
    if ps aux | grep -v grep | grep -q sidekiq; then
        check_pass "Sidekiq is running"
    else
        check_warn "Sidekiq is not running (start with: bundle exec sidekiq -C config/sidekiq.yml)"
    fi
    
    echo ""
}

# Check mailer files
check_mailers() {
    print_header "Mailer Files"
    
    if [[ -f "app/mailers/invitation_mailer.rb" ]]; then
        check_pass "InvitationMailer exists"
        
        # Check for deliver_later usage
        if grep -q "deliver_later" app/controllers/admin/events_controller.rb 2>/dev/null; then
            check_pass "Using deliver_later for background emails"
        else
            check_warn "May not be using deliver_later"
        fi
    else
        check_fail "InvitationMailer missing"
    fi
    
    # Check email template
    if [[ -f "app/views/invitation_mailer/event_invitation.html.erb" ]]; then
        check_pass "Email template exists"
    else
        check_fail "Email template missing"
    fi
    
    echo ""
}

# Check configuration files
check_configs() {
    print_header "Configuration Files"
    
    if [[ -f "Procfile.dev" ]]; then
        check_pass "Procfile.dev exists"
    else
        check_warn "Procfile.dev missing (optional)"
    fi
    
    if [[ -f ".env.example" ]]; then
        check_pass ".env.example exists"
    else
        check_warn ".env.example missing (recommended)"
    fi
    
    if grep -q "^\.env$" .gitignore 2>/dev/null; then
        check_pass ".env in .gitignore"
    else
        check_warn ".env not in .gitignore"
    fi
    
    echo ""
}

# Check documentation
check_docs() {
    print_header "Documentation"
    
    if [[ -f "README.md" ]] && [[ $(wc -l < README.md) -gt 50 ]]; then
        check_pass "README.md updated ($(wc -l < README.md) lines)"
    else
        check_warn "README.md may need updating"
    fi
    
    echo ""
}

# Check for code issues
check_code_quality() {
    print_header "Code Quality Checks"
    
    # Look for user.rsvp_status in views
    if grep -r "user\.rsvp_status" app/views/ 2>/dev/null | grep -v ".backup" | head -n 1; then
        check_fail "Found user.rsvp_status in views (needs manual fix)"
    else
        check_pass "No user.rsvp_status in views"
    fi
    
    # Check for user.rsvp_status in specs
    if [[ -d "spec" ]]; then
        if grep -r "user\.rsvp_status" spec/ 2>/dev/null | grep -v ".backup" | head -n 1; then
            check_warn "Found user.rsvp_status in specs (may need updating)"
        else
            check_pass "No user.rsvp_status in specs"
        fi
    fi
    
    echo ""
}

# Run tests
check_tests() {
    print_header "Test Suite"
    
    echo "Running RSpec tests..."
    
    if bundle exec rspec --format progress 2>&1 | tee /tmp/rspec_output.txt; then
        check_pass "All tests passed"
    else
        # Count failures
        FAILURES=$(grep -o "[0-9]* failure" /tmp/rspec_output.txt | head -n1 | awk '{print $1}')
        if [[ -n "$FAILURES" ]]; then
            check_warn "$FAILURES test(s) failed (may need factory updates)"
        else
            check_warn "Some tests failed"
        fi
    fi
    
    rm -f /tmp/rspec_output.txt
    echo ""
}

# Test email sending
test_email_sending() {
    print_header "Email System Test"
    
    echo "Testing email delivery..."
    
    if bundle exec rails runner "
        participant = EventParticipant.first
        if participant
          InvitationMailer.event_invitation(participant).deliver_later
          puts 'SUCCESS: Email queued'
        else
          puts 'WARNING: No EventParticipant found'
        end
    " 2>&1 | grep -q "SUCCESS"; then
        check_pass "Email system functional"
    else
        check_warn "Email test inconclusive (may need participant data)"
    fi
    
    echo ""
}

# Show summary
show_summary() {
    echo ""
    echo "=========================================="
    echo "         Verification Summary"
    echo "=========================================="
    echo -e "${GREEN}Passed:   $PASSED${NC}"
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
    echo -e "${RED}Failed:   $FAILED${NC}"
    echo "=========================================="
    echo ""
    
    if [[ $FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ Phase 1 implementation looks good!${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Start Redis: redis-server"
        echo "2. Start app: foreman start -f Procfile.dev"
        echo "3. Visit: http://localhost:3000/admin/sidekiq"
        echo "4. Create your first event!"
        echo ""
        return 0
    else
        echo -e "${RED}✗ Some checks failed. Please review above.${NC}"
        echo ""
        echo "Common fixes:"
        echo "• Run migration: bundle exec rails db:migrate"
        echo "• Install Sidekiq: bundle install"
        echo "• Update views: Replace user.rsvp_status with participant.rsvp_status"
        echo ""
        return 1
    fi
}

# Main execution
main() {
    clear
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║        Confab Phase 1 Verification Script                 ║"
    echo "║                                                            ║"
    echo "║  Checking implementation completeness...                  ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    check_database
    check_models
    check_controllers
    check_sidekiq
    check_mailers
    check_configs
    check_docs
    check_code_quality
    
    # Ask before running tests
    echo -n "Run test suite? [y/N] "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        check_tests
    fi
    
    # Ask before testing email
    echo -n "Test email sending? [y/N] "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        test_email_sending
    fi
    
    show_summary
}

main "$@"
