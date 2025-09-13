#!/bin/bash
# shellcheck disable=SC2086

if [[ $GITHUB_EVENT_NAME != "push" && $GITHUB_EVENT_NAME != "pull_request" ]]; then
  echo "::warning title=unsupported::action ran on unsupported event ${GITHUB_EVENT_NAME}"
  exit 0
fi

if [[ -z $BASE_SHA && $GITHUB_EVENT_NAME == "push" ]]; then
  # Use the 'before' SHA from the push payload. It's the most reliable reference.
  BASE_SHA=$(jq -r '.before' "${GITHUB_EVENT_PATH}")

  # If 'before' is the null SHA (all zeros), it's a new branch, and we need a different strategy.
  if [[ "$BASE_SHA" =~ ^0+$ ]]; then
    # Fallback for new branches: count commits and find the Nth parent.
    COMMIT_COUNT=$(jq '.commits | length' "${GITHUB_EVENT_PATH}")
    PROPOSED_BASE="HEAD~${COMMIT_COUNT}"

    # Verify the proposed base commit exists. It won't on an initial repository push.
    if git rev-parse --verify --quiet "$PROPOSED_BASE" >/dev/null 2>&1; then
      BASE_SHA="$PROPOSED_BASE"
    else
      # If the ancestor doesn't exist, it's an initial commit.
      # diff against the "empty tree" to list all files as changed.
      # This special SHA is the well-known hash for an empty tree in Git.
      echo "::debug::Ancestor commit not found. Diffing against empty tree for initial push."
      BASE_SHA="4b825dc642cb6eb9a060e54bf8d69288fbee4904"
    fi
  fi
fi

# The following lines use the determined BASE_SHA to find what changed.
CHANGED="$(git diff --exit-code --quiet ${BASE_SHA} HEAD -- ${DIFF_PATHS} && echo 'false' || echo 'true')"
FILES="$(git diff --name-only ${BASE_SHA} HEAD -- ${DIFF_PATHS} | tr '\n' ' ')"

echo "changed=${CHANGED}" >> "${GITHUB_OUTPUT}"

if [[ $CHANGED == "false" ]]; then
  echo "json=[]" >> "${GITHUB_OUTPUT}"
  echo "❌ no files were changed"
  exit 0
fi

echo "✅ files were changed"

if [[ $FILES ]]; then
  echo "::group::changed files"
  echo $FILES | tr ' ' '\n'
  echo "::endgroup::"

  # send list of files to
  echo "files=${FILES}" >> "${GITHUB_OUTPUT}"
  echo "json=$(jq --compact-output --null-input '$ARGS.positional' --args -- "${FILES}")" >> "${GITHUB_OUTPUT}"
fi
