#!/bin/bash
# Confab Phase 1 Rollback Script
# Safely rollback Phase 1 changes if needed
# Author: Claude
# Date: February 11, 2026

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              ⚠️  ROLLBACK WARNING ⚠️                       ║"
echo "║                                                            ║"
echo "║  This will undo Phase 1 changes:                          ║"
echo "║  • Rollback database migration                            ║"
echo "║  • Restore from backup (if available)                     ║"
echo "║  • Reset git branch                                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

read -p "Are you SURE you want to rollback? [yes/NO] " -r
if [[ ! $REPLY == "yes" ]]; then
    echo "Rollback cancelled"
    exit 0
fi

echo ""
echo -e "${YELLOW}Starting rollback...${NC}"
echo ""

# Find the most recent backup
BACKUP_DIR=$(find backups -type d -name "phase1_*" 2>/dev/null | sort -r | head -n1)

if [[ -n "$BACKUP_DIR" ]]; then
    echo -e "${GREEN}Found backup:${NC} $BACKUP_DIR"
    
    # Rollback database
    echo "Rolling back database migration..."
    if bundle exec rails db:rollback; then
        echo -e "${GREEN}✓${NC} Database rolled back"
    else
        echo -e "${RED}✗${NC} Database rollback failed"
    fi
    
    # Restore files
    echo "Restoring backed up files..."
    
    [[ -f "$BACKUP_DIR/user.rb" ]] && cp "$BACKUP_DIR/user.rb" app/models/
    [[ -f "$BACKUP_DIR/events_controller.rb" ]] && cp "$BACKUP_DIR/events_controller.rb" app/controllers/admin/
    [[ -f "$BACKUP_DIR/invitation_mailer.rb" ]] && cp "$BACKUP_DIR/invitation_mailer.rb" app/mailers/
    [[ -f "$BACKUP_DIR/README.md" ]] && cp "$BACKUP_DIR/README.md" ./
    [[ -f "$BACKUP_DIR/Gemfile" ]] && cp "$BACKUP_DIR/Gemfile" ./
    
    echo -e "${GREEN}✓${NC} Files restored from backup"
    
    # Restore database backup if exists
    if [[ -f "$BACKUP_DIR/development.sqlite3.backup" ]]; then
        cp "$BACKUP_DIR/development.sqlite3.backup" storage/development.sqlite3
        echo -e "${GREEN}✓${NC} Database file restored"
    fi
    
else
    echo -e "${YELLOW}No backup found${NC}"
    echo "Attempting git rollback only..."
fi

# Git rollback
echo "Rolling back git changes..."
CURRENT_BRANCH=$(git branch --show-current)

if [[ $CURRENT_BRANCH == phase1-* ]]; then
    git checkout main 2>/dev/null || git checkout master
    git branch -D "$CURRENT_BRANCH"
    echo -e "${GREEN}✓${NC} Git branch removed: $CURRENT_BRANCH"
else
    git reset --hard HEAD~1
    echo -e "${GREEN}✓${NC} Git reset to previous commit"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Rollback complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Your application should be back to pre-Phase 1 state"
echo ""
echo "Next steps:"
echo "1. Verify: bundle exec rails console"
echo "2. Check: User.column_names.include?('rsvp_status')"
echo "   (should be true after rollback)"
echo "3. Bundle install if needed: bundle install"
echo ""
