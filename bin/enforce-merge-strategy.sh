#!/usr/bin/env bash
# enforce-merge-strategy.sh — guarantee every merge uses the project's configured strategy
#
# Reads .factory/merge-config.yaml to determine the required merge strategy and
# delete-branch policy, then refuses any caller-supplied flags that contradict
# the config. On success, executes the merge via gh.
#
# Usage:
#   enforce-merge-strategy.sh <pr-number> --squash --delete-branch [--dry-run]
#   enforce-merge-strategy.sh <pr-number> --merge  --delete-branch [--dry-run]
#   enforce-merge-strategy.sh <pr-number> --rebase --delete-branch [--dry-run]
#
# Arguments:
#   <pr-number>       GitHub PR number (e.g. 4)
#   --squash          Squash-merge strategy
#   --merge           Create-a-merge-commit strategy
#   --rebase          Rebase strategy
#   --delete-branch   Delete the source branch after merge
#   --dry-run         Print the gh command that WOULD be run; exit 0 without merging
#
# Exit:
#   0   Merge executed (or dry-run printed) successfully
#   1   Strategy contradicts config, config missing/unparseable, bad args, merge failed
#
# Governance:
#   D-039: no bypass flags (--force, --skip, allowlists) are permitted.
#          If config says squash, the caller MUST pass --squash — no silent correction.
#   D-040: negative tests must prove this script CAN fail (see tests/ directory).
#
# Design — FAIL CLOSED:
#   If merge-config.yaml is missing or unparseable, exit 1 rather than assuming defaults.
#   If caller passes a contradicting strategy, REFUSE with an explanatory message.
set -euo pipefail

# ── Locate merge-config.yaml relative to this script ─────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MERGE_CONFIG="${SCRIPT_DIR}/../merge-config.yaml"

# ── Usage helper ─────────────────────────────────────────────────────────────
usage() {
  echo "Usage: $(basename "$0") <pr-number> --squash|--merge|--rebase --delete-branch [--dry-run]" >&2
  exit 1
}

# ── Argument parsing ─────────────────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
  usage
fi

PR_NUMBER="$1"
shift

# Validate PR number
if [[ ! "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "ERROR: <pr-number> must be a positive integer, got: '${PR_NUMBER}'" >&2
  usage
fi

DRY_RUN=false
STRATEGY=""
DELETE_BRANCH=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --squash)        STRATEGY="squash" ;;
    --merge)         STRATEGY="merge" ;;
    --rebase)        STRATEGY="rebase" ;;
    --delete-branch) DELETE_BRANCH=true ;;
    --dry-run)       DRY_RUN=true ;;
    *)
      echo "ERROR: unknown flag: '$1'" >&2
      usage
      ;;
  esac
  shift
done

if [[ -z "$STRATEGY" ]]; then
  echo "ERROR: no merge strategy specified; one of --squash, --merge, --rebase is required" >&2
  usage
fi

# ── Load merge-config.yaml — fail closed if missing or unparseable ───────────
if [[ ! -f "$MERGE_CONFIG" ]]; then
  echo "ERROR: merge-config.yaml not found at: ${MERGE_CONFIG}" >&2
  echo "FAIL CLOSED: cannot verify merge strategy without config." >&2
  exit 1
fi

# Parse squash_merge — grep for the top-level key (not indented, not commented)
SQUASH_MERGE_RAW=$(grep -E '^squash_merge:[[:space:]]' "$MERGE_CONFIG" 2>/dev/null || true)
if [[ -z "$SQUASH_MERGE_RAW" ]]; then
  echo "ERROR: squash_merge key missing or unparseable in: ${MERGE_CONFIG}" >&2
  echo "FAIL CLOSED: cannot verify merge strategy without config." >&2
  exit 1
fi
SQUASH_MERGE=$(echo "$SQUASH_MERGE_RAW" | sed 's/^squash_merge:[[:space:]]*//' | tr -d '[:space:]')

