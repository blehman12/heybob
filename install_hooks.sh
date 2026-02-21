#!/bin/bash
# Install evm1 git hooks
# Run this after cloning or if hooks stop working: bash install_hooks.sh

HOOKS_DIR="$(git rev-parse --show-toplevel)/.git/hooks"

cat > "$HOOKS_DIR/pre-push" << 'EOF'
#!/bin/bash
cd "$(git rev-parse --show-toplevel)"
~/.rbenv/bin/rbenv exec ruby pre_push_check.rb

if [ $? -ne 0 ]; then
  echo ""
  echo "Push aborted. Fix errors above first."
  echo "To skip (not recommended): git push --no-verify"
  exit 1
fi

exit 0
EOF

chmod +x "$HOOKS_DIR/pre-push"
echo "✓ pre-push hook installed at $HOOKS_DIR/pre-push"
