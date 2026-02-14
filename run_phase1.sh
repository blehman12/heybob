#!/bin/bash
# Confab Phase 1 - Master Control Script
# Orchestrates installation, verification, and rollback
# Author: Claude
# Date: February 11, 2026

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

show_menu() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║        CONFAB PHASE 1 - MASTER CONTROL PANEL              ║"
    echo "║                                                            ║"
    echo "║  Automated implementation of critical fixes:               ║"
    echo "║  • RSVP data model correction                             ║"
    echo "║  • Sidekiq background job system                          ║"
    echo "║  • Email invitation system                                ║"
    echo "║  • Comprehensive documentation                            ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "Select an option:"
    echo ""
    echo -e "${GREEN}1)${NC} 🚀 Install Phase 1 (Full Implementation)"
    echo -e "${BLUE}2)${NC} ✓  Verify Phase 1 Installation"
    echo -e "${YELLOW}3)${NC} 📋 Show Implementation Status"
    echo -e "${RED}4)${NC} ↶  Rollback Phase 1 Changes"
    echo ""
    echo -e "${CYAN}5)${NC} 📖 View Documentation"
    echo -e "${CYAN}6)${NC} 🔧 Test Individual Components"
    echo -e "${CYAN}7)${NC} 💡 Show Next Steps / Help"
    echo ""
    echo "0) Exit"
    echo ""
    echo -n "Enter choice [0-7]: "
}

install_phase1() {
    clear
    echo -e "${GREEN}Starting Phase 1 Installation...${NC}"
    echo ""
    
    if [[ ! -f "$SCRIPT_DIR/phase1_install.sh" ]]; then
        echo -e "${RED}Error: phase1_install.sh not found${NC}"
        echo "Make sure all Phase 1 files are in the same directory"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    chmod +x "$SCRIPT_DIR/phase1_install.sh"
    "$SCRIPT_DIR/phase1_install.sh"
    
    echo ""
    read -p "Press Enter to continue..."
}

verify_installation() {
    clear
    echo -e "${BLUE}Verifying Phase 1 Installation...${NC}"
    echo ""
    
    if [[ ! -f "$SCRIPT_DIR/phase1_verify.sh" ]]; then
        echo -e "${RED}Error: phase1_verify.sh not found${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    chmod +x "$SCRIPT_DIR/phase1_verify.sh"
    "$SCRIPT_DIR/phase1_verify.sh"
    
    echo ""
    read -p "Press Enter to continue..."
}

show_status() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}              PHASE 1 IMPLEMENTATION STATUS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Check if we're in a Rails project
    if [[ ! -f "config/application.rb" ]]; then
        echo -e "${RED}✗ Not in a Rails project directory${NC}"
        echo "  Navigate to your Confab project directory first"
        echo ""
        read -p "Press Enter to continue..."
        return 1
    fi
    
    echo -e "${GREEN}✓ In Rails project directory${NC}"
    echo ""
    
    # Check git branch
    BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    if [[ $BRANCH == phase1-* ]]; then
        echo -e "${YELLOW}Current branch:${NC} $BRANCH (Phase 1 branch)"
    else
        echo -e "${YELLOW}Current branch:${NC} $BRANCH"
    fi
    echo ""
    
    # Check database
    echo -e "${CYAN}Database Status:${NC}"
    if bundle exec rails runner "puts User.column_names.include?('rsvp_status')" 2>/dev/null | grep -q "false"; then
        echo -e "  ${GREEN}✓ RSVP migration applied (users.rsvp_status removed)${NC}"
    else
        echo -e "  ${YELLOW}○ RSVP migration not applied yet${NC}"
    fi
    
    # Check Sidekiq
    echo -e "${CYAN}Sidekiq Status:${NC}"
    if grep -q "gem 'sidekiq'" Gemfile 2>/dev/null; then
        echo -e "  ${GREEN}✓ Sidekiq in Gemfile${NC}"
    else
        echo -e "  ${YELLOW}○ Sidekiq not in Gemfile${NC}"
    fi
    
    if [[ -f "config/sidekiq.yml" ]]; then
        echo -e "  ${GREEN}✓ Sidekiq configured${NC}"
    else
        echo -e "  ${YELLOW}○ Sidekiq not configured${NC}"
    fi
    
    if ps aux | grep -v grep | grep -q sidekiq; then
        echo -e "  ${GREEN}✓ Sidekiq running${NC}"
    else
        echo -e "  ${YELLOW}○ Sidekiq not running${NC}"
    fi
    
    # Check Redis
    echo -e "${CYAN}Redis Status:${NC}"
    if command -v redis-cli &> /dev/null; then
        if redis-cli ping &> /dev/null; then
            echo -e "  ${GREEN}✓ Redis running${NC}"
        else
            echo -e "  ${YELLOW}○ Redis installed but not running${NC}"
        fi
    else
        echo -e "  ${YELLOW}○ Redis not installed${NC}"
    fi
    
    # Check files
    echo -e "${CYAN}Key Files:${NC}"
    [[ -f "app/models/user.rb" ]] && echo -e "  ${GREEN}✓ User model${NC}" || echo -e "  ${RED}✗ User model${NC}"
    [[ -f "app/controllers/admin/events_controller.rb" ]] && echo -e "  ${GREEN}✓ Events controller${NC}" || echo -e "  ${RED}✗ Events controller${NC}"
    [[ -f "app/mailers/invitation_mailer.rb" ]] && echo -e "  ${GREEN}✓ Invitation mailer${NC}" || echo -e "  ${YELLOW}○ Invitation mailer${NC}"
    [[ -f "Procfile.dev" ]] && echo -e "  ${GREEN}✓ Procfile.dev${NC}" || echo -e "  ${YELLOW}○ Procfile.dev${NC}"
    
    # Check documentation
    echo -e "${CYAN}Documentation:${NC}"
    if [[ -f "README.md" ]] && [[ $(wc -l < README.md) -gt 50 ]]; then
        echo -e "  ${GREEN}✓ README.md ($(wc -l < README.md) lines)${NC}"
    else
        echo -e "  ${YELLOW}○ README.md needs updating${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    read -p "Press Enter to continue..."
}

