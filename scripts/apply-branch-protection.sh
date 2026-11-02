#!/usr/bin/env bash
# Usage: ./scripts/apply-branch-protection.sh OWNER/REPO
# Can: gh CLI da dang nhap bang tai khoan co quyen admin tren repo.
set -euo pipefail
REPO="${1:?usage: $0 OWNER/REPO}"
FILE=".github/rulesets/main-protection.json"

existing=$(gh api "repos/$REPO/rulesets" --jq '.[] | select(.name=="main-protection") | .id' || true)
if [ -n "$existing" ]; then
  echo "Updating ruleset $existing"
  gh api -X PUT "repos/$REPO/rulesets/$existing" --input "$FILE" >/dev/null
else
  echo "Creating ruleset"
  gh api -X POST "repos/$REPO/rulesets" --input "$FILE" >/dev/null
fi
gh label create needs-human  --repo "$REPO" --color B60205 --description "Agent phai dung, cho nguoi quyet dinh" 2>/dev/null || true
gh label create plan-blocked --repo "$REPO" --color D93F0B --description "Plan sai/thieu, Muse da dung, cho Codex sua plan" 2>/dev/null || true
echo "Done. Kiem tra: Settings > Rules > Rulesets > main-protection"
