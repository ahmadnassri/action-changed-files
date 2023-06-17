#!/bin/bash
# shellcheck disable=SC2086

if [[ $GITHUB_EVENT_NAME != "push" && $GITHUB_EVENT_NAME != "pull_request" ]]; then
  echo "::warning title=unsupported::action ran on unsupported event ${GITHUB_EVENT_NAME}"
  exit 0
fi

if [[ -z $BASE_SHA && $GITHUB_EVENT_NAME == "push" ]]; then
  BASE_SHA="HEAD~$(jq '.commits | length' "${GITHUB_EVENT_PATH}")" # push events
fi

CHANGED="$(git diff --exit-code --quiet ${BASE_SHA} HEAD -- ${DIFF_PATHS} && echo 'false' || echo 'true')"
FILES="$(git diff --name-only ${BASE_SHA} HEAD -- ${DIFF_PATHS} | tr '\n' ' ')"


echo "changed=${CHANGED}" >> "${GITHUB_OUTPUT}"

if [[ $FILES ]]; then
  echo "files=${FILES}" >> "${GITHUB_OUTPUT}"
  echo "json=$(jq --compact-output --null-input '$ARGS.positional' --args -- "${FILES}")" >> "${GITHUB_OUTPUT}"
else
  echo "json=[]" >> "${GITHUB_OUTPUT}"
fi