rollback_phase1() {
    clear
    echo -e "${RED}Rollback Phase 1${NC}"
    echo ""
    
    if [[ ! -f "$SCRIPT_DIR/phase1_rollback.sh" ]]; then
        echo -e "${RED}Error: phase1_rollback.sh not found${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    chmod +x "$SCRIPT_DIR/phase1_rollback.sh"
    "$SCRIPT_DIR/phase1_rollback.sh"
    
    echo ""
    read -p "Press Enter to continue..."
}

view_documentation() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                    DOCUMENTATION${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Available documentation files:"
    echo ""
    
    local docs=(
        "INDEX.md:Overview of all Phase 1 files"
        "QUICK_REFERENCE.md:Quick reference for critical changes"
        "PHASE1_CHECKLIST.md:Step-by-step implementation guide"
        "confab_code_review.md:Complete code analysis"
        "SIDEKIQ_SETUP.md:Detailed Sidekiq setup guide"
        "README.md:Project README"
    )
    
    for i in "${!docs[@]}"; do
        IFS=':' read -r file desc <<< "${docs[$i]}"
        if [[ -f "$SCRIPT_DIR/$file" ]]; then
            echo -e "${GREEN}$((i+1)))${NC} $file - $desc"
        else
            echo -e "${YELLOW}$((i+1)))${NC} $file - $desc (not found)"
        fi
    done
    
    echo ""
    echo "0) Back to main menu"
    echo ""
    echo -n "Select document to view [0-${#docs[@]}]: "
    read -r choice
    
    if [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#docs[@]}" ]]; then
        IFS=':' read -r file desc <<< "${docs[$((choice-1))]}"
        if [[ -f "$SCRIPT_DIR/$file" ]]; then
            less "$SCRIPT_DIR/$file"
        else
            echo -e "${RED}File not found: $file${NC}"
            sleep 2
        fi
    fi
}

test_components() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}              TEST INDIVIDUAL COMPONENTS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "1) Test Database Migration"
    echo "2) Test Redis Connection"
    echo "3) Test Sidekiq Connection"
    echo "4) Test Email Sending"
    echo "5) Run RSpec Tests"
    echo "6) Check for user.rsvp_status references"
    echo ""
    echo "0) Back to main menu"
    echo ""
    echo -n "Select test [0-6]: "
    read -r choice
    
    echo ""
    
    case $choice in
        1)
            echo "Testing database migration status..."
            bundle exec rails runner "
                puts 'Users table columns:'
                puts User.column_names.inspect
                puts ''
                puts 'Has rsvp_status: ' + User.column_names.include?('rsvp_status').to_s
            "
            ;;
        2)
            echo "Testing Redis connection..."
            if command -v redis-cli &> /dev/null; then
                redis-cli ping
                echo "Redis is accessible"
            else
                echo -e "${RED}Redis not installed${NC}"
            fi
            ;;
        3)
            echo "Testing Sidekiq connection..."
            bundle exec rails runner "
                require 'sidekiq/api'
                stats = Sidekiq::Stats.new
                puts 'Sidekiq Stats:'
                puts '  Processed: ' + stats.processed.to_s
                puts '  Failed: ' + stats.failed.to_s
                puts '  Queues: ' + Sidekiq::Queue.all.map(&:name).join(', ')
            "
            ;;
        4)
            echo "Testing email sending..."
            bundle exec rails runner "
                participant = EventParticipant.first
                if participant
                    InvitationMailer.event_invitation(participant).deliver_later
                    puts 'Email queued successfully'
                else
                    puts 'No EventParticipant found - create some test data first'
                end
            "
            ;;
        5)
            echo "Running RSpec tests..."
            bundle exec rspec
            ;;
        6)
            echo "Checking for user.rsvp_status references..."
            echo ""
            echo "In controllers:"
            grep -r "user\.rsvp_status" app/controllers/ 2>/dev/null || echo "  None found ✓"
            echo ""
            echo "In views:"
            grep -r "user\.rsvp_status" app/views/ 2>/dev/null || echo "  None found ✓"
            echo ""
            echo "In models:"
            grep -r "enum rsvp_status" app/models/user.rb 2>/dev/null || echo "  None found ✓"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
}

