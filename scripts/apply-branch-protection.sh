#!/usr/bin/env bash
# Usage: ./scripts/apply-branch-protection.sh OWNER/REPO
# Can: gh CLI da dang nhap bang tai khoan co quyen admin tren repo.
set -euo pipefail
REPO="${1:?usage: $0 OWNER/REPO}"
cd "$(dirname "$0")/.."

# Refuse to apply the owner-specific configuration to another repository.
[[ "$REPO" == "vietnamnguyen-owner/ffgg-comp" ]] || {
  echo "This configuration is only for vietnamnguyen-owner/ffgg-comp" >&2
  exit 1
}
owner_id=$(gh api "repos/$REPO" --jq '.owner.id')
[[ "$owner_id" == "127170901" ]] || { echo "Unexpected repository owner" >&2; exit 1; }

# Read errors must stop the script, rather than being mistaken for an absent rule.
rulesets=$(gh api "repos/$REPO/rulesets" --paginate --jq '.[] | [.name, (.id | tostring)] | @tsv')
for name in main-protection main-owner-only; do
  FILE=".github/rulesets/$name.json"
  existing=$(awk -F '\t' -v name="$name" '$1 == name { print $2 }' <<< "$rulesets")
  if [ -n "$existing" ]; then
    echo "Updating $name ($existing)"
    gh api -H 'X-GitHub-Api-Version: 2026-03-10' -X PUT "repos/$REPO/rulesets/$existing" --input "$FILE" >/dev/null
  else
    echo "Creating $name"
    gh api -H 'X-GitHub-Api-Version: 2026-03-10' -X POST "repos/$REPO/rulesets" --input "$FILE" >/dev/null
  fi
done
gh label create needs-human  --repo "$REPO" --color B60205 --description "Agent phai dung, cho nguoi quyet dinh" 2>/dev/null || true
gh label create plan-blocked --repo "$REPO" --color D93F0B --description "Plan sai/thieu, Muse da dung, cho Codex sua plan" 2>/dev/null || true
echo "Done. Check both main-protection and main-owner-only in Settings > Rules > Rulesets."
