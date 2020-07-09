#!/usr/bin/env bash

# Exit immediately if a any command exits with a non-zero status
# e.g. pull-request merge fails because of conflict
set -e

# Set destination branch
DEST_BRANCH=$1
BB_EXIT_CODE=$2

#echo "from $BITBUCKET_BRANCH to $DEST_BRANCH"
#echo "by $BITBUCKET_REPO_OWNER / $BITBUCKET_REPO_SLUG"
#echo "$BB_USER / $BB_PASSWORD"

if [[ BB_EXIT_CODE -ne 0 ]]; then
  exit 1
fi

# Create new pull request
echo "Creating PR: $BITBUCKET_BRANCH -> $DEST_BRANCH"
curl -X POST https://api.bitbucket.org/2.0/repositories/$BITBUCKET_REPO_OWNER/$BITBUCKET_REPO_SLUG/pullrequests \
  --fail --show-error --silent \
  --user $BB_USER:$BB_PASSWORD \
  -H 'content-type: application/json' \
  -d '{
    "title": "'$BITBUCKET_BRANCH' -> '$DEST_BRANCH'",
    "description": "automatic PR from pipelines",
    "state": "OPEN",
    "destination": {
      "branch": {
              "name": "'$DEST_BRANCH'"
          }
    },
    "source": {
      "branch": {
              "name": "'$BITBUCKET_BRANCH'"
          }
    },
    "close_source_branch": true
  }'