show_next_steps() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                  NEXT STEPS & HELP${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Check if Phase 1 is installed
    if bundle exec rails runner "puts User.column_names.include?('rsvp_status')" 2>/dev/null | grep -q "false"; then
        echo -e "${GREEN}✓ Phase 1 appears to be installed!${NC}"
        echo ""
        echo "Next steps to get your app running:"
        echo ""
        echo "1. Start Redis (if not running):"
        echo -e "   ${YELLOW}redis-server${NC}"
        echo ""
        echo "2. Start your application with Foreman:"
        echo -e "   ${YELLOW}foreman start -f Procfile.dev${NC}"
        echo ""
        echo "   Or in separate terminals:"
        echo -e "   Terminal 1: ${YELLOW}rails server${NC}"
        echo -e "   Terminal 2: ${YELLOW}bundle exec sidekiq -C config/sidekiq.yml${NC}"
        echo ""
        echo "3. Access your application:"
        echo -e "   ${BLUE}http://localhost:3000${NC}"
        echo ""
        echo "4. Access Sidekiq dashboard:"
        echo -e "   ${BLUE}http://localhost:3000/admin/sidekiq${NC}"
        echo ""
        echo "5. Create your first event and test invitations!"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Testing the email system:"
        echo ""
        echo -e "   ${YELLOW}rails console${NC}"
        echo -e "   ${CYAN}> participant = EventParticipant.first${NC}"
        echo -e "   ${CYAN}> InvitationMailer.event_invitation(participant).deliver_later${NC}"
        echo ""
        echo "Check Sidekiq dashboard to see the job processed!"
        echo ""
    else
        echo -e "${YELLOW}Phase 1 not yet installed${NC}"
        echo ""
        echo "To get started:"
        echo ""
        echo "1. Run the installation from the main menu (Option 1)"
        echo ""
        echo "2. The script will:"
        echo "   • Create backups of your current code"
        echo "   • Create a git branch for safety"
        echo "   • Fix the RSVP data model"
        echo "   • Install Sidekiq"
        echo "   • Set up email system"
        echo "   • Update documentation"
        echo ""
        echo "3. Estimated time: 15-20 minutes"
        echo ""
        echo "4. Manual work saved: ~14 hours!"
        echo ""
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Troubleshooting:"
    echo ""
    echo "• Redis not starting:"
    echo -e "  Mac: ${YELLOW}brew services start redis${NC}"
    echo -e "  Linux: ${YELLOW}sudo systemctl start redis${NC}"
    echo ""
    echo "• Sidekiq not processing jobs:"
    echo "  Check Redis is running: redis-cli ping"
    echo "  Check logs: tail -f log/sidekiq.log"
    echo ""
    echo "• Tests failing:"
    echo "  Update test database: RAILS_ENV=test rails db:migrate"
    echo "  Check factories for user.rsvp_status references"
    echo ""
    echo "• Need to rollback:"
    echo "  Use Option 4 from the main menu"
    echo ""
    
    read -p "Press Enter to continue..."
}

# Main loop
main() {
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1) install_phase1 ;;
            2) verify_installation ;;
            3) show_status ;;
            4) rollback_phase1 ;;
            5) view_documentation ;;
            6) test_components ;;
            7) show_next_steps ;;
            0) 
                clear
                echo -e "${GREEN}Thank you for using Confab Phase 1 installer!${NC}"
                echo ""
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

# Check if we're in the right directory
if [[ ! -f "config/application.rb" ]]; then
    echo -e "${RED}Error: Not in a Rails project directory${NC}"
    echo ""
    echo "Please navigate to your Confab project directory and run this script again"
    echo ""
    echo "Example:"
    echo "  cd /path/to/confab"
    echo "  ./run_phase1.sh"
    echo ""
    exit 1
fi

# Run main menu
main