# Parse delete_branch_on_merge
DELETE_BRANCH_CONFIG_RAW=$(grep -E '^delete_branch_on_merge:[[:space:]]' "$MERGE_CONFIG" 2>/dev/null || true)
if [[ -z "$DELETE_BRANCH_CONFIG_RAW" ]]; then
  echo "ERROR: delete_branch_on_merge key missing or unparseable in: ${MERGE_CONFIG}" >&2
  echo "FAIL CLOSED: cannot verify merge strategy without config." >&2
  exit 1
fi
DELETE_BRANCH_CONFIG=$(echo "$DELETE_BRANCH_CONFIG_RAW" | sed 's/^delete_branch_on_merge:[[:space:]]*//' | tr -d '[:space:]')

# ── Validate parsed values are recognizable booleans ────────────────────────
case "$SQUASH_MERGE" in
  true|false) ;;
  *)
    echo "ERROR: unrecognized squash_merge value in merge-config.yaml: '${SQUASH_MERGE}'" >&2
    echo "  Expected 'true' or 'false'." >&2
    echo "FAIL CLOSED: cannot verify merge strategy with an invalid config value." >&2
    exit 1
    ;;
esac

case "$DELETE_BRANCH_CONFIG" in
  true|false) ;;
  *)
    echo "ERROR: unrecognized delete_branch_on_merge value in merge-config.yaml: '${DELETE_BRANCH_CONFIG}'" >&2
    echo "  Expected 'true' or 'false'." >&2
    echo "FAIL CLOSED: cannot verify merge strategy with an invalid config value." >&2
    exit 1
    ;;
esac

# ── Determine required strategy from config ──────────────────────────────────
if [[ "$SQUASH_MERGE" == "true" ]]; then
  REQUIRED_STRATEGY="squash"
else
  # squash_merge: false means squash is forbidden; merge or rebase are both allowed
  # We don't have separate rebase_merge/merge_commit flags in this config format,
  # so we accept either non-squash strategy when squash_merge is false.
  REQUIRED_STRATEGY="non-squash"
fi

# ── Enforce strategy — refuse contradicting flags ────────────────────────────
if [[ "$REQUIRED_STRATEGY" == "squash" && "$STRATEGY" != "squash" ]]; then
  echo "ERROR: merge strategy '${STRATEGY}' contradicts merge-config.yaml" >&2
  echo "  merge-config.yaml: squash_merge=true (required strategy: --squash)" >&2
  echo "  Caller requested:  --${STRATEGY}" >&2
  echo "" >&2
  echo "Fix: change your command to use --squash to match the project config." >&2
  exit 1
fi

if [[ "$REQUIRED_STRATEGY" == "non-squash" && "$STRATEGY" == "squash" ]]; then
  echo "ERROR: merge strategy '--squash' contradicts merge-config.yaml" >&2
  echo "  merge-config.yaml: squash_merge=false (squash is forbidden)" >&2
  echo "  Caller requested:  --squash" >&2
  echo "" >&2
  echo "Fix: use --merge or --rebase to match the project config." >&2
  exit 1
fi

# ── Enforce delete-branch policy ─────────────────────────────────────────────
if [[ "$DELETE_BRANCH_CONFIG" == "true" && "$DELETE_BRANCH" == "false" ]]; then
  echo "ERROR: merge-config.yaml requires --delete-branch (delete_branch_on_merge=true)" >&2
  echo "  Add --delete-branch to your command." >&2
  exit 1
fi

if [[ "$DELETE_BRANCH_CONFIG" == "false" && "$DELETE_BRANCH" == "true" ]]; then
  echo "ERROR: merge-config.yaml forbids --delete-branch (delete_branch_on_merge=false)" >&2
  echo "  Remove --delete-branch from your command." >&2
  exit 1
fi

# ── Build gh command arguments as array (no eval, no word-splitting risk) ────
GH_ARGS=(pr merge "$PR_NUMBER" "--${STRATEGY}" --delete-branch)

# ── Dry-run: print and exit without merging ──────────────────────────────────
if [[ "$DRY_RUN" == "true" ]]; then
  echo "DRY RUN — would execute:"
  echo "  gh ${GH_ARGS[*]}"
  exit 0
fi

# ── Execute merge ─────────────────────────────────────────────────────────────
echo "Executing: gh ${GH_ARGS[*]}"
exec gh "${GH_ARGS[@]}"